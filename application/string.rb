def markString(input)
	writer = HTMLWriter.new
	writer.i { input }
	return writer.output
end

def processDescription(input, default)
end
