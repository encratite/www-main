require 'PathMap'
require 'PastebinForm'
require 'SyntaxHighlighting'
require 'HashFormWriter'

require 'site/HTMLWriter'
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
	form = HashFormWriter.new(output, PathMap::PastebinSubmitPost, hashFields )
	
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
	
	writer = HTMLWriter.new output
	
	if request.sessionUser == nil
		authorName = request.cookies[CookieConfiguration::Author]
		form.field(label: 'Author', name: PastebinForm::Author, author: authorName)
	else
		writer.p { "You are currently logged in as <b>#{request.sessionUser.name}</b>." }
		form.hidden(name: PastebinForm::Author, value: '')
	end
	
	columnCount = 2
	
	form.field(label: 'Description of the post', name: PastebinForm::PostDescription, value: postDescription)
	writer.p { writer.write 'Specify the syntax highlighting selection method you would like to use:' }
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
		
		writer.tr do
			writer.td colspan: columnCount do
				info =
<<END
Public posts are listed on this site and can be accessed freely by all users by following links or guessing the URLs of posts using their numeric identifiers.
If you do not wish this post to be visible to strangers you might want to mark this post as "Private".
This will cause the post not to be listed on this site and users will only be able to access it through a long randomly generated string in its URL.
This way only the people you show it to will know how to access it.
END
			end
		end
		
		usePrivate = request.cookies[CookieConfiguration::Private] == '1'
		
		writer.tr do
			writer.td { writer.radio label: 'Public', name: PastebinForm::PrivatePost, value: '0', checked: !usePrivate }
			writer.td { writer.radio label: 'Private', name: PastebinForm::PrivatePost, checked: '1', usePrivate }
		end
		
		writer.tr do
			writer.td colspan: columnCount do
				info =
<<END
By default, all posts on this site are stored permanently and will not be removed automatically.
If you do not wish your post to remain online indefinitely you may specify when it will expire.
Registered users may delete their posts at any time once they are logged in.
Unregistered users may delete their posts as long as their IP address matches the address they used at the time of the creation of the post.
END
				writer.write info
			end
		end
	
		writer.tr id: 'contentRow' do
			writer.td colspan: columnCount do
				writer.p do
					info =
<<END
Each post in this pastebin consists of one or multiple units.
Each one of these units can use a different syntax highlighting mode.
You can add further units to a post at a later time.
For example, you might make a post which features a README file in plain text format without any syntax highlighting and a unit containing C++ source code which uses C++ syntax highlighting.
You may enter a more precise description for the particular unit for this post.
This is particularly useful if you intend to add further units to this post but you may also just leave it empty.
END
					writer.write info
				end
				form.field(label: 'Description of this unit', name: PastebinForm::UnitDescription, value: unitDescription)
				form.textarea(label: 'Paste the content here', name: PastebinForm::Content)
			end
		end
	end
	form.finish
	output.concat writeJavaScript("showModeSelector();")
end
