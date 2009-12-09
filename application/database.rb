require 'configuration/table'

def getTableSymbol(symbol)
	TableConfiguration.const_get symbol
end

def getDataset(symbol)
	$database[getTableSymbol symbol]
end
