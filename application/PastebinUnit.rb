require 'string'
require 'SyntaxHighlighting'

require 'www-library/SymbolTransfer'

class PastebinUnit < SymbolTransfer

	UnnamedUnit = 'Unnamed unit'

	attr_reader :id, :bodyDescription, :bodyPasteType, :noDescription, :pasteType
	
	#this field is only set by editUnitQueryInitialisation when a unit is being edited
	attr_reader :content
	
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
