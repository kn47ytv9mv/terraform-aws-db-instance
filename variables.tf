variable "identifier" {
  default     = null
  description = "Identifier of the instance. Must begin with a letter and contain only lowercase alphanumeric characters and hyphens — AWS rejects anything else. If null, a unique identifier is generated."

  validation {
    condition     = var.identifier == null || can(regex("^[a-z][a-z0-9-]*$", var.identifier))
    error_message = "An instance identifier must begin with a letter and contain only lowercase alphanumeric characters and hyphens."
  }
}

variable "engine" {
  default     = null
  description = "Database engine (e.g. 'postgres', 'mysql', 'mariadb', 'oracle-se2', 'sqlserver-ex'). Cannot be changed after creation."
}

variable "engine_version" {
  default     = null
  description = "Engine version (e.g. '17.2'). A partial version ('17') tracks the latest minor release in that major version. If null, AWS picks its own current default for the engine."
}

variable "instance_class" {
  default     = null
  description = "Compute and memory capacity of the instance (e.g. 'db.t4g.micro', 'db.m7g.large'). Instance classes available differ by engine and region."
}

variable "db_name" {
  default     = null
  description = "Name of a database to create inside the instance when it is first provisioned. Not every engine supports this at creation time, and the naming rules are engine-specific. If null, no database is created."
}

variable "username" {
  default     = null
  description = "Master username. Cannot be changed after creation without replacing the instance."
}

variable "password" {
  default     = null
  description = "Master password, stored in Terraform state in plain text. Prefer manage_master_user_password (AWS generates and rotates the password in Secrets Manager) or password_wo (never written to state at all). Mutually exclusive with both."
  sensitive   = true
}

variable "password_wo" {
  default     = null
  description = "Master password as a write-only value — sent to AWS during apply but never persisted to Terraform state. Requires password_wo_version, and changing the password means incrementing that version. Mutually exclusive with password and manage_master_user_password."
  sensitive   = true

  validation {
    condition     = length([for v in [var.password, var.password_wo, var.manage_master_user_password == true ? true : null] : v if v != null]) <= 1
    error_message = "At most one of password, password_wo, or manage_master_user_password may be set."
  }
}

variable "password_wo_version" {
  default     = null
  description = "Version counter for password_wo. Increment it to push a changed password; leaving it unchanged leaves the password alone, since Terraform cannot see the write-only value itself to diff it."

  validation {
    condition     = (var.password_wo == null) == (var.password_wo_version == null)
    error_message = "password_wo and password_wo_version must be set together."
  }
}

variable "manage_master_user_password" {
  default     = null
  description = "Whether AWS generates the master password and manages it in Secrets Manager, including rotation. The recommended option — no password ever passes through Terraform. Mutually exclusive with password and password_wo. If null, AWS's own default (disabled) applies."
}

variable "master_user_secret_kms_key_id" {
  default     = null
  description = "KMS key encrypting the Secrets Manager secret created by manage_master_user_password. If null, AWS's own managed key is used."
}

variable "allocated_storage" {
  default     = null
  description = "Storage allocated to the instance, in gibibytes. Required unless restoring from snapshot_identifier or creating a read replica via replicate_source_db, both of which inherit it."
}

variable "max_allocated_storage" {
  default     = null
  description = "Upper limit, in gibibytes, that storage autoscaling may grow allocated_storage to. If null, storage autoscaling is disabled and the instance is capped at allocated_storage."
}

variable "storage_type" {
  default     = null
  description = "Storage type ('gp3', 'gp2', 'io1', 'io2', or 'standard' for magnetic). If null, AWS picks its own default for the instance class and size."
}

variable "iops" {
  default     = null
  description = "Provisioned IOPS. Only meaningful for 'io1'/'io2', or for 'gp3' above the size threshold at which AWS allows provisioning beyond the baseline."
}

variable "storage_throughput" {
  default     = null
  description = "Provisioned storage throughput in mebibytes per second. Only meaningful for 'gp3'."
}

