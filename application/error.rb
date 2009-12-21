require 'site/MIMEType'

def plainError(message)
	[MIMEType::Plain, message]
end

def fieldError
	plainError 'Not all required fields have been specified.'
end
