require 'hash'

require 'site/HTMLWriter'
require 'site/random'

class SecuredFormWriter < HTMLWriter
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
			hidden(RandomString, ::RandomString.get(RandomStringLength))
			hidden HashField
		end
	end
	
	def secureSubmit
		securedField
		submit
	end
end