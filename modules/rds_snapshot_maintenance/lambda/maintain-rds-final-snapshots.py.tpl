import boto3

# ---------------------------------------------------------------------------------------------------------------------
# SNAPSHOT MANAGEMENT FOR ${identifier}
#
# terraform-aws-rds-finalsnapshot
# Copyright 2018 Connect Group
#
# Create a SSM Parameter that maintains the id of the snapshot to restore after a `terraform destroy`.
#
# The SSM Parameter is called "/rds_final_snapshot/${identifier}/snapshot_to_restore"
# The SSM Parameter is not managed by Terraform, so will not be destroyed with the database and other infrastructure.
#
# Also, delete old final snapshots, retaining only as many as are specified in `number_of_snapshots_to_retain`
#
# The lambda runs just once, within 3 minutes of creation, and should not be run again.
# ---------------------------------------------------------------------------------------------------------------------

# Global so that `get_all_db_cluster_snapshots`, `get_all_db_snapshots` and `handler` can access the AWS RDS API.
rds = boto3.client('rds')

# ---------------------------------------------------------------------------------------------------------------------
# Main entry point into the Lambda function.
# Event and Context are ignored; instead the variables required by the Lambda are compiled in by the terraform
# file_template resource.
# ---------------------------------------------------------------------------------------------------------------------
def handler(event,context):

  final_snapshot_identifier = "${final_snapshot_identifier}"
  number_of_snapshots_to_retain = ${number_of_snapshots_to_retain}
  identifier = "${identifier}"
  is_cluster = ${is_cluster}

  # -------------------------------------------------------------------------------------------------------------------
  # 1. Update SSM Parameter /rds_final_snapshot/${identifier}/snapshot_to_restore
  #    with value of final_snapshot_identifier.
  # -------------------------------------------------------------------------------------------------------------------
  ssm = boto3.client('ssm')
  ssm.put_parameter(
    Name='/rds_final_snapshot/'+ identifier + '/snapshot_to_restore',
    Value=final_snapshot_identifier,
    Type='String',
    Overwrite=True)

  # Put something in the Cloudwatch Log.
  print "Tracked /rds_final_snapshot/" + identifier + "/snapshot_to_restore = " + final_snapshot_identifier

  # -------------------------------------------------------------------------------------------------------------------
  # 2. Remove old db final snapshots
  # -------------------------------------------------------------------------------------------------------------------
  if number_of_snapshots_to_retain >= 0:

    # `final_snapshot_identifier[:-5]` will trim the last 5 characters from the snapshot identifier,
    # which we expect to be digits.
    if is_cluster:
      snapshots = get_all_db_cluster_snapshots(identifier, final_snapshot_identifier[:-5])
    else:
      snapshots = get_all_db_snapshots(identifier, final_snapshot_identifier[:-5])

    if len(snapshots) > number_of_snapshots_to_retain:
      if number_of_snapshots_to_retain > 0:
        # Ordered by creation time with oldest first
        snapshots.sort(key=lambda k: k['SnapshotCreateTime'])

        # Remove the last snapshots from the list (we want to keep them)
        del snapshots[-number_of_snapshots_to_retain:]

      # -------------------------------
      # delete snapshots still in list.
      # -------------------------------
      for snapshot in snapshots:
        if is_cluster:
          snapshot_identifier=snapshot['DBClusterSnapshotIdentifier']
          rds.delete_db_cluster_snapshot(DBClusterSnapshotIdentifier=snapshot_identifier)
          print "Deleted DB Cluster Snapshot " + snapshot_identifier
        else:
          snapshot_identifier=snapshot['DBSnapshotIdentifier']
          rds.delete_db_snapshot(DBSnapshotIdentifier=snapshot_identifier)
          print "Deleted DB Snapshot " + snapshot_identifier

  return "Finished"

# ---------------------------------------------------------------------------------------------------------------------
# Get a list of DB Cluster Snapshots applicable to the Cluster identifier, and whose snapshot identifier
# begins with `snapshot_prefix`
# ---------------------------------------------------------------------------------------------------------------------
def get_all_db_cluster_snapshots(identifier, snapshot_prefix):
    snapshots = []

    kwargs = { 'DBClusterIdentifier': identifier, 'SnapshotType': 'manual' }
    while True:
        resp = rds.describe_db_cluster_snapshots(**kwargs)
        for snapshot in resp['DBClusterSnapshots']:
          if snapshot['DBClusterSnapshotIdentifier'].startswith(snapshot_prefix):
            snapshots.append(snapshot)

        try:
            kwargs['Marker'] = resp['Marker']
        except KeyError:
            break

    return snapshots

# ---------------------------------------------------------------------------------------------------------------------
# Get a list of all DB Instance Snapshots applicable to the Cluster identifier, and whose snapshot identifier
# begins with `snapshot_prefix`
# ---------------------------------------------------------------------------------------------------------------------
def get_all_db_snapshots(identifier, snapshot_prefix):
    snapshots = []

    kwargs = { 'DBInstanceIdentifier': identifier, 'SnapshotType': 'manual' }
    while True:
        resp = rds.describe_db_snapshots(**kwargs)

        for snapshot in resp['DBSnapshots']:
          if snapshot['DBSnapshotIdentifier'].startswith(snapshot_prefix):
            snapshots.append(snapshot)

        try:
            kwargs['Marker'] = resp['Marker']
        except KeyError:
            break

    return snapshots