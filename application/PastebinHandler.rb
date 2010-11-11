require 'PastebinForm'
require 'error'
require 'PastebinPost'
require 'SiteContainer'
require 'PostTree'

require 'configuration/loader'
requireConfiguration 'pastebin'

require 'visual/PastebinHandler'

require 'PastebinHandler/processPostSubmission'

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
		
		handlers =
		[
			[:submitNewPostHandler, 'submitNewPost', :submitNewPost],
			[:deletePostHandler, 'delete', :deletePost, 1],
			[:deleteUnitHandler, 'deleteUnit', :deleteUnit, 1],
			
			[:createReplyHandler, 'reply', :createReply, 1],
			[:createPrivateReplyHandler, 'privateReply', :createPrivateReply, 1],
			
			[:viewPostHandler, 'view', :viewPost, 1],
			[:viewPrivatePostHandler, 'viewPrivate', :viewPrivatePost, 1],
			
			[:editUnitHandler, 'edit', :editUnit, 1],
			[:editPrivateUnitHandler, 'editPrivate', :editPrivateUnit, 2],
			
			[:submitUnitModificationHandler, 'submitModification', :submitUnitModification],
			[:submitPrivateUnitModificationHandler, 'submitPrivateModification', :submitPrivateUnitModification],
			
			[:submitReplyHandler, 'submitReply', :submitReply],
			[:submitPrivateReplyHandler, 'submitPrivateReply', :submitPrivateReply],
			
			[:downloadHandler, 'download', :download, 1],
			[:privateDownloadHandler, 'privateDownload', :privateDownload, 2],
			
			[:addUnitHandler, 'addUnit', :addUnit, 1],
			[:addPrivateUnitHandler, 'addPrivateUnit', :addPrivateUnit, 1],
			
			[:submitUnitHandler, 'submitUnit', :submitUnit],
			[:submitPrivateUnitHandler, 'submitPrivateUnit', :submitPrivateUnit],
		]
		
		handlers.each do |arguments|
			handlerSymbol = arguments[0]
			arguments = arguments[1..-1]
			arguments[1] = method(arguments[1])
			handler = WWWLib::RequestHandler.handler(*arguments)
			setMember(handlerSymbol, handler)
		end
		
		WWWLib::RequestHandler.getBufferedObjects.each { |handler| pastebinHandler.add(handler) }
	end
	
	def pastebinError(content, request)
		data = ['Pastebin error', content]
		raise WWWLib::RequestManager::Exception.new(@pastebinGenerator.get(data, request))
	end

	def createNewPost(request)
		form = PastebinForm.new(request)
		form.mode = :new
		return @pastebinGenerator.get(['Pastebin', pastebinForm(form)], request)
	end
	
	def processReplyCreationRequest(request, private)
		#check if the post ID is valid
		if private
			privateString = request.arguments[0]
			posts = @posts.where(private_string: privateString)
			mode = :privateReply
		else
			postId = getRequestId request
			posts = @posts.where(id: postId, private_string: nil)
			mode = :reply
		end
		posts = posts.all
		argumentError if posts.empty?
		replyPost = PastebinPost.new
		replyPost.transferSymbols(posts.first)
		form = PastebinForm.new(request)
		form.mode = mode
		form.replyPost = replyPost
		return @pastebinGenerator.get(['Reply to post', pastebinForm(form)], request)
	end
	
	def createReply(request)
		return processReplyCreationRequest(request, false)
	end
	
	def createPrivateReply(request)
		return processReplyCreationRequest(request, true)
	end

	def floodCheck(request)
		query = "select count(*) from flood_protection where ip = '#{request.address}' and paste_time + interval '#{PastebinConfiguration::PasteInterval} seconds' >= '#{Time.now.utc}'"
		count = @database.connection.fetch(query).first.values.first
		return count > PastebinConfiguration::PastesPerInterval
	end

	def createPrivateString(length)
		dataset = @database.post
		while true
			sessionString = WWWLib::RandomString.get(length)
			break if dataset.where(private_string: sessionString).count == 0
		end
		return sessionString
	end
	
	def debugPostSubmission(request)
		actualData = serialiseFields(getFieldValues(request, PastebinForm::NewSubmissionPostFields))
		debugData = request.getPost(PastebinForm::Debug)
		
		if debugData == actualData
			puts 'Data matches'
			#pastebinError('Data matches.', request)
		else
			puts 'Data does not match!'
			puts "Actual data:\n#{actualData}"
			puts "Debug data:\n#{debugData}"
			
			writer = WWWLib::HTMLWriter.new
			writer.p { 'Data does not match:' }
			textAreaArguments = {cols: '50', rows: '30'}
			writer.textArea('Actual data', 'test1', actualData, textAreaArguments)
			writer.textArea('Debug data', 'test2', debugData, textAreaArguments)
			#pastebinError(writer.output, request)
		end
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
	
	def submitNewPost(request)
		return processPostSubmission(request, :new)
	end
	
	def submitUnitModification(request)
		return processPostSubmission(request, :edit)
	end
	
	def submitPrivateUnitModification(request)
		return processPostSubmission(request, :privateEdit)
	end
	
	def submitReply(request)
		return processPostSubmission(request, :reply)
	end
	
	def submitPrivateReply(request)
		return processPostSubmission(request, :privateReply)
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
	
	def getPrivateString
		return createPrivateString(PastebinConfiguration::PrivateStringLength)
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
	
	def processPostView(request, isPrivate)
		if isPrivate
			target = request.arguments[0]
		else
			target = getRequestId request
		end
		post = nil
		tree = nil
		@database.transaction do
			post = PastebinPost.new
			post.showPostQueryInitialisation(target, self, request, @database)
			tree = PostTree.new(@database, post)
		end
		return showPastebinPost(request, post, tree)
	end

	def viewPost(request)
		return processPostView(request, false)
	end
	
	def viewPrivatePost(request)
		return processPostView(request, true)
	end
	
	def parsePosts(posts)
		output = []
		lastId = nil
		currentPost = nil
		posts.each do |rawPost|
			post = PastebinPost.new
			post.transferSymbols rawPost
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

	def viewPosts(request)
		arguments = request.arguments
		if arguments.empty?
			page = 0
		else
			page = WWWLib.readId(arguments[0]) - 1
		end
		
		@database.transaction do
			postsPerPage = PastebinConfiguration::PostsPerPage
			#private_string must be NULL - only public posts may be browsed
			#reply_to must be NULL, too - we only want to see the posts which actually started a thread
			posts = @posts.where(private_string: nil, reply_to: nil)
			count = posts.count
			pageCount = count == 0 ? 1 : (Float(count) / postsPerPage).ceil
			pastebinError('Invalid page specified.', request) if page >= pageCount
			offset = [count - (page + 1) * postsPerPage, 0].max
			
			posts = posts.left_outer_join(:site_user, :id => :user_id)
			posts = posts.filter(pastebin_post__private_string: nil, pastebin_post__reply_to: nil)
			
			posts = posts.select(
				:pastebin_post__id.as(:pastebin_post_id), :pastebin_post__user_id, :pastebin_post__author, :pastebin_post__description, :pastebin_post__creation,
				#:site_user__name.as(:user_name),
				:site_user__name,
			)
			
			posts = posts.limit(postsPerPage, offset)

			posts = posts.from_self(alias: :user_post)
			posts = posts.left_outer_join(:pastebin_unit, :post_id => :user_post__pastebin_post_id)
			
			posts = posts.select(
				:user_post__pastebin_post_id, :user_post__user_id, :user_post__author, :user_post__description, :user_post__creation,
				:user_post__name,
				:pastebin_unit__paste_type,
				'length(pastebin_unit.content)'.lit.as(:content_size)
			)
			
			posts = posts.all
			parsedPosts = parsePosts(posts)
			output = listPastebinPosts(request, parsedPosts, page + 1, pageCount)
			return @pastebinGenerator.get(output, request)
		end
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
	
	def deletePost(request)
		postId = getRequestId request
		post = PastebinPost.new
		@database.transaction do
			post.deletePostQueryInitialisation(postId, @database)
			writePermissionCheck(request, post)
			deletePostTree postId
		end
		return confirmPostDeletion(post, request)
	end
	
	def deleteUnit(request)
		unitId = getRequestId request
		post = PastebinPost.new
		deletedPost = nil
		@database.transaction do
			postId = post.deleteUnitQueryInitialisation(unitId, @database)
			writePermissionCheck(request, post)
			@units.where(id: unitId).delete
			unitCount = @units.where(post_id: postId).count
			deletedPost = unitCount == 0
			deletePostTree postId if deletedPost
		end
		return confirmUnitDeletion(post, request, deletedPost)
	end
	
	def editUnit(request)
		unitId = getRequestId request
		post = PastebinPost.new
		@database.transaction do
			post.editUnitQueryInitialisation(unitId, @database)
			writePermissionCheck(request, post)
			return editUnitForm(post, request)
		end
	end
	
	def editPrivateUnit(request)
		unitId = getRequestId request
		privateString = request.arguments[1]
		post = PastebinPost.new
		@database.transaction do
			post.editUnitQueryInitialisation(unitId, @database)
			argumentError if post.privateString != privateString
			writePermissionCheck(request, post)
			return editUnitForm(post, request)
		end
	end
	
	def writePermissionCheck(request, post)
		raiseError(permissionError, request) if !hasWriteAccess(request, post)
	end
	
	def processDownload(request, privateString)
		unitId = getRequestId request
		
		@database.transaction do
			rows = @units.select(:post_id, :content).where(id: unitId).all
			raiseError(argumentError, request) if rows.empty?
			unit = rows.first
			postId = unit[:post_id]
			unitContent = unit[:content]
			rows = @posts.select(:private_string).where(id: postId).all
			raiseError(internalError 'Missing post', request) if rows.empty?
			post = rows.first
			postPrivateString = post[:private_string]
			#it's a public post and it's being viewed using the regular download handler
			publicSuccess = (privateString == nil && postPrivateString == nil)
			#this might seem redundant but I like verbosity
			#it's a private post, it's being viewed using the private download handler and the private string specified in the argument matches that of the post
			privateSuccess = (privateString != nil && postPrivateString != nil && privateString == postPrivateString)
			if !(publicSuccess || privateSuccess)
				raiseError(argumentError, request)
			end
			#return the actual code as plain text
			reply = WWWLib::HTTPReply.new(unitContent)
			reply.plain
			return reply
		end
	end
	
	def download(request)
		return processDownload(request, nil)
	end
	
	def privateDownload(request)
		privateString = request.arguments[1]
		return processDownload(request, privateString)
	end
	
	def isEditMode(mode)
		return [:edit, :privateEdit].include?(mode)
	end
	
	def isReplyMode(mode)
		return [:reply, :privateReply].include?(mode)
	end
	
	def isAddUnitMode(mode)
		return [:addUnit, :privateAddUnit].include?(mode)
	end
			
	def addUnit(request)
		postId = getRequestId request
		post = PastebinPost.new
		@database.transaction do
			post.simpleInitialisation(postId, @database, true)
			writePermissionCheck(request, post)
			return addUnitForm(post, request)
		end
	end
	
	def addPrivateUnit(request)
		privateString = request.arguments.first
		post = PastebinPost.new
		@database.transaction do
			post.simpleInitialisation(postId, @database, true)
			argumentError if post.privateString != privateString
			writePermissionCheck(request, post)
			return addUnitForm(post, request)
		end
	end
	
	def submitUnit(request)
	end
	
	def submitPrivateUnit(request)
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
		form.isPrivatePost = post.isPrivate
		form.expirationIndex = post.expirationIndex
		form.editUnitId = unit.id
		form.editPost = post
		form.mode = post.isPrivate ? :privateEdit : :edit
		body = pastebinForm(form)
		title = 'Editing post'
		return @pastebinGenerator.get([title, body], request)
	end
	
	def addUnitForm(post, request)
		form = PastebinForm.new(request)
		form.author = post.editAuthor
		form.postDescription = getDescriptionField post
		form.isPrivatePost = post.isPrivate
		form.expirationIndex = post.expirationIndex
		form.editPost = post
		form.mode = post.isPrivate ? :privateAddUnit : :addUnit
		body = pastebinForm(form)
		title = 'Add a unit to your post'
		return @pastebinGenerator.get([title, body], request)
	end
end
