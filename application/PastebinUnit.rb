require 'string'

require 'site/SymbolTransfer'

class PastebinUnit < SymbolTransfer

	NoDescription = 'No description'

	attr_reader :bodyDescription
	
	def initialize(input)
		transferSymbols(input, {}, [:highlightingStyle, :highlightedContent])
		
	end
end
