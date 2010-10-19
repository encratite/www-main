require 'hash'

require 'www-library/HTMLWriter'
require 'www-library/random'

class SecuredFormWriter < WWWLib::HTMLWriter
	RandomString = 'security1'
	HashField = 'security2'
	RandomStringLength = 128
	
	def securedForm(action,  request, arguments = {}, &block)
		addressHash = fnv1a(request.address)
		arguments[:onsubmit] = "calculateHash('#{addressHash}');"
		form(action, arguments) { block.call }
	end
	
	def securedField
		p class: 'security' do
			hidden(RandomString, WWWLib::::RandomString.get(RandomStringLength))
			hidden HashField
		end
	end
	
	def secureSubmit(description = 'Submit', arguments = {})
		securedField
		submit(description, arguments)
	end
end
