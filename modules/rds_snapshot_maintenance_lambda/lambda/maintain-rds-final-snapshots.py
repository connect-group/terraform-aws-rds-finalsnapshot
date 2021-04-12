import boto3
import json
import http.client
from urllib.request import build_opener, HTTPHandler, Request
from botocore.exceptions import ClientError

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

  if event['RequestType'] == "Delete":
    sendResponse(event, context, "SUCCESS", {})
    return

  responseStatus = "SUCCESS"
  responseData   = {"Error":""}

  if 'ResourceProperties' in event:
      inputs = event['ResourceProperties']
  else:
      raise Exception('ResourceProperties not supplied!')

  if 'final_snapshot_identifier' in inputs:
    final_snapshot_identifier = inputs['final_snapshot_identifier']
  else:
    sendResponse(event, context, "FAILED", {"Error": "final_snapshot_identifier not specified"})
    return

  if 'number_of_snapshots_to_retain' in inputs:
    number_of_snapshots_to_retain = int(inputs['number_of_snapshots_to_retain'])
  else:
    sendResponse(event, context, "FAILED", {"Error": "number_of_snapshots_to_retain not supplied!"})
    return

  if 'identifier' in inputs:
    identifier = inputs['identifier']
  else:
    sendResponse(event, context, "FAILED", {"Error": "identifier not supplied!"})
    return

  if 'is_cluster' in inputs:
    is_cluster = (inputs['is_cluster'].lower() == 'true' or inputs['is_cluster'] == '1')
  else:
    sendResponse(event, context, "FAILED", {"Error": "is_cluster not supplied!"})
    return

  # -------------------------------------------------------------------------------------------------------------------
  # Reboot DB Instance if necessary
  # -------------------------------------------------------------------------------------------------------------------
  if is_cluster:
    reboot_cluster_if_required(identifier)
  else:
    reboot_instance_if_required(identifier)


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
          print("Deleted DB Cluster Snapshot " + snapshot_identifier)
        else:
          snapshot_identifier=snapshot['DBSnapshotIdentifier']
          rds.delete_db_snapshot(DBSnapshotIdentifier=snapshot_identifier)
          print("Deleted DB Snapshot " + snapshot_identifier)


  sendResponse(event, context, responseStatus, responseData)
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

# ---------------------------------------------------------------------------------------------------------------------
# Send the response to a signed url endpoint, so CloudFormation can pick up the result.
# ---------------------------------------------------------------------------------------------------------------------
def sendResponse(event, context, responseStatus, responseData):
  responseBody = json.dumps({
    "Status": responseStatus,
    "Reason": "See the details in CloudWatch Log Stream: " + context.log_stream_name,
    "PhysicalResourceId": context.log_stream_name,
    "StackId": event['StackId'],
    "RequestId": event['RequestId'],
    "LogicalResourceId": event['LogicalResourceId'],
    "Data": responseData
  })

  encodedResponseBody = responseBody.encode('utf-8')

  print(('ResponseURL: {}'.format(event['ResponseURL'])))
  print(('ResponseBody: {}'.format(responseBody)))

  opener = build_opener(HTTPHandler)
  request = Request(event['ResponseURL'], data=encodedResponseBody)
  request.add_header('Content-Type', '')
  request.add_header('Content-Length', len(encodedResponseBody))
  request.get_method = lambda: 'PUT'
  response = opener.open(request)
  print(("Status code: {}".format(response.getcode())))
  print(("Status message: {}".format(response.msg)))

def reboot_instance_if_required(identifier):
  reboot_required = False
  db_instances = rds.describe_db_instances(DBInstanceIdentifier=identifier)
  param_groups = db_instances['DBInstances'][0]['DBParameterGroups']
  for param_group in param_groups:
    if param_group['ParameterApplyStatus'] == "pending-reboot":
      reboot_required = True

  if reboot_required:
    print("Rebooting Instance " + identifier)
    rds.reboot_db_instance(DBInstanceIdentifier=identifier, ForceFailover=False)

def reboot_cluster_if_required(identifier):
  clusters = rds.describe_db_clusters(DBClusterIdentifier=identifier)
  members = clusters['DBClusters'][0]['DBClusterMembers']
  for member in members:
    instance_id = member['DBInstanceIdentifier']
    reboot_instance_if_required(instance_id)
