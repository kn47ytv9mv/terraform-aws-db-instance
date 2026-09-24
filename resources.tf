resource "random_uuid" "resource" {}

resource "aws_db_instance" "resource" {
  identifier     = coalesce(var.identifier, "db-${random_uuid.resource.id}")
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.username

  password                      = var.password
  password_wo                   = var.password_wo
  password_wo_version           = var.password_wo_version
  manage_master_user_password   = var.manage_master_user_password
  master_user_secret_kms_key_id = var.master_user_secret_kms_key_id

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_throughput    = var.storage_throughput
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  availability_zone      = var.availability_zone
  multi_az               = var.multi_az
  port                   = var.port
  network_type           = var.network_type
  publicly_accessible    = var.publicly_accessible

  parameter_group_name = var.parameter_group_name
  option_group_name    = var.option_group_name

  backup_retention_period  = var.backup_retention_period
  backup_window            = var.backup_window
  maintenance_window       = var.maintenance_window
  copy_tags_to_snapshot    = var.copy_tags_to_snapshot
  delete_automated_backups = var.delete_automated_backups

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier
  deletion_protection       = var.deletion_protection

  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn

  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  snapshot_identifier = var.snapshot_identifier
  replicate_source_db = var.replicate_source_db
  ca_cert_identifier  = var.ca_cert_identifier
  license_model       = var.license_model

  tags = var.tags
}

output "id" {
  description = "The ID of the instance."
  value       = aws_db_instance.resource.id
}

output "arn" {
  description = "The ARN of the instance."
  value       = aws_db_instance.resource.arn
}

output "identifier" {
  description = "The identifier of the instance."
  value       = aws_db_instance.resource.identifier
}

output "endpoint" {
  description = "Connection endpoint of the instance, as host:port."
  value       = aws_db_instance.resource.endpoint
}

output "address" {
  description = "Hostname of the instance, without the port."
  value       = aws_db_instance.resource.address
}

output "port" {
  description = "Port the instance accepts connections on."
  value       = aws_db_instance.resource.port
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID of the instance's endpoint, for an alias record in terraform-aws-route53-record."
  value       = aws_db_instance.resource.hosted_zone_id
}

output "resource_id" {
  description = "AWS's own immutable ID for the instance, used in IAM database authentication policies."
  value       = aws_db_instance.resource.resource_id
}

output "master_user_secret" {
  description = "Secrets Manager secret AWS created for the master password, when manage_master_user_password is enabled. Empty otherwise."
  value       = aws_db_instance.resource.master_user_secret
}
