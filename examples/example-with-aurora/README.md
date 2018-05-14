# Final Snapshot used in conjunction with Aurora Cluster

This folder contains an example of an Aurora Cluster deployed in AWS.

1. The infrastructure is first created with `terraform apply -var first_run=true`
1. When destroyed with `terraform destroy`, a final snapshot will be taken.
2. When recreated with `terraform apply`, (no first_run var this time) the snapshot will be restored.
3. When destroyed with `terraform destroy`, a final snapshot will be taken and the previous final snapshot removed.
4. When recreated with `terraform apply`, the latest final snapshot will be restored.   

# Tidying Up
If you want to clean up after the database, you will need to `terraform destroy` and then manually remove the final
snapshot and SSM Parameter using the web console or the AWS command line tool.