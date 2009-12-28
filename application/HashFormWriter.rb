require 'site/HTMLWriter'

class HashFormWriter < HTMLWriter
	Security = 'security'
	
	def hashForm(action, hashFields, arguments = {}, &block)
		hashArguments = hashFields.map { |field| "'#{field}'" }
		hashArguments = hashArguments.join(', ')
		arguments[:onsubmit] = "hashFields(#{hashArguments});"
		form(action, arguments) { block.call }
	end
	
	def hashField
		p class: 'security' do hidden(Security) end
	end
	
	def hashSubmit
		hashField
		submit
	end
end
