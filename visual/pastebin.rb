require 'PathMap'
require 'PastebinForm'
require 'SyntaxHighlighting'
require 'HashFormWriter'

require 'site/JavaScript'

require 'configuration/cookie'
require 'configuration/pastebin'

def visualPastebinNewPost
end

def privacyInfo
<<END
Public posts are listed on this site and can be accessed freely by all users by following links or guessing the URLs of posts using their numeric identifiers.
If you do not wish this post to be visible to strangers you might want to mark this post as "Private".
This will cause the post not to be listed on this site and users will only be able to access it through a long randomly generated string in its URL.
This way only the people you show it to will know how to access it.
END
end

def expirationInfo
<<END
By default, all posts on this site are stored permanently and will not be removed automatically.
If you do not wish your post to remain online indefinitely you may specify when it will expire.
Registered users may delete their posts at any time once they are logged in.
Unregistered users may delete their posts as long as their IP address matches the address they used at the time of the creation of the post.
END
end

def unitsInfo
<<END
Each post in this pastebin consists of one or multiple units.
Each one of these units can use a different syntax highlighting mode.
You can add further units to a post at a later time.
For example, you might make a post which features a README file in plain text format without any syntax highlighting and a unit containing C++ source code which uses C++ syntax highlighting.
You may enter a more precise description for the particular unit for this post.
This is particularly useful if you intend to add further units to this post but you may also just leave it empty.
END
end

def getFieldLength(symbol)
	return {maxlength: PastebinConfiguration.const_get(symbol)}
end

def visualPastebinForm(request, postDescription = nil, unitDescription = nil, content = nil, highlightingSelectionMode = 0, lastSelection = nil)
	highlightingGroups =
	[
		'Use no syntax highlighting (plain text)',
		"Common programming languages (#{SyntaxHighlighting::CommonScripts.size} available)",
		"All syntax highlighting types (#{SyntaxHighlighting::AllScripts.size} available)",
		'Expert mode (manually specify the name of a vim script)'
	]
	
	output = ''
	writer = HashFormWriter.new(output, request)
	
	writer.hashForm PathMap::PastebinSubmitNewPost, PastebinForm::PostFields do
	
		radioCounter = 0
		
		radioField = lambda do
			checked = radioCounter == highlightingSelectionMode
			arguments = {onclick: "highlightingMode(#{radioCounter});"}
			
			writer.radio(highlightingGroups[radioCounter], PastebinForm::HighlightingGroup, PastebinForm::HighlightingGroupIdentifiers[radioCounter], checked, arguments)
			
			radioCounter += 1
		end
		
		basicOptions = lastSelection ? SyntaxHighlighting.getSelectionList(true, lastSelection) : SyntaxHighlighting::CommonScripts
		advancedOptions = lastSelection ? SyntaxHighlighting.getSelectionList(false, lastSelection) : SyntaxHighlighting::AllScripts
		formFields =
		[
			lambda { writer.select(PastebinForm::CommonHighlighting, basicOptions) },
			lambda { writer.select(PastebinForm::AdvancedHighlighting, advancedOptions) },
			lambda do
				writer.ul class: 'formLabel', id: (PastebinForm::ExpertHighlighting + 'List') do
					writer.li { 'Specify the vim script you want to be used (e.g. "cpp"):' }
					writer.li { writer.input(type: 'text', name: PastebinForm::ExpertHighlighting) }
				end
			end
		]
		
		if request.sessionUser == nil
			authorName = request.cookies[CookieConfiguration::Author]
			writer.text('Author (optional)', PastebinForm::Author, authorName, getFieldLength(:VimScriptLengthMaximum))
		else
			writer.p { "You are currently logged in as <b>#{request.sessionUser.name}</b>." }
			writer.hidden(PastebinForm::Author, '')
		end
		
		columnCount = 2
		
		writer.text('Description of the post (optional)', PastebinForm::PostDescription, postDescription, getFieldLength(:PostDescriptionLengthMaximum))
		writer.p { 'Specify the syntax highlighting selection method you would like to use:' }
		writer.table id: 'syntaxTable' do
			leftSide = {class: 'leftSide'}
			rightSide = {class: 'rightSide'}
			writer.tr do
				writer.td(leftSide) { radioField.call }
				writer.td(rightSide) {}
			end

			formFields.each do |formField|
				writer.tr do
					writer.td(leftSide) { radioField.call }
					writer.td(rightSide) { formField.call }
				end
			end
		end
		
		usePrivate = request.cookies[CookieConfiguration::Private] == '1'
		
		privacyOptions =
		[
			SelectOption.new('Public post', '0', !usePrivate),
			SelectOption.new('Private post', '1', usePrivate)
		]
		
		writer.select(PastebinForm::PrivatePost,  privacyOptions, {label: 'Privacy options'})
		
		firstOffset = 0
		
		cookie = request.cookies[CookieConfiguration::Expiration]
		
		if cookie != nil
			begin
				expirationIndex = Integer cookie
			rescue ArgumentError
				expirationIndex = firstOffset
			end
		else
			expirationIndex = firstOffset
		end
		
		optionCount = PastebinConfiguration::ExpirationOptions.size
		expirationIndex = firstOffset if !(firstOffset..(optionCount - 1)).include?(expirationIndex)
		offset = 0
		
		expirationOptions = PastebinConfiguration::ExpirationOptions.map do |description, seconds|
			option = SelectOption.new(description, offset.to_s, offset == expirationIndex)
			offset += 1
			option
		end		
		
		writer.select(PastebinForm::Expiration, expirationOptions, {label: 'Post expiration'})
		
		writer.text('Description of this unit (optional)', PastebinForm::UnitDescription, unitDescription, getFieldLength(:UnitDescriptionLengthMaximum))
		writer.textArea('Paste the content here', PastebinForm::Content, content, {cols: '30', rows: '10'})
		
		writer.hashSubmit
	end
	
	output.concat writeJavaScript("showModeSelector();")
end
