AWS RDS Final Snapshot Management Module
========================================
This module, or specifically the two submodules `snapshot_identifiers` and `snapshot_maintenance` will manage 
Final Snapshots of AWS database instances and clusters.

The primary purpose of the modules is to allow for destruction of a database, such that it will capture a final 
snapshot and then restore it when later recreated.  

The use case is for development and testing environments which should not be running 24/7 (eg. to save money, or reduce
risk).  Perhaps a project is only developed infrequently; or perhaps you only want development to run 9-5 Mon-Fri.

This module restores a database which was previously destroyed.

> ###### WARNING
> Destroying infrastructure is by its nature destructive - when developing an environment,
> take plenty of manual backups until you have tested your infrastructure code! 

This module can be used from the command-line and can also be used within a CI environment, but there is one manual
step.  The very first time the database is created, the "first_run" variable must be set to true.  On all other runs,
it should be set to false.

This can be handled as follows,

    # First run
    terraform apply -var first_run=true
    
    # Subsequent runs:
    terraform destroy
    terraform apply
    terraform destroy
    terraform apply

Please read all of the README if using or maintaining this module.

The Root module should be used primarily for testing or evaluation.  It will create a usable RDS
database instance, but does not have the full flexibility that a database module such as 
"terraform-aws-modules/aws/rds".

The Root module calls these modules which can (and should) be used separately to create independent resources:
                
* [rds_snapshot_identifiers](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/tree/master/modules/rds_snapshot_identifiers) - calculates Snapshot identifiers
* [rds_snapshot_maintenance](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/tree/master/modules/rds_snapshot_maintenance) - deletes old Snapshots

> ###### IMPORTANT
> When using the child modules directly, both of them must be used, even if you do not want to delete old snapshots.  
> The second module handles some state information which must be implemented after the database instance or cluster 
> is created.

Usage With 'Built-In' Simple MySQL Instance
-------------------------------------------

module "db_with_final_snapshot_management" {
  source = "connect-group/rds/aws"

  first_run = "{$var.first_run}"

  instance_identifier = "demodb"
  instance_class      = "db.t2.micro"
  allocated_storage   = 5

  database_name     = "demodb"
  username          = "user"
  password          = "AVerySecureInitialPasswordPerhapsChangeItManually"

  number_of_snapshots_to_retain = 0
}

## terraform version
This module requires >=0.10.4 because it uses 'Local Values' bug fixed in 0.10.4
and the `timeadd` function from version 0.11.2 

## description
This module will generate database snapshot names for restore/final snapshot
to ensure that infrastucture can be backed up, destroyed, and restored.

It will retain the last `number_of_snapshots_to_retain`.
If the number to retain is zero, it will simply delete the snapshot.
If the number to retain is 'ALL' then no snapshots will be deleted.

## pre-requisites
The AWS account should have been bootstrapped with connect_tf_core version 1.3.6 or later.
Specifically it expects a Lambda Function to exist named "maintain_rds_final_snapshots"

### How does it work
This module will create a Cloudwatch scheduled event which will run just once, within 5 minutes
of creation.

## variables to supply to the module
To see what a variable does look in variables.tf for descriptions.

The following variables are MANDATORY:
* final_snapshot_identifier


The following variables can be left blank and use the indicated defaults if
blank:
* number_of_snapshots_to_retain (Default = 1)

Authors
-------
Currently maintained by [these awesome contributors](https://github.com/connect-group/terraform-aws-rds-finalsnapshot/graphs/contributors).
Module managed by [Adam Perry](https://github.com/4dz) and [Connect Group](https://github.com/connect-group)

License
-------

Apache 2 Licensed. See LICENSE for full details.