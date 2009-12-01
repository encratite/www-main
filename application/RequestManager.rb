require 'HTTPReplies'

class RequestManager
	def initialize()
		@handlers = []
	end
	
	def addHandler(newHandler)
		@handlers <<= newHandler
	end
	
	def handleRequest(request)
		@handlers.each do |handler|
			if handler.match request
			
			end
		end
		
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
end
