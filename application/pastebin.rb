require 'PathMap'
require 'PastebinForm'
require 'error'
require 'configuration/pastebin'
require 'visual/pastebin'

def newPastebinPost(request)
	$pastebinGenerator.get([PathMap.getDescription(:Pastebin), visualPastebinForm], request)
end

def submitNewPastebinPost(request)
	requiredFields =
	[
		PastebinForm::PostDescription,
		PastebinForm::UnitDescription,
		
		PastebinForm::HighlightingGroup,
		
		PastebinForm::CommonHighlighting,
		PastebinForm::AdvancedHighlighting,
		PastebinForm::ExpertHighlighting,
		
		PastebinForm::Content,
	]
	
	return fieldError if !request.postIsSet(requiredFields)
end
