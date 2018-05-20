# ---------------------------------------------------------------------------------------------------------------------
# The snapshot_to_restore and final_snapshot_identifier are the important outputs.
# ---------------------------------------------------------------------------------------------------------------------
output "snapshot_to_restore" {
  description="String. Name of the snapshot which a database instance/cluster should restore on creation."
  value="${local.snapshot_to_restore}"
}

output "final_snapshot_identifier" {
  description="String. Name of the snapshot which a database instance/cluster should create when destroyed."
  value="${local.final_snapshot_identifier}"
}
//    snapshot_to_restore = "${local.snapshot_to_restore}"
//    final_snapshot_identifier = "${format("%s-final-snapshot-%05d", var.identifier, local.first_run? 1 : substr(format("%s%s","00000",local.previous_final_snapshot),-5,-1)+1)}"

# ---------------------------------------------------------------------------------------------------------------------
# Echo the input variables for convenience - so snapshot_maintenance module can refer to this module rather than
# hardcoding/repeating the inputs.
# ---------------------------------------------------------------------------------------------------------------------
output "identifier" {
  description = "String. Unique Database Instance or Cluster identifier."
  value="${var.identifier}"
}