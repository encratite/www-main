require 'HashFormWriter'

class HashFormWriter < HashFormWriter
	Security = 'security'
	
	def hashField
		field type: :input, inputType: :hidden, name: Security
	end
	
	def finish
		hashField
		super
	end
end
