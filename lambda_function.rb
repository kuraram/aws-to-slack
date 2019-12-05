require "json"
#require "slack-notifier"
require "net/http"
require "uri"
require "json"

def codebuild_handler(event:, context:)

  puts "=== event ===\n #{event}\n ==="	# Display event
  project = event["detail"]["project-name"]
  status = event["detail"]["build-status"]
  additional_info = event["detail"]["additional-information"]
  build_id = additional_info["logs"]["stream-name"]
  log_link = additional_info["logs"]["deep-link"]
  phases = additional_info["phases"]
  phase_txt = ""
  phases.each do | phase |
    if phase["phase-status"] == "FAILED"
      phase_txt = phase["phase-context"][0]	# Retrieve error
    end
  end
  codebuild_notifer(build_id, project, status, phase_txt, log_link)

end

def codebuild_notifer(build_id, project, status, phase_txt, link)

	uri  = URI.parse(ENV["URL"])
	params = { 	# Create payload
      text: get_text(status, project), 
      channel: ENV["CHANNEL"],
      "attachments":[{
        author_name: "#{project} in codebuild",
        author_link: "https://ap-northeast-1.console.aws.amazon.com/codesuite/codebuild/projects/#{project}/history",
        text: phase_txt,
        color: get_color(status),
        actions: [{"type": "button", "text": "view log", "url": link}]
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

def get_text(status, project)
  if status == "FAILED"
    return "<!here> #{project} プロジェクトが失敗しました:cry:"
  else
    return "<!here> #{project} プロジェクトが成功しました:blush:"
  end

end

def get_color(status)
  if status == "FAILED"
    return "danger"
  else
    return "good"
  end
end