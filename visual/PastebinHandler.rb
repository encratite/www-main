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
		writer.ul do
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
				
				id = unit.id.to_s
				arguments = [id]
					
				unitActions << [@downloadHandler, 'Download']
				
				if permission
					unitActions +=
					[
						[@editUnitHandler, 'Edit'],
						[@deleteUnitHandler, 'Delete'],
					]
				end
				
				actions = []
				unitActions.each do |handler, description|
					linkWriter = WWWLib::HTMLWriter.new
					linkWriter.a(href: post.getUnitPath(handler, unit)) { description }
					actions << linkWriter.output
				end
				
				actionsString = actions.join(', ')
				
				unitFields << ['Actions', actionsString]
				
				getModificationFields(unitFields, unit)
				
				writer.li do
					writer.table(class: 'descriptionTable') do
						unitFields.each do |description, value|
							writer.tr do
								writer.td(class: 'description') { description }
								writer.td { value.to_s }
							end
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
		treeRootClass = 'postTreeRoot'
		listClass = isRoot ? treeRootClass : 'postTreeChild'
		writer.li(class: listClass, newlineType: :final) do
			target = post.getPostPath(@viewPostHandler)
			writer.a(href: target) do
				post.bodyDescription
			end
		end
		children = post.children
		if !children.empty?
			arguments = {newlineType: :full}
			if isRoot
				arguments[:class] = treeRootClass
			end
			writer.tagCall('li', arguments) do
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
			[@createReplyHandler, 'Reply']
		]
		permission = hasWriteAccess(request, post)
		if permission
			actions +=
			[
				[@addUnitHandler, 'Add unit'],
				[@deletePostHandler, 'Delete post'],
			]
		end
		
		links = []
		actions.each do |handler, description|
			linkWriter = WWWLib::HTMLWriter.new
			linkWriter.a(href: post.getPostPath(handler)) { description }
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
		
		root = tree.root
		if !root.children.empty?
			writer.ul(class: 'postTree') do
				writer.li { 'Posts in this thread:' }
				drawPostTree(writer, root)
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
					path = post.getPostPath(@viewPostHandler)
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
end
