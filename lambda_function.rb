require "json"
require "slack-notifier"

def hello(event:, context:)
  notifier = Slack::Notifier.new 

	ENV["URL"] do
		defaults channel: ENV["CHANNEL"], link_names: 1
	end

  notifier.post text: 'Hello, Lambda for Ruby'
end