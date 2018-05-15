# ---------------------------------------------------------------------------------------------------------------------
# SNAPSHOT MANAGEMENT
# This file defines a Lambda that will create a SSM Parameter that maintains the id of the snapshot to restore after
# a `terraform destroy`.
#
# It will also delete old final snapshots, retaining only as many as are specified in `number_of_snapshots_to_retain`
#
# The lambda runs just once, within 3 minutes of creation, and is not required to run again.
# ---------------------------------------------------------------------------------------------------------------------

# This module requires >=0.10.4 because it uses 'Local Values' bug fixed in 0.10.4
# and the timeadd function from 0.11.2
terraform {
  required_version = ">=0.11.2"
}

# ---------------------------------------------------------------------------------------------------------------------
# Create the Lambda.
# ---------------------------------------------------------------------------------------------------------------------
data "template_file" "maintain-rds-final-snapshots" {
  template = "${file("${path.module}/lambda/maintain-rds-final-snapshots.py.tpl")}"
  vars {
    final_snapshot_identifier     = "${null_resource.snapshot_constants.triggers.final_snapshot_identifier}",
    number_of_snapshots_to_retain = "${var.number_of_snapshots_to_retain == "ALL" ? -1 : var.number_of_snapshots_to_retain }",
    identifier                    = "${var.identifier}"
    is_cluster                    = "${var.is_cluster? "True" : "False"}"
  }
}

data "archive_file" "maintain-rds-final-snapshots-zip" {
  type = "zip"
  output_path = "${path.module}/lambda/maintain-rds-final-snapshots.py.zip"

  source {
    content  = "${data.template_file.maintain-rds-final-snapshots.rendered}"
    filename = "maintain_rds_final_snapshots.py"
  }
}

resource "aws_lambda_function" "maintain-rds-final-snapshots" {
  filename = "${substr(data.archive_file.maintain-rds-final-snapshots-zip.output_path, length(path.cwd) + 1, -1)}"
  function_name = "maintain_rds_final_snapshots_${var.identifier}"
  role = "${aws_iam_role.maintain-rds-final-snapshots-role.arn}"
  handler = "maintain_rds_final_snapshots.handler"
  source_code_hash = "${data.archive_file.maintain-rds-final-snapshots-zip.output_base64sha256}"
  runtime = "python2.7"
  description = "MANAGED BY TERRAFORM"
}


# ---------------------------------------------------------------------------------------------------------------------
# IAM Permissions to allow the Lambda to,
#   * Log to Cloudwatch logs
#   * Describe Snapshots for a DBInstance/Cluster
#   * Delete DBInstance/Cluster snapshots
#   * Write an SSM Parameter
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "maintain-rds-final-snapshots-role" {
  name = "maintain_rds_final_snapshots_${var.identifier}_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


locals {
  # Interpolate with the IAM Policy to create a policy specific to either DB Instance or DB Cluster snapshots.
  cluster="${var.is_cluster ? "Cluster" : ""}"
}

resource "aws_iam_policy" "maintain-rds-final-snapshots-policy" {
  name = "maintain_rds_final_snapshots_${var.identifier}_policy"
  path = "/"
  description = "MANAGED BY TERRAFORM Allow Lambda to delete/copy/manage db snapshots"
  policy = <<EOF
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
            "Action": [ "ssm:PutParameter" ],
            "Resource": "arn:aws:ssm:*:*:parameter/rds_final_snapshot/${var.identifier}/snapshot_to_restore"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "attach-policy" {
  name = "attach-policy-to-maintain-rds-final-snapshots_${var.identifier}_role"
  roles = ["${aws_iam_role.maintain-rds-final-snapshots-role.name}"]
  policy_arn = "${aws_iam_policy.maintain-rds-final-snapshots-policy.arn}"
}


# ---------------------------------------------------------------------------------------------------------------------
# Generate a cron() schedule from a timestamp which will run just once, 3 minutes after the database is
# created/restored.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  #2017-11-22T00:10:00Z -> cron(10 00 22 11 ? 2017)
  #Database endpoint is added to force the timestamp to be generated after the database has been created
  when = "${timeadd(timestamp(), "2m")}T${var.database_endpoint}"
  time="${split(":", element(split("T", local.when),1))}"
  date="${split("-", element(split("T", local.when),0))}"
  schedule_expression="cron(${local.time[1]} ${local.time[0]} ${local.date[2]} ${local.date[1]} ? ${local.date[0]})"
}

resource "aws_cloudwatch_event_rule" "maintain-rds-final-snapshot" {
  name = "trigger_maintain-rds-final-snapshot-${var.identifier}"

  # The database_endpoint is here primarily to ensure the cloudwatch event is created after the database.
  description = "TERRAFORMED: maintain-rds-final-snapshot ${var.database_endpoint}"
  schedule_expression = "${local.schedule_expression}"

  lifecycle {
    ignore_changes = ["schedule_expression"]
  }
}

resource "aws_cloudwatch_event_target" "maintain-rds-final-snapshot" {
  rule  = "${aws_cloudwatch_event_rule.maintain-rds-final-snapshot.name}"
  arn   = "${aws_lambda_function.maintain-rds-final-snapshots.arn}"
}


# ---------------------------------------------------------------------------------------------------------------------
# Allow Cloudwatch to execute the Lambda.
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_lambda_permission" "allow-cloudwatch-to-call-maintain-rds-final-snapshot-lambda" {
  statement_id = "AllowExecutionFromCloudWatch_maintain-rds-final-snapshot-${null_resource.snapshot_constants.triggers.final_snapshot_identifier}"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.maintain-rds-final-snapshots.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.maintain-rds-final-snapshot.arn}"
}