variable "storage_encrypted" {
  default     = true
  description = "Whether storage is encrypted at rest. Defaults true — an unencrypted database is rarely the intent, and encryption cannot be enabled in place afterward, only by restoring a snapshot into a new instance. Inherited automatically (and not settable) when restoring from a snapshot or creating a read replica."
}

variable "kms_key_id" {
  default     = null
  description = "ARN of the KMS key encrypting storage, from terraform-aws-kms-key. Only used when storage_encrypted is true. If null, AWS's own managed key for RDS is used."
}

variable "db_subnet_group_name" {
  default     = null
  description = "Name of the subnet group placing this instance in a VPC, from terraform-aws-db-subnet-group. If null, the instance lands in the default VPC, which is rarely the intent."
}

variable "vpc_security_group_ids" {
  default     = null
  description = "IDs of the security groups controlling network access to the instance, from terraform-aws-vpc-security-groups."
}

variable "availability_zone" {
  default     = null
  description = "Availability zone to place the instance in. Cannot be combined with multi_az. If null, AWS chooses one from the subnet group."

  validation {
    condition     = var.availability_zone == null || var.multi_az != true
    error_message = "availability_zone cannot be combined with multi_az, since a Multi-AZ instance spans two zones by definition."
  }
}

variable "multi_az" {
  default     = null
  description = "Whether AWS maintains a synchronous standby replica in a second availability zone and fails over to it automatically. Roughly doubles instance cost. If null, AWS's own default (disabled) applies."
}

variable "port" {
  default     = null
  description = "Port the database accepts connections on. If null, the engine's own default applies (5432 for PostgreSQL, 3306 for MySQL and MariaDB)."
}

variable "network_type" {
  default     = null
  description = "Network protocol the instance accepts ('IPV4' or 'DUAL' for dual-stack IPv4 and IPv6). If null, AWS's own default applies."
}

variable "publicly_accessible" {
  default     = false
  description = "Whether the instance gets a public IP address and a publicly resolvable DNS name. Defaults false — a database reachable from the internet is almost never the intent, and security groups are the only thing standing in front of it."
}

variable "parameter_group_name" {
  default     = null
  description = "Name of the parameter group applying engine configuration, from terraform-aws-db-parameter-group. Its family must match this instance's engine and major version. If null, AWS's default parameter group for the engine applies."
}

variable "option_group_name" {
  default     = null
  description = "Name of the option group enabling engine-specific features (Oracle and SQL Server, mainly). If null, AWS's default option group applies."
}

variable "backup_retention_period" {
  default     = 7
  description = "Days of automated backups retained, 0 to 35. Defaults to 7 rather than AWS's own default, matching this family's direction elsewhere of enabling durability protections out of the box. Setting 0 disables automated backups entirely and also disables point-in-time recovery."
}

variable "backup_window" {
  default     = null
  description = "Daily UTC window automated backups are taken in (e.g. '03:00-04:00'). Must not overlap maintenance_window. If null, AWS assigns one."
}

variable "maintenance_window" {
  default     = null
  description = "Weekly UTC window AWS applies maintenance in (e.g. 'sun:05:00-sun:06:00'). If null, AWS assigns one."
}

variable "copy_tags_to_snapshot" {
  default     = true
  description = "Whether the instance's tags are copied onto its snapshots. Defaults true, so a snapshot stays attributable to whatever created it long after the instance is gone."
}

variable "delete_automated_backups" {
  default     = null
  description = "Whether automated backups are deleted along with the instance. If null, AWS's own default (delete them) applies."
}

variable "skip_final_snapshot" {
  default     = false
  description = "Whether destroying the instance skips taking a final snapshot. Defaults false, so data is not lost to a single destroy — which means final_snapshot_identifier must be set. Set true only for an instance genuinely holding nothing worth keeping."
}

