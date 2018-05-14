provider "aws" {
  region = "eu-west-1"
}

##############################################################
# terraform-aws-rds-finalsnapshot Modules
##############################################################
module "snapshot_identifiers" {
  source = "../../modules/rds_snapshot_identifiers"

  first_run="${var.first_run}"
  identifier="democluster"
}

module "snapshot_maintenance" {
  source="../../modules/rds_snapshot_maintenance"

  final_snapshot_identifier="${module.snapshot_identifiers.final_snapshot_identifier}"
  is_cluster=true
  identifier="${aws_rds_cluster.aurora.cluster_identifier}"
  database_endpoint="${aws_rds_cluster.aurora.endpoint}"
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
# Aurora Cluster
##############################################################
resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${module.snapshot_identifiers.identifier}"

  database_name           = "demodb"
  master_username         = "user"
  master_password         = "YourPwdShouldBeLongAndSecure!"

  # Aurora has a minimum of 1
  backup_retention_period = 1

  # Snapshot name to restore upon DB creation
  snapshot_identifier = "${module.snapshot_identifiers.snapshot_to_restore}"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "${module.snapshot_identifiers.final_snapshot_identifier}"

  db_subnet_group_name = "${aws_db_subnet_group.aurora.name}"
  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.aurora.name}"

  vpc_security_group_ids = [
    "${data.aws_security_group.default.id}"
  ]
}

resource "aws_rds_cluster_instance" "aurora" {
  count="2"
  identifier = "demodb-${count.index}"
  cluster_identifier = "${aws_rds_cluster.aurora.id}"
  instance_class = "db.t2.small"
  db_subnet_group_name = "${aws_db_subnet_group.aurora.name}"

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

resource "aws_db_subnet_group" "aurora" {
  name = "demodb_subnet_group"

  subnet_ids = ["${data.aws_subnet_ids.all.ids}"]

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}

resource "aws_rds_cluster_parameter_group" "aurora" {
  name = "demodb-db-parameter-group"
  family = "aurora5.6"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8"
  }

  parameter {
    name  = "lower_case_table_names"
    value = "1"
    apply_method = "pending-reboot"
  }
}
