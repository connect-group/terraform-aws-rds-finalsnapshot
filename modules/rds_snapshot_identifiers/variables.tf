# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------
variable "first_run" {
  description = "(Required) Boolean. Should always be set the first time a database is created.  If true, assumes that there is no backup to restore.  After the first run, can be set to false."
}

variable "identifier" {
  description = "(Required) String. Unique Database Instance or Cluster identifier"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# For which sensible defaults have been set.
# ---------------------------------------------------------------------------------------------------------------------
variable "first_run_snapshot_identifier" {
  default=""
  description="(Optional) Only used on the first run, when a database is created for the first time.  If present, the database will be restored from this snapshot.  On all subsequent database creations, the last 'final snapshot' will be used to restore the database regardless of the value of this variable."
}
