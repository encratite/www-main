require 'hash'
require 'error'
require 'SecuredFormWriter'
require 'site/RequestManager'

def processFormFields(request)
	randomString = request.getPost(SecuredFormWriter::RandomString)
	addressHash = fnv1a(request.address)
	formHash = request.getPost(SecuredFormWriter::HashField)
	hash = fnv1a(randomString + addressHash)
	if hash != formHash
		raise RequestManager::Exception.new($generator.get(hashError, request))
	end
end
