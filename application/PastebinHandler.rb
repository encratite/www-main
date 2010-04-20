require 'PastebinForm'
require 'error'
require 'SyntaxHighlighting'
require 'PastebinPost'
require 'SiteContainer'

require 'configuration/loader'
requireConfiguration 'pastebin'

require 'visual/general'
require 'visual/PastebinHandler'

require 'site/RequestManager'
require 'site/random'
require 'site/input'
require 'site/HTTPReply'
require 'site/input'

class PastebinHandler < SiteContainer
	Pastebin = 'pastebin'
	SubmitNewPost = 'submitNewPost'
	View = 'view'
	ViewPrivate = 'viewPrivate'
	List = 'list'
	DeletePost = 'delete'
	DeleteUnit = 'deleteUnit'
	Edit = 'edit'
	
	def installHandlers
		pastebinHandler = RequestHandler.menu('Pastebin', Pastebin, method(:newPost))
		addMainHandler pastebinHandler
		
		RequestHandler.newBufferedObjectsGroup
		
		RequestHandler.menu('Create new post', nil, method(:newPost))
		RequestHandler.menu('View posts', List, method(:viewPosts), 0..1)
		
		@submitNewPostHandler = RequestHandler.handler(SubmitNewPost, method(:submitNewPost))
		@viewPostHandler = RequestHandler.handler(View, method(:viewPost), 1)
		@viewPrivatePostHandler = RequestHandler.handler(ViewPrivate, method(:viewPrivatePost), 1)
		@deletePostHandler = RequestHandler.handler(DeletePost, method(:deletePost), 1)
		@deleteUnitHandler = RequestHandler.handler(DeleteUnit, method(:deleteUnit), 1)
		@editHandler = RequestHandler.handler(edit, method(:edit), 1)
		
		RequestHandler.getBufferedObjects.each { |handler| pastebinHandler.add(handler) }
	end
	
	def pastebinError(content, request)
		data = ['Pastebin error', content]
		raise RequestManager::Exception.new(@pastebinGenerator.get(data, request))
	end

	def newPost(request)
		@pastebinGenerator.get(['Pastebin', pastebinForm(request)], request)
	end

	def floodCheck(request)
		query = "select count(*) from flood_protection where ip = '#{request.address}' and paste_time + interval '#{PastebinConfiguration::PasteInterval} seconds' >= now()"
		count = @database.fetch(query).first.values.first
		return count > PastebinConfiguration::PastesPerInterval
	end

	def createAnonymousString(length)
		dataset = @database[:pastebin_post]
		while true
			sessionString = RandomString.get length
			break if dataset.where(anonymous_string: sessionString).count == 0
		end
		return sessionString
	end
	
	def debugPostSubmission(request)
		actualData = serialiseFields(getFieldValues(request, PastebinForm::PostFields))
		debugData = request.getPost(PastebinForm::Debug)
		
		if debugData == actualData
			puts 'Data matches'
			#pastebinError('Data matches.', request)
		else
			puts 'Data does not match!'
			puts "Actual data:\n#{actualData}"
			puts "Debug data:\n#{debugData}"
			
			writer = HTMLWriter.new
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
			[privatePost, 'privacy option', [0, 1]],
			[expiration, 'expiration option', (0..(PastebinConfiguration::ExpirationOptions.size - 1))],
		]
		
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
		debugPostSubmission request if PastebinForm::DebugMode

		author,
			
		postDescription,
		
		highlightingGroup,
		
		commonHighlighting,
		advancedHighlighting,
		expertHighlighting,
		
		privatePost,
		expiration,
		
		unitDescription,
		
		content = processFormFields(request, PastebinForm::PostFields)
		
		stringLengthChecks = getStringLengthChecks(author, postDescription, unitDescription, content, expertHighlighting)
		
		errors = []
		
		privatePost = privatePost.to_i
		expiration = expiration.to_i
		
		validValues = getValidValues(highlightingGroup, privatePost, expiration)
		
		syntaxHighlightingFields =
		[
			commonHighlighting,
			advancedHighlighting,
			expertHighlighting,
		]
		
		@database.transaction do
			performErrorChecks(errors, request, stringLengthChecks, validValues, content)
			
			useSyntaxHighlighting =
				PastebinForm::HighlightingGroupIdentifiers.include?(highlightingGroup) &&
				highlightingGroup != PastebinForm::NoHighlighting
				
			highlightingSelectionMode = nil
			lastSelection = nil
				
			if useSyntaxHighlighting
				highlightingSelectionMode = PastebinForm::HighlightingGroupIdentifiers.index highlightingGroup
				syntaxHighlighting = syntaxHighlightingFields[highlightingSelectionMode - 1]
				if SyntaxHighlighting::isValidScript syntaxHighlighting
					lastSelection = syntaxHighlighting
				else
					errors << 'The vim syntax highlighting script you have specified does not exist.'
				end
			end
			
			if !errors.empty?
				errorContent = pastebinForm(request, errors, postDescription, unitDescription, content, highlightingSelectionMode, lastSelection)
				pastebinError(errorContent, request)
			end

			isLoggedIn = request.sessionUser != nil
			
			postUser = isLoggedIn ? request.sessionUser.id : nil
			postAuthor = !isLoggedIn ? author : nil
			postExpiration = expiration == 0 ? nil : (:NOW.sql_function + "#{PastebinConfiguration::ExpirationOptions[expiration][1]} second")
			anonymousString = privatePost == 1 ? createAnonymousString(PastebinConfiguration::AnonymousStringLength) : nil
			postReply = nil

			newPost =
			{
				user_id: postUser,
				
				author: postAuthor,
				ip: request.address,
				
				description: postDescription,
				
				expiration: postExpiration,
				
				anonymous_string: anonymousString,
				
				reply_to: postReply
			}

			dataset = @database[:pastebin_post]
			postId = dataset.insert newPost
			
			isPlain = highlightingGroup == PastebinForm::NoHighlighting
			if isPlain
				highlightedContent = nil
				pasteType = nil
			else
				highlightedContent = SyntaxHighlighting::highlight(syntaxHighlighting, content)
				pasteType = syntaxHighlighting
			end
			
			newUnit =
			{
				post_id: postId,
				
				description: unitDescription,
				content: content,
				
				highlighted_content: highlightedContent,
				
				paste_type: pasteType
			}
			
			dataset = @database[:pastebin_unit]
			dataset.insert newUnit
			
			if anonymousString == nil
				postPath = @viewPostHandler.getPath(postId)
			else
				postPath = @viewPrivatePostHandler.getPath(anonymousString)
			end
			
			return HTTPReply.localRefer(request, postPath)
		end
	end

	def getRequestId(request)
		arguments = request.arguments
		id = readId arguments[0]
		argumentError if id == nil
		return id
	end

	def viewPost(request)
		postId = getRequestId request
		post = nil
		@database.transaction do
			post = PastebinPost.new
			post.showPostQueryInitialisation(postId, self, request, @database)
		end
		return showPastebinPost(request, post)
	end
	
	def viewPrivatePost(request)
		privateString = request.arguments[0]
		post = nil
		@database.transaction do
			post = PastebinPost.new
			post.showPostQueryInitialisation(privateString, self, request, @database)
		end
		return showPastebinPost(request, post)
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
			page = readId(arguments[0]) - 1
		end
		
		@database.transaction do
			dataset = @database[:pastebin_post]
			postsPerPage = PastebinConfiguration::PostsPerPage
			posts = dataset.where(anonymous_string: nil, reply_to: nil)
			count = posts.count
			pageCount = count == 0 ? 1 : (Float(count) / postsPerPage).ceil
			pastebinError('Invalid page specified.', request) if page >= pageCount
			offset = [count - (page + 1) * postsPerPage, 0].max
			
			posts = posts.left_outer_join(:site_user, :id => :user_id)
			posts = posts.filter(pastebin_post__anonymous_string: nil, pastebin_post__reply_to: nil)
			
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
		posts = @database[:pastebin_post]
		replies = posts.where(reply_to: id)
		replies.each { |reply| deletePostTree reply.id }
		units = @database[:pastebin_unit]
		units.where(post_id: id).delete
		posts.where(id: id).delete
	end
	
	def deletePost(request)
		postId = getRequestId request
		post = PastebinPost.new
		@database.transaction do
			post.deletePostQueryInitialisation(postId, @database)
			raiseError(permissionError, request) if !hasWriteAccess(request, post)
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
			raiseError(permissionError, request) if !hasWriteAccess(request, post)
			units = database[:pastebin_unit]
			units.where(id: unitId).delete
			unitCount = units.where(post_id: postId).count
			deletedPost = unitCount == 0
			deletePostTree postId if deletedPost
		end
		return confirmUnitDeletion(post, request, deletedPost)
	end
	
	def edit(request)
	end
end
