require 'string'
require 'SyntaxHighlighting'

require 'www-library/SymbolTransfer'

class PastebinUnit < WWWLib::SymbolTransfer

	UnnamedUnit = 'Unnamed unit'

	attr_reader :bodyDescription, :bodyPasteType, :noDescription, :pasteType, :modificationCounter
	
	#this field is only set by editUnitQueryInitialisation when a unit is being edited
	attr_reader :content
	
	def initialize(input, fullUnitInitialisation = true)
		transferSymbols(input, {}, [:highlightingStyle, :highlightedContent])
		if fullUnitInitialisation
			@bodyPasteType =
				@pasteType == nil ?
					'Plain text' :
					SyntaxHighlighting::getScriptDescription(@pasteType)
			@noDescription = @description.empty?
			@bodyDescription = ''
			processDescription(@noDescription, @description, @bodyDescription, UnnamedUnit)
		end
	end
end
