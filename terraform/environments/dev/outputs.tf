output "app_url" {
  description = "URL de la aplicacion"
  value       = module.beanstalk.app_url
}

output "health_url" {
  description = "URL del health check"
  value       = module.beanstalk.health_url
}

output "environment_name" {
  description = "Nombre del entorno en Elastic Beanstalk"
  value       = module.beanstalk.environment_name
}

output "version_desplegada" {
  value = module.beanstalk.version_label
}

output "estrategia_de_despliegue" {
  value = var.deployment_policy
}

output "rds_endpoint" {
  value = module.rds.address
}

output "plataforma" {
  value = module.beanstalk.solution_stack
}
