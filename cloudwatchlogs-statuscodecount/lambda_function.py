import json
import boto3
import os
import requests
import datetime
import logging
import re
import matplotlib.pyplot as plt
import asyncio

days = 7    # how many days ?

logger = logging.getLogger()
logger.setLevel(logging.INFO)

async def _post(file_path):
    
    webhook_url =os.environ["URL"]
    params = { 	# Create payload
        'token':os.environ["TOKEN"], 
        "channels": os.environ["CHANNEL"],
    }
    
    files = {'file': open(file_path, 'rb')}
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
    
    sess = boto3.Session(
                        aws_access_key_id=access_key_id,
                        aws_secret_access_key = secret_access_key
                        )
    region = os.environ["region"]
    cw_client = sess.client("logs", region_name=region)
    
    logGroup = os.environ["logGroup"]
    logStream = [os.environ["logStream1"], os.environ["logStream2"]]
    print(logStream)
    dt_now = datetime.datetime.now()
    count = {} # statuscodeのcountに利用
    index = 0

    for hour in range(0, 24*days, 1):   #時間ごと

        for name in logStream:  #ログストリームごと
            #print(name)
            if hour%24==0 and name == logStream[-1] and hour!=0:
                index += 1
                for status in count.keys():
                    count[status].append(0)

            startTime = dt_now - datetime.timedelta(hours=hour+1)
            endTime = dt_now - datetime.timedelta(hours=hour)
            startTimeStamp = int(startTime.timestamp())*1000
            endTimeStamp = int(endTime.timestamp())*1000

            print(logGroup)
            print(name)
            response = cw_client.get_log_events(
                            logGroupName=logGroup,
                            logStreamName=name,
                            startTime=startTimeStamp,
                            endTime=endTimeStamp,
                            startFromHead=True
                        )
            #print("====")
            #print(response["events"][0]["message"])
            #print(response["events"][-1]["message"])
            for event in response["events"]:
                message = event["message"]
                
                #print(message)
                if " Completed 2" in message or " Completed 302" in message:
                    continue
                elif " Completed " in message:
                    status = message.split()[13]
                    if count.get(status) == None:
                        count[status]=[0]*(index+1)
                    count[status][index]+=1
    
    count_tuple = sorted(count.items())
    
    #　棒グラフ
    total_count = dict((x, sum(y)) for x, y in count_tuple)
    print(total_count)

    colorlist = []
    for status in list(total_count.keys()):
        if int(status) < 400:
            colorlist.append("b")
        elif int(status) < 500:
            colorlist.append("g")
        else:
            colorlist.append("r")

    fig, ax = plt.subplots(figsize=(7, 5))
    rects = ax.bar(list(total_count.keys()), list(total_count.values()), width=0.7, color=colorlist)
    ax.set_xlabel("status code")
    ax.set_ylabel("counts")
    ax.set_title("counts of weekly status code")

    for rect in rects:
        height = rect.get_height()
        ax.annotate('{}'.format(height),
                   xy=(rect.get_x() + rect.get_width() / 2, height),
                   xytext=(0, 3),
                   textcoords="offset points",
                   ha='center', va='bottom')

    fig.savefig("/tmp/total_counts.png")

    # 折れ線グラフ
    dates = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    figg = plt.figure()
    ax = figg.add_subplot(1, 1, 1)
    plt.grid(True)

    for status, array in count_tuple:
        ax.plot(dates, array, label=status, marker='o')

    ax.legend()
    ax.set_xlabel("date")
    ax.set_ylabel("counts")
    ax.set_title("counts of daily status code")

    figg.savefig("/tmp/daily_counts.png")

    loop = asyncio.get_event_loop()
    gather = asyncio.gather(
        _post("/tmp/total_counts.png"),
        _post("/tmp/daily_counts.png")
    )
    loop.run_until_complete(gather)
