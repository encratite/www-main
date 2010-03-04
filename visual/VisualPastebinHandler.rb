require 'PathMap'
require 'PastebinForm'
require 'SyntaxHighlighting'
require 'SecuredFormWriter'
require 'PastebinHandler'

require 'site/JavaScript'

require 'configuration/cookie'
require 'configuration/pastebin'

class VisualPastebinHandler
	def initialize(pastebinHandler, pastebinGenerator)
		@pastebinHandler = pastebinHandler
		@pastebinGenerator = pastebinGenerator
	end
	
	def pasteFieldLength(symbol)
		return {maxlength: PastebinConfiguration.const_get(symbol)}
	end

	def pastebinForm(request, errors = nil, postDescription = nil, unitDescription = nil, content = nil, highlightingSelectionMode = nil, lastSelection = nil)
		highlightingGroups =
		[
			'Use no syntax highlighting (plain text)',
			"Common programming languages (#{SyntaxHighlighting::CommonScripts.size} available)",
			"All syntax highlighting types (#{SyntaxHighlighting::AllScripts.size} available)",
			'Expert mode (manually specify the name of a vim script)'
		]
		
		output = ''
		writer = SecuredFormWriter.new(output, request)
		
		if errors != nil
			writer.p { 'Your request could not be processed because one or multiple errors have occured:' }
			writer.ul class: 'error' do
				errors.each { |error| writer.li { error } }
			end
			writer.p { 'Please try again.' }
		end
		
		if highlightingSelectionMode == nil
			highlightingSelectionMode = request.cookies[CookieConfiguration::PastebinMode]
			if highlightingSelectionMode == nil
				highlightingSelectionMode = 0
			else
				highlightingSelectionMode = highlightingSelectionMode.to_i
				highlightingSelectionMode = 0 if \
					highlightingSelectionMode < 0 || \
					highlightingSelectionMode >= highlightingGroups.size
			end
		end
		
		lastSelection = request.cookies[CookieConfiguration::VimScript] if lastSelection == nil
		
		writer.securedForm(PathMap::PastebinSubmitNewPost, request) do
		
			radioCounter = 0
			
			radioField = lambda do
				checked = radioCounter == highlightingSelectionMode
				arguments = {onclick: "highlightingMode(#{radioCounter});", id: "radio#{radioCounter}"}
				
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
						fieldArguments = {type: 'input', name: PastebinForm::ExpertHighlighting}
						fieldArguments[:value] = lastSelection if lastSelection != nil
						writer.li { 'Specify the vim script you want to be used (e.g. "cpp"):' }
						writer.li { writer.tag('input', fieldArguments) }
					end
				end
			]
			
			if request.sessionUser == nil
				authorName = request.cookies[CookieConfiguration::Author]
				writer.text('Author (optional)', PastebinForm::Author, authorName, pasteFieldLength(:VimScriptLengthMaximum))
			else
				writer.p { "You are currently logged in as <b>#{request.sessionUser.htmlName}</b>." }
				writer.hidden(PastebinForm::Author, '')
			end
			
			columnCount = 2
			
			writer.text('Description of the post (optional)', PastebinForm::PostDescription, postDescription, pasteFieldLength(:PostDescriptionLengthMaximum))
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
			
			writer.text('Description of this unit (optional)', PastebinForm::UnitDescription, unitDescription, pasteFieldLength(:UnitDescriptionLengthMaximum))
			writer.textArea('Paste the content here', PastebinForm::Content, content, {cols: '30', rows: '10', maxlength: PastebinConfiguration::UnitSizeLimit})
			
			writer.textArea('Debug', PastebinForm::Debug) if PastebinForm::DebugMode
			
			writer.secureSubmit
		end
		
		output.concat writeJavaScript(<<END
showModeSelector();
var content = document.getElementById('content');
content.onkeydown = tabHandler;
content.onkeypress = tabPressHandler;
END
		)
		
		return output
	end

	def getModificationFields(fields, source)
		if source.modificationCounter > 0
			fields.concat [
				['Last modification', source.lastModification],
				['Number of modifications', source.modificationCounter]
			]
		end
	end

	def getDescription(post, inTopic = true)
		return post.description if inTopic
		return post.bodyDescription
	end

	def processPastebinUnit(writer, post)
		unitOffset = 1
		post.units.each do |unit|
			type =
				unit.pasteType == nil ?
					'Plain text' :
					SyntaxHighlighting::getScriptDescription(unit.pasteType)
			
			unitFields =
			[
				['Unit', "#{unitOffset}/#{post.units.size}"],
			]
			
			unitFields << ['Description',  unit.description] if !unit.description.empty?
			
			unitFields.concat [
				['Type', type],
			]
			
			if unit.timeAdded != post.creation
				unitFields << ['Time added', unit.timeAdded]
			end
			
			getModificationFields(unitFields, unit)
			
			writer.table(class: 'descriptionTable') do
				unitFields.each do |description, value|
					writer.tr do
						writer.td(class: 'description') { description }
						writer.td { value.to_s }
					end
				end
			end
			
			content = unit.highlightedContent || unit.content
			content = content.gsub('  ', '&nbsp;&nbsp;')
			contentLines = content.split "\n"
			
			writer.div(class: 'unitContainer') do
				isEven = false
				writer.ul(class: 'contentList') do
					lineCounter = 1
					contentLines.each do |line|
						if lineCounter == contentLines.size
							lineClass = isEven ? 'evenLastLine' : 'oddLastLine'
						else
							lineClass = isEven ? 'evenLine' : 'oddLine'
						end
						writer.li(class: lineClass) { line }
						isEven = !isEven
						lineCounter += 1
					end
				end
				
				writer.ul(class: 'lineNumbers') do
					lineCounter = 1
					contentLines.size.times do |i|
						arguments = {}
						arguments[:class] = 'lastLine' if lineCounter == contentLines.size
						writer.li(arguments) { lineCounter.to_s }
						lineCounter += 1
					end
				end
			end
			unitOffset += 1
		end
	end

	def showPastebinPost(request, post)
		output = ''
		writer = HTMLWriter.new output

		fields =
		[
			['Author', post.bodyAuthor],
			['Description', getDescription(post, false)],
			['Time created', post.creation]
		]
		
		getModificationFields(fields, post)
		
		if post.expiration != nil
			fields << ['Expires', post.expiration]
		end
		
		fields << ['Number of units', post.units.size]
		
		writer.table(class: 'descriptionTable') do
			fields.each do |description, value|
				writer.tr do
					writer.td(class: 'description') { description }
					writer.td { value.to_s }
				end
			end
		end
		
		processPastebinUnit(writer, post)
		
		title = "#{getDescription(post)} - Pastebin"
		
		return @pastebinGenerator.get([title, output], request)
	end
	
	def getTypeString(post)
		limit = 3
		output = []
		counter = 0
		post.pasteTypes.each do |type|
			limit += 1
			break if counter == limit
			output << SyntaxHighlighting.getScriptDescription(type)
		end
		return output.join(', ')
	end
	
	def trimString(input, limit)
		return input if input.size <= limit
		filler = '...'
		output = input[0 .. (limit - filler.size - 1)] + filler
		return output
	end

	def listPastebinPosts(request, posts, page, pageCount)
		output = ''
		writer = HTMLWriter.new output
		
		columns =
		[
			'Description',
			'Author',
			'Type',
			'Date',
		]
		
		writer.table(class: 'postList') do
			writer.tr do
				columns.each do |column|
					writer.th { column }
				end
			end
			posts.reverse_each do |post|
				description = trimString(post.bodyDescription, PastebinConfiguration::ListDescriptionLengthMaximum)
				author = trimString(post.bodyAuthor, PastebinConfiguration::ListAuthorLengthMaximum)
				writer.tr do
					path = @pastebinHandler.getPath([PastebinHandler::View, post.pastebinPostId.to_s])
					writer.td do
						writer.a(href: path) do
							description
						end
					end
					typeString = getTypeString post
					writer.td { author }
					writer.td { typeString }
					writer.td { post.creation.to_s }
				end
			end
		end
		
		if page == 1
			title = 'Most recent pastes'
		else
			title = "Viewing pastes - page #{page}/#{pageCount}"
		end
		
		return [title, output]
	end
	
	def pastebinNewPost
	end
end