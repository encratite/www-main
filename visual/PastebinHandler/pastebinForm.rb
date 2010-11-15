require 'PastebinForm'
require 'SecuredFormWriter'
require 'SiteContainer'

require 'configuration/loader'
requireConfiguration 'cookie'

class PastebinHandler < SiteContainer
	def getPrivacyOptions(form)
		isPrivate = form.isPrivate
		privacyOptions =
		[
			WWWLib::SelectOption.new('Public post', '0', !isPrivate),
			WWWLib::SelectOption.new('Private post', '1', isPrivate),
		]
	end
	
	def writePrivateField(writer, post)
		writer.hidden(PastebinForm::PrivateString, post.privateString)
	end
	
	def conditionalPrivateField(writer, post)
		if post.isPrivate
			writePrivateField(writer, post)
		end
	end
	
	def createSubmissionSection(mode, writer, form)
		case mode
		when :new
			writer.secureSubmit
		when :edit
			writer.hidden(PastebinForm::EditUnitId, form.editPost.activeUnit.id)
			conditionalPrivateField(writer, form.editPost)
			writer.secureSubmit('Edit')
		when :reply
			if form.replyPost.isPrivate
				writePrivateField(writer, form.replyPost)
			else
				writer.hidden(PastebinForm::ReplyPostId, form.replyPost.id)
			end
			writer.secureSubmit('Reply')
		when :addUnit
			writer.hidden(PastebinForm::AddUnitPostId, form.editPost.id)
			conditionalPrivateField(writer, form.editPost)
			writer.secureSubmit('Add unit')
		end
	end
	
	def processHighlightingSelectionMode(form)
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
	end
	
	def getHandler(mode)
		handlerMap =
		{
			new: @submitNewPostHandler,
			edit: @submitUnitModificationHandler,
			reply: @submitReplyHandler,
			addUnit: @submitUnitHandler,
		}
		
		handler = handlerMap[mode]
		if handler == nil
			raise "Encountered an unknown form mode: #{mode}"
		end
		return handler
	end
	
	def writeTabScript(writer)
		writer.write WWWLib.writeJavaScript(<<END
showModeSelector();
var content = document.getElementById('content');
content.onkeydown = tabHandler;
content.onkeypress = tabPressHandler;
END
		)
	end
	
	def writeErrorSection(form, writer)
		if form.errors != nil
			writer.p { 'Your form.request could not be processed because one or multiple form.errors have occured:' }
			writer.ul class: 'error' do
				form.errors.each { |error| writer.li { error } }
			end
			writer.p { 'Please try again.' }
		end
	end
	
	def getFormFields(form, writer)
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
					writer.li(newlineType: :full) { writer.tag('input', fieldArguments) }
				end
			end
		]
	end
	
	def processAuthorField(form, writer)
		if form.request.sessionUser == nil
			if form.author == nil
				form.author = form.request.cookies[CookieConfiguration::Author]
			end
			writer.text('Author (optional)', PastebinForm::Author, form.author, pasteFieldLength(:VimScriptLengthMaximum))
		else
			writer.p do
				writer.write 'You are currently logged in as '
				writer.b { form.request.sessionUser.htmlName }
				writer.write '.'
			end
			writer.hidden(PastebinForm::Author, '')
		end
	end
	
	def postDescription(form, writer)
		writer.text('Description of the post (optional)', PastebinForm::PostDescription, form.postDescription, pasteFieldLength(:PostDescriptionLengthMaximum))
	end
	
	def writeHighlightingSelectionMethod(form, writer)
		formFields = formFields = getFormFields(form, writer)
		
		radioCounter = 0
			
		radioField = lambda do
			checked = radioCounter == form.highlightingSelectionMode
			arguments = {onclick: "highlightingMode(#{radioCounter});", id: "radio#{radioCounter}"}
			
			writer.radio(HighlightingGroups[radioCounter], PastebinForm::HighlightingGroup, PastebinForm::HighlightingGroupIdentifiers[radioCounter], checked, arguments)
			
			radioCounter += 1
			nil
		end
		
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
	end
	
	def writeRootPostFields(form, writer)
		writer.select(PastebinForm::PrivatePost,  getPrivacyOptions(form), {label: 'Privacy options'})

		firstOffset = 0
		
		if form.expirationIndex == nil
			cookie = form.request.cookies[CookieConfiguration::Expiration]
			
			if cookie != nil
				begin
					form.expirationIndex = Integer(cookie)
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
	end
	
	def writeUnitFields(form, writer)
		writer.text('Description of this unit (optional)', PastebinForm::UnitDescription, form.unitDescription, pasteFieldLength(:UnitDescriptionLengthMaximum))
		writer.textArea('Paste the content here', PastebinForm::Content, form.content, {cols: '30', rows: '10', maxlength: PastebinConfiguration::UnitSizeLimit})
	end
	
	def processFormPrivateField(form)
		if form.isPrivate == nil
			form.isPrivate = form.request.cookies[CookieConfiguration::Private].to_i == 1
		end
	end
	
	def pastebinForm(form)
		mode = form.mode
		
		new = mode == :new
		editing = mode == :edit
		replying = mode == :reply
		addingUnit = mode == :addUnit
		modifyingPost = editing || addingUnit
		
		output = ''
		writer = SecuredFormWriter.new(output, form.request)
		
		writeErrorSection(form, writer)
		processHighlightingSelectionMode(form)
		handler = getHandler(mode)
		
		writer.securedForm(handler.getPath, form.request) do
			processAuthorField(form, writer)
			postDescription(form, writer)
			writeHighlightingSelectionMethod(form, writer)
			processFormPrivateField(form)
			#The expiration and the privacy settings are only visible in the following modes:
			#1. Making a new post
			#2. When editing a non-reply post
			#3. When adding a unit to a non-reply post
			modifyingRootPost = modifyingPost && form.editPost.replyTo == nil
			writeRootPostFields(form, writer) if new || modifyingRootPost
			writeUnitFields(form, writer)
			createSubmissionSection(mode, writer, form)
		end
		
		writeTabScript(writer)
		
		return writer.output
	end
end
