import json
import boto3
import base64
import datetime
import os
from datetime import date
from botocore.exceptions import ClientError
iam = boto3.client('iam')
secretmanager = boto3.client('secretsmanager')
IAM_UserName = os.environ['iam_username']
secret_name = os.environ['secret_name']
TopicArn = os.environ['sns_topic_arn']
sns_send_report = boto3.client('sns',region_name='ap-southeast-1')

def error_handling(message):
    sns_send_report.publish(TopicArn=TopicArn, 
                            Subject="Access key rotate failed", 
                            Message="Access key rotate failed: "+str(message) )
    raise
    
def check_key():
    try:
        response = iam.list_access_keys(UserName=IAM_UserName)
        print(response)
        if(len(response['AccessKeyMetadata']) >1):
            raise Exception("more than 1 access key found")
        elif(len(response['AccessKeyMetadata']) ==0):
            raise Exception("no access key found")
        return(response['AccessKeyMetadata'][0])
    except ClientError as e:
        error_handling(e)
    except Exception  as e:
        error_handling(e)
    
def create_key():
    try:
        response = iam.create_access_key(UserName=IAM_UserName)
        accessKeyID = response['AccessKey']['AccessKeyId']
        accessKeySecret = response['AccessKey']['SecretAccessKey']
        json_data=json.dumps({'accessKeyID':accessKeyID,'accessKeySecret':accessKeySecret})
        secmanagerv=secretmanager.put_secret_value(SecretId=secret_name,SecretString=json_data)
    except ClientError as e:
        error_handling(e)
        
def delete_key(accessKeyMetadata):
    try:
        userName = accessKeyMetadata['UserName']
        accessKeyId = accessKeyMetadata['AccessKeyId']
        iam.update_access_key(AccessKeyId=accessKeyId,Status='Inactive',UserName=userName)
        iam.delete_access_key (UserName=userName,AccessKeyId=accessKeyId)
    except ClientError as e:
        error_handling(e)
        
def handler(event, context):
    # get the existing key
    accessKeyMetadata = check_key()
    
    # create new accesskey and update key in secret manager
    create_key()
    
    # delete the old key
    delete_key(accessKeyMetadata)
