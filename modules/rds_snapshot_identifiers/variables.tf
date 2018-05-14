# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------
variable "first_run" {
  description = "(Required) Boolean. Should always be set the first time a database is created.  If true, assumes that there is no backup to restore.  After the first run, can be set to false."
}

variable "identifier" {
  description = "(Required) String. Unique Database Instance or Cluster identifier"
}