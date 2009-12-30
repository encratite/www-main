require 'PathMap'
require 'PastebinForm'
require 'error'
require 'configuration/pastebin'
require 'visual/pastebin'

def newPastebinPost(request)
	$pastebinGenerator.get([PathMap.getDescription(:Pastebin), visualPastebinForm(request)], request)
end

def submitNewPastebinPost(request)
	return fieldError if !request.postIsSet(PastebinForm::PostFields)
	
	return "FUCK YEAH"
end
