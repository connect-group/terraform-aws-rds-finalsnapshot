Final Snapshot used in conjunction with Aurora Cluster
======================================================
This folder contains an example of an Aurora cluster deployed in AWS.

1. The infrastructure is first created with `terraform apply`
1. When destroyed with `terraform destroy`, a final snapshot will be taken.
2. When recreated with `terraform apply`, (no first_run var this time) the snapshot will be restored.
3. When destroyed with `terraform destroy`, a final snapshot will be taken and the previous final snapshot removed.
4. When recreated with `terraform apply`, the latest final snapshot will be restored.   

Configuration in this directory creates set of RDS resources including a DB cluster, DB instances, DB subnet group 
and DB parameter group.

Data sources are used to discover existing VPC resources (VPC, subnet and security group).

The database_endpoint passed to snapshot_maintenance should be based on the list of database instances;
the idea being that the lambda is not triggered until all database instances are in service.
For that reason the endpoint is set to `${element(aws_rds_cluster_instance.aurora.*.endpoint, 0)}`
in order to force a dependency on all of the instances.

Usage
-----
To run this example you need to execute:

```bash
$ terraform init
$ terraform plan 
$ terraform apply
$ terraform destroy
$ terraform apply
$ terraform destroy
$ terraform apply
$ terraform destroy
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these 
resources.

Aurora Cluster Considerations
-----------------------------
Restoring an Aurora Cluster from a backup can, on occasion, take hours - 3 or more.
If you are seeking to reduce costs by destroying infrastructure it might be more advisable to destroy all database
instance in the cluster, but do not destroy the cluster itself.  This could be achieved by putting the cluster in a
different Terraform configuration (folder) to the instances; or through careful state manipulation.

Tidying Up
----------
If you want to clean up after the database, you will need to `terraform destroy` and then manually remove the final
snapshot using the web console or the AWS command line tool.

**Delete the snapshot**
```bash
$ aws --region=eu-west-1 rds describe-db-cluster-snapshots --db-cluster-identifier "democluster" \
      --query 'DBClusterSnapshots[*].DBClusterSnapshotIdentifier' --output text
      
democluster-final-snapshot-00003

$ aws --region=eu-west-1 rds delete-db-cluster-snapshot --db-cluster-snapshot-identifier "democluster-final-snapshot-00003"
```

 