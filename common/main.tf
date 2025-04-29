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

output "forenstack_rsa_key" {
  value = aws_key_pair.forenstack_rsa_key.key_name
  
}
