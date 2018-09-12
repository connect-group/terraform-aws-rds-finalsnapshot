1. Create a database using KMS Key A.
2. Run terraform destroy
3. Run terraform apply
4. Change the database to use Key B
5. Run terraform apply

This will cause a -/+ plan which destroys the database and then recreates it.

The lambdas will run for up to 16 minutes while the database is destroyed.  Then they will correctly update the finalsnapshot.

Note that apply will keep destroying/creating the database as you cannot change a key in this way!

See https://aws.amazon.com/premiumsupport/knowledge-center/update-encryption-key-rds/


