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

module "snapshot_maintenance" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:connect-group/terraform-aws-rds-finalsnapshot.git//modules/rds_snapshot_maintenance?ref=v1.0.0"
  # Or the public registry,
  #   source = "connect-group/rds/aws//modules/rds_snapshot_maintenance"
  #   version="1.0.0"

  source = "./modules/rds_snapshot_maintenance"

  identifier                           = var.instance_identifier
  override_restore_snapshot_identifier = var.override_restore_snapshot_identifier

  is_cluster                    = false
  database_endpoint             = aws_db_instance.database.endpoint
  number_of_snapshots_to_retain = var.number_of_snapshots_to_retain
}

resource "aws_db_instance" "database" {
  identifier                = module.snapshot_maintenance.identifier
  allocated_storage         = var.allocated_storage
  storage_type              = "gp2"
  engine                    = "mysql"
  engine_version            = "5.7"
  instance_class            = var.instance_class
  name                      = var.database_name
  username                  = var.username
  password                  = var.password
  parameter_group_name      = "default.mysql5.7"
  snapshot_identifier       = module.snapshot_maintenance.snapshot_to_restore
  final_snapshot_identifier = module.snapshot_maintenance.final_snapshot_identifier
}

