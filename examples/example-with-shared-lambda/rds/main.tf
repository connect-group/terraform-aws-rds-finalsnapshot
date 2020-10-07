terraform {
  required_version = ">=0.11.2"
}

provider "aws" {
  region = "eu-west-1"
}

module "snapshot_maintenance_1" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  #   source = "git::git@github.com:connect-group/terraform-aws-rds-finalsnapshot.git//modules/rds_snapshot_maintenance?ref=v1.0.0"
  # Or the public registry,
  #   source = "connect-group/rds-finalsnapshot/aws//modules/rds_snapshot_maintenance"
  #   version="1.0.0"
  source = "../../../modules/rds_snapshot_maintenance"

  shared_lambda_function_name   = "global_shared_rds_snapshot_maintenance"
  identifier                    = "demodbinstance1"
  is_cluster                    = false
  database_endpoint             = "${aws_db_instance.database1.endpoint}"
  number_of_snapshots_to_retain = 1
}

resource "aws_db_instance" "database1" {
  identifier                = "${module.snapshot_maintenance_1.identifier}"
  allocated_storage         = 5
  backup_retention_period   = 0                                                            # no daily backups
  storage_type              = "gp2"
  engine                    = "mysql"
  engine_version            = "5.7"
  instance_class            = "db.t2.micro"
  name                      = "demodb1"
  username                  = "master1"
  password                  = "PasswordForDatabase1!"
  parameter_group_name      = "default.mysql5.7"
  snapshot_identifier       = "${module.snapshot_maintenance_1.snapshot_to_restore}"
  final_snapshot_identifier = "${module.snapshot_maintenance_1.final_snapshot_identifier}"
}

module "snapshot_maintenance_2" {
  source = "../../../modules/rds_snapshot_maintenance"

  shared_lambda_function_name   = "global_shared_rds_snapshot_maintenance"
  identifier                    = "demodbinstance2"
  is_cluster                    = false
  database_endpoint             = "${aws_db_instance.database2.endpoint}"
  number_of_snapshots_to_retain = 1
}

resource "aws_db_instance" "database2" {
  identifier                = "${module.snapshot_maintenance_2.identifier}"
  allocated_storage         = 5
  backup_retention_period   = 0                                                            # no daily backups
  storage_type              = "gp2"
  engine                    = "mysql"
  engine_version            = "5.7"
  instance_class            = "db.t2.micro"
  name                      = "demodb2"
  username                  = "master2"
  password                  = "PasswordForDatabase2!"
  parameter_group_name      = "default.mysql5.7"
  snapshot_identifier       = "${module.snapshot_maintenance_2.snapshot_to_restore}"
  final_snapshot_identifier = "${module.snapshot_maintenance_2.final_snapshot_identifier}"
}
