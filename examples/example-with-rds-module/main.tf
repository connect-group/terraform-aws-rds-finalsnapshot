##############################################################
# Based on the terraform-aws-modules MySQL Example.
##############################################################
provider "aws" {
  region = "eu-west-1"
}

##############################################################
# terraform-aws-rds-finalsnapshot Modules
##############################################################
//module "snapshot_identifiers" {
//  source = "../../modules/rds_snapshot_identifiers"
//
//  identifier="demodb"
//}

module "snapshot_maintenance" {
  source="../../modules/rds_snapshot_maintenance"

  first_run="${var.first_run}"
  is_cluster=false
  identifier="demodb"
  database_endpoint="${module.db.this_db_instance_endpoint}"
  number_of_snapshots_to_retain = 0
}

##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = "${data.aws_vpc.default.id}"
}

data "aws_security_group" "default" {
  vpc_id = "${data.aws_vpc.default.id}"
  name   = "default"
}

##############################################################
# DB Example originally from https://github.com/terraform-aws-modules/terraform-aws-rds/tree/master/examples/complete-mysql
##############################################################
module "db" {
  source = "terraform-aws-modules/rds/aws"
  version = "1.15.0"

  identifier = "${module.snapshot_maintenance.identifier}"

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.large"
  allocated_storage = 5
  storage_encrypted = false

  # kms_key_id        = "arm:aws:kms:<region>:<accound id>:key/<kms key id>"
  name     = "demodb"
  username = "user"
  password = "YourPwdShouldBeLongAndSecure!"
  port     = "3306"

  vpc_security_group_ids = ["${data.aws_security_group.default.id}"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  # DB subnet group
  subnet_ids = ["${data.aws_subnet_ids.all.ids}"]

  # DB parameter group
  family = "mysql5.7"

  # Snapshot name to restore upon DB creation
  snapshot_identifier = "${module.snapshot_maintenance.snapshot_to_restore}"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "${module.snapshot_maintenance.final_snapshot_identifier}"

  skip_final_snapshot = "false"
}