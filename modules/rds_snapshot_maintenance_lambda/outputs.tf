output "arn" {
  value = element(
    concat(aws_lambda_function.maintain-rds-final-snapshots.*.arn, [""]),
    0,
  )
}

output "role" {
  value = element(
    concat(aws_iam_role.maintain-rds-final-snapshots-role.*.name, [""]),
    0,
  )
}

output "function_name" {
  value = var.function_name
}

output "query_arn" {
  value = element(
    concat(aws_lambda_function.find-final-snapshot.*.arn, [""]),
    0,
  )
}

output "query_role" {
  value = element(
    concat(aws_iam_role.find-final-snapshot-role.*.name, [""]),
    0,
  )
}

output "query_function_name" {
  value = "${var.function_name}Q"
}

