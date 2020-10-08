AWS RDS Final Snapshot Management Module
========================================

---

> ** IMPORTANT **
> Please upgrade to module version 1.0.11 if you are using Terraform 0.10.x or 0.11.x or a version below 0.12.20.
> Please use module version 2.0.1 if you are using Terraform 0.12.20+ or 0.13.x

---

> UPDATED to reboot database instance(s) following a snapshot restore if a parameter group requires a pending-reboot.

This module, or specifically the submodule `rds_snapshot_maintenance` will manage 
Final Snapshots of AWS database instances and clusters to ensure that infrastructure can be backed up, destroyed, 
and restored.

It will retain the last `number_of_snapshots_to_retain`.  If the number to retain is 'ALL' then no snapshots will be 
deleted.

The primary purpose of the modules is to allow for destruction of a database, such that it will capture a final 
snapshot and then restore it when later recreated.  

The use case is for development and testing environments which should not be running 24/7 (eg. to save money, or reduce
risk).  Perhaps a project is only developed infrequently; or perhaps you only want development to run 9-5 Mon-Fri.

This module supports creation of a database; and subsequent restoration of a database which was previously destroyed.

> ###### WARNING
> Destroying infrastructure is by its nature destructive - when developing an environment,
> take plenty of manual backups until you have tested your infrastructure code! 

This module can be used from the command-line and can also be used within a CI environment.

Backups are created and restored as follows,

    terraform apply
    terraform destroy
    terraform apply
    terraform destroy
    terraform apply

The Root module should be used primarily for testing or evaluation.  It will create a usable RDS
database instance, but does not have the full flexibility of a more complete database module such as 
"terraform-aws-modules/aws/rds".  Instead the two submodules should be used.

The Root module calls these submodules which can (and should) be used to create independent resources:
                
* [rds_snapshot_maintenance](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/tree/master/modules/rds_snapshot_maintenance) - deletes old Snapshots, calculates Snapshot identifiers
* [rds_snapshot_maintenance_lambda](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/tree/master/modules/rds_snapshot_maintenance_lambda) - helper lambda 

> ###### IMPORTANT
> When using the child modules directly, simply use the rds_snapshot_maintenance module and pass in the database
> identifier.

Usage With 'Built-In' Simple MySQL Instance
-------------------------------------------
```hcl
module "db_with_final_snapshot_management" {
  source = "connect-group/rds-finalsnapshot/aws"

  instance_identifier = "demodb"
  instance_class      = "db.t2.micro"
  allocated_storage   = 5

  database_name     = "demodb"
  username          = "user"
  password          = "AVerySecureInitialPasswordPerhapsChangeItManually"

  number_of_snapshots_to_retain = 0
}
```


Usage With Official Terraform RDS Module
----------------------------------------
```hcl
module "snapshot_maintenance" {
  source="connect-group/rds-finalsnapshot/aws//modules/rds_snapshot_maintenance"

  identifier="demodb"

  is_cluster=false
  database_endpoint="${module.db.this_db_instance_endpoint}"
  number_of_snapshots_to_retain = 1
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${module.snapshot_maintenance.identifier}"

  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.large"
  allocated_storage = 5

  name     = "demodb"
  username = "user"
  password = "YourPwdShouldBeLongAndSecure!"
  port     = "3306"

  vpc_security_group_ids = ["sg-12345678"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # DB subnet group
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  # DB parameter group
  family = "mysql5.7"

  # Snapshot names managed by module
  snapshot_identifier = "${module.snapshot_maintenance.snapshot_to_restore}"
  final_snapshot_identifier = "${module.snapshot_maintenance.final_snapshot_identifier}"
  skip_final_snapshot = "false"
}
```

Usage With Aurora Cluster
-------------------------
The database_endpoint passed to snapshot_maintenance should be based on the list of database instances;
the idea being that the lambda is not triggered until all database instances are in service.
For that reason the endpoint is set to `${element(aws_rds_cluster_instance.aurora.*.endpoint, 0)}`
in order to force a dependency on all of the instances.

