require 'PathMap'
require 'PastebinForm'
require 'error'
require 'processForm'
require 'database'
require 'SyntaxHighlighting'
require 'PastebinPost'

require 'configuration/pastebin'

require 'visual/general'
require 'visual/pastebin'

require 'site/RequestManager'
require 'site/random'
require 'site/input'
require 'site/HTTPReply'
require 'site/input'

def pastebinError(content)
	raise RequestManager::Exception.new ['Pastebin error', content]
end

def newPastebinPost(request)
	$pastebinGenerator.get([PathMap.getDescription(:Pastebin), visualPastebinForm(request)], request)
end

def floodCheck(request)
	query = "select count(*) from flood_protection where ip = '#{request.address}' and paste_time + interval '#{PastebinConfiguration::PasteInterval} seconds' >= now()"
	count = $database.fetch(query).first.values.first
	return count > PastebinConfiguration::PastesPerInterval
end

def createAnonymousString(length)
	dataset = getDataset :PastebinPost
	while true
		string = RandomString.get length
		break if dataset.where(anonymous_string: sessionString).count == 0
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
			errors << 'You have triggered the pastebin flood protection by posting too frequently so your request could not be processed.'
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
			
		highlightingSelectionMode = nil
		lastSelection = nil
			
		if useSyntaxHighlighting
			highlightingSelectionMode = PastebinForm::HighlightingGroupIdentifiers.index highlightingGroup
			syntaxHighlighting = syntaxHighlightingFields[highlightingSelectionMode - 1]
			if SyntaxHighlighting::isValidScript syntaxHighlighting
				lastSelection = syntaxHighlighting
			else
				errors << 'The vim syntax highlighting script you have specified does not exist.'
			end
		end
		
		if !errors.empty?
			errorContent = visualPastebinForm(request, errors, postDescription, unitDescription, content, highlightingSelectionMode, lastSelection)
			pastebinError errorContent
		end

		isLoggedIn = request.sessionUser != nil
		
		postUser = isLoggedIn ? request.sessionUser.id : nil
		postAuthor = !isLoggedIn ? author : nil
		postExpiration = expiration == 0 ? nil : PastebinConfiguration::ExpirationOptions[expiration][1]
		anonymousString = privatePost == 1 ? createAnonymousString(PastebinConfiguration::AnonymousStringLength) : nil
		postReply = nil

		newPost =
		{
			user_id: postUser,
			
			author: postAuthor,
			ip: request.address,
			
			description: postDescription,
			
			expiration: postExpiration,
			
			anonymous_string: anonymousString,
			
			reply_to: postReply
		}

		dataset = getDataset :PastebinPost
		postId = dataset.insert newPost
		
		isPlain = highlightingGroup == PastebinForm::NoHighlighting
		highlightedContent = isPlain ? nil : SyntaxHighlighting::highlight(syntaxHighlighting, content)
		pasteType = isPlain ? nil : syntaxHighlighting
		
		newUnit =
		{
			post_id: postId,
			
			description: unitDescription,
			content: content,
			highlighted_content: highlightedContent,
			
			paste_type: pasteType
		}
		
		dataset = getDataset :PastebinUnit
		dataset.insert newUnit
		
		postPath = "#{PathMap::PastebinView}/#{postId}"
		return HTTPReply.localRefer(request, postPath)
	end
end

def getPostId(request)
	arguments = request.arguments
	argumentError if arguments.empty?
	postId = readId arguments[0]
	argumentError if postId == nil
	return postId
end

def viewPastebinPost(request)
	postId = getPostId request
	post = $database.transaction { PastebinPost.new postId }
	return visualShowPastebinPost(request, post)
end
