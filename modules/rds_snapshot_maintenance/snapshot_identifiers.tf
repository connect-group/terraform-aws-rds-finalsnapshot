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

#
# An SSM Parameter (non-secure) managed outside of terraform, so it will live beyond a 'destroy', just as the
# database final snapshot is created on destroy but not managed by Terraform.
#
data "aws_ssm_parameter" "snapshot_to_restore" {
  count = "${var.first_run ? 0 : 1}"
  name = "/rds_final_snapshot/${var.identifier}/snapshot_to_restore"
}

locals {
  # Defined as a local because we use it twice in the snapshot_constants block below.
  snapshot_to_restore = "${element(concat(data.aws_ssm_parameter.snapshot_to_restore.*.value, list(var.first_run_snapshot_identifier)), 0)}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Tip:
# A Null resource can act as a set of constants which once defined, will not change unless destroyed/deleted from
# the terraform configuration.
#
# For this to work, you must set the lifecycle { ignore_changes = triggers } as below.
# ---------------------------------------------------------------------------------------------------------------------
resource "null_resource" "snapshot_constants" {
  triggers {
    snapshot_to_restore = "${local.snapshot_to_restore}"
    final_snapshot_identifier = "${format("%s-final-snapshot-%05d", var.identifier, var.first_run? 1 : substr(format("%s%s","00000",local.snapshot_to_restore),-5,-1)+1)}"
  }

  lifecycle {
    ignore_changes = ["triggers"]
  }
}
