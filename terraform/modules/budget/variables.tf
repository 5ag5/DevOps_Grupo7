variable "name_prefix" {
  type = string
}

variable "limit_usd" {
  description = "Limite mensual en dolares"
  type        = number
  default     = 10
}

variable "email" {
  description = "Correo que recibe las alertas"
  type        = string
}
