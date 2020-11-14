require "json"
#require "slack-notifier"
require "net/http"
require "uri"
require "json"
require "aws-sdk-cloudwatchlogs"
require 'base64'
require "zlib"
require 'stringio'

#抽出するログデータの最大件数
OUTPUT_LIMIT=30

def lambda_handler(event:, context:)
    
    p event
    # データの解凍
    bytes = event["awslogs"]["data"]
    gzip = Base64.decode64(bytes)
    gz = Zlib::GzipReader.new(StringIO.new(gzip.to_s))    
    uncompressed_string = gz.read
    json_message = JSON.parse(uncompressed_string)
    p json_message
    
    logGroup = json_message["logGroup"]
    logStream = json_message["logStream"]
    timestamp = json_message["logEvents"][0]["timestamp"]
    
    client = Aws::CloudWatchLogs::Client.new({
      region: "ap-northeast-1",
      access_key_id: ENV["access_key_id"],
      secret_access_key: ENV["secret_access_key"]
    })
    
    # 集計開始日時
    #start_time = Time.new(2020, 4, 13, 19, 51, 35, "+09:00")
    # 集計終了日時
    #end_time = Time.new(2020, 4, 13, 19, 52, 35, "+09:00")
    
    # ログメッセージを10件取得
    p logGroup
    p logStream
    p timestamp
    resp = client.get_log_events({
      log_group_name: logGroup,
      log_stream_name: logStream,
      #start_time: 1,
      #end_time: 1,
      end_time: timestamp+1500,
      start_from_head: false,
      limit: OUTPUT_LIMIT,
    })
    
    # エンドポイントの取得
    endpoint = nil
    statuscode = nil
    flag = false
    resp.events.reverse_each do | eve |
      p eve
      if eve.message =~ /Started/ and flag  then
        endpoint = eve.message.match(/Started(.*)/)
        break
      end
      
      if eve.message =~ /Completed 4/ then
        statuscode = eve.message
        flag = true
      end
      
      if  eve.message =~ /Completed 5/ then
        p statuscode = "<!channel> #{eve.message}"
        flag = true
      end
      
    end
    
    p endpoint
    if endpoint.nil? then
      #endpoint = "aaaa"
      endpoint = "CANNOT FIND ENDPOINT (OUT OF RANGE (#{OUTPUT_LIMIT}))" 
    end
    return if statuscode == nil
    
    fields = []
    fields.append({
      "title": "logGroup",
      "value": logGroup,
      "short": true,
    })
    
    fields.append({
      "title": "logStream",
      "value": logStream,
      "short": true,
    })
    
    fields.append({
      "title": "Endpoint",
      "value": endpoint,
      "short": false,
    })
    
    
    uri  = URI.parse(ENV["URL"])
    params = { 	# Create payload
      text: statuscode.to_s, 
      fields: fields,
      channel: ENV["CHANNEL"],
      color: "danger"
    }

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.start do
    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(payload: params.to_json)
    http.request(request)
  end
    
end