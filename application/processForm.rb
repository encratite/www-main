require 'hash'
require 'error'
require 'SecuredFormWriter'
require 'site/RequestManager'

def processFormFields(request, names)
	randomString = request.getPost(SecuredFormWriter::RandomString)
	formHash = request.getPost(SecuredFormWriter::HashField)
	
	fields = names.map { |name| request.getPost(name) }
	fieldError if fields.include?(nil) || randomString == nil || formHash == nil
	
	addressHash = fnv1a(request.address)
	
	input = randomString + addressHash
	hash = fnv1a(input)
	if hash != formHash
		raise RequestManager::Exception.new($generator.get(hashError, request))
	end
	
	return fields
end
