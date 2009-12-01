class RequestHandler
	def initialize()
		@handlers = []
	end
	
	def match(request)
		path = request.path
		
		if @path.size > path.size
			return false
		end
		
		path.size.times do |i|
			if path[i] != @path[i]
				return false
			end
		end
		
		process
		
		return true
	end
end
