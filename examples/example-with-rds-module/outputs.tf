output "snapshot_to_restore" {
  description="String. Name of the snapshot which a database instance/cluster should restore on creation."
  value="${module.snapshot_maintenance.snapshot_to_restore}"
}

output "final_snapshot_identifier" {
  description="String. Name of the snapshot which a database instance/cluster should create when destroyed."
  value="${module.snapshot_maintenance.final_snapshot_identifier}"
}

output "identifier" {
  description = "String. Unique Database Instance identifier."
  value="${module.snapshot_maintenance.identifier}"
}