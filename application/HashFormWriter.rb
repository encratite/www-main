require 'site/HTMLWriter'

class HashFormWriter < HTMLWriter
	Security = 'security'
	
	def hashForm(action, hashFields, arguments = {}, &block)
		hashArguments = hashFields.map { |field| "'#{field}'" }
		hashArguments = arguments.join(', ')
		arguments[:onsubmit] = "hashFields(#{hashArguments});"
		form(action, arguments, block)
	end
	
	def hashField
		p class: 'security' { hidden(Security) }
	end
	
	def hashSubmit
		hashField
		submit
	end
end
