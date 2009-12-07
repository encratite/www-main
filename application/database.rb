require 'configuration/table'

def getTableSymbol(symbol)
end

def getDataset(symbol)
	$database[getTableSymbol symbol]
end
