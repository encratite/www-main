require 'hash'
require 'error'
require 'SecuredFormWriter'
require 'site/RequestManager'

def processFormFields(request, names)
	randomString = request.getPost(SecuredFormWriter::RandomString)
	addressHash = fnv1a(request.address)
	formHash = request.getPost(SecuredFormWriter::HashField)
	input = randomString + addressHash
	hash = fnv1a(input)
	if hash != formHash
		raise RequestManager::Exception.new($generator.get(hashError, request))
	end
	
	fields = names.map { |name| request.getPost(name) }
	fieldError if fields.include? nil
	
	return fields
end
