require 'site/FormWriter'

class HashFormWriter < FormWriter
	Security = 'security'
	
	def initialize(output, action, hashFields)
		arguments = hashFields.map { |field| "'#{field}'" }
		arguments = arguments.join(', ')
		onSubmit = "hashFields(#{arguments});"
		super(output, action, onSubmit)
	end
	
	def hashField
		field type: :input, inputType: :hidden, name: Security
	end
	
	def finish
		hashField
		super
	end
end
