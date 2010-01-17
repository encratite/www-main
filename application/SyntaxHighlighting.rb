require 'SecuredFormWriter'
require 'error'

require 'configuration/VimSyntax'

require 'site/HTML'
require 'site/string'

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
		
		input = input.delete("\r")
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
		
		`#{PastebinConfiguration::VimPath} #{flags} #{cFlags} #{inputFile.path}`
		
		markup = outputFile.open.read
		
		#debug = File.new("G:\\test", "w+")
		#debug.write(markup)
		#debug.close
		
		css = extractString(markup, "<style type=\"text/css\">\n<!--\n", "-->\n</style>")
		#puts "Input:\n#{css}"
		plainError 'Unable to extract stylesheets from vim output.' if css == nil
		cssLines = css.split("\n")
		cssLines.reject! do |line|
			tokens = line.split(' ')
			output = nil
			if tokens.empty?
				output = true
			else
				token = tokens[0]
				output = token.empty? || token[0] != '.'
			end
			output
		end
		cssLines = cssLines.map { |line| 'span' + line }
		#puts "Output:\n#{cssLines}"
		css = cssLines.join("\n")
		#puts css.class
		#puts "Output:\n#{css}"
		
		code = extractString(markup, "<pre>\n", "</pre>")
		plainError 'Unable to extract code from vim output.' if code == nil
		
		return [css, code]
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
