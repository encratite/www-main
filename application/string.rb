def markString(input)
	writer = HTMLWriter.new
	writer.i { input }
	return writer.output
end

def processDescription(condition, variable, body, default)
	if condition
		variable.replace default
		body.replace(markString variable)
	else
		body.replace variable
	end
	return nil
end
