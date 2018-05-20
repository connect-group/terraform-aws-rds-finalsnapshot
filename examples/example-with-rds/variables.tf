variable "first_run" {
  default=false
  description = "Must be set to true the first time plan/apply are run"
}

variable "restore_snapshot" {
  default=""
  description = "Override the snapshot which is restored."
}