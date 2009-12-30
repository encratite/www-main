require 'hash'
require 'error'
require 'HashFormWriter'

class FormCheck
	Process = Proc.new do |request, names|
		return fieldError if !request.postIsSet(names)
		fields = names.map { |name| request.getPost name }
		security = request.getPost(HashFormWriter::Security)
		error = hashCheck(fields, security)
		return $generator.get error, request if error != nil
	end
end
