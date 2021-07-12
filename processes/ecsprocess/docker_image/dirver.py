import os
import boto3
import pandas as pd
import traceback

s3 = boto3.client('s3')
BUCKET_NAME = os.environ['BUCKET_NAME']

print("hello world")
print("BUCKET_NAME :: " + BUCKET_NAME)
MYSQL_PASSWORD = os.environ['database/mysql/password']
print("MYSQL_PASSWORD :: " + MYSQL_PASSWORD)

s3_client = boto3.client("s3")
# Create the S3 object
obj = s3_client.get_object(
    Bucket=BUCKET_NAME,
    Key='sql-demo.csv'
)

# Read data from the S3 object
data = pd.read_csv(obj['Body'])

# Print the data frame
print('Printing the data frame...')
print(data)


# Note since the execution policy doesn't have ssm decrypt role hence
# this will throw error but task policy has ssm decrypt  role and
# these very same vlaues will be passed an environment value

# Also note that that one doesn't need to set environment variable in Dockerfile 
# as this parameters is working above without even setting the environment varaible.
try:
    ssm_client = boto3.client('ssm')
    encrypted_pass = ssm_client.get_parameter(
        Name='database/mysql/password', WithDecryption=True)['Parameter']['Value']
    print("encrypted pass is :: " + encrypted_pass)
except Exception as ex:
    # Send some context about this error to Lambda Logs
    print("Note::::  since the execution policy doesn't have ssm decrypt role hence this will throw error ::::")
    print("Exception with msg ::  {}".format(str(ex)))
    print(traceback.format_exc())
