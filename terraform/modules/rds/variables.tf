variable "name_prefix" {
  description = "Prefijo para nombrar la base de datos"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos inicial"
  type        = string
}

variable "db_username" {
  description = "Usuario maestro"
  type        = string
}

variable "db_password" {
  description = "Contrasena maestra"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "Tipo de instancia de RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Tamano del disco en GiB"
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Dias de backups automaticos (0 = desactivados)"
  type        = number
  default     = 0
}

variable "security_group_ids" {
  description = "Security groups de la base de datos"
  type        = list(string)
}
