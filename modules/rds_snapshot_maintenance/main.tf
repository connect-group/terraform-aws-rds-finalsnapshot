# ---------------------------------------------------------------------------------------------------------------------
# SNAPSHOT MANAGEMENT
# This file defines a Lambda that will create a SSM Parameter that maintains the id of the snapshot to restore after
# a `terraform destroy`.
#
# It will also delete old final snapshots, retaining only as many as are specified in `number_of_snapshots_to_retain`
#
# The lambda runs just once, within 3 minutes of creation, and is not required to run again.
# ---------------------------------------------------------------------------------------------------------------------

module "maintain-rds-final-snapshots-lambda" {
  source              = "../rds_snapshot_maintenance_lambda"
  include_this_module = length(var.shared_lambda_function_name) == 0
  function_name       = "maintain_rds_final_snapshots_${var.identifier}"
}

data "aws_lambda_function" "maintain-rds-final-snapshots" {
  count         = length(var.shared_lambda_function_name) > 0 ? 1 : 0
  function_name = var.shared_lambda_function_name
}

locals {
  function_name = length(var.shared_lambda_function_name) > 0 ? var.shared_lambda_function_name : module.maintain-rds-final-snapshots-lambda.function_name
  function_arn = replace(
    element(
      concat(
        data.aws_lambda_function.maintain-rds-final-snapshots.*.arn,
        [module.maintain-rds-final-snapshots-lambda.arn],
      ),
      0,
    ),
    ":$LATEST",
    "",
  )
  function_role = element(
    split(
      "/",
      element(
        concat(
          data.aws_lambda_function.maintain-rds-final-snapshots.*.role,
          [module.maintain-rds-final-snapshots-lambda.role],
        ),
        0,
      ),
    ),
    1,
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Permissions to allow the Lambda to,
#   * Log to Cloudwatch logs
#   * Describe Snapshots for a DBInstance/Cluster
#   * Delete DBInstance/Cluster snapshots
#   * Describe the DBInstance/Cluster (find out if it needs a reboot)
#   * Reboot
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Interpolate with the IAM Policy to create a policy specific to either DB Instance or DB Cluster snapshots.
  cluster = var.is_cluster ? "Cluster" : ""
}

resource "aws_iam_policy" "maintain-rds-final-snapshots-policy" {
  name        = "manage_finalsnapshot_${var.identifier}_policy"
  path        = "/"
  description = "MANAGED BY TERRAFORM Allow Lambda to delete/copy/manage db snapshots"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Effect": "Allow",
          "Action": ["logs:*"],
          "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [ "rds:DescribeDB${local.cluster}Snapshots" ],
            "Resource": "${var.is_cluster ? "*" : format("arn:aws:rds:*:*:db:%s", var.identifier)}"
        },
        {
            "Effect": "Allow",
            "Action": [ "rds:DeleteDB${local.cluster}Snapshot" ],
            "Resource": "arn:aws:rds:*:*:${var.is_cluster ? "cluster-snapshot" : "snapshot"}:${format("%s-final-snapshot-", var.identifier)}*"
        },
        {
            "Effect": "Allow",
            "Action": [ "rds:DescribeDBInstances" ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_policy" "reboot-rds-policy" {
  count       = var.is_cluster ? 0 : 1
  name        = "manage_reboot_${var.identifier}_policy"
  path        = "/"
  description = "MANAGED BY TERRAFORM Allow Lambda to reboot db instance"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [ "rds:RebootDBInstance" ],
            "Resource": "${format("arn:aws:rds:*:*:db:%s", var.identifier)}"
        }
    ]
}
EOF

}

resource "aws_iam_policy" "reboot-cluster-policy" {
  count       = var.is_cluster ? 1 : 0
  name        = "manage_reboot_${var.identifier}_policy"
  path        = "/"
  description = "MANAGED BY TERRAFORM Allow Lambda to reboot db instance"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [ "rds:DescribeDBClusters" ],
            "Resource": "${format("arn:aws:rds:*:*:cluster:%s", var.identifier)}"
        },
        {
            "Effect": "Allow",
            "Action": [ "rds:RebootDBInstance" ],
            "Resource": "arn:aws:rds:*:*:db:*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "attach-policy" {
  role       = local.function_role
  policy_arn = aws_iam_policy.maintain-rds-final-snapshots-policy.arn
}

resource "aws_iam_role_policy_attachment" "attach-reboot-policy" {
  role = local.function_role
  policy_arn = element(
    concat(
      aws_iam_policy.reboot-rds-policy.*.arn,
      aws_iam_policy.reboot-cluster-policy.*.arn,
    ),
    0,
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# Execute Lambda, after attaching the policy and after creating the database.
# ---------------------------------------------------------------------------------------------------------------------
module "exec-maintenance-lambda-delete-old-snapshots" {
  source              = "connect-group/lambda-exec/aws"
  version             = "2.0.0"

  name                = "manage-finalsnapshot-for-${var.identifier}"
  lambda_function_arn = local.function_arn

  lambda_inputs = {
    depends_on_policy             = aws_iam_role_policy_attachment.attach-policy.id
    depends_on_database           = var.database_endpoint
    final_snapshot_identifier     = local.final_snapshot_identifier
    number_of_snapshots_to_retain = var.number_of_snapshots_to_retain == "ALL" ? -1 : var.number_of_snapshots_to_retain
    identifier                    = var.identifier
    is_cluster                    = var.is_cluster ? "True" : "False"
  }

  //run_on_every_apply = "${timestamp()}"

  lambda_outputs = [
    "Error",
  ]
}

