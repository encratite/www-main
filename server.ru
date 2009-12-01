class HttpReplies
	Ok = 200
	NotFound = 404
end

def handleRequest(environment)
	content = "Environment:\n"
	environment.each { |key, value| content += "#{key}: #{value.to_s} (#{value.class.to_s})\n" }
	
	replyCode = HttpReplies::Ok
	
	fields =
	{
		'Content-Type' => 'text/plain',
		'Content-Length' => content.size.to_s
	}
	
	output =
	[
		replyCode,
		fields,
		[content]
	]
	
	return output
end

#run handleRequest
run lambda { |environment| handleRequest environment }
