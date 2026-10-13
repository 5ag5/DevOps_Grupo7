# Los roles solo se crean si create_roles = true.
# Si es false, se usan por nombre roles que ya existen en la cuenta.

locals {
  service_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy",
  ]

  ec2_role_policies = [
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier",
    "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker",
  ]
}

# --- Rol de servicio: lo asume Elastic Beanstalk ---
resource "aws_iam_role" "service" {
  count = var.create_roles ? 1 : 0
  name  = "${var.name_prefix}-eb-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "elasticbeanstalk.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = { StringEquals = { "sts:ExternalId" = "elasticbeanstalk" } }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "service" {
  for_each   = var.create_roles ? toset(local.service_role_policies) : toset([])
  role       = aws_iam_role.service[0].name
  policy_arn = each.value
}

# --- Rol de las instancias EC2 ---
resource "aws_iam_role" "ec2" {
  count = var.create_roles ? 1 : 0
  name  = "${var.name_prefix}-eb-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2" {
  for_each   = var.create_roles ? toset(local.ec2_role_policies) : toset([])
  role       = aws_iam_role.ec2[0].name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "ec2" {
  count = var.create_roles ? 1 : 0
  name  = "${var.name_prefix}-eb-ec2-profile"
  role  = aws_iam_role.ec2[0].name
}
