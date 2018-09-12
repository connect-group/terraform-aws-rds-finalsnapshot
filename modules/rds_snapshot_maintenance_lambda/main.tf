# ---------------------------------------------------------------------------------------------------------------------
# Create the maintenance Lambda.
# ---------------------------------------------------------------------------------------------------------------------
data "template_file" "maintain-rds-final-snapshots" {
  count="${var.include_this_module?1:0}"
  template = "${file("${path.module}/lambda/maintain-rds-final-snapshots.py")}"
  vars {
    function_name = "${var.function_name}"
  }
}

data "archive_file" "maintain-rds-final-snapshots-zip" {
  count="${var.include_this_module?1:0}"
  type = "zip"
  output_path = "${path.module}/lambda/maintain-rds-final-snapshots.py.zip"

  source {
    content  = "${data.template_file.maintain-rds-final-snapshots.0.rendered}"
    filename = "maintain_rds_final_snapshots.py"
  }
}

resource "aws_lambda_function" "maintain-rds-final-snapshots" {
  count="${var.include_this_module?1:0}"
  filename = "${substr(data.archive_file.maintain-rds-final-snapshots-zip.0.output_path, length(path.cwd) + 1, -1)}"
  function_name = "${var.function_name}"
  role = "${aws_iam_role.maintain-rds-final-snapshots-role.0.arn}"
  handler = "maintain_rds_final_snapshots.handler"
  source_code_hash = "${data.archive_file.maintain-rds-final-snapshots-zip.0.output_base64sha256}"
  runtime = "python2.7"
  description = "MANAGED BY TERRAFORM"
}

resource "aws_iam_role" "maintain-rds-final-snapshots-role" {
  count="${var.include_this_module?1:0}"
  name = "${var.function_name}_role"
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



# ---------------------------------------------------------------------------------------------------------------------
# Create the query Lambda.
# ---------------------------------------------------------------------------------------------------------------------
data "template_file" "find-final-snapshot" {
  count="${var.include_this_module?1:0}"
  template = "${file("${path.module}/lambda/find-final-snapshot.py")}"
  vars {
    function_name = "${var.function_name}Q"
  }
}

data "archive_file" "find-final-snapshot-zip" {
  count="${var.include_this_module?1:0}"
  type = "zip"
  output_path = "${path.module}/lambda/find-final-snapshot.py.zip"

  source {
    content  = "${data.template_file.find-final-snapshot.0.rendered}"
    filename = "find_final_snapshot.py"
  }
}

resource "aws_lambda_function" "find-final-snapshot" {
  count="${var.include_this_module?1:0}"
  filename = "${substr(data.archive_file.find-final-snapshot-zip.0.output_path, length(path.cwd) + 1, -1)}"
  function_name = "${var.function_name}Q"
  role = "${aws_iam_role.find-final-snapshot-role.0.arn}"
  handler = "find_final_snapshot.handler"
  source_code_hash = "${data.archive_file.find-final-snapshot-zip.0.output_base64sha256}"
  runtime = "python2.7"
  timeout = 300
  description = "MANAGED BY TERRAFORM"
}

resource "aws_iam_role" "find-final-snapshot-role" {
  count="${var.include_this_module?1:0}"
  name = "${var.function_name}Q_role"
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