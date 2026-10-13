variable "name_prefix" {
  description = "Prefijo para nombrar los recursos (ej. blacklist-dev)"
  type        = string
}

variable "db_port" {
  description = "Puerto de la base de datos"
  type        = number
  default     = 5432
}
