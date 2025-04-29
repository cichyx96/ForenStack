resource "aws_s3_bucket" "config-bucket" {
    bucket = "forenstack-config-bucket"
    force_destroy = true
    tags = {
        Name = "forenstack-config-bucket"
        Type = "Forenstack-Terraform"
    }
  
}

output "s3_config_bucket" {
  value = aws_s3_bucket.config-bucket.bucket
  
}