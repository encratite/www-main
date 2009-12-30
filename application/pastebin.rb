require 'PathMap'
require 'PastebinForm'
require 'error'
require 'configuration/pastebin'
require 'visual/pastebin'

def newPastebinPost(request)
	$pastebinGenerator.get([PathMap.getDescription(:Pastebin), visualPastebinForm(request)], request)
end

def submitNewPastebinPost(request)
	FormCheck::Process.call(request, PastebinForm::PostFields)
end
