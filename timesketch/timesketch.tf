locals {
  user_data_script_location = "ec2/user_data.sh"
  s3_config_bucket = var.s3_config_bucket
  forenstack_rsa_key = var.forenstack_rsa_key
  ssm_instance_profile_name = var.ssm_instance_profile_name
  timesketch_ec2_tag = "forenstack-timesketch-ec2"
}








resource "aws_instance" "timesketch" {
  ami                    = "ami-01c7096235204c7be"
  #instance_type          = "t2.micro"
  instance_type          = "t2.xlarge"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  #user_data_base64 = base64encode("${templatefile(local.user_data_script_location, { BUCKET_NAME = local.s3_config_bucket })}")
  key_name = local.forenstack_rsa_key
  iam_instance_profile = local.ssm_instance_profile_name


  tags = {
    Name = local.timesketch_ec2_tag
    Type = "Forenstack-Terraform"
  }
}

# Copy ansible/timesketch.yml to the S3 bucket
resource "aws_s3_object" "timesketch_ansible" {
  bucket = local.s3_config_bucket
  key    = "ansible/timesketch.yml"
  source = "${path.module}/ansible/timesketch.yml"
}

resource "aws_ssm_association" "forenstack_ansible" {
  name = "AWS-ApplyAnsiblePlaybooks"
    parameters = {
        SourceType = "S3"
        #SourceInfo = "{\"path\":\"s3://${aws_s3_bucket.config-bucket.bucket}/ansible/\"}"
        SourceInfo = "{\"path\":\"https://s3.amazonaws.com/${local.s3_config_bucket}/ansible/\"}"
        PlaybookFile = "timesketch.yml"


    }
    targets {
        key    = "tag:Name"
        values = [local.timesketch_ec2_tag]
    }
}


resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow outbound traffic for SSM"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "timesketch_external_ip" {
  value = aws_instance.timesketch.public_ip
  
}