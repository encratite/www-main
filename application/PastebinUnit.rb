require 'string'
require 'SyntaxHighlighting'

require 'site/SymbolTransfer'

class PastebinUnit < SymbolTransfer

	UnnamedUnit = 'Unnamed unit'

	attr_reader :bodyDescription, :bodyPasteType, :noDescription
	
	def initialize(input)
		transferSymbols(input, {}, [:highlightingStyle, :highlightedContent])
		@bodyPasteType =
			@pasteType == nil ?
				'Plain text' :
				SyntaxHighlighting::getScriptDescription(@pasteType)
		@noDescription = @description.empty?
		@bodyDescription = ''
		processDescription(@noDescription, @description, @bodyDescription, @bodyPasteType)
	end
end
