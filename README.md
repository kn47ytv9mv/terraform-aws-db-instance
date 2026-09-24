# terraform-aws-db-instance

Terraform module for an RDS database instance — a single managed
database server running PostgreSQL, MySQL, MariaDB, Oracle, or SQL
Server.

## Cost

RDS bills per instance-hour by instance class, plus allocated storage,
provisioned IOPS, backup storage beyond the free allotment equal to
the database size, and data transfer. `multi_az` roughly doubles the
instance-hour cost by running a standby. `performance_insights_enabled`
is free at 7-day retention and billed beyond it. See AWS's
[RDS pricing](https://aws.amazon.com/rds/pricing/) page for current
rates.

## Design

For Aurora, use
[`terraform-aws-rds-cluster`](https://github.com/kn47ytv9mv/terraform-aws-rds-cluster)
instead — Aurora is a cluster of compute instances over shared storage,
a genuinely different shape from a single instance with its own
attached volume, and the two do not share a resource.

Pair with
[`terraform-aws-db-subnet-group`](https://github.com/kn47ytv9mv/terraform-aws-db-subnet-group)
to place the instance in a VPC,
[`terraform-aws-db-parameter-group`](https://github.com/kn47ytv9mv/terraform-aws-db-parameter-group)
to configure the engine, and
[`terraform-aws-vpc-security-groups`](https://github.com/kn47ytv9mv/terraform-aws-vpc-security-groups)
to control access. Each is a separate module because each is routinely
shared across several databases.

### Passwords

Three mutually exclusive options, in descending order of preference:

- `manage_master_user_password` — AWS generates the password, stores it
  in Secrets Manager, and rotates it. No password passes through
  Terraform at all. The `master_user_secret` output names the secret
  AWS created.
- `password_wo` with `password_wo_version` — a write-only value, sent
  to AWS during apply but never persisted to Terraform state. Changing
  the password means incrementing the version, since Terraform cannot
  read the value back to diff it.
- `password` — stored in state in plain text. Present because some
  workflows still need it; prefer either option above.

### Defaults chosen over AWS's own

- `storage_encrypted` defaults **true**. Encryption cannot be turned on
  in place later — only by restoring a snapshot into a new instance —
  so the default is the safe one.
- `publicly_accessible` defaults **false**, matching this family's
  direction elsewhere.
- `backup_retention_period` defaults to **7** days, matching
  [`terraform-aws-efs`](https://github.com/kn47ytv9mv/terraform-aws-efs)'s
  choice to enable durability protections out of the box. Setting it to
  `0` disables automated backups *and* point-in-time recovery.
- `copy_tags_to_snapshot` defaults **true**, so a snapshot stays
  attributable after the instance is gone.
- `skip_final_snapshot` defaults **false**, so a single destroy does not
  discard the data. That makes `final_snapshot_identifier` mandatory,
  enforced at plan time rather than surfacing as a failed destroy.
- `deletion_protection` defaults **false**. Enabling it makes
  `terraform destroy` fail until a separate apply turns it off, so the
  two-step teardown is opted into deliberately rather than inherited.

### Deliberately not covered

Blue/green deployments (`blue_green_update`), point-in-time restore
(`restore_to_point_in_time`), S3 import (`s3_import`), and Active
Directory domain joining are not exposed. Each is a materially more
advanced workflow than "run a managed database," and each would carry
significant surface area into a module most callers use without it.
Reach for the raw resource directly if one is needed.

## Usage

```hcl
module "database" {
  source = "kn47ytv9mv/db-instance/aws"

  engine            = "postgres"
  engine_version    = "17"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  db_name  = "app"
  username = "app"

  manage_master_user_password = true

  db_subnet_group_name   = module.subnet_group.name
  vpc_security_group_ids = [module.security_group.id]

  final_snapshot_identifier = "app-final"
}
```

Or directly from this repository, supplying the password as a
write-only value that never reaches Terraform state:

```hcl
module "database" {
  source = "github.com/kn47ytv9mv/terraform-aws-db-instance"

  engine            = "postgres"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  username            = "app"
  password_wo         = var.database_password
  password_wo_version = 1

  final_snapshot_identifier = "app-final"
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.11 |
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| identifier | Identifier of the instance. Must begin with a letter and contain only lowercase alphanumeric characters and hyphens — AWS rejects anything else. If null, a unique identifier is generated. | `null` | no |
| engine | Database engine (e.g. `'postgres'`, `'mysql'`, `'mariadb'`, `'oracle-se2'`, `'sqlserver-ex'`). Cannot be changed after creation. | `null` | no |
| engine_version | Engine version (e.g. `'17.2'`). A partial version (`'17'`) tracks the latest minor release in that major version. If null, AWS picks its own current default for the engine. | `null` | no |
| instance_class | Compute and memory capacity of the instance (e.g. `'db.t4g.micro'`, `'db.m7g.large'`). Instance classes available differ by engine and region. | `null` | no |
| db_name | Name of a database to create inside the instance when it is first provisioned. Not every engine supports this at creation time, and the naming rules are engine-specific. If null, no database is created. | `null` | no |
| username | Master username. Cannot be changed after creation without replacing the instance. | `null` | no |
| password | Master password, stored in Terraform state in plain text. Prefer `manage_master_user_password` or `password_wo`. Mutually exclusive with both. | `null` | no |
| password_wo | Master password as a write-only value — sent to AWS during apply but never persisted to Terraform state. Requires `password_wo_version`. Mutually exclusive with `password` and `manage_master_user_password`. | `null` | no |
| password_wo_version | Version counter for `password_wo`. Increment it to push a changed password. | `null` | no |
| manage_master_user_password | Whether AWS generates the master password and manages it in Secrets Manager, including rotation. The recommended option. Mutually exclusive with `password` and `password_wo`. If null, AWS's own default (disabled) applies. | `null` | no |
| master_user_secret_kms_key_id | KMS key encrypting the Secrets Manager secret created by `manage_master_user_password`. If null, AWS's own managed key is used. | `null` | no |
| allocated_storage | Storage allocated to the instance, in gibibytes. Required unless restoring from `snapshot_identifier` or creating a read replica via `replicate_source_db`. | `null` | no |
| max_allocated_storage | Upper limit, in gibibytes, that storage autoscaling may grow `allocated_storage` to. If null, storage autoscaling is disabled. | `null` | no |
| storage_type | Storage type (`'gp3'`, `'gp2'`, `'io1'`, `'io2'`, or `'standard'`). If null, AWS picks its own default. | `null` | no |
| iops | Provisioned IOPS. Only meaningful for `'io1'`/`'io2'`, or `'gp3'` above the size threshold. | `null` | no |
| storage_throughput | Provisioned storage throughput in mebibytes per second. Only meaningful for `'gp3'`. | `null` | no |
| storage_encrypted | Whether storage is encrypted at rest. Defaults true — encryption cannot be enabled in place afterward. | `true` | no |
| kms_key_id | ARN of the KMS key encrypting storage, from `terraform-aws-kms-key`. If null, AWS's own managed key for RDS is used. | `null` | no |
| db_subnet_group_name | Name of the subnet group placing this instance in a VPC, from `terraform-aws-db-subnet-group`. If null, the instance lands in the default VPC. | `null` | no |
| vpc_security_group_ids | IDs of the security groups controlling network access, from `terraform-aws-vpc-security-groups`. | `null` | no |
| availability_zone | Availability zone to place the instance in. Cannot be combined with `multi_az`. | `null` | no |
| multi_az | Whether AWS maintains a synchronous standby in a second availability zone. Roughly doubles instance cost. | `null` | no |
| port | Port the database accepts connections on. If null, the engine's own default applies. | `null` | no |
| network_type | Network protocol the instance accepts (`'IPV4'` or `'DUAL'`). | `null` | no |
| publicly_accessible | Whether the instance gets a public IP and publicly resolvable DNS name. Defaults false. | `false` | no |
| parameter_group_name | Name of the parameter group, from `terraform-aws-db-parameter-group`. Its family must match this instance's engine and major version. | `null` | no |
| option_group_name | Name of the option group enabling engine-specific features. | `null` | no |
| backup_retention_period | Days of automated backups retained, 0 to 35. Defaults to 7. Setting 0 disables automated backups and point-in-time recovery. | `7` | no |
| backup_window | Daily UTC window automated backups are taken in (e.g. `'03:00-04:00'`). Must not overlap `maintenance_window`. | `null` | no |
| maintenance_window | Weekly UTC window AWS applies maintenance in (e.g. `'sun:05:00-sun:06:00'`). | `null` | no |
| copy_tags_to_snapshot | Whether the instance's tags are copied onto its snapshots. | `true` | no |
| delete_automated_backups | Whether automated backups are deleted along with the instance. | `null` | no |
| skip_final_snapshot | Whether destroying the instance skips taking a final snapshot. Defaults false, which makes `final_snapshot_identifier` required. | `false` | no |
| final_snapshot_identifier | Name of the snapshot taken when the instance is destroyed. Required unless `skip_final_snapshot` is true. Must be unique among existing snapshots. | `null` | no |
| deletion_protection | Whether AWS refuses to delete the instance while set. Enabling it makes `terraform destroy` fail until a separate apply turns it off. | `false` | no |
| auto_minor_version_upgrade | Whether AWS applies minor engine upgrades automatically during the maintenance window. | `null` | no |
| allow_major_version_upgrade | Whether a change to `engine_version` crossing a major version is permitted. | `null` | no |
| apply_immediately | Whether modifications are applied immediately rather than deferred to the next maintenance window. | `null` | no |
| performance_insights_enabled | Whether Performance Insights collects database load metrics. Not supported on every instance class. | `null` | no |
| performance_insights_retention_period | Days Performance Insights data is retained. 7 and 731 are always valid; other values must be a multiple of 31. | `null` | no |
| performance_insights_kms_key_id | ARN of the KMS key encrypting Performance Insights data. | `null` | no |
| monitoring_interval | Seconds between Enhanced Monitoring collections (0 to disable, or 1, 5, 10, 15, 30, 60). Any non-zero value requires `monitoring_role_arn`. | `null` | no |
| monitoring_role_arn | ARN of an IAM role permitting RDS to publish Enhanced Monitoring metrics, from `terraform-aws-iam-role`. | `null` | no |
| enabled_cloudwatch_logs_exports | Log types exported to CloudWatch Logs. Valid types are engine-specific. | `null` | no |
| iam_database_authentication_enabled | Whether database accounts may authenticate with IAM credentials. MySQL, MariaDB, and PostgreSQL only. | `null` | no |
| snapshot_identifier | Identifier or ARN of a snapshot to restore this instance from. Storage encryption and allocated storage are inherited from it. | `null` | no |
| replicate_source_db | Identifier or ARN of an existing instance to make this one a read replica of. | `null` | no |
| ca_cert_identifier | Certificate authority bundle for the instance's TLS certificate (e.g. `'rds-ca-rsa2048-g1'`). | `null` | no |
| license_model | Licensing model, for engines that offer a choice (`'license-included'`, `'bring-your-own-license'`, `'general-public-license'`). | `null` | no |
| tags | A map of tags to assign to the instance. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the instance. |
| arn | The ARN of the instance. |
| identifier | The identifier of the instance. |
| endpoint | Connection endpoint of the instance, as `host:port`. |
| address | Hostname of the instance, without the port. |
| port | Port the instance accepts connections on. |
| hosted_zone_id | Route53 hosted zone ID of the instance's endpoint, for an alias record in `terraform-aws-route53-record`. |
| resource_id | AWS's own immutable ID for the instance, used in IAM database authentication policies. |
| master_user_secret | Secrets Manager secret AWS created for the master password, when `manage_master_user_password` is enabled. Empty otherwise. |

## License

MIT — see [LICENSE.md](LICENSE.md).
