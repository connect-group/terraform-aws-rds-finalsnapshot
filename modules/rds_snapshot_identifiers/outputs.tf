# ---------------------------------------------------------------------------------------------------------------------
# The snapshot_to_restore and final_snapshot_identifier are the important outputs.
# ---------------------------------------------------------------------------------------------------------------------
output "snapshot_to_restore" {
  description="String. Name of the snapshot which a database instance/cluster should restore on creation."
  value="${null_resource.snapshot_constants.triggers.snapshot_to_restore}"
}

output "final_snapshot_identifier" {
  description="String. Name of the snapshot which a database instance/cluster should create when destroyed."
  value="${null_resource.snapshot_constants.triggers.final_snapshot_identifier}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Echo the input variables for convenience - so snapshot_maintenance module can refer to this module rather than
# hardcoding/repeating the inputs.
# ---------------------------------------------------------------------------------------------------------------------
output "identifier" {
  description = "String. Unique Database Instance or Cluster identifier."
  value="${var.identifier}"
}
