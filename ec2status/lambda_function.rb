require "json"
#require "slack-notifier"
require "net/http"
require "uri"
require "json"
require "aws-sdk-ec2"

def lambda_handler(event:, context:)
    
    ec2_region = event["region"]
    ec2_id = event["detail"]["instance-id"]
   
    info = nil
    ec2 = Aws::EC2::Resource.new(region: ec2_region)
    ec2.instances.each do |i|
    	if i.id == ec2_id then
    	    info = i
    	    break
        end
    end
    
    fields = []
    fields.append({
        "title": "Name",
        "value": get_name(info.id),
        "short": true,
    })
    
    fields.append({
        "title": "Instance Type",
        "value": info.instance_type,
        "short": true,
    })
    
    fields.append({
        "title": "Private IP",
        "value": info.private_ip_address,
        "short": true,
    })
    
    fields.append({
        "title": "Public IP",
        "value": info.public_ip_address,
        "short": true,
    })
    
    
    params = { 	# Create payload
    text: "<!here> インスタンスが起動しました",
    channel: ENV["CHANNEL"],
    "fields": fields,
    "color": "good",
	}
    
    uri  = URI.parse(ENV["URL"])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.start do
        request = Net::HTTP::Post.new(uri.path)
        request.set_form_data(payload: params.to_json)
        http.request(request)
	end
    
end

def get_name(id)
    
    return id

end