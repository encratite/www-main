require 'site/MIMEType'

def visualiseEnvironment(request)
	output = "Environment:\n"
	request.environment.each { |key, value| output += "#{key}: #{value} (#{value.class})\n" }
	input = request.environment['rack.input'].read()
	output += "\nInput:\n#{input}"
	return MIMEType::Plain, output
end
