require 'configuration/VimSyntax'
require 'SecuredFormWriter'
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
	
	def self.isValidScript(script)
		VimSyntax::Scripts.each do |file, description|
			return true if file == script
		end
		return fakse
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
	
	def self.highlight(script, input)
		outputFile = Tempfile.new('outputFile')
		outputFile.close
		
		inputFile = Tempfile.new('inputFile')
		inputFile << input
		inputFile.close
		
		flags = ['f', 'n', 'X', 'e', 's']
		
		cFlags =
		[
			"set filetype=#{script}\"",
			'syntax on',
			'let html_use_css=1',
			'run syntax/2html.vim',
			"wq! \"#{outputFile.path}\"",
			'q',
		]
		
		flags = flags.map { |flag| "-#{flag}" }
		flags = flags.join ' '
		
		cFlags = cFlags.map { |cFlag| "-c \"#{cFlag}\"" }
		cFlags = cFlags.join ' '
		
		`#{PastebinConfiguration::VimPath} #{flags} #{cFlags} #{inputFile}`
		
		output = outputFile.open.read
		
		return output
	end
	
	def self.getScriptDescription(script)
		AllScripts.each do |option|
			return option.description if option.value == script
		end
		raise 'Encountered an invalid script name in a unit.'
	end
	
	CommonScripts = self.generateList true
	AllScripts = self.generateList false
end
