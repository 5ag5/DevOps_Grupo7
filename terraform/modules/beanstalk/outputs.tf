output "app_url" {
  value = "http://${aws_elastic_beanstalk_environment.this.cname}"
}

output "health_url" {
  value = "http://${aws_elastic_beanstalk_environment.this.cname}${var.health_check_path}"
}

output "environment_name" {
  value = aws_elastic_beanstalk_environment.this.name
}

output "version_label" {
  value = aws_elastic_beanstalk_application_version.this.name
}

output "solution_stack" {
  value = data.aws_elastic_beanstalk_solution_stack.docker.name
}
