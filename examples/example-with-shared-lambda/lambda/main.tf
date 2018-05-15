provider "aws" {
  region = "eu-west-1"
}

module "global_lambda" {
  source = "../../../modules/rds_snapshot_maintenance_lambda"
  function_name = "global_shared_rds_snapshot_maintenance"
}