variable "final_snapshot_identifier" {
  default     = null
  description = "Name of the snapshot taken when the instance is destroyed. Required unless skip_final_snapshot is true. Must be unique among existing snapshots — reusing the name of one that still exists fails the destroy."

  validation {
    condition     = var.skip_final_snapshot || var.final_snapshot_identifier != null
    error_message = "final_snapshot_identifier is required unless skip_final_snapshot is true, since a destroy would otherwise fail at teardown time rather than here."
  }
}

variable "deletion_protection" {
  default     = false
  description = "Whether AWS refuses to delete the instance while set. Defaults false, since enabling it makes terraform destroy fail until a separate apply turns it off again — worth enabling deliberately for a production database, understanding that teardown then takes two steps."
}

variable "auto_minor_version_upgrade" {
  default     = null
  description = "Whether AWS applies minor engine version upgrades automatically during the maintenance window. If null, AWS's own default (enabled) applies."
}

variable "allow_major_version_upgrade" {
  default     = null
  description = "Whether a change to engine_version crossing a major version is permitted. Without it, AWS rejects the upgrade rather than performing it."
}

variable "apply_immediately" {
  default     = null
  description = "Whether modifications are applied immediately rather than deferred to the next maintenance window. Immediate application can cause downtime and, for some changes, a reboot. If null, AWS's own default (defer) applies."
}

variable "performance_insights_enabled" {
  default     = null
  description = "Whether Performance Insights collects database load metrics. Not supported on every instance class. If null, AWS's own default (disabled) applies."
}

variable "performance_insights_retention_period" {
  default     = null
  description = "Days Performance Insights data is retained. 7 (the free tier) and 731 are always valid; other values must be a multiple of 31. If null, AWS's own default applies."
}

variable "performance_insights_kms_key_id" {
  default     = null
  description = "ARN of the KMS key encrypting Performance Insights data. If null, AWS's own managed key is used."
}

variable "monitoring_interval" {
  default     = null
  description = "Seconds between Enhanced Monitoring metric collections (0 to disable, or 1, 5, 10, 15, 30, 60). Any non-zero value requires monitoring_role_arn. If null, monitoring is disabled."
}

variable "monitoring_role_arn" {
  default     = null
  description = "ARN of an IAM role permitting RDS to publish Enhanced Monitoring metrics to CloudWatch Logs, from terraform-aws-iam-role. Required whenever monitoring_interval is non-zero."

  validation {
    condition     = var.monitoring_interval == null || var.monitoring_interval == 0 || var.monitoring_role_arn != null
    error_message = "monitoring_role_arn is required whenever monitoring_interval is non-zero."
  }
}

variable "enabled_cloudwatch_logs_exports" {
  default     = null
  description = "Log types exported to CloudWatch Logs. Valid types are engine-specific ('postgresql' and 'upgrade' for PostgreSQL; 'audit', 'error', 'general', and 'slowquery' for MySQL and MariaDB). If null, no logs are exported."
}

variable "iam_database_authentication_enabled" {
  default     = null
  description = "Whether database accounts may authenticate with IAM credentials instead of a password. Supported on MySQL, MariaDB, and PostgreSQL only. If null, AWS's own default (disabled) applies."
}

variable "snapshot_identifier" {
  default     = null
  description = "Identifier or ARN of a snapshot to restore this instance from, instead of creating an empty one. Storage encryption and allocated storage are inherited from the snapshot."
}

variable "replicate_source_db" {
  default     = null
  description = "Identifier or ARN of an existing instance to make this one a read replica of. A replica inherits most settings from its source and cannot set db_name or username."
}

variable "ca_cert_identifier" {
  default     = null
  description = "Certificate authority bundle used for the instance's TLS certificate (e.g. 'rds-ca-rsa2048-g1'). If null, AWS's own current default applies."
}

variable "license_model" {
  default     = null
  description = "Licensing model, for engines that offer a choice ('license-included', 'bring-your-own-license', 'general-public-license'). If null, AWS's own default for the engine applies."
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the instance."
}
