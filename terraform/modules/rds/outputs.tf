output "address" {
  description = "Endpoint de la base de datos"
  value       = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "database_url" {
  description = "URL de conexion lista para SQLAlchemy"
  sensitive   = true
  value = format(
    "postgresql://%s:%s@%s:%d/%s?sslmode=require",
    var.db_username,
    urlencode(var.db_password),
    aws_db_instance.this.address,
    aws_db_instance.this.port,
    var.db_name,
  )
}
