# ---------------------------------------------------------------------------------------------------------------------
# These outputs are from the maintenance module
# ---------------------------------------------------------------------------------------------------------------------
output "snapshot_to_restore" {
  description="String. Name of the snapshot which a database instance/cluster should restore on creation."
  value="${module.snapshot_maintenance.snapshot_to_restore}"
}

output "final_snapshot_identifier" {
  description="String. Name of the snapshot which a database instance/cluster should create when destroyed."
  value="${module.snapshot_maintenance.final_snapshot_identifier}"
}

# ---------------------------------------------------------------------------------------------------------------------
# These outputs are from the sample RDS Database Instance
# ---------------------------------------------------------------------------------------------------------------------

output "address" {
  description = "The address of the RDS instance."
  value="${aws_db_instance.database.address}"
}
output "arn" {
  description = "The ARN of the RDS instance."
  value="${aws_db_instance.database.arn}"
}

output "allocated_storage" {
  description = "The amount of allocated storage."
  value="${aws_db_instance.database.allocated_storage}"
}
output "availability_zone" {
  description = "The availability zone of the instance."
  value="${aws_db_instance.database.availability_zone}"
}
output "backup_retention_period" {
  description = "The backup retention period."
  value="${aws_db_instance.database.backup_retention_period}"
}
output "backup_window" {
  description = "The backup window."
  value="${aws_db_instance.database.backup_window}"
}
output "ca_cert_identifier" {
  description = "Specifies the identifier of the CA certificate for the DB instance."
  value="${aws_db_instance.database.ca_cert_identifier}"
}
output "endpoint" {
  description = "The connection endpoint."
  value="${aws_db_instance.database.endpoint}"
}
output "engine" {
  description = "The database engine."
  value="${aws_db_instance.database.engine}"
}
output "engine_version" {
  description = "The database engine version."
  value="${aws_db_instance.database.engine_version}"
}
output "hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)."
  value="${aws_db_instance.database.hosted_zone_id}"
}
output "id" {
  description = "The RDS instance ID."
  value="${aws_db_instance.database.id}"
}
output "instance_class" {
  description = "- The RDS instance class."
  value="${aws_db_instance.database.instance_class}"
}
output "maintenance_window" {
  description = "The instance maintenance window."
  value="${aws_db_instance.database.maintenance_window}"
}
output "multi_az" {
  description = "If the RDS instance is multi AZ enabled."
  value="${aws_db_instance.database.multi_az}"
}
output "name" {
  description = "The database name."
  value="${aws_db_instance.database.name}"
}
output "port" {
  description = "The database port."
  value="${aws_db_instance.database.port}"
}
output "resource_id" {
  description = "The RDS Resource ID of this instance."
  value="${aws_db_instance.database.resource_id}"
}
output "status" {
  description = "The RDS instance status."
  value="${aws_db_instance.database.status}"
}
output "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted."
  value="${aws_db_instance.database.storage_encrypted}"
}
output "username" {
  description = "The master username for the database."
  value="${aws_db_instance.database.username}"
}