# Two RDS Databases, one global Lambda
> You must have created the "lambda" infrastructure before running this Terraform configuration.

This project will create two databases, but will not create any lambda functions.  Instead it will
use the global function, and attach permissions so that it can maintain the final snapshots and SSM
parameters required by these two databases.
