require 'error'
require 'PastebinPost'
require 'SiteContainer'
require 'PostTree'

require 'configuration/loader'
requireConfiguration 'pastebin'

require 'visual/PastebinHandler'

require 'PastebinHandler/processPostSubmission'
require 'PastebinHandler/handler'

require 'www-library/RequestManager'
require 'www-library/random'
require 'www-library/input'
require 'www-library/HTTPReply'

require 'nil/symbol'

class PastebinHandler < SiteContainer
	include SymbolicAssignment
	
	def initialize(site)
		super
		@posts = @database.post
		@units = @database.unit
	end
	
	def installHandlers
		pastebinHandler = WWWLib::RequestHandler.menu('Pastebin', 'pastebin', method(:createNewPost))
		addMainHandler pastebinHandler
		
		WWWLib::RequestHandler.newBufferedObjectsGroup
		
		WWWLib::RequestHandler.menu('Create new post', nil, method(:createNewPost))
		WWWLib::RequestHandler.menu('View posts', 'list', method(:viewPosts), 0..1)
		
		#The handlers basically feature three types of argument passing.
		
		#1. POST only => nil
		
		#2. GET for a post => :post
		#For public posts:
		#    1. integer: 0
		#    2. integer: ID of the post
		#For private posts:
		#    1. integer: 1
		#    2. string: private string of the post
		
		#3. GET for a unit => :unit
		#For public posts:
		#    1. integer: ID of the unit
		#For private posts:
		#    1. integer: ID of the unit
		#    2. string: private string of the post
		
		handlers =
		[
			[:viewPostHandler, 'view', :viewPost, :post],
			[:submitNewPostHandler, 'submitNewPost', :submitNewPost, nil],
			[:downloadHandler, 'download', :download, :unit],
			[:deletePostHandler, 'delete', :deletePost, :post],
			[:deleteUnitHandler, 'deleteUnit', :deleteUnit, :unit],
			
			[:createReplyHandler, 'reply', :createReply, :post],
			[:submitReplyHandler, 'submitReply', :submitReply, nil],
			
			[:editUnitHandler, 'edit', :editUnit, :unit],
			[:submitUnitModificationHandler, 'submitModification', :submitUnitModification, nil],
			
			[:addUnitHandler, 'addUnit', :addUnit, :post],
			[:submitUnitHandler, 'submitUnit', :submitUnit, nil],
		]
		
		handlers.each do |handlerSymbol, string, methodSymbol, argumentType|
			actualMethod = method(methodSymbol)
			case argumentType
			when :post
				proxyMethod = lambda do |request|
					arguments = request.arguments
					isPrivate = arguments[0].to_i == 1
					target = arguments[1]
					target = target.to_i if isPrivate
					actualMethod.call(request, isPrivate, target)
				end
				argumentCount = 2
			when :unit
				proxyMethod = lambda do |request|
					arguments = request.arguments
					unitId = arguments[0].to_i
					isPrivate = arguments.size == 2
					if isPrivate
						privateString = arguments[1]
					else
						privateString = nil
					end
					actualMethod.call(request, unitId, privateString)
				end
				argumentCount = 1..2
			when nil
				proxyMethod = actualMethod
				argumentCount = nil
			end
			handler = WWWLib::RequestHandler.handler(string, proxyMethod, argumentCount)
			setMember(handlerSymbol, handler)
		end
		
		WWWLib::RequestHandler.getBufferedObjects.each { |handler| pastebinHandler.add(handler) }
	end
	
	def pastebinError(content, request)
		data = ['Pastebin error', content]
		raise WWWLib::RequestManager::Exception.new(@pastebinGenerator.get(data, request))
	end

	def floodCheck(request)
		query = "select count(*) from flood_protection where ip = '#{request.address}' and paste_time + interval '#{PastebinConfiguration::PasteInterval} seconds' >= '#{Time.now.utc}'"
		count = @database.connection.fetch(query).first.values.first
		return count > PastebinConfiguration::PastesPerInterval
	end
	
	def getPrivateString
		length = PastebinConfiguration::PrivateStringLength
		dataset = @database.post
		while true
			sessionString = WWWLib::RandomString.get(length)
			break if dataset.where(private_string: sessionString).count == 0
		end
		return sessionString
	end
	
	def getStringLengthChecks(author, postDescription, unitDescription, content, expertHighlighting)
		stringLengthChecks =
		[
			[author, 'name', PastebinConfiguration::AuthorLengthMaximum],
			[postDescription, 'post description', PastebinConfiguration::PostDescriptionLengthMaximum],
			[unitDescription, 'unit description', PastebinConfiguration::UnitDescriptionLengthMaximum],
			[content, 'content', PastebinConfiguration::UnitSizeLimit],
			[expertHighlighting, 'vim script name', PastebinConfiguration::VimScriptLengthMaximum],
		]
		
		return stringLengthChecks
	end
	
	def getValidValues(highlightingGroup, privatePost, expiration)
		validValues =
		[
			[highlightingGroup, 'highlighting group', PastebinForm::HighlightingGroupIdentifiers],
		]
		
		if privatePost != nil && expiration != nil
			validValues +=
			[
				[privatePost, 'privacy option', [0, 1]],
				[expiration, 'expiration option', (0..(PastebinConfiguration::ExpirationOptions.size - 1))],
			]
		end
		
		return validValues
	end
	
	def performErrorChecks(errors, request, stringLengthChecks, validValues, content)
		isSpammer = floodCheck request
		if isSpammer
			errors << 'You have triggered the pastebin flood protection by posting too frequently so your request could not be processed.'
		end
		
		errors << 'You have not specified any content for your post.' if content.empty?
		
		stringLengthChecks.each do |field, name, limit|
			next if field.size <= limit
			errors << "The #{name} you have specified is too long - the limit is #{limit}."
		end
		
		validValues.each do |field, name, values|
			next if values.include?(field)
			errors << "The #{name} you have specified is invalid."
		end
	end
	
	def getPostValue(request, symbol)
		output = request.getPost(PastebinForm.const_get(symbol))
		return nil if output == nil
		return output
	end
	
	def getIntPost(request, symbol)
		output = getPostValue(request, symbol)
		return nil if output == nil
		return output.to_i
	end
	
	def updatePostTreeVisibility(postId, isPrivate)
		children = @database.post.select(:id).where(reply_to: postId).all
		children.each do |row|
			id = row[:id]
			privateString = isPrivate ? getPrivateString : nil
			@database.post.where(id: id).update(private_string: privateString)
			#depth first search
			updatePostTreeVisibility(id, isPrivate)
		end
	end

	def getRequestId(request)
		arguments = request.arguments
		id = WWWLib.readId(arguments[0])
		argumentError if id == nil
		return id
	end
	
	def parsePosts(posts)
		output = []
		lastId = nil
		currentPost = nil
		posts.each do |rawPost|
			post = PastebinPost.new(@database)
			post.transferSymbols(rawPost)
			post.initialiseMembers
			if post.pastebinPostId == lastId
				currentPost.pasteTypes << post.pasteType
				currentPost.contentSize += post.contentSize
			else
				lastId = post.pastebinPostId
				output << post
				currentPost = post
				post.pasteTypes = [post.pasteType]
			end
		end
		return output
	end
	
	def hasWriteAccess(request, post)
		if post.userId == nil
			#puts "#{request.address.inspect}, #{post.ip.inspect}"
			return request.address == post.ip
		else
			#puts "#{post.userId.inspect}, #{request.sessionUser != nil ? request.sessionUser.id.inspect : 'request.sessionUser == nil'}"
			return request.sessionUser != nil && post.userId == request.sessionUser.id
		end
	end
	
	def deletePostTree(id)
		replies = @database.post.where(reply_to: id)
		replies.each { |reply| deletePostTree reply.id }
		@units.where(post_id: id).delete
		@posts.where(id: id).delete
	end
	
	def writePermissionCheck(request, post)
		raiseError(permissionError, request) if !hasWriteAccess(request, post)
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
		form.author = post.editAuthor
		form.postDescription = getDescriptionField post
		form.unitDescription = getDescriptionField unit
		form.content = unit.content
		form.highlightingSelectionMode = highlightingSelectionMode
		form.lastSelection = lastSelection
		form.expirationIndex = post.expirationIndex
		form.isPrivate = post.isPrivate
		form.editUnitId = unit.id
		form.editPost = post
		form.mode = :edit
		body = pastebinForm(form)
		title = 'Editing post'
		return @pastebinGenerator.get([title, body], request)
	end
	
	def addUnitForm(post, request)
		form = PastebinForm.new(request)
		form.author = post.editAuthor
		form.postDescription = getDescriptionField post
		form.expirationIndex = post.expirationIndex
		form.editPost = post
		form.isPrivate = post.isPrivate
		form.mode = :addUnit
		body = pastebinForm(form)
		title = 'Add a unit to your post'
		return @pastebinGenerator.get([title, body], request)
	end
end
