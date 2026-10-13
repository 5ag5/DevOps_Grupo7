variable "name_prefix" {
  description = "Prefijo para nombrar recursos (bucket)"
  type        = string
}

variable "app_name" {
  description = "Nombre de la aplicacion en Elastic Beanstalk"
  type        = string
}

variable "env_name" {
  description = "Nombre del entorno en Elastic Beanstalk"
  type        = string
}

variable "description" {
  description = "Descripcion de la aplicacion"
  type        = string
  default     = "API de lista negra de emails (Flask + PostgreSQL en Docker)"
}

variable "app_zip_path" {
  description = "Ruta al zip de la aplicacion"
  type        = string
}

variable "version_label" {
  description = "Etiqueta de la version. Vacia = se genera del contenido del zip"
  type        = string
  default     = ""
}

# --- Red y roles ---
variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "instance_security_group_ids" {
  description = "Security groups adicionales para las instancias"
  type        = list(string)
}

variable "service_role_name" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

# --- Aplicacion ---
variable "env_vars" {
  description = "Variables de entorno de la aplicacion"
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

# --- Capacidad ---
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_instances" {
  type    = number
  default = 1
}

variable "max_instances" {
  type    = number
  default = 2
}

# --- Estrategia de despliegue ---
variable "deployment_policy" {
  description = "AllAtOnce | Rolling | RollingWithAdditionalBatch | Immutable | TrafficSplitting"
  type        = string
  default     = "AllAtOnce"

  validation {
    condition     = contains(["AllAtOnce", "Rolling", "RollingWithAdditionalBatch", "Immutable", "TrafficSplitting"], var.deployment_policy)
    error_message = "deployment_policy debe ser AllAtOnce, Rolling, RollingWithAdditionalBatch, Immutable o TrafficSplitting."
  }
}

variable "batch_size_type" {
  type    = string
  default = "Fixed"
}

variable "batch_size" {
  type    = number
  default = 1
}

variable "traffic_split_percent" {
  type    = number
  default = 20
}

variable "traffic_split_evaluation_minutes" {
  type    = number
  default = 5
}
