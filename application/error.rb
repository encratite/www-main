require 'site/MIMEType'
require 'site/general'

def plainError(message)
	[MIMEType::Plain, message]
end

def fieldError
	plainError 'Not all required fields have been specified.'
end

def javaScriptError
	['JavaScript error', visualError 'You need to turn on JavaScript in order to use this feature.']
end

def hashError
	['Hash error', visualError 'Invalid hash.']
end
