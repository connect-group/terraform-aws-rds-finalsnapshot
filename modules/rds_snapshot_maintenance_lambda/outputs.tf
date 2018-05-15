output "arn" {
  value = "${element(concat(aws_lambda_function.maintain-rds-final-snapshots.*.arn, list("")), 0)}"
}

output "role" {
  value = "${element(concat(aws_iam_role.maintain-rds-final-snapshots-role.*.name, list("")), 0)}"
}

output "function_name" {
  value = "${var.function_name}"
}