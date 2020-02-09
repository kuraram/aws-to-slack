require "json"
#require "slack-notifier"
require "net/http"
require "uri"
require "json"

def lambda_handler(event:, context:)

  #puts "=== event ===\n #{event}\n ==="	# Display event
  
  uri  = URI.parse(ENV["URL"])
  params = { 	# Create payload
    text: event.to_s,
    channel: ENV["CHANNEL"]
  }
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.start do
    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(payload: params.to_json)
    http.request(request)
  end

end