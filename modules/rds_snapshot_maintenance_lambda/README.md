AWS RDS Snapshot Lambda Module
==============================

Terraform Module users are encouraged to use this submodule directly rather than use the root module.

This module will create a Lambda function which is used by the rds_snapshot_maintenance module to
manage SSM Parameters (alias/track name of final snapshots) and also, delete older final snapshost
as per the retention variable.

If you wish to reduce the number of Lambda functions in your environment, and have multiple databases
or clusters which need to be destroyed and recreated on a regular basis, then you can create one
Lambda and share it with all invocations of the rds_snapshot_maintenance module.

> Do not include this module in the same Terraform configuration as the rds_snapshot_maintenance
> module or else an error will occur on plan as a data source will look for this lambda, and fail.
>
> The intention is that if using this module directly it is added to a global/account level 
> Terraform configuration.

Usage
-----
```hcl
module "global_lambda" {
  source = "../../../modules/rds_snapshot_maintenance_lambda"
  function_name = "global_shared_rds_snapshot_maintenance"
}
```

... then in a different folder on disk (a different Terraform configuration)

```hcl
module "snapshot_maintenance" {
  source="connect-group/rds-finalsnapshot/aws//modules/rds_snapshot_maintenance"

  shared_lambda_function_name = "global_shared_rds_snapshot_maintenance"
  first_run="${var.first_run}"
  first_run_snapshot_identifier="some_known_snapshot"
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

Examples
--------
* [Shared Lambda Example](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/tree/master/examples/example-with-shared-lambda)

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