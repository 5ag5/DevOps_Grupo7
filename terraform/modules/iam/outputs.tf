# depends_on asegura que las politicas esten adjuntas antes de que
# Beanstalk use los roles.

output "service_role_name" {
  value      = var.create_roles ? aws_iam_role.service[0].name : var.existing_service_role_name
  depends_on = [aws_iam_role_policy_attachment.service]
}

output "instance_profile_name" {
  value      = var.create_roles ? aws_iam_instance_profile.ec2[0].name : var.existing_instance_profile_name
  depends_on = [aws_iam_role_policy_attachment.ec2]
}
