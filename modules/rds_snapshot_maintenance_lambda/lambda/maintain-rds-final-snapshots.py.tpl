import boto3

# ---------------------------------------------------------------------------------------------------------------------
# RDS SNAPSHOT MANAGEMENT ${function_name}
#
# terraform-aws-rds-finalsnapshot
# Copyright 2018 Connect Group
#
# Delete old final snapshots, retaining only as many as are specified in `number_of_snapshots_to_retain`
# ---------------------------------------------------------------------------------------------------------------------

# Global so that `get_all_db_cluster_snapshots`, `get_all_db_snapshots` and `handler` can access the AWS RDS API.
rds = boto3.client('rds')

# ---------------------------------------------------------------------------------------------------------------------
# Main entry point into the Lambda function.
# Event and Context are ignored; instead the variables required by the Lambda are compiled in by the terraform
# file_template resource.
# ---------------------------------------------------------------------------------------------------------------------
def handler(event,context):

  if 'final_snapshot_identifier' in event:
    final_snapshot_identifier = event['final_snapshot_identifier']
  else:
    raise Exception('final_snapshot_identifier not supplied!')

  if 'number_of_snapshots_to_retain' in event:
    number_of_snapshots_to_retain = event['number_of_snapshots_to_retain']
  else:
    raise Exception('number_of_snapshots_to_retain not supplied!')

  if 'identifier' in event:
    identifier = event['identifier']
  else:
    raise Exception('identifier not supplied!')

  if 'is_cluster' in event:
    is_cluster = str(event['is_cluster']).lower() == 'true'
  else:
    raise Exception('is_cluster not supplied!')

  # -------------------------------------------------------------------------------------------------------------------
  # Remove old db final snapshots
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