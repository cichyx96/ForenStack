variable "create_timesketch" {
  description = "Set to true to create the Timesketch module"
  type        = bool
  default     = false
}

variable "create_velociraptor" {
  description = "Set to true to create the Velociraptor module"
  type        = bool
  default     = true
}