require 'PastebinForm'
require 'SecuredFormWriter'
require 'SiteContainer'

require 'configuration/loader'
requireConfiguration 'cookie'

class PastebinHandler < SiteContainer
	def pastebinForm(form)
		editing = form.editUnitId != nil
		output = ''
		writer = SecuredFormWriter.new(output, form.request)
		
		if form.errors != nil
			writer.p { 'Your form.request could not be processed because one or multiple form.errors have occured:' }
			writer.ul class: 'error' do
				form.errors.each { |error| writer.li { error } }
			end
			writer.p { 'Please try again.' }
		end
		
		if form.highlightingSelectionMode == nil
			form.highlightingSelectionMode = form.request.cookies[CookieConfiguration::PastebinMode]
			if form.highlightingSelectionMode == nil
				form.highlightingSelectionMode = 0
			else
				form.highlightingSelectionMode = form.highlightingSelectionMode.to_i
				form.highlightingSelectionMode = 0 if \
					form.highlightingSelectionMode < 0 || \
					form.highlightingSelectionMode >= HighlightingGroups.size
			end
		end
		
		form.lastSelection = form.request.cookies[CookieConfiguration::VimScript] if form.lastSelection == nil
		
		handler = editing ? @submitUnitModification : @submitNewPostHandler
		
		writer.securedForm(handler.getPath, form.request) do
		
			radioCounter = 0
			
			radioField = lambda do
				checked = radioCounter == form.highlightingSelectionMode
				arguments = {onclick: "highlightingMode(#{radioCounter});", id: "radio#{radioCounter}"}
				
				writer.radio(HighlightingGroups[radioCounter], PastebinForm::HighlightingGroup, PastebinForm::HighlightingGroupIdentifiers[radioCounter], checked, arguments)
				
				radioCounter += 1
			end
			
			basicOptions = form.lastSelection ? SyntaxHighlighting.getSelectionList(true, form.lastSelection) : SyntaxHighlighting::CommonScripts
			advancedOptions = form.lastSelection ? SyntaxHighlighting.getSelectionList(false, form.lastSelection) : SyntaxHighlighting::AllScripts
			formFields =
			[
				lambda { writer.select(PastebinForm::CommonHighlighting, basicOptions) },
				lambda { writer.select(PastebinForm::AdvancedHighlighting, advancedOptions) },
				lambda do
					writer.ul class: 'formLabel', id: (PastebinForm::ExpertHighlighting + 'List') do
						fieldArguments = {type: 'input', name: PastebinForm::ExpertHighlighting}
						fieldArguments[:value] = form.lastSelection if form.lastSelection != nil
						writer.li { 'Specify the vim script you want to be used (e.g. "cpp"):' }
						writer.li { writer.tag('input', fieldArguments) }
					end
				end
			]
			
			if form.request.sessionUser == nil
				if form.author == nil
					form.author = form.request.cookies[CookieConfiguration::Author]
				end
				writer.text('Author (optional)', PastebinForm::Author, form.author, pasteFieldLength(:VimScriptLengthMaximum))
			else
				writer.p { "You are currently logged in as <b>#{form.request.sessionUser.htmlName}</b>." }
				writer.hidden(PastebinForm::Author, '')
			end
			
			columnCount = 2
			
			writer.text('Description of the post (optional)', PastebinForm::PostDescription, form.postDescription, pasteFieldLength(:PostDescriptionLengthMaximum))
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
			
			if form.isPrivatePost == nil
				form.isPrivatePost = form.request.cookies[CookieConfiguration::Private] == '1'
			end
			
			privacyOptions =
			[
				WWWLib::SelectOption.new('Public post', '0', !form.isPrivatePost),
				WWWLib::SelectOption.new('Private post', '1', form.isPrivatePost),
			]
			
			writer.select(PastebinForm::PrivatePost,  privacyOptions, {label: 'Privacy options'})
			
			firstOffset = 0
			
			if form.expirationIndex == nil
				cookie = form.request.cookies[CookieConfiguration::Expiration]
				
				if cookie != nil
					begin
						form.expirationIndex = Integer cookie
					rescue ArgumentError
						form.expirationIndex = firstOffset
					end
				else
					form.expirationIndex = firstOffset
				end
			end
			
			optionCount = PastebinConfiguration::ExpirationOptions.size
			form.expirationIndex = firstOffset if !(firstOffset..(optionCount - 1)).include?(form.expirationIndex)
			offset = 0
			
			expirationOptions = PastebinConfiguration::ExpirationOptions.map do |description, seconds|
				option = WWWLib::SelectOption.new(description, offset.to_s, offset == form.expirationIndex)
				offset += 1
				option
			end		
			
			writer.select(PastebinForm::Expiration, expirationOptions, {label: 'Post expiration'})
			
			writer.text('Description of this unit (optional)', PastebinForm::UnitDescription, form.unitDescription, pasteFieldLength(:UnitDescriptionLengthMaximum))
			writer.textArea('Paste the content here', PastebinForm::Content, form.content, {cols: '30', rows: '10', maxlength: PastebinConfiguration::UnitSizeLimit})
			
			writer.textArea('Debug', PastebinForm::Debug) if PastebinForm::DebugMode
			
			if editing
				writer.hidden(PastebinForm::EditUnitId, form.editUnitId)
				writer.secureSubmit('Edit')
			else
				writer.secureSubmit
			end
		end
		
		output.concat WWWLib.writeJavaScript(<<END
showModeSelector();
var content = document.getElementById('content');
content.onkeydown = tabHandler;
content.onkeypress = tabPressHandler;
END
		)
		
		return output
	end
end