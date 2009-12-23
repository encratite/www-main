require 'site/FormWriter'
require 'site/HTMLWriter'

class HashFormWriter < FormWriter
	Security = 'security'
	
	def initialize(output, action, hashFields)
		arguments = hashFields.map { |field| "'#{field}'" }
		arguments = arguments.join(', ')
		onSubmit = "hashFields(#{arguments});"
		super(output, action, onSubmit)
	end
	
	def hashField
		writer = HTMLWriter.new @output
		writer.p class: 'security' do
			field type: :input, inputType: :hidden, name: Security, paragraph: false
		end
	end
	
	def finish
		hashField
		super
	end
end
