# VPC y subredes por defecto de la region
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Security group adicional para las instancias de Beanstalk.
# Beanstalk crea su propio grupo (AWSEBSecurityGroup); este se agrega para que
# RDS pueda referenciarlo y Terraform controle el orden al destruir.
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Instancias de Elastic Beanstalk (${var.name_prefix})"
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Salida a internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS solo acepta conexiones a PostgreSQL desde las instancias de Beanstalk
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "PostgreSQL (${var.name_prefix})"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "PostgreSQL desde Elastic Beanstalk"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
