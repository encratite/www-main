require 'configuration/VimSyntax'

class SyntaxHighlighting
	def self.generateList(isCommon)
		output = []
		VimSyntax::Scripts.each do |script|
			if isCommon
				output << script[0..1] if script.size >= 3 && script[2]
			else
				output << script[0..1]
			end
		end
		output
	end
	
	CommonScripts = self.generateList true
	AllScripts = self.generateList false
end
