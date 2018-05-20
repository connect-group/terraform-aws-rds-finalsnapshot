AWS RDS Snapshot Maintenance Module
===================================

> ###### IMPORTANT
> The first time this configuration is applied the `first_run` variable passed to the modules must be `true`.
>
> All subsequent applies should have `first_run` set to false or ommitted (as false is default).

Terraform Module users are encouraged to use this submodule directly rather than use the root module.

This submodule will ensure that a database or cluster which is associated with the module, will have its final snapshots
configured in such a way that you can apply/destroy/apply/destroy your database and it will be restored on each apply.

This module handles rotation of/unique names for the final snapshot: and solves a flaw which can occur when
destroying a database: without this submodule, if a final snapshot already exists then the destroy will fail.  

The submodule will also delete old final snapshots, while retaining a number specified by the 
`number_of_snapshots_to_retain` variable.

* The optional variable `override_restore_snapshot_identifier` *may* be used to specify
a known snapshot from which to create the database.  This allows for restoration of the database from another
environment, or from a backup N days ago.

How it works
------------
This module will generate a final_snapshot_identifier: this is the name of the snapshot which will be created when
the database or cluster is destroyed.

This module will also generate a snapshot_identifier if a previous final snapshot does not exist (typically, the first
time the database is created)`, which identifies the previous final snapshot to restore the database from.

This module also removes old final_snapshots upon successful creation of the database or cluster which it
is maintaining.

Usage
-----
```hcl
module "snapshot_maintenance" {
  source="connect-group/rds-finalsnapshot/aws//modules/rds_snapshot_maintenance"

  identifier="instance_identifier"
  is_cluster=false
  database_endpoint="${aws_db_instance.database.endpoint}"
  number_of_snapshots_to_retain=3
}

# Or this can be an aws_rds_cluster
resource "aws_db_instance" "database" {
  # ...
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
Currently maintained by [these contributors](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/graphs/contributors).
Module managed by [Adam Perry](https://github.com/4dz) and [Connect Group](https://github.com/connect-group)

License
-------
Apache 2 Licensed. See LICENSE for full details.