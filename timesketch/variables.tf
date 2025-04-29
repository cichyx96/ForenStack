variable "s3_config_bucket" {
  description = "S3 bucket for storing configuration files"
  type        = string
}

variable "forenstack_rsa_key" {
  description = "RSA key for Forenstack"
  type        = string
}

variable "ssm_instance_profile_name" {
  description = "SSM instance profile name"
  type        = string
  
}