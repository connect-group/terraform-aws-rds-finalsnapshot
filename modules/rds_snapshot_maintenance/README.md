AWS RDS Snapshot Maintenance Module
===================================
Terraform Module users are encouraged to use this submodule directly, in combination with the `rds_snapshot_identifiers`
module, rather than use the root module.

This module will generate a final_snapshot_identifier: this is the name of the snapshot which will be created when
the database or cluster is destroyed.

This module will also generate a snapshot_identifier if this is not the `first_run`, which identifies the snapshot to
restore the database from.

*On the `first_run` only*, the optional variable `first_run_snapshot_identifier` may be used to specify
a known snapshot from which to create the database.  On subsequent runs, this variable is ignored.

Usage
-----
```hcl
module "snapshot_identifiers" {
  source = "connect-group/rds/aws//modules/rds_snapshot_identifiers"

  first_run="${var.first_run}"
  identifier="instance_identifier"
  first_run_snapshot_identifier="some_known_snapshot"
}

resource "aws_db_instance" "database" {
  # ...
}

module "snapshot_maintenance" {
  source="connect-group/rds/aws//modules/rds_snapshot_maintenance"

  final_snapshot_identifier="${module.snapshot_identifiers.final_snapshot_identifier}"
  is_cluster=false
  identifier="${aws_db_instance.database.identifier}"
  database_endpoint="${aws_db_instance.database.endpoint}"
  number_of_snapshots_to_retain=3
}
```

Terraform Version
-----------------
This module requires >=0.10.4 because it uses 'Local Values' bug fixed in 0.10.4 and the `timeadd` function from 
version 0.11.2.

More Information
----------------
For more information and examples please review the [root module README](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/tree/master/README.md) 

Authors
-------
Currently maintained by [these awesome contributors](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/graphs/contributors).
Module managed by [Adam Perry](https://github.com/4dz) and [Connect Group](https://github.com/connect-group)

License
-------
Apache 2 Licensed. See LICENSE for full details.