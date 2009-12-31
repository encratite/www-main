require 'site/HTMLWriter'

class HashFormWriter < HTMLWriter
	Security = 'security'
	
	def hashForm(action, type, namesSymbol, arguments = {}, &block)
		nameSymbols = type.const_get namesSymbol
		hashFields = nameSymbols.map { |symbol| type.const_get symbol }
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
