import boto3
import json
import httplib
from urllib2 import build_opener, HTTPHandler, Request
from botocore.exceptions import ClientError

# ---------------------------------------------------------------------------------------------------------------------
# RDS SNAPSHOT MANAGEMENT (FIND A SNAPSHOT) ${function_name}
#
# terraform-aws-rds-finalsnapshot
# Copyright 2018 Connect Group
#
# Find a DB or DB Cluster Snapshot based on the supplied identifer; return a default value if not found.
#
# Inputs:-
#  * identifier - instance or cluster identifier
#  * is_cluster - when true, indicates the identifier is a cluster identifier
#  * final_snapshot_prefix - the name of the snapshot must begin with this string
#  * default_value - returned if a snapshots is not found
#
# Outputs:-
#  * SnapshotIdentifier
#  * Error
# ---------------------------------------------------------------------------------------------------------------------

# Global so that `get_db_cluster_snapshot`, `get_db_snapshot` and `handler` can access the AWS RDS API.
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
  responseData = {"SnapshotIdentifier":"", "Error":""}

  if 'ResourceProperties' in event:
    inputs = event['ResourceProperties']
  else:
    raise Exception('ResourceProperties not supplied!')

  if 'identifier' in inputs:
    identifier=inputs['identifier']
  else:
    sendResponse(event, context, "FAILED", {"Error": "identifier not specified"})
    return

  if 'final_snapshot_prefix' in inputs:
    final_snapshot_prefix=inputs['final_snapshot_prefix']
  else:
    sendResponse(event, context, "FAILED", {"Error": "final_snapshot_prefix not specified"})
    return

  if 'is_cluster' in inputs:
    is_cluster = (inputs['is_cluster'].lower() == 'true' or inputs['is_cluster'] == '1')
  else:
    is_cluster = False

  if 'default_value' in inputs:
    responseData["SnapshotIdentifier"] = inputs["default_value"]

  #
  # Obtain a list of snapshots; each snapshot identifier will begin with 'final_snapshot_prefix'
  #
  if is_cluster:
    snapshots = get_all_db_cluster_snapshots(identifier, final_snapshot_prefix)
  else:
    snapshots = get_all_db_snapshots(identifier, final_snapshot_prefix)

  # Ordered by creation time with newest first
  snapshots.sort(key=lambda k: k['SnapshotCreateTime'], reverse=True)

  if len(snapshots) > 0:
    if is_cluster:
      responseData["SnapshotIdentifier"] = snapshots[0]['DBClusterSnapshotIdentifier']
    else:
      responseData["SnapshotIdentifier"] = snapshots[0]['DBSnapshotIdentifier']

  # print some thing if it helps with logging
  print "result="+responseData["SnapshotIdentifier"]
  print "Error="+responseData['Error']

  sendResponse(event, context, responseStatus, responseData)

  return "OK"

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

  print('ResponseURL: {}'.format(event['ResponseURL']))
  print('ResponseBody: {}'.format(responseBody))

  opener = build_opener(HTTPHandler)
  request = Request(event['ResponseURL'], data=responseBody)
  request.add_header('Content-Type', '')
  request.add_header('Content-Length', len(responseBody))
  request.get_method = lambda: 'PUT'
  response = opener.open(request)
  print("Status code: {}".format(response.getcode()))
  print("Status message: {}".format(response.msg))

