require 'PathMap'
require 'PastebinForm'
require 'SyntaxHighlighting'
require 'HashFormform'

require 'site/HTMLform'
require 'site/JavaScript'

require 'configuration/cookie'

def visualPastebinNewPost
end

def visualPastebinForm(request, postDescription = nil, unitDescription = nil, highlightingSelectionMode = 0, lastSelection = nil)
	highlightingGroups =
	[
		'Use no syntax highlighting (plain text)',
		"Common programming languages (#{SyntaxHighlighting::CommonScripts.size} available)",
		"All syntax highlighting types (#{SyntaxHighlighting::AllScripts.size} available)",
		'Expert mode (manually specify the name of a vim script)'
	]
	
	hashFields =
	[
		PastebinForm::PostDescription,
		
		PastebinForm::HighlightingGroup,
		
		PastebinForm::CommonHighlighting,
		PastebinForm::AdvancedHighlighting,
		PastebinForm::ExpertHighlighting,
		
		PastebinForm::UnitDescription,
		
		PastebinForm::Content,
	]
	
	output = ''
	form = HashFormform.new(output, PathMap::PastebinSubmitPost, hashFields) do
	
		radioCounter = 0
		
		radioField = lambda do
			arguments =
			{
				type: :radio,
				label: highlightingGroups[radioCounter],
				name: PastebinForm::HighlightingGroup,
				onClick: "highlightingMode(#{radioCounter});",
				value: PastebinForm::HighlightingGroupIdentifiers[radioCounter],
				paragraph: false
			}
			
			arguments[:checked] = true if radioCounter == highlightingSelectionMode
			form.field arguments
			radioCounter += 1
		end
		
		basicOptions = lastSelection ? SyntaxHighlighting.getSelectionList(true, lastSelection) : SyntaxHighlighting::CommonScripts
		advancedOptions = lastSelection ? SyntaxHighlighting.getSelectionList(false, lastSelection) : SyntaxHighlighting::AllScripts
		formFields =
		[
			lambda { form.select(name: PastebinForm::CommonHighlighting, options: basicOptions, paragraph: false) },
			lambda { form.select(name: PastebinForm::AdvancedHighlighting, options: advancedOptions, paragraph: false) },
			lambda { form.text(label: 'Specify the vim script you want to be used (e.g. "cpp")', name: PastebinForm::ExpertHighlighting, ulId: PastebinForm::ExpertHighlighting, id: PastebinForm::ExpertHighlighting + 'Id', paragraph: false) }
		]
		
		if request.sessionUser == nil
			authorName = request.cookies[CookieConfiguration::Author]
			form.field(label: 'Author', name: PastebinForm::Author, author: authorName)
		else
			form.p { "You are currently logged in as <b>#{request.sessionUser.name}</b>." }
			form.hidden(name: PastebinForm::Author, value: '')
		end
		
		columnCount = 2
		
		form.field(label: 'Description of the post', name: PastebinForm::PostDescription, value: postDescription)
		form.p { form.write 'Specify the syntax highlighting selection method you would like to use:' }
		form.table id: 'syntaxTable' do
			leftSide = {class: 'leftSide'}
			rightSide = {class: 'rightSide'}
			form.tr do
				form.td(leftSide) { radioField.call }
				form.td(rightSide) {}
			end

			formFields.each do |formField|
				form.tr do
					form.td(leftSide) { radioField.call }
					form.td(rightSide) { formField.call }
				end
			end
		end
			
		form.p do
			info =
<<END
Public posts are listed on this site and can be accessed freely by all users by following links or guessing the URLs of posts using their numeric identifiers.
If you do not wish this post to be visible to strangers you might want to mark this post as "Private".
This will cause the post not to be listed on this site and users will only be able to access it through a long randomly generated string in its URL.
This way only the people you show it to will know how to access it.
END
		end
		
		usePrivate = request.cookies[CookieConfiguration::Private] == '1'
		
		privacyOptions =
		[
			SelectOption.new('Public', '0', !usePrivate),
			SelectOption.new('Private', '1', usePrivate)
		]
		
		form.select name: PastebinForm::PrivatePost,  privacyOptions
		
		form.tr do
			form.td colspan: columnCount do
				info =
<<END
By default, all posts on this site are stored permanently and will not be removed automatically.
If you do not wish your post to remain online indefinitely you may specify when it will expire.
Registered users may delete their posts at any time once they are logged in.
Unregistered users may delete their posts as long as their IP address matches the address they used at the time of the creation of the post.
END
				form.write info
			end
		end
		
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
		optionsPerLine = 4
		rowCount = optionCount / optionsPerLine
		offset = 0
		
		rowCount.times do
			form.tr do
				optionsPerLine.times do
					description, seconds = PastebinConfiguration::ExpirationOptions[offset]
					form.td { form.radio(label: description, name: PastebinForm::Expiration, value: seconds.to_s, checked: offset == expirationIndex) }
					offset += 1
				end
			end
		end

		form.tr id: 'contentRow' do
			form.td colspan: columnCount do
				form.p do
					info =
<<END
Each post in this pastebin consists of one or multiple units.
Each one of these units can use a different syntax highlighting mode.
You can add further units to a post at a later time.
For example, you might make a post which features a README file in plain text format without any syntax highlighting and a unit containing C++ source code which uses C++ syntax highlighting.
You may enter a more precise description for the particular unit for this post.
This is particularly useful if you intend to add further units to this post but you may also just leave it empty.
END
					form.write info
				end
				form.field(label: 'Description of this unit', name: PastebinForm::UnitDescription, value: unitDescription)
				form.textarea(label: 'Paste the content here', name: PastebinForm::Content)
			end
		end
		
	end
	
	output.concat writeJavaScript("showModeSelector();")
end
