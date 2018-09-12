# ---------------------------------------------------------------------------------------------------------------------
# SNAPSHOT IDENTIFIERS
# Calculate the snapshot to restore (if there is one from a previous destroy event) and
# the name of the next final_snapshot.  The final snapshot name is based on the identifier and a counter
# ---------------------------------------------------------------------------------------------------------------------


# This module requires >=0.10.4 because it uses 'Local Values' bug fixed in 0.10.4
# But since the snapshot_maintenance module uses timeadd (added in 0.11.2), may as well keep the two
# modules in sync.
terraform {
  required_version = ">=0.11.2"
}

# ---------------------------------------------------------------------------------------------------------------------
# Use a global, or module specific lambda, depending on 'shared_lambda_function_name'
# ---------------------------------------------------------------------------------------------------------------------
data "aws_lambda_function" "find_snapshot" {
  count="${length(var.shared_lambda_function_name)>0 ? 1 : 0}"
  function_name="${var.shared_lambda_function_name}Q"
}

locals {
  query_function_name = "${length(var.shared_lambda_function_name)>0 ? format("%sQ",var.shared_lambda_function_name) : module.maintain-rds-final-snapshots-lambda.query_function_name}"
  query_function_arn  = "${replace(element(concat(data.aws_lambda_function.find_snapshot.*.arn, list(module.maintain-rds-final-snapshots-lambda.query_arn)), 0), ":$LATEST", "")}"
  query_function_role = "${element(split("/",element(concat(data.aws_lambda_function.find_snapshot.*.role, list(module.maintain-rds-final-snapshots-lambda.query_role)), 0)), 1)}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Attach Policy to Lambda, allow find_snapshot to read snapshots belonging to the instance.
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "find_final_snapshot-policy" {
  name = "find_finalsnapshot_${var.identifier}_policy"
  path = "/"
  description = "MANAGED BY TERRAFORM Allow Lambda to find db snapshots"
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
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach-policy-to-find-final-snapshot-lambda" {
  role = "${local.query_function_role}"
  policy_arn = "${aws_iam_policy.find_final_snapshot-policy.arn}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Execute Lambda, after attaching the policy.
# Execute it 4 times... this is to catch a case where a database +/- replace
# means the lambda needs a lot of time to capture the new snapshot thats created on destroy.
# ---------------------------------------------------------------------------------------------------------------------
locals {
  query_lambda_inputs = {
    depends_on_policy     = "${aws_iam_role_policy_attachment.attach-policy-to-find-final-snapshot-lambda.id}"
    identifier            = "${var.identifier}"
    is_cluster            = "${var.is_cluster}"
    final_snapshot_prefix = "${format("%s-final-snapshot-", var.identifier)}"
    default_value         = ""
    run_on_every_apply = "${timestamp()}"
  }

  query_lambda_outputs = [
    "SnapshotIdentifier",
    "Error",
  ]
}

resource "aws_cloudformation_stack" "find_final_snapshot" {
  name               = "find-snapshot-for-${var.identifier}"
  timeout_in_minutes = "20"

  template_body = <<EOF
{
  "Description" : "Execute a Lambda 4 times, and return the results of last time",
  "Resources": {
    "ExecuteLambdaPre1": {
      "Type": "Custom::ExecuteLambda",
      "Properties": 
        ${jsonencode(merge(map("ServiceToken",local.query_function_arn), local.query_lambda_inputs))}
    },
    "ExecuteLambdaPre2": {
      "DependsOn": "ExecuteLambdaPre1",
      "Type": "Custom::ExecuteLambda",
      "Properties": 
        ${jsonencode(merge(map("ServiceToken",local.query_function_arn), local.query_lambda_inputs))}
    },
    "ExecuteLambdaPre3": {
      "DependsOn": "ExecuteLambdaPre2",
      "Type": "Custom::ExecuteLambda",
      "Properties": 
        ${jsonencode(merge(map("ServiceToken",local.query_function_arn), local.query_lambda_inputs))}
    },
    "ExecuteLambda": {
      "DependsOn": "ExecuteLambdaPre3",
      "Type": "Custom::ExecuteLambda",
      "Properties": 
        ${jsonencode(merge(map("ServiceToken",local.query_function_arn), local.query_lambda_inputs))}
    }
  },
  "Outputs": {
    ${join(",", formatlist("\"%s\":{\"Value\": {\"Fn::GetAtt\":[\"ExecuteLambda\", \"%s\"]}}", local.query_lambda_outputs, local.query_lambda_outputs))}
  }
}
EOF
}


# ---------------------------------------------------------------------------------------------------------------------
# Calculate/Organise results of lambda (name of final snapshot)
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Defined as a local because we use it twice in the snapshot_constants block below.
  previous_final_snapshot   = "${lookup(aws_cloudformation_stack.find_final_snapshot.outputs, "SnapshotIdentifier", "")}"
  snapshot_to_restore       = "${length(var.override_restore_snapshot_identifier) > 0 ? var.override_restore_snapshot_identifier : local.previous_final_snapshot}"
  first_run                 = "${length(local.previous_final_snapshot) == 0}"
  counter                   = "${format("%05d", local.first_run? 1 : replace(substr(format("%s%s","00000",local.previous_final_snapshot),-5,-1), "/^0+(\\d+)/", "$1")+1)}"
  final_snapshot_identifier = "${format("%s-final-snapshot-%s", var.identifier, local.counter)}"
}
