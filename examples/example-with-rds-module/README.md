Final Snapshot used in conjunction with official rds module
===========================================================
This folder contains an example of an RDS MySQL Instance deployed in AWS.

1. The infrastructure is first created with `terraform apply -var first_run=true`
1. When destroyed with `terraform destroy`, a final snapshot will be taken.
2. When recreated with `terraform apply`, (no first_run var this time) the snapshot will be restored.
3. When destroyed with `terraform destroy`, a final snapshot will be taken and the previous final snapshot removed.
4. When recreated with `terraform apply`, the latest final snapshot will be restored.   

Configuration in this directory creates set of RDS resources including DB instance, DB subnet group and DB 
parameter group.

Data sources are used to discover existing VPC resources (VPC, subnet and security group).

Usage
-----
To run this example you need to execute:

```bash
$ terraform init
$ terraform plan -var first_run=true
$ terraform apply -var first_run=true
$ terraform destroy # (warning, wait 3 minutes before destroying)
$ terraform apply
$ terraform destroy # (warning, wait 3 minutes before destroying)
$ terraform apply
$ terraform destroy # (warning, wait 3 minutes before destroying)
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these 
resources.

Tidying Up
----------
If you want to clean up after the database, you will need to `terraform destroy` and then manually remove the final
snapshot and SSM Parameter using the web console or the AWS command line tool.

**Delete the snapshot**
```bash
$ aws --region=eu-west-1 rds describe-db-snapshots --db-instance-identifier "demodb" \
      --query 'DBSnapshots[*].DBSnapshotIdentifier' --output text
      
demodb-final-snapshot-00003

$ aws --region=eu-west-1 rds delete-db-snapshot --db-snapshot-identifier "demodb-final-snapshot-00003"
```

**Delete the SSM Parameter**
```bash
$ aws ssm delete-parameter --name "/rds_final_snapshot/demodb/snapshot_to_restore"
```

 