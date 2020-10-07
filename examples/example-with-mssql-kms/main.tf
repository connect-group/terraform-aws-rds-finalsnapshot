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
  source                               = "../../modules/rds_snapshot_maintenance"
  identifier                           = "demomssqlinstance"
  is_cluster                           = false
  database_endpoint                    = aws_db_instance.database.endpoint
  number_of_snapshots_to_retain        = 1
  override_restore_snapshot_identifier = var.restore_snapshot
}

resource "aws_db_instance" "database" {
  identifier        = module.snapshot_maintenance.identifier
  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "sqlserver-web"
  engine_version    = "14.00.3015.40.v1"
  instance_class    = "db.t2.medium"

  username = "master"
  password = "IHaveThePower!"

  snapshot_identifier       = module.snapshot_maintenance.snapshot_to_restore
  final_snapshot_identifier = module.snapshot_maintenance.final_snapshot_identifier
  backup_retention_period   = 0

  kms_key_id        = aws_kms_key.this.arn
  storage_encrypted = true
}

resource "aws_kms_key" "this" {
  description             = "database storage encryption key"
  deletion_window_in_days = "10"
}

