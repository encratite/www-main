require 'configuration/VimSyntax'
require 'site/FormWriter'
require 'site/HTML'

class SyntaxHighlighting
	def self.generateList(isCommon)
		output = []
		VimSyntax::Scripts.each do |script|
			value = script[0]
			description = HTMLEntities.encode script[1]
			if !isCommon || (script.size >= 3 && script[2])
				output << SelectOption.new(description, value)
			end
		end
		output
	end
	
	def self.getSelectionList(isCommon, selection)
		source = isCommon ? CommonScripts : AllScripts
		source.map do |option|
			return option if option.type != selection
			output = option.clone
			output.selected = true
			output
		end
	end
	
	CommonScripts = self.generateList true
	AllScripts = self.generateList false
end
