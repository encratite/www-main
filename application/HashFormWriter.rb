require 'site/FormWriter'
require 'site/HTMLWriter'

class HashFormWriter < FormWriter
	Security = 'security'
	
	def initialize(output, action, hashFields, arguments = {}, &block)
		hashFields = arguments[:hashFields]
		raise 'No hash fields have been specified' if hashFields == nil
		hashArguments = hashFields.map { |field| "'#{field}'" }
		hashArguments = arguments.join(', ')
		arguments[:onsubmit] = "hashFields(#{hashArguments});"
		super(output, action, arguments, block)
	end
	
	def hashField
		writer = HTMLWriter.new @output
		writer.p class: 'security' do
			field type: :input, inputType: :hidden, name: Security, paragraph: false
		end
	end
	
	def submit
		hashField
		super
	end
end
