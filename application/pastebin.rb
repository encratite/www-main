require 'PathMap'
require 'PastebinForm'
require 'error'
require 'processForm'
require 'configuration/pastebin'
require 'visual/general'
require 'visual/pastebin'
require 'site/RequestManager'

def pastebinError(message)
	raise RequestManager::Exception(['Pastebin error', visualError(message)])
end

def newPastebinPost(request)
	$pastebinGenerator.get([PathMap.getDescription(:Pastebin), visualPastebinForm(request)], request)
end

def floodCheck(request)
	query = "select count(*) from flood_protection where ip = '#{request.address}' and paste_time + interval '#{PastebinConfiguration::PasteInterval} seconds' >= now()"
	count = $database.fetch(query).first.values.first
	if count >= PastebinConfiguration::PastesPerInterval
		pastebinError 'You have triggered the pastebin flood protection by posting too frequently so your request could not be processed. Please try again in a few minutes.'
	end
end

def submitNewPastebinPost(request)
	author,
		
	postDescription,
	
	highlightingGroup,
	
	commonHighlighting,
	advancedHighlighting,
	expertHighlighting,
	
	privatePost,
	expiration,
	
	unitDescription,
	
	content = processFormFields(request, PastebinForm::PostFields)
	
	$database.transaction do
		floodCheck request
	end
end
