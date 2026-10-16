data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Codigo de la aplicacion en S3
# ---------------------------------------------------------------------------
locals {
  zip_hash      = substr(filemd5(var.app_zip_path), 0, 10)
  version_label = coalesce(var.version_label, "v-${local.zip_hash}")
}

resource "aws_s3_bucket" "versions" {
  bucket        = "${var.name_prefix}-eb-versions-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  force_destroy = true
}

resource "aws_s3_object" "app" {
  bucket = aws_s3_bucket.versions.id
  key    = "${var.app_name}/${local.version_label}-${local.zip_hash}.zip"
  source = var.app_zip_path
  etag   = filemd5(var.app_zip_path)
}

# ---------------------------------------------------------------------------
# Aplicacion, version y plataforma
# ---------------------------------------------------------------------------
resource "aws_elastic_beanstalk_application" "this" {
  name        = var.app_name
  description = var.description
}

resource "aws_elastic_beanstalk_application_version" "this" {
  name        = local.version_label
  application = aws_elastic_beanstalk_application.this.name
  bucket      = aws_s3_bucket.versions.id
  key         = aws_s3_object.app.key

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_elastic_beanstalk_solution_stack" "docker" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux 2023 (.*) running Docker$"
}

# ---------------------------------------------------------------------------
# Configuracion del entorno
# ---------------------------------------------------------------------------
locals {
  base_settings = [
    # Tipo de entorno y roles
    { namespace = "aws:elasticbeanstalk:environment", name = "EnvironmentType", value = "LoadBalanced" },
    { namespace = "aws:elasticbeanstalk:environment", name = "LoadBalancerType", value = "application" },
    { namespace = "aws:elasticbeanstalk:environment", name = "ServiceRole", value = var.service_role_name },
    { namespace = "aws:autoscaling:launchconfiguration", name = "IamInstanceProfile", value = var.instance_profile_name },
    { namespace = "aws:autoscaling:launchconfiguration", name = "SecurityGroups", value = join(",", var.instance_security_group_ids) },

    # Capacidad
    { namespace = "aws:ec2:instances", name = "InstanceTypes", value = var.instance_type },
    { namespace = "aws:autoscaling:asg", name = "MinSize", value = tostring(var.min_instances) },
    { namespace = "aws:autoscaling:asg", name = "MaxSize", value = tostring(var.max_instances) },

    # Red
    { namespace = "aws:ec2:vpc", name = "VPCId", value = var.vpc_id },
    { namespace = "aws:ec2:vpc", name = "Subnets", value = join(",", var.subnet_ids) },
    { namespace = "aws:ec2:vpc", name = "ELBSubnets", value = join(",", var.subnet_ids) },
    { namespace = "aws:ec2:vpc", name = "ELBScheme", value = "public" },
    { namespace = "aws:ec2:vpc", name = "AssociatePublicIpAddress", value = "true" },

    # Health checks del balanceador
    { namespace = "aws:elasticbeanstalk:environment:process:default", name = "HealthCheckPath", value = var.health_check_path },
    { namespace = "aws:elasticbeanstalk:environment:process:default", name = "MatcherHTTPCode", value = "200" },
    { namespace = "aws:elasticbeanstalk:environment:process:default", name = "HealthCheckInterval", value = "15" },
    { namespace = "aws:elasticbeanstalk:environment:process:default", name = "HealthCheckTimeout", value = "5" },
    { namespace = "aws:elasticbeanstalk:environment:process:default", name = "HealthyThresholdCount", value = "3" },
    { namespace = "aws:elasticbeanstalk:environment:process:default", name = "UnhealthyThresholdCount", value = "5" },
    { namespace = "aws:elasticbeanstalk:healthreporting:system", name = "SystemType", value = "enhanced" },

    # Estrategia de despliegue
    { namespace = "aws:elasticbeanstalk:command", name = "DeploymentPolicy", value = var.deployment_policy },
    { namespace = "aws:elasticbeanstalk:command", name = "BatchSizeType", value = var.batch_size_type },
    { namespace = "aws:elasticbeanstalk:command", name = "BatchSize", value = tostring(var.batch_size) },
  ]

  traffic_split_settings = var.deployment_policy == "TrafficSplitting" ? [
    { namespace = "aws:elasticbeanstalk:trafficsplitting", name = "NewVersionPercent", value = tostring(var.traffic_split_percent) },
    { namespace = "aws:elasticbeanstalk:trafficsplitting", name = "EvaluationTime", value = tostring(var.traffic_split_evaluation_minutes) },
  ] : []

  # Variables de entorno de la aplicacion (DATABASE_URL, JWT_SECRET_KEY, ...)
  env_var_settings = [
    for k in sort(keys(var.env_vars)) : {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = k
      value     = var.env_vars[k]
    }
  ]

  settings = concat(local.base_settings, local.traffic_split_settings, local.env_var_settings)
}

resource "aws_elastic_beanstalk_environment" "this" {
  name                   = var.env_name
  application            = aws_elastic_beanstalk_application.this.name
  solution_stack_name    = data.aws_elastic_beanstalk_solution_stack.docker.name
  version_label          = aws_elastic_beanstalk_application_version.this.name
  tier                   = "WebServer"
  wait_for_ready_timeout = "30m"

  dynamic "setting" {
    for_each = local.settings
    content {
      namespace = setting.value.namespace
      name      = setting.value.name
      value     = setting.value.value
    }
  }
}
