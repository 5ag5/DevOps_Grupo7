resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-db"
  engine         = "postgres"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = 0 # sin storage autoscaling
  storage_type          = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false
  multi_az               = false

  # Sin backups ni snapshot final: se crea y se destruye rapido y no genera costos extra
  backup_retention_period  = var.backup_retention_days
  skip_final_snapshot      = true
  delete_automated_backups = true
  deletion_protection      = false
  apply_immediately        = true
}
