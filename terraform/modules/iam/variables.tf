variable "name_prefix" {
  description = "Prefijo para nombrar los roles"
  type        = string
}

variable "create_roles" {
  description = "true = crea los roles. false = usa roles existentes"
  type        = bool
  default     = true
}

variable "existing_service_role_name" {
  description = "Rol de servicio existente (solo si create_roles = false)"
  type        = string
  default     = "aws-elasticbeanstalk-service-role"
}

variable "existing_instance_profile_name" {
  description = "Perfil de instancia existente (solo si create_roles = false)"
  type        = string
  default     = "aws-elasticbeanstalk-ec2-role"
}
