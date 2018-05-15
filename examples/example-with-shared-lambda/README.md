# Example of using a shared lambda
If you have multiple databases and clusters in an AWS Account and make use of this module,
then you will end up with a number of Lambda functions which all do the same thing.

You can reduce this clutter by setting up a global, shared lambda which can be used by
all databases and clusters.

This example has two folders:
* lambda
* rds

You must apply the terraform configuration in the 'lambda' folder first.

Then, apply the configuration in the 'rds' folder which will create two databases sharing one
lambda function. 