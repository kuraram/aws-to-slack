require "json"
#require "slack-notifier"
require "net/http"
require "uri"
require "json"

def lambda_handler(event:, context:)

  puts "=== event ===\n #{event}\n ==="	# Display event
  sns = event["Records"][0]["Sns"]
  subject = sns["Subject"]
  timestamp = sns["Timestamp"]
  phase_txt = ""
 
  lb_notifer(sns, subject, timestamp, phase_txt)

end

def lb_notifer(sns, subject, timestamp, phase_txt)

  uri  = URI.parse(ENV["URL"])
  params = { 	# Create payload
    text: subject.to_s, 
    channel: ENV["CHANNEL"],
    "attachments":[{
      author_name: "ALB Console",
      author_link: "https://ap-northeast-1.console.aws.amazon.com/ec2/v2/home?region=ap-northeast-1#LoadBalancers:sort=loadBalancerName",
      color: "danger",
    }]
  }

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.start do
    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(payload: params.to_json)
    http.request(request)
  end

end