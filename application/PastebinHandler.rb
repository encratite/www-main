require 'PastebinForm'
require 'error'
require 'SyntaxHighlighting'
require 'PastebinPost'
require 'SiteContainer'

require 'configuration/loader'
requireConfiguration 'pastebin'
requireConfiguration 'cookie'

require 'visual/general'
require 'visual/PastebinHandler'

require 'www-library/RequestManager'
require 'www-library/random'
require 'www-library/input'
require 'www-library/HTTPReply'

class PastebinHandler < SiteContainer
	Pastebin = 'pastebin'
	SubmitNewPost = 'submitNewPost'
	View = 'view'
	ViewPrivate = 'viewPrivate'
	List = 'list'
	DeletePost = 'delete'
	DeleteUnit = 'deleteUnit'
	EditUnit = 'edit'
	SubmitUnitModification = 'submitModification'
	
	def installHandlers
		pastebinHandler = WWWLib::RequestHandler.menu('Pastebin', Pastebin, method(:postData))
		addMainHandler pastebinHandler
		
		WWWLib::RequestHandler.newBufferedObjectsGroup
		
		WWWLib::RequestHandler.menu('Create new post', nil, method(:postData))
		WWWLib::RequestHandler.menu('View posts', List, method(:viewPosts), 0..1)
		
		@submitNewPostHandler = WWWLib::RequestHandler.handler(SubmitNewPost, method(:submitNewPost))
		@viewPostHandler = WWWLib::RequestHandler.handler(View, method(:viewPost), 1)
		@viewPrivatePostHandler = WWWLib::RequestHandler.handler(ViewPrivate, method(:viewPrivatePost), 1)
		@deletePostHandler = WWWLib::RequestHandler.handler(DeletePost, method(:deletePost), 1)
		@deleteUnitHandler = WWWLib::RequestHandler.handler(DeleteUnit, method(:deleteUnit), 1)
		@editUnitHandler = WWWLib::RequestHandler.handler(EditUnit, method(:editUnit), 1)
		@submitUnitModification = WWWLib::RequestHandler.handler(SubmitUnitModification, method(:submitUnitModification))
		
		WWWLib::RequestHandler.getBufferedObjects.each { |handler| pastebinHandler.add(handler) }
	end
	
	def pastebinError(content, request)
		data = ['Pastebin error', content]
		raise WWWLib::RequestManager::Exception.new(@pastebinGenerator.get(data, request))
	end

	def postData(request)
		form = PastebinForm.new(request)
		@pastebinGenerator.get(['Pastebin', pastebinForm(form)], request)
	end

	def floodCheck(request)
		query = "select count(*) from flood_protection where ip = '#{request.address}' and paste_time + interval '#{PastebinConfiguration::PasteInterval} seconds' >= now()"
		count = @database.fetch(query).first.values.first
		return count > PastebinConfiguration::PastesPerInterval
	end

	def createPrivateString(length)
		dataset = @database[:pastebin_post]
		while true
			sessionString = WWWLib::RandomString.get length
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
		return processNewPostOrModification(request, false)
	end

	def processNewPostOrModification(request, editing)
		debugPostSubmission request if PastebinForm::DebugMode
		
		source =  editing ? PastebinForm::EditPostFields : PastebinForm::NewSubmissionPostFields
		input = processFormFields(request, source)

		author,
			
		postDescription,
		
		highlightingGroup,
		
		commonHighlighting,
		advancedHighlighting,
		expertHighlighting,
		
		privatePost,
		expiration,
		
		unitDescription,
		
		content = input
		
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
			
			posts = @database[:pastebin_post]
			units = @database[:pastebin_unit]
			
			isPrivatePost = nil
			expirationIndex = expiration
			
			if editing
				#check if the unit ID is valid and determine the post associated with it
				#right now the ID of the unit to be edited is the last field - could be changed by PastebinForm though, so watch out
				editUnitId = input[-1].to_i
				editPost = PastebinPost.new
				editPost.editPermissionQueryInitialisation(editUnitId, @database)
				writePermissionCheck(request, editPost)
			else
				editUnitId = nil
			end
			
			if !errors.empty?
				#an error occured - break out of this function by raising an exception
				#display a pastebin form with properly filled in fields (even while editing) and the error messages
				form = PastebinForm.new(request)
				form.errors = errors
				form.author = author
				form.postDescription = postDescription
				form.unitDescription = unitDescription
				form.content = content
				form.highlightingSelectionMode = highlightingSelectionMode
				form.lastSelection = lastSelection
				form.isPrivatePost = isPrivatePost
				form.expirationIndex = expirationIndex
				form.editUnitId = editUnitId
				errorContent = pastebinForm(form)
				#this raises an exception
				pastebinError(errorContent, request)
			end
			
			now = Time.now.utc

			isLoggedIn = request.sessionUser != nil
			
			postUser = isLoggedIn ? request.sessionUser.id : nil
			postAuthor = !isLoggedIn ? author : nil
			expirationTime = now + PastebinConfiguration::ExpirationOptions[expiration][1]
			postExpiration = expiration == 0 ? nil : expirationTime
			postReply = nil

			postData =
			{
				user_id: postUser,
				
				author: postAuthor,
				ip: request.address,
				
				description: postDescription,
				
				expiration: postExpiration,
				expiration_index: expirationIndex,
				
				reply_to: postReply,
			}
			
			isPrivate = privatePost == 1
			privateString = isPrivate ? createPrivateString(PastebinConfiguration::PrivateStringLength) : nil

			if editing
				if !(editPost.isPrivate && isPrivate)
					#there are basically 4 cases to cover - just exclude the one where no new private string must be generated and written to the post
					#unnecessarily writing a null is not a big deal anyways
					postData[:private_string] = privateString
				end
				#increase the modification counter
				postData[:modification_counter] = editPost.modificationCounter + 1
				postData[:last_modification] = now
				postId = editPost.id
				posts.where(id: postId).update(postData)
			else
				postData[:private_string] = privateString
				postData[:creation] = now
				postId = posts.insert(postData)
			end
			
			isPlain = highlightingGroup == PastebinForm::NoHighlighting
			if isPlain
				highlightedContent = nil
				pasteType = nil
			else
				highlightedContent = SyntaxHighlighting::highlight(syntaxHighlighting, content)
				pasteType = syntaxHighlighting
			end
			
			unitData =
			{
				post_id: postId,
				
				description: unitDescription,
				content: content,
				
				highlighted_content: highlightedContent,
				
				paste_type: pasteType
			}
			
			if editing
				#increase the modification counter for the unit, too
				unitData[:modification_counter] = editPost.activeUnit.modificationCounter + 1
				unitData[:last_modification] = now
				units.where(id: editUnitId).update(unitData)
			else
				unitData[:time_added] = now
				units.insert(unitData)
			end
			
			if privateString == nil
				postPath = @viewPostHandler.getPath(postId)
			else
				postPath = @viewPrivatePostHandler.getPath(privateString)
			end
			
			reply = WWWLib::HTTPReply.localRefer(request, postPath)
			
			if useSyntaxHighlighting
				[
					[:PastebinMode, highlightingSelectionMode.to_s],
					[:VimScript, syntaxHighlighting]
				].each do |symbol, value|
					name = CookieConfiguration.const_get(symbol)
					cookie = @site.getCookie(name, value)
					reply.addCookie(cookie)
				end
			else
				[
					:PastebinMode,
					:VimScript
				].each do |symbol|
					name = CookieConfiguration.const_get(symbol)
					reply.deleteCookie(name, @site.mainHandler.getPath)
				end
			end
			
			return reply
		end
	end

	def getRequestId(request)
		arguments = request.arguments
		id = WWWLib.readId(arguments[0])
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
			page = WWWLib.readId(arguments[0]) - 1
		end
		
		@database.transaction do
			dataset = @database[:pastebin_post]
			postsPerPage = PastebinConfiguration::PostsPerPage
			posts = dataset.where(private_string: nil, reply_to: nil)
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
			units = @database[:pastebin_unit]
			units.where(id: unitId).delete
			unitCount = units.where(post_id: postId).count
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
	
	def writePermissionCheck(request, post)
		raiseError(permissionError, request) if !hasWriteAccess(request, post)
	end
	
	def submitUnitModification(request)
		return processNewPostOrModification(request, true)
	end
end
