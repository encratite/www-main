require 'hash'
require 'error'
require 'HashFormWriter'
require 'site/RequestManager'

def processFormFields(request, names)
	raise RequestManager::Exception.new(fieldError) if !request.postIsSet(names)
	fields = names.map { |name| request.getPost name }
	security = request.getPost(HashFormWriter::Security)
	error = hashCheck(fields, security)
	raise RequestManager::Exception.new($generator.get(error, request)) if error != nil
	return fields
end
