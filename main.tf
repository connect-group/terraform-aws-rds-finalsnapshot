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

# This module requires >=0.10.4 because it uses 'Local Values' bug fixed in 0.10.4
# and the timeadd function from 0.11.2 
terraform {
  required_version = ">=0.11.2"
}

module "snapshot_identifiers" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:connect-group/terraform-aws-rds-finalsnapshot.git//modules/snapshot_identifiers?ref=v1.0.0"
  source="./modules/rds_snapshot_identifiers"
  first_run="${var.first_run}"
  identifier="${var.instance_identifier}"
  first_run_snapshot_identifier="${var.first_run_snapshot_identifier}"
}

resource "aws_db_instance" "database" {
  identifier = "${module.snapshot_identifiers.identifier}"
  allocated_storage    = "${var.allocated_storage}"
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "${var.instance_class}"
  name                 = "${var.database_name}"
  username             = "${var.username}"
  password             = "${var.password}"
  parameter_group_name = "default.mysql5.7"
  snapshot_identifier = "${module.snapshot_identifiers.snapshot_to_restore}"
  final_snapshot_identifier = "${module.snapshot_identifiers.final_snapshot_identifier}"
}

module "snapshot_maintenance" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:connect-group/terraform-aws-rds-finalsnapshot.git//modules/snapshot_maintenance?ref=v1.0.0"

  source="./modules/rds_snapshot_maintenance"
  final_snapshot_identifier="${module.snapshot_identifiers.final_snapshot_identifier}"
  is_cluster=false
  identifier="${aws_db_instance.database.identifier}"
  database_endpoint="${aws_db_instance.database.endpoint}"
  number_of_snapshots_to_retain="${var.number_of_snapshots_to_retain}"
}

