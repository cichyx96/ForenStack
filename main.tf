provider "aws" {
  region = "eu-west-1"
}

locals {
  user_data_script_location = "ec2/user_data.sh"
}

resource "aws_s3_bucket" "config-bucket" {
    bucket = "forenstack-config-bucket"
    
    tags = {
        Name = "forenstack-config-bucket"
        Type = "Forenstack-Terraform"
    }
  
}

# Copy ec2/forenstack_configure.yml to the S3 bucket
resource "aws_s3_object" "forenstack_ansible" {
  bucket = aws_s3_bucket.config-bucket.bucket
  key    = "ansible/forenstack_configure.yml"
  source = "ec2/forenstack_configure.yml"
}

# Copy ec2/timesketch.yml to the S3 bucket
resource "aws_s3_object" "timesketch_ansible" {
  bucket = aws_s3_bucket.config-bucket.bucket
  key    = "ansible/timesketch.yml"
  source = "ec2/timesketch.yml"
}

resource "tls_private_key" "forenstack_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  content  = tls_private_key.forenstack_key.private_key_pem
  filename = "${path.module}/ec2/id_rsa"
}

resource "local_file" "public_key" {
  content  = tls_private_key.forenstack_key.public_key_openssh
  filename = "${path.module}/ec2/id_rsa.pub"
}

resource "aws_key_pair" "forenstack_rsa_key" {
  key_name   = "forenstack_key"
  public_key = tls_private_key.forenstack_key.public_key_openssh

    tags = {
        Name = "forenstack_key"
        Type = "Forenstack-Terraform"
    }
}

# ---------------------- SSM -----------------------  
resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Read from S3 bucket policy
resource "aws_iam_role_policy_attachment" "s3_read_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}
# ----------------------- SSM -----------------------


resource "aws_instance" "web" {
  ami                    = "ami-01c7096235204c7be"
  #instance_type          = "t2.micro"
  instance_type          = "t2.xlarge"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  user_data_base64 = base64encode("${templatefile(local.user_data_script_location, { BUCKET_NAME = aws_s3_bucket.config-bucket.bucket })}")
  key_name = aws_key_pair.forenstack_rsa_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name


  tags = {
    Name = "forenstack-ec2"
    Type = "Forenstack-Terraform"
  }
}

resource "aws_ssm_association" "forenstack_ansible" {
  name = "AWS-ApplyAnsiblePlaybooks"
    parameters = {
        SourceType = "S3"
        #SourceInfo = "{\"path\":\"s3://${aws_s3_bucket.config-bucket.bucket}/ansible/\"}"
        SourceInfo = "{\"path\":\"https://${aws_s3_bucket.config-bucket.bucket}.s3.amazonaws.com/ansible/\"}"
        PlaybookFile = "timesketch.yml"


    }
    targets {
        key    = "tag:Name"
        values = ["forenstack-ec2"]
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