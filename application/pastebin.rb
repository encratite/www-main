require 'PathMap'
require 'PastebinForm'
require 'error'
require 'processForm'
require 'SyntaxHighlighting'

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
	return count > PastebinConfiguration::PastesPerInterval
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
	
	stringLengthChecks =
	[
		[author, 'name', PastebinConfiguration::AuthorLengthMaximum],
		[postDescription, 'post description', PastebinConfiguration::PostDescriptionLengthMaximum],
		[unitDescription, 'unit description', PastebinConfiguration::UnitDescriptionLengthMaximum],
		[content, 'content', PastebinConfiguration::UnitSizeLimit],
		[expertHighlighting, 'vim script name', PastebinConfiguration::VimScriptLengthMaximum],
	]
	
	errors = []
	
	privatePost = privatePost.to_i
	expiration = expiration.to_i
	
	validValues =
	[
		[highlightingGroup, 'highlighting group', PastebinForm::HighlightingGroupIdentifiers],
		[privatePost, 'privacy option', [0, 1]],
		[expiration, 'expiration option', (0..(PastebinConfiguration::ExpirationOptions.size - 1))],
	]
	
	syntaxHighlightingFields =
	[
		commonHighlighting,
		advancedHighlighting,
		expertHighlighting,
	]
	
	$database.transaction do
		isSpammer = floodCheck request
		if isSpammer
			errors << 'You have triggered the pastebin flood protection by posting too frequently so your request could not be processed. Please try again in a few minutes.'
		end
		
		stringLengthChecks.each do |field, name, limit|
			next if field.size <= limit
			errors << "The #{name} you have specified is too long - the limit is #{limit}."
		end
		
		validValues.each do |field, name, values|
			next if values.include?(field)
			errors << "The #{name} you have specified is invalid."
		end
		
		useSyntaxHighlighting =
			PastebinForm::HighlightingGroupIdentifiers.include?(highlightingGroup) &&
			highlightingGroup != PastebinForm::NoHighlighting
			
		if useSyntaxHighlighting
			offset = PastebinForm::HighlightingGroupIdentifiers.index highlightingGroup
			syntaxHighlighting = syntaxHighlightingFields[offset]
			if !SyntaxHighlighting::isValidScript syntaxHighlighting
				errors << 'The vim syntax highlighting script you have specified does not exist.'
			end
		end
	end
end
