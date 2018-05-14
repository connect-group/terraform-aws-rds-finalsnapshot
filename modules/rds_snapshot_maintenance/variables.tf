# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------
variable "identifier" {
  description = "(Required) String. Unique Database Instance or Cluster identifier. Should be the output from the snapshot_identifiers module, or the database instance/cluster."
}

variable "final_snapshot_identifier" {
  description="(Required) String. Name of the snapshot which a database instance/cluster should create when destroyed.  Cannot be the same as an existing snapshot, or else destroy will fail.  Should be the output from the snapshot_identifiers module."
}

variable "is_cluster" {
  description="(Required) Boolean. `true` if the database for which snapshots are being managed, is a cluster (AWS Aurora). Otherwise set to `false`."
}

variable "database_endpoint" {
  description="(Required) This is required to ensure the lambda is triggered AFTER the database/cluster is created."
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# For which sensible defaults have been set.
# ---------------------------------------------------------------------------------------------------------------------
variable "number_of_snapshots_to_retain" {
  default=1
  description = "(Optional) Number of final snapshots to retain after restoration.  Minimum 0.  Can be set to the string 'ALL' in which case snapshots are never deleted.  Default: 1"
}
