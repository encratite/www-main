require 'SiteContainer'

require 'site/MIMEType'

class EnvironmentHandler < SiteContainer
	def installHandlers
		handler = RequestHandler.handler('environment', method(:showEnvironment))
		@requestManager.addHandler handler
	end

	def showEnvironment(request)
		output = "Environment:\n"
		request.environment.each { |key, value| output += "#{key}: #{value} (#{value.class})\n" }
		input = request.environment['rack.input'].read()
		output += "\nInput:\n#{input}"
		return MIMEType::Plain, output
	end
end
