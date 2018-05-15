# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------
variable "first_run" {
  description = "(Required) Boolean. Should always be set the first time a database is created.  If true, assumes that there is no backup to restore.  After the first run, can be set to false."
}

variable "identifier" {
  description = "(Required) String. Unique Database Instance or Cluster identifier. Should be the output from the snapshot_identifiers module, or the database instance/cluster."
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
variable "first_run_snapshot_identifier" {
  default=""
  description="(Optional) Only used on the first run, when a database is created for the first time.  If present, the database will be restored from this snapshot.  On all subsequent database creations, the last 'final snapshot' will be used to restore the database regardless of the value of this variable."
}

variable "number_of_snapshots_to_retain" {
  default=1
  description = "(Optional) Number of final snapshots to retain after restoration.  Minimum 0.  Can be set to the string 'ALL' in which case snapshots are never deleted.  Default: 1"
}

variable "shared_lambda_function_name" {
  default=""
  description = "(Optional) If specified, will look for and use a shared lambda, instead of creating one lambda per managed database/cluster."
}