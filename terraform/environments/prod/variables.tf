# ---------------------------------------------------------------------------
# Generales
# ---------------------------------------------------------------------------
variable "region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-2"
}

variable "project" {
  description = "Nombre del proyecto (prefijo de todos los recursos)"
  type        = string
  default     = "blacklist"
}

variable "environment" {
  description = "Nombre del entorno"
  type        = string
  default     = "prod"
}

# ---------------------------------------------------------------------------
# Aplicacion
# ---------------------------------------------------------------------------
variable "app_zip_path" {
  description = "Ruta al zip de la app, relativa a esta carpeta (lo genera scripts/empaquetar)"
  type        = string
  default     = "../../../blacklist.zip"
}

variable "version_label" {
  description = "Etiqueta de la version (v1, v2...). Vacia = se genera del contenido del zip"
  type        = string
  default     = ""
}

variable "jwt_secret_key" {
  description = "Clave con la que Flask-JWT-Extended firma y valida los tokens"
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Base de datos
# ---------------------------------------------------------------------------
variable "db_name" {
  type    = string
  default = "blacklist_db"
}

variable "db_username" {
  type    = string
  default = "postgres"
}

variable "db_password" {
  description = "Contrasena de PostgreSQL (minimo 8 caracteres, sin / @ \" ni espacios)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8 && !can(regex("[/@\" ]", var.db_password))
    error_message = "La contrasena debe tener al menos 8 caracteres y no puede contener / @ \" ni espacios."
  }
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

# ---------------------------------------------------------------------------
# Capacidad
# ---------------------------------------------------------------------------
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_instances" {
  type    = number
  default = 3
}

variable "max_instances" {
  type    = number
  default = 6
}

# ---------------------------------------------------------------------------
# Estrategia de despliegue
# ---------------------------------------------------------------------------
variable "deployment_policy" {
  description = "AllAtOnce | Rolling | RollingWithAdditionalBatch | Immutable | TrafficSplitting"
  type        = string
  default     = "Rolling"
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

# ---------------------------------------------------------------------------
# Roles de IAM
# ---------------------------------------------------------------------------
variable "create_iam_roles" {
  description = "true = Terraform crea los roles. false = usa roles existentes"
  type        = bool
  default     = true
}

variable "service_role_name" {
  description = "Rol de servicio existente (solo si create_iam_roles = false)"
  type        = string
  default     = "aws-elasticbeanstalk-service-role"
}

variable "instance_profile_name" {
  description = "Perfil de instancia existente (solo si create_iam_roles = false)"
  type        = string
  default     = "aws-elasticbeanstalk-ec2-role"
}

# ---------------------------------------------------------------------------
# Presupuesto
# ---------------------------------------------------------------------------
variable "budget_email" {
  description = "Correo para alertas de gasto. Vacio = no se crea la alerta"
  type        = string
  default     = ""
}

variable "budget_limit_usd" {
  description = "Limite mensual de la alerta en dolares"
  type        = number
  default     = 10
}