```hcl
module "snapshot_maintenance" {
  source="connect-group/rds-finalsnapshot/aws//modules/rds_snapshot_maintenance"

  identifier="democluster"

  is_cluster=true
  database_endpoint="${element(aws_rds_cluster_instance.aurora.*.endpoint, 0)}"
  number_of_snapshots_to_retain = 1
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = 2
  identifier         = "aurora-cluster-demo-${count.index}"
  cluster_identifier = "${aws_rds_cluster.aurora.id}"
  instance_class     = "db.r3.large"
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${module.snapshot_maintenance.identifier}"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  database_name      = "demodb"
  master_username    = "user"
  master_password    = "AnInsanelyDifficultToGuessPasswordWhichShouldBeChanged"
}
```

Aurora Cluster Considerations
-----------------------------
Restoring an Aurora Cluster from a backup can, on occasion, take hours - 3 or more.
If you are seeking to reduce costs by destroying infrastructure it might be more advisable to destroy all database
instance in the cluster, but do not destroy the cluster itself.  This could be achieved by putting the cluster in a
different Terraform configuration (folder) to the instances; or through careful state manipulation.

Advanced Usage - Shared Lambda
------------------------------
This module creates one "Lambda" function for every database or cluster which is maintained by it.
This should not incur additional costs, because Lambdas are charged for execution and not storage; but it will clutter
up the Lambda web console (for example) with numerous Lambda functions if you use a lot of databases or clusters.

To avoid this, it is possible to generate just one 'global' Lambda function, and then refer to it.

The global Lambda function must be defined in a separate Terraform Configuration to the databases which it maintains.
One suggestion is to have an "account_bootstrap" configuration which will create shared infastructure and IAM roles
- this is the perfect place to add the global Lambda.

An [example of shared lambda usage](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/tree/master/examples/example-with-shared-lambda) 
is listed in the examples section below.  For completeness, a brief example is also included here.

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

KMS Keys
--------
If using KMS Keys, do not destroy them - else you will not be able to restore the backup.
Try keeping them in a separate Terraform configuration project (folder).

You may want to prevent destruction with a lifecycle statement, e.g.

```hcl
resource "aws_kms_key" "this" {
 description             = "database storage encryption key"
 deletion_window_in_days = "30"
 enable_key_rotation     = true

 lifecycle {
   prevent_destroy = true
 }
}
```

Note that it is very difficult to manually change the KMS Key.  This is because
changing the key,
1. destroys the database; 
2. snapshots it with the original key;
3. creates a new database with the new key; 
4. Restores the snapshot and the old key

For more information see https://aws.amazon.com/premiumsupport/knowledge-center/update-encryption-key-rds/

Examples
--------

* [Complete RDS example for MySQL using official Terraform RDS Module](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/tree/master/examples/example-with-rds-module)
* [Complete Aurora example](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/tree/master/examples/example-with-aurora)
* [Complete RDS MySQL example](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/tree/master/examples/example-with-rds)
* [Shared Lambda Example](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/tree/master/examples/example-with-shared-lambda)

Terraform Version
-----------------
Version 1.0.10 of this module requires >=0.10.4 because it uses 'Local Values' bug fixed in 0.10.4 and the `timeadd` function from 
version 0.11.2.

Version 2.0.1 of this module requires >=0.12.20 and is compatible with 0.13.x

How does it work? (Under the hood)
----------------------------------
This module creates a Lambda function which will run just once, after the database is created: it will remove  
snapshots to ensure that the expected number of retained snapshots is met.

The AWS RDS service maintains the final snapshot, which is not managed by Terraform; but on 'first run', and until the 
database is destroyed for the first time, that snapshot will not exist.  To detect the snapshot, a CloudFormation 
CustomResource is used to execute a Lambda that checks for the existence of a snapshot.  See the  
[terraform-aws-lambda-exec](https://github.com/connect-group/terraform-aws-lambda-exec) module for more information 
about how to execute a Lambda during terraform execution.

Authors
-------
Currently maintained by [these awesome contributors](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/graphs/contributors).
Module managed by [Adam Perry](https://github.com/4dz) and [Connect Group](https://github.com/connect-group)

License
-------
Apache 2 Licensed. See LICENSE for full details.
