require 'www-library/HTMLWriter'
require 'visual/highlight'

def processDescription(condition, variable, body, default)
	if condition
		variable.replace default
		body.replace(makeCursive variable)
	else
		body.replace variable
	end
	return nil
end
