import json
import boto3
import os
import requests
import logging
import asyncio

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_widget_db():
    
    widget = {
        "view": "timeSeries",
        "stacked": False,
        "start": "-PT24H",
        "metrics": [
            [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "toypo-api-production-01" ],
            [ "AWS/RDS", "WriteLatency", "DBInstanceIdentifier", "toypo-api-production-01" , { "yAxis": "right"}],
        ],
        "region": "ap-northeast-1",
         "timezone": "+0900"
    }
    return widget

def get_widget_mem():
    
    widget ={
        "view": "timeSeries",
        "stacked": False,
        "start": "-PT24H",
        "metrics": [
            [ "System/Linux", "MemoryUtilization", "InstanceId", "i-0bfc2f1c5d494a095" ],
            [ "...", "i-0b9a2b079cda561ce" ],
            [ "...", "i-071bf8eeecfd60a22" ],
            [ "...", "i-08d8204277cba1558" ]
        ],
        "region": "ap-northeast-1",
         "timezone": "+0900"
    }
    return widget

def get_widget_cpu():
    
    widget ={
        "view": "timeSeries",
        "stacked": False,
        "start": "-PT24H",
        "metrics": [
            [ "AWS/EC2", "CPUUtilization", "InstanceId", "i-0bfc2f1c5d494a095" ],
            [ "...", "i-0b9a2b079cda561ce" ],
            [ "...", "i-071bf8eeecfd60a22" ],
            [ "...", "i-08d8204277cba1558" ]
        ],
        "region": "ap-northeast-1",
         "timezone": "+0900"
    }
    return widget

def get_widget_redis():
    
    widget ={
        "view": "timeSeries",
        "stacked": False,
        "start": "-PT24H",
        "metrics": [
            [ "AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "CacheClusterId", "redis-for-master-001", "CacheNodeId", "0001" ],
            [ "...", "redis-for-master-002", ".", "." ],
            [ "...", "redis-for-master-003", ".", "." ],
            [ ".", "CPUUtilization", ".", "redis-for-master-001", ".", "." ],
            [ "...", "redis-for-master-002", ".", "." ],
            [ "...", "redis-for-master-003", ".", "." ]
        ],
        "region": "ap-northeast-1",
         "timezone": "+0900"
    }
    return widget
    
async def post(cw_client, webhook_url, params, widget):

    try: 
        response = cw_client.get_metric_widget_image(MetricWidget = widget)
    except ClientError as e:
        print(e.response['Error']['Message'])
    else:
        print("Get Image succeeded:")
        image = {'file': response['MetricWidgetImage']}

    req = requests.post(webhook_url, params=params, files=image)
    files = [('file', image), ('file', image)]
    req = requests.post(webhook_url, params=params, files=files)
    try:
        req.raise_for_status()
        logger.info("Message posted.")
        return req.text
    except requests.RequestException as e:
        logger.error("Request failed: %s", e)


def lambda_handler(event, context):
    
    access_key_id=os.environ["access_key_id"]
    secret_access_key=os.environ["secret_access_key"]
    
    sess = boto3.Session(aws_access_key_id = access_key_id,aws_secret_access_key = secret_access_key)
    cw_client = sess.client("cloudwatch")
    
    # add
    widget_db = json.dumps(get_widget_db())
    widget_mem = json.dumps(get_widget_mem())
    widget_cpu = json.dumps(get_widget_cpu())
    widget_redis = json.dumps(get_widget_redis())   
    
    webhook_url =os.environ["URL"]
    params = { 	# Create payload
        'token':os.environ["TOKEN"], 
        "channels": os.environ["CHANNEL"],
    }
    
    loop = asyncio.get_event_loop()
    gather = asyncio.gather(
        post(cw_client, webhook_url, params, widget_db),
        post(cw_client, webhook_url, params, widget_mem),
        post(cw_client, webhook_url, params, widget_cpu),
        post(cw_client, webhook_url, params, widget_redis)
    )
    loop.run_until_complete(gather)
    
    
        