require 'SiteContainer'

require 'www-library/MIMEType'
require 'www-library/RequestHandler'

class EnvironmentHandler < SiteContainer
  def installHandlers
    handler = WWWLib::RequestHandler.handler('environment', method(:showEnvironment))
    @requestManager.addHandler handler
  end

  def showEnvironment(request)
    output = "Environment:\n"
    request.environment.each { |key, value| output += "#{key}: #{value} (#{value.class})\n" }
    input = request.environment['rack.input'].read()
    output += "\nInput:\n#{input}"
    return WWWLib::MIMEType::Plain, output
  end
end
