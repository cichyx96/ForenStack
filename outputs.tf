output "url" {
  value = "http://${aws_instance.web.public_ip}"
}

output "private_key_path" {
  value = local_file.private_key.filename
  
}