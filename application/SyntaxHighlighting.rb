require 'SecuredFormWriter'
require 'error'

require 'configuration/loader'
requireConfiguration 'VimSyntax'

require 'www-library/HTML'
require 'www-library/string'

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
		return source if selection == nil
		output = []
		source.each do |option|
			if option.value != selection
				output << option
				next
			end
			newOption = option.clone
			newOption.selected = true
			output << newOption
		end
		return output
	end
	
	def self.highlight(script, input)
		outputFile = Tempfile.new('outputFile')
		outputFile.close
		
		input = input.delete("\r")
		inputFile = Tempfile.new('inputFile')
		inputFile << input
		inputFile.close
		
		flags = ['f', 'n', 'X', 'e', 's']
		
		vimCommands =
		[
			"set filetype=#{script}\"",
			'set background=light',
			#'colorscheme navajo',
			'set wrap linebreak textwidth=0',
			'syntax on',
			'let html_use_css=1',
			'run syntax/2html.vim',
			"wq! \"#{outputFile.path}\"",
			'q',
		]
		
		flags = flags.map { |flag| "-#{flag}" }
		flags = flags.join ' '
		
		vimCommands = vimCommands.map { |cFlag| "-c \"#{cFlag}\"" }
		vimCommands = vimCommands.join ' '
		
		#output = system "#{PastebinConfiguration::VimPath} #{flags} #{vimCommands} #{inputFile.path}"
		#plainError 'A vim error occured' if !output
		`#{PastebinConfiguration::VimPath} #{flags} #{vimCommands} #{inputFile.path}`
		
		markup = outputFile.open.read
		
		code = extractString(markup, "<pre>\n", "</pre>")
		plainError 'Unable to extract code from vim output.' if code == nil
		
		return code
	end
	
	def self.getScriptDescription(script)
		return 'Plain text' if script == nil
		AllScripts.each do |option|
			return option.description if option.value == script
		end
		raise 'Encountered an invalid script name in a unit.'
	end
	
	CommonScripts = self.generateList true
	AllScripts = self.generateList false
end
