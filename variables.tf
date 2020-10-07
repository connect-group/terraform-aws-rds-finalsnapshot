# ---------------------------------------------------------------------------------------------------------------------
# The following variables define how final snapshots are handled.
# ---------------------------------------------------------------------------------------------------------------------

variable "instance_identifier" {
  description = "(Required) Unique Database Instance identifier.  IMPORTANT: This cannot be randomly generated, since to restore a snapshot you need to know the instance identifier!"
}

# OPTIONAL PARAMETERS
variable "override_restore_snapshot_identifier" {
  default     = ""
  description = "(Optional) Use with care.  If present, the database will be restored from this snapshot instead of the last final snapshot.  If you have number_of_snapshot_to_retain=0, the final snapshot will be deleted forever!  This should usually be blank but could be overriddent from the command line to restore a database from another environment or previous (not most recent) final snapshot."
}

variable "number_of_snapshots_to_retain" {
  default     = 1
  description = "(Optional) Number of final snapshots to retain after restoration.  Minimum 0.  Can be set to the string 'ALL' in which case snapshots are never deleted.  Default: 1"
}

# ---------------------------------------------------------------------------------------------------------------------
# The following variables define a simple RDS Database Instance, mainly for demonstration purposes
# ---------------------------------------------------------------------------------------------------------------------

variable "username" {
  default     = ""
  description = "(Required unless a snapshot_identifier is provided) Username for the master DB user."
}

variable "password" {
  default     = ""
  description = "(Required unless a snapshot_identifier is provided) Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file."
}

variable "allocated_storage" {
  default     = ""
  description = "(Required unless a snapshot_identifier is provided) The allocated storage in gigabytes."
}

# OPTIONAL PARAMETERS
variable "database_name" {
  default     = ""
  description = "(Optional) The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance."
}

variable "instance_class" {
  default     = "db.t2.micro"
  description = "(Optional) The instance type of the RDS instance. Defaults to 'db.t2.micro'"
}

