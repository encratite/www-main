require 'string'
require 'SyntaxHighlighting'

require 'site/SymbolTransfer'

class PastebinUnit < SymbolTransfer

	UnnamedUnit = 'Unnamed unit'

	attr_reader :bodyDescription, :bodyPasteType
	
	def initialize(input)
		transferSymbols(input, {}, [:highlightingStyle, :highlightedContent])
		@bodyPasteType =
			@pasteType == nil ?
				'Plain text' :
				SyntaxHighlighting::getScriptDescription(@pasteType)
		@noDescription = @description.empty?
		processDescription(@noDescription, @description, @bodyDescription, @bodyPasteType)
	end
end
