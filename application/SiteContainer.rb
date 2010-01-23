class SiteContainer
	def initialize(site)
		site.instance_variables.each do |variable|
			symbol = variable.to_s
			value = site.instance_variable_get symbol
			instance_variable_set(symbol, value)
		end
		
		@localPrefix = []
		installHandlers
	end
	
	def convertArray(input)
		return input.class == Array ? input : [input]
	end
	
	def installHandler(path, handlerSymbol, argumentCount = 0)
		separator = '/'
		path = convertArray(@prefix) + convertArray(@localPrefix) + convertArray(path)
		path = separator + path * separator
		
		handler = lambda { |request| send(handlerSymbol, request) } if handlerSymbol.class == Symbol
		
		requestHandler = RequestHandler.new(path, handler, argumentCount)
		@requestManager.addHandler requestHandler
	end
	
	def installMenuHandler(description, path, handlerSymbol, condition = lambda { |request| true }, argumentCount = 0)
		installHandler(path, handlerSymbol, argumentCount)
		@menu.add(description, path, condition)
	end
end
