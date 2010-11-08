require 'PastebinHandler'
require 'SiteContainer'

require 'www-library/JavaScript'
require 'www-library/string'
require 'www-library/HTMLWriter'

require 'configuration/loader'
requireConfiguration 'pastebin'

require 'visual/PastebinHandler/pastebinForm'

class PastebinHandler < SiteContainer
	HighlightingGroups =
	[
		'Use no syntax highlighting (plain text)',
		"Common programming languages (#{SyntaxHighlighting::CommonScripts.size} available)",
		"All syntax highlighting types (#{SyntaxHighlighting::AllScripts.size} available)",
		'Expert mode (manually specify the name of a vim script)'
	]
	
	PlainTextHighlightingIndex = 0
	AllSyntaxHighlightingTypesIndex = 2
	
	def pasteFieldLength(symbol)
		return {maxlength: PastebinConfiguration.const_get(symbol)}
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

	def processPastebinUnits(writer, post, permission)
		unitOffset = 1
		post.units.each do |unit|
			unitFields = []
			
			unitCount = post.units.size
			
			
			if unitCount > 1
				unitFields << ['Unit', "#{unitOffset}/#{unitCount}"]
			end
				
			if !unit.noDescription
				unitFields << ['Description',  unit.bodyDescription]
			end
			
			unitFields +=
			[
				['Type', unit.bodyPasteType],
				['Size', WWWLib.getSizeString(unit.content.size)],
			]
			
			if unit.timeAdded != post.creation
				unitFields << ['Time added', unit.timeAdded]
			end
			
			unitActions = []
			
			downloadDescription = 'Download'
				
			if post.privateString == nil
				#it's a public post - use the regular public unit download handler
				unitActions << [@downloadHandler, downloadDescription]
				
			else
				#it's a private post - use the private unit download handler with the correct private string
				unitActions << [@privateDownloadHandler, downloadDescription, post.privateString]
			end
			
			if permission
				unitActions +=
				[
					[@editUnitHandler, 'Edit'],
					[@deleteUnitHandler, 'Delete'],
				]
			end
			
			idString = unit.id.to_s
			actions = []
			unitActions.each do |handler, description, customArguments = nil|
				linkWriter = WWWLib::HTMLWriter.new
				arguments = [idString]
				if customArguments.class != Array
					customArguments = [customArguments]
				end
				arguments += customArguments if customArguments != nil
				linkWriter.a(href: handler.getPath(*arguments)) { description }
				actions << linkWriter.output
			end
			
			actionsString = actions.join(', ')
			
			unitFields << ['Actions', actionsString]
			
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
			
			#generate a minimal amount of HTML entities to achieve the desired spacing
			space = '&nbsp;'
			content = content.gsub("\t", ' ' * 4)
			content = content.gsub('  ', "#{space} ")
			content = content.gsub("\r", '')
			
			contentLines = content.split "\n"
			
			renderContentAsList(writer, contentLines)
			
			unitOffset += 1
		end
	end
	
	def renderContentAsList(writer, contentLines)
		writer.ul(class: 'lineNumbers') do
			lineCounter = 1
			contentLines.size.times do |i|
				arguments = {}
				arguments[:class] = 'lastLine' if lineCounter == contentLines.size
				writer.li(arguments) { lineCounter.to_s }
				lineCounter += 1
			end
			nil
		end
	
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
	end
	
	def drawPostTree(writer, post, isRoot = true)
		arguments = {newlineType: :final}
		if !isRoot
			arguments[:class] = 'postTreeChild'
		end
		function = lambda { post.bodyDescription }
		writer.tag('li', arguments, function)
		children = post.children
		if !children.empty?
			writer.li(newlineType: :full) do
				writer.ul(class: 'innerPostTree') do
					children.each do |child|
						drawPostTree(writer, child, false)
					end
				end
			end
		end
	end

	def showPastebinPost(request, post, tree)
		writer = WWWLib::HTMLWriter.new

		fields =
		[
			['Author', post.bodyAuthor],
			['Description', getDescription(post, false)],
			['Time created', post.creation]
		]
		
		actions =
		[
			[@createReplyHandler, 'Reply'],
		]
		
		permission = hasWriteAccess(request, post)
		
		actions << [@deletePostHandler, 'Delete post'] if permission
		
		links = []
		actions.each do |handler, description|
			linkWriter = WWWLib::HTMLWriter.new
			linkWriter.a(href: handler.getPath(post.id.to_s)) { description }
			links << linkWriter.output
		end
		
		fields << ['Actions', links.join(', ')]
		
		getModificationFields(fields, post)
		
		if post.expiration != nil
			fields << ['Expires', post.expiration]
		end
		
		unitCount = post.units.size
		if unitCount > 1
			fields << ['Number of units', unitCount]
		end
		
		writer.table(class: 'descriptionTable') do
			fields.each do |description, value|
				writer.tr do
					writer.td(class: 'description') { description }
					writer.td { value.to_s }
				end
			end
		end
		
		processPastebinUnits(writer, post, permission)
		
		if !post.children.empty?
			writer.ul(class: 'postTree') do
				drawPostTree(writer, post)
			end
		end
		
		title = "#{getDescription(post)} - Pastebin"
		
		return @pastebinGenerator.get([title, writer.output], request)
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
		writer = WWWLib::HTMLWriter.new
		
		columns =
		[
			'Description',
			'Author',
			'Type',
			'Size',
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
					path = @viewPostHandler.getPath post.pastebinPostId.to_s
					writer.td do
						writer.a(href: path) do
							description
						end
					end
					
					typeString = getTypeString(post)
					sizeString = WWWLib.getSizeString(post.contentSize)
					
					[
						author,
						typeString,
						sizeString,
						post.creation.to_s
					].each do |column|
						writer.td { column }
					end
				end
			end
		end
		
		if page == 1
			title = 'Most recent pastes'
		else
			title = "Viewing pastes - page #{page}/#{pageCount}"
		end
		
		return [title, writer.output]
	end
	
	def confirmPostDeletion(post, request)
		title = 'Post deleted'
		writer = WWWLib::HTMLWriter.new
		writer.p do
			writer.write 'Your post '
			writer.b { "\"#{post.bodyDescription}\"" }
			writer.write ' and all the replies to it have been removed.'
		end
		return @pastebinGenerator.get([title, writer.output], request)
	end
	
	def confirmUnitDeletion(post, request, deletedPost)
		unit = post.activeUnit
		writer = WWWLib::HTMLWriter.new
		title = nil
		writer.p do
			if unit.noDescription
				writer.write "Your #{unit.bodyDescription} unit has been deleted."
			else
				writer.write 'Your unit '
				writer.b { "\"#{unit.bodyDescription}\"" }
				writer.write ' has been deleted.'
			end
			
			if deletedPost
				title = 'Post deleted'
				if post.noDescription
					writer.write ' Your post '
				else
					writer.write 'The post '
					writer.b { "\"#{post.bodyDescription}\"" }
				end
				writer.write ' and all the replies to it have been removed because you deleted the only unit it contained.'
			else
				title = 'Unit deleted'
			end
		end
		return @pastebinGenerator.get([title, writer.output], request)
	end
	
	def getDescriptionField(object)
		return object.noDescription ? '' : object.description
	end
	
	def editUnitForm(post, request)
		unit = post.activeUnit
		if unit.pasteType == nil
			#it's plain text
			highlightingSelectionMode = PlainTextHighlightingIndex
			lastSelection = nil
		else
			highlightingSelectionMode = AllSyntaxHighlightingTypesIndex
			lastSelection = unit.pasteType
		end
		form = PastebinForm.new(request)
		form.errors = nil
		form.author = post.editAuthor
		form.postDescription = getDescriptionField post
		form.unitDescription = getDescriptionField unit
		form.content = unit.content
		form.highlightingSelectionMode = highlightingSelectionMode
		form.lastSelection = lastSelection
		form.isPrivatePost = post.isPrivate
		form.expirationIndex = post.expirationIndex
		form.editUnitId = unit.id
		form.editPost = post
		form.mode = :edit
		body = pastebinForm(form)
		title = 'Editing post'
		return @pastebinGenerator.get([title, body], request)
	end
end
