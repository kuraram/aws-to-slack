require "json"
#require "slack-notifier"
require "net/http"
require "uri"
require "json"

def lambda_handler(event:, context:)

	puts "=== event ===\n #{event}\n"
  puts "=============\n"	# Display event"
	sns = event["Records"][0]["Sns"]
	message = sns["Message"]
	message = JSON.parse(message)
	detail = message["detail"]
  state = detail["state"]
 
  codedeploy_notifer(sns, message, detail, state)

end

def codedeploy_notifer(sns, message, detail, state)

	uri  = URI.parse(ENV["URL"])
  params = { 	# Create payload
    text: "CodeDeploy #{state} in #{detail["deploymentGroup"]}",
    channel: ENV["CHANNEL"],
    "attachments":[{
      author_name: "Deploy Console",
      author_link: "https://ap-northeast-1.console.aws.amazon.com/codesuite/codedeploy/applications/#{detail["application"]}?region=ap-northeast-1",
      color: get_color(state),
      actions: [{"type": "button", "text": "view log", "url": ENV["LOG_URL"]}]
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

def get_color(state)
  if state == "FAILURE"
    return "danger"
  else
    return "good"
  end
end