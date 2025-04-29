provider "aws" {
  region = "eu-west-1"
}

module "timesketch" {
  source = "./timesketch"
  s3_config_bucket = module.common.s3_config_bucket
  forenstack_rsa_key = module.common.forenstack_rsa_key
  ssm_instance_profile_name = module.common.ssm_instance_profile_name
 
  count = var.create_timesketch ? 1 : 0
}

module "velociraptor" {
  source = "./velociraptor"
  s3_config_bucket = module.common.s3_config_bucket
  forenstack_rsa_key = module.common.forenstack_rsa_key
  ssm_instance_profile_name = module.common.ssm_instance_profile_name
 
  count = var.create_velociraptor ? 1 : 0
}


module "common" {
  source = "./common"
}

# output "ts_url" {
#   value = "http://${module.timesketch.timesketch_external_ip}"
  
# }

output "velo_url" {
  value = var.create_velociraptor && length(module.velociraptor) > 0 ? "${module.velociraptor[0].velociraptor_url}" : null
}

# output "velo_outputs" {
#   value = var.create_velociraptor && length(module.velociraptor) > 0 ? module.velociraptor[0] : null
#   sensitive = false
# }