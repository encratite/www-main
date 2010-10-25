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
			unitFields =
			[
				['Unit', "#{unitOffset}/#{post.units.size}"],
				['Description',  unit.bodyDescription],
				['Type', unit.bodyPasteType],
				['Size', WWWLib.getSizeString(unit.content.size)],
			]
			
			if unit.timeAdded != post.creation
				unitFields << ['Time added', unit.timeAdded]
			end
			
			if permission
				unitActions =
				[
					[@editUnitHandler, 'Edit'],
					[@deleteUnitHandler, 'Delete'],
				]
				idString = unit.id.to_s
				actions = []
				unitActions.each do |handler, description|
					linkWriter = WWWLib::HTMLWriter.new
					linkWriter.a(href: handler.getPath(idString)) { description }
					actions << linkWriter.output
				end
				actionsString = actions.join(', ')
				unitFields << ['Actions', actionsString]
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
			space = '&nbsp;'
			content = content.gsub('  ', space * 2)
			content = content.gsub("\t", space * 4)
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
		writer = WWWLib::HTMLWriter.new

		fields =
		[
			['Author', post.bodyAuthor],
			['Description', getDescription(post, false)],
			['Time created', post.creation]
		]
		
		permission = hasWriteAccess(request, post)
		if permission
			linkWriter = WWWLib::HTMLWriter.new
			linkWriter.a(href: @deletePostHandler.getPath(post.id.to_s)) { 'Delete post' }
			fields << ['Actions', linkWriter.output]
		end
		
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
		
		processPastebinUnits(writer, post, permission)
		
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
		body = pastebinForm(form)
		title = 'Editing post'
		return @pastebinGenerator.get([title, body], request)
	end
end
