mock_provider "aws" {}

run "invalid_identifier_is_rejected" {
  command = plan

  variables {
    identifier          = "0Bad_Identifier"
    instance_class      = "db.t4g.micro"
    engine              = "postgres"
    skip_final_snapshot = true
  }

  expect_failures = [var.identifier]
}

run "final_snapshot_identifier_required_unless_skipped" {
  command = plan

  variables {
    instance_class = "db.t4g.micro"
    engine         = "postgres"
  }

  expect_failures = [var.final_snapshot_identifier]
}

run "password_and_manage_master_user_password_are_mutually_exclusive" {
  command = plan

  variables {
    instance_class              = "db.t4g.micro"
    engine                      = "postgres"
    skip_final_snapshot         = true
    password                    = "correct-horse-battery-staple"
    manage_master_user_password = true
  }

  expect_failures = [var.password_wo]
}

run "password_wo_requires_its_version" {
  command = plan

  variables {
    instance_class      = "db.t4g.micro"
    engine              = "postgres"
    skip_final_snapshot = true
    password_wo         = "correct-horse-battery-staple"
  }

  expect_failures = [var.password_wo_version]
}

run "monitoring_interval_requires_a_role" {
  command = plan

  variables {
    instance_class      = "db.t4g.micro"
    engine              = "postgres"
    skip_final_snapshot = true
    monitoring_interval = 60
  }

  expect_failures = [var.monitoring_role_arn]
}

run "availability_zone_conflicts_with_multi_az" {
  command = plan

  variables {
    instance_class      = "db.t4g.micro"
    engine              = "postgres"
    skip_final_snapshot = true
    availability_zone   = "us-east-1a"
    multi_az            = true
  }

  expect_failures = [var.availability_zone]
}

run "identifier_defaults_to_prefixed_random_uuid" {
  command = apply

  variables {
    instance_class      = "db.t4g.micro"
    engine              = "postgres"
    skip_final_snapshot = true
  }

  assert {
    condition     = aws_db_instance.resource.identifier == "db-${random_uuid.resource.id}"
    error_message = "Leaving identifier unset should fall back to a letter-prefixed random_uuid, since AWS rejects an identifier that does not begin with a letter."
  }
}

run "secure_defaults_are_applied" {
  command = plan

  variables {
    instance_class      = "db.t4g.micro"
    engine              = "postgres"
    skip_final_snapshot = true
  }

  assert {
    condition     = aws_db_instance.resource.storage_encrypted == true
    error_message = "Storage encryption should be enabled by default."
  }

  assert {
    condition     = aws_db_instance.resource.publicly_accessible == false
    error_message = "The instance should not be publicly accessible by default."
  }

  assert {
    condition     = aws_db_instance.resource.backup_retention_period == 7
    error_message = "Automated backups should be retained for 7 days by default."
  }

  assert {
    condition     = aws_db_instance.resource.copy_tags_to_snapshot == true
    error_message = "Tags should be copied to snapshots by default."
  }
}

run "monitoring_role_accepted_when_interval_set" {
  command = plan

  variables {
    instance_class      = "db.t4g.micro"
    engine              = "postgres"
    skip_final_snapshot = true
    monitoring_interval = 60
    monitoring_role_arn = "arn:aws:iam::123456789012:role/rds-monitoring"
  }

  assert {
    condition     = aws_db_instance.resource.monitoring_interval == 60
    error_message = "A monitoring interval paired with a role should pass through unchanged."
  }
}

run "readme_default_example" {
  command = plan

  variables {
    engine                      = "postgres"
    engine_version              = "17"
    instance_class              = "db.t4g.micro"
    allocated_storage           = 20
    db_name                     = "app"
    username                    = "app"
    manage_master_user_password = true
    db_subnet_group_name        = "production-database"
    vpc_security_group_ids      = ["sg-1111"]
    final_snapshot_identifier   = "app-final"
  }
}

run "readme_write_only_password_example" {
  command = plan

  variables {
    engine                    = "postgres"
    instance_class            = "db.t4g.micro"
    allocated_storage         = 20
    username                  = "app"
    password_wo               = "correct-horse-battery-staple"
    password_wo_version       = 1
    final_snapshot_identifier = "app-final"
  }
}
