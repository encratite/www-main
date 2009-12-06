require 'configuration/table'

def getDataset(symbol)
	return $database[TableConfiguration.get_const symbol]
end
