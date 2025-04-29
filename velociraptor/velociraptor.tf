locals {
  s3_config_bucket = var.s3_config_bucket
  forenstack_rsa_key = var.forenstack_rsa_key
  #ssm_instance_profile_name = var.ssm_instance_profile_name
  velociraptor_ec2_tag = "forenstack-velociraptor-ec2"
  velociraptor_merge_config_filename = "server.config.merge.json"
  velociraptor_merge_config_key = "velociraptor/${local.velociraptor_merge_config_filename}"
  velociraptor_merge_config_s3_path = "${local.s3_config_bucket}/${local.velociraptor_merge_config_key}"
  velociraptor_ebs_size = var.velociraptor_ebs_size
  velociraptor_username = "forenstack_admin"
  velociraptor_password_key = "/velociraptor/password"
}

resource "aws_iam_role" "velociraptor_role" {
  name = "velociraptor-role"
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
  role       = aws_iam_role.velociraptor_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# Write to S3 bucket policy
resource "aws_iam_role_policy_attachment" "s3_write_policy_attachment" {
  role       = aws_iam_role.velociraptor_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess" # Should be more restrictive
}
# Read velociraptor password from SSM
resource "aws_iam_role_policy_attachment" "ssm_read_policy_attachment" {
  role       = aws_iam_role.velociraptor_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_instance_profile" "velociraptor_instance_profile" {
  name = "velociraptor-instance-profile"
  role = aws_iam_role.velociraptor_role.name
}

resource "aws_instance" "velociraptor" {
  ami                    = "ami-01c7096235204c7be"
  #instance_type          = "t2.micro"
  instance_type          = "t2.xlarge"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  #user_data_base64 = base64encode("${templatefile(local.user_data_script_location, { BUCKET_NAME = local.s3_config_bucket })}")
  key_name = local.forenstack_rsa_key
  iam_instance_profile = aws_iam_instance_profile.velociraptor_instance_profile.name

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = local.velociraptor_ebs_size
    volume_type = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = local.velociraptor_ec2_tag
    Type = "Forenstack-Terraform"
  }
}

# Copy ansible/timesketch.yml to the S3 bucket
resource "aws_s3_object" "velociraptor_ansible" {
  bucket = local.s3_config_bucket
  key    = "ansible/velociraptor.yml"
  source = "${path.module}/ansible/velociraptor.yml"
  source_hash = filemd5("${path.module}/ansible/velociraptor.yml")
}

# Copy config/server.config.merge.json to the S3 bucket
resource "aws_s3_object" "velociraptor_config" {
  bucket = local.s3_config_bucket
  key    = local.velociraptor_merge_config_key
  source = "${path.module}/config/${local.velociraptor_merge_config_filename}"
  source_hash = filemd5("${path.module}/config/${local.velociraptor_merge_config_filename}")
}

# Generate a random password
resource "random_password" "velociraptor_password" {
  length           = 16
  special          = true
  override_special = "_-" #since password is passed to bash script, we should avoid most special characters
  min_numeric = 1
}

# Store the password in SSM Parameter Store
resource "aws_ssm_parameter" "velociraptor_password" {
  name        = local.velociraptor_password_key
  description = "Password for Velociraptor"
  type        = "SecureString"
  value       = random_password.velociraptor_password.result
}

output "ssm_parameter_name" {
  value = aws_ssm_parameter.velociraptor_password.name
}

resource "aws_ssm_association" "forenstack_ansible" {
  name = "AWS-ApplyAnsiblePlaybooks"
    parameters = {
        SourceType = "S3"
        #SourceInfo = "{\"path\":\"s3://${aws_s3_bucket.config-bucket.bucket}/ansible/\"}"
        SourceInfo = "{\"path\":\"https://s3.amazonaws.com/${local.s3_config_bucket}/ansible/\"}"
        PlaybookFile = "velociraptor.yml"
        ExtraVariables = join(" ", [
            "velociraptor_config_bucket=${local.s3_config_bucket}",
            "velociraptor_config_key=${local.velociraptor_merge_config_key}",
            "velociraptor_config_filename=${local.velociraptor_merge_config_filename}",
            "velociraptor_username=${local.velociraptor_username}",
            "velociraptor_password_key=${local.velociraptor_password_key}",
        ])
        
        
    }
    targets {
        key    = "tag:Name"
        values = [local.velociraptor_ec2_tag]
    }
    output_location {
      s3_bucket_name = local.s3_config_bucket
      s3_key_prefix  = "ansible-logs/"
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
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8889
    to_port     = 8889
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

output "velociraptor_url" {
  value = format("https://%s:8889", aws_instance.velociraptor.public_ip)
  
}

output "velociraptor_username" {
  value = local.velociraptor_username
}

output "velociraptor_password" {
  value = random_password.velociraptor_password.result
  #sensitive = true
}