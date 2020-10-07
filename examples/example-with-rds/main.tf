# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A DATABASE IN AWS
# These templates show an example of how to use the snapshot_identifiers and snapshot_maintenance sub-modules.
#
# This top level module is intended as an example ffor testing and for simple databases only.
#
# The intention is that the two snapshot modules be used in conjunction with other database modules
# such as `terraform-aws-modules/rds/aws` or `claranet/aurora/aws` (for example) giving the user complete flexibility 
# over the database or cluster they wish to create.
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">=0.11.2"
}

provider "aws" {
  region = "eu-west-1"
}

module "snapshot_maintenance" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  #   source = "git::git@github.com:connect-group/terraform-aws-rds-finalsnapshot.git//modules/rds_snapshot_maintenance?ref=v1.0.0"
  # Or the public registry,
  #   source = "connect-group/rds-finalsnapshot/aws//modules/rds_snapshot_maintenance"
  #   version="1.0.0"
  source = "../../modules/rds_snapshot_maintenance"

  identifier                           = "demodbinstance"
  is_cluster                           = false
  database_endpoint                    = aws_db_instance.database.endpoint
  number_of_snapshots_to_retain        = 1
  override_restore_snapshot_identifier = var.restore_snapshot
}

resource "aws_db_instance" "database" {
  identifier           = module.snapshot_maintenance.identifier
  allocated_storage    = 5
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "demodb"
  username             = "master"
  password             = "IHaveThePower!"
  parameter_group_name = aws_db_parameter_group.dbparameters.name

  snapshot_identifier       = module.snapshot_maintenance.snapshot_to_restore
  final_snapshot_identifier = module.snapshot_maintenance.final_snapshot_identifier
  backup_retention_period   = 0
}

resource "aws_db_parameter_group" "dbparameters" {
  name   = "example-db-parameter-group"
  family = "mysql5.7"

  parameter {
    name         = "character_set_server"
    value        = "utf8"
    apply_method = "immediate"
  }

  parameter {
    name         = "character_set_database"
    value        = "utf8"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_server"
    value        = "utf8_unicode_ci"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_connection"
    value        = "utf8_unicode_ci"
    apply_method = "immediate"
  }

  parameter {
    name         = "lower_case_table_names"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "wait_timeout"
    value        = 300
    apply_method = "immediate"
  }

  parameter {
    name         = "event_scheduler"
    value        = "ON"
    apply_method = "immediate"
  }
}

