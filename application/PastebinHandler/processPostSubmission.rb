require 'PastebinForm'
require 'error'
require 'SyntaxHighlighting'
require 'PastebinPost'
require 'SiteContainer'

require 'configuration/loader'
requireConfiguration 'pastebin'
requireConfiguration 'cookie'

require 'www-library/HTTPReply'

class PastebinHandler < SiteContainer
	#mode may be either :new (for new posts), :edit (for submitting modifications for existing posts) or :reply (for new replies to existing posts)
	def processPostSubmission(request, mode)
		editing = isEditMode(mode)
		replying = isReplyMode(mode)
		addingUnit = isAddUnitMode(mode)
		
		if editing
			#check if the unit ID is valid and determine the post associated with it
			#right now the ID of the unit to be edited is the last field - could be changed by PastebinForm though, so watch out
			editUnitId = request.getPost(PastebinForm::EditUnitId).to_i
			editPost = PastebinPost.new
			editPost.editPermissionQueryInitialisation(editUnitId, @database)
			if mode == :privateEdit
				#check if the private string specified in the post matches
				#doesn't matter if it returns nil
				requestPrivateString = request.getPost(PastebinForm::EditPrivateString)
				argumentError if requestPrivateString != editPost.privateString
			end
			writePermissionCheck(request, editPost)
		end
		
		editingPrimaryPost = (editing && editPost.replyTo == nil)
		
		case mode
		when :new
			source = PastebinForm::NewSubmissionPostFields
		when :edit
			source = editingPrimaryPost ?
				PastebinForm::EditPostFields :
				PastebinForm::EditReplyPostFields
		when :privateEdit
			source = editingPrimaryPost ?
				PastebinForm::EditPrivatePostFields :
				PastebinForm::EditPrivateReplyPostFields
		when :reply
			source = PastebinForm::ReplyPostFields
		when :privateReply
			source = PastebinForm::PrivateReplyPostFields
		else
			raise 'Invalid process submission mode specified'
		end
		
		input = processFormFields(request, source)

		#CommonPostFields
		author,
			
		postDescription,
		
		highlightingGroup,
		
		commonHighlighting,
		advancedHighlighting,
		expertHighlighting,
		
		unitDescription,
		
		content = input
		
		#CreationPostFields - only available with mode == :new and mode == :edit of a post with reply_to = NULL
		privatePost = getIntPost(request, :PrivatePost)
		expiration = getIntPost(request, :Expiration)
		
		stringLengthChecks = getStringLengthChecks(author, postDescription, unitDescription, content, expertHighlighting)
		
		errors = []
		
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
			
			isPrivatePost = nil
			expirationIndex = expiration
			
			case mode
			when :new
				editUnitId = nil
			when :reply, :privateReply
				replyPostId = request.getPost(PastebinForm::ReplyPostId).to_i
				if mode == :reply
					#check if the user is replying to a valid post ID only
					rows = @posts.where(id: replyPostId, private_string: nil).all
				else
					#check if the user is replying to a valid combination of post ID and private string
					replyPostPrivateString = getPostValue(request, :ReplyPrivateString)
					rows = @posts.where(private_string: replyPostPrivateString).all
				end
				argumentError if rows.empty?
				parentPost = PastebinPost.new
				parentPost.transferSymbols(rows.first)
				parentPost.initialiseMembers
				replyPostId = parentPost.id
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
				if editing
					form.editPost = editPost
				elsif replying
					form.replyPost = parentPost
				end
				form.mode = mode
				errorContent = pastebinForm(form)
				#this raises an exception
				pastebinError(errorContent, request)
			end
			
			now = Time.now.utc

			isLoggedIn = request.sessionUser != nil
			
			postUser = isLoggedIn ? request.sessionUser.id : nil
			postAuthor = !isLoggedIn ? author : nil
			if replying
				postReply = replyPostId
			else
				if editing
					postReply = editPost.replyTo
				else
					#new post
					postReply = nil
				end
			end

			postData =
			{
				user_id: postUser,
				
				author: postAuthor,
				ip: request.address,
				
				description: postDescription,
				
				reply_to: postReply,
			}
			
			if mode == :new || editingPrimaryPost
				expirationTime = now + PastebinConfiguration::ExpirationOptions[expiration][1]
				postExpiration = expiration == 0 ? nil : expirationTime
			
				postData[:expiration] = postExpiration
				postData[:expiration_index] = expirationIndex
				
				isPrivate = privatePost == 1
				privateString = isPrivate ? getPrivateString : nil
			end

			if editing
				if editingPrimaryPost
					if editPost.isPrivate
						if isPrivate
							#the post remains private - reuse its private string in the refer(r)al
							privateString = editPost.privateString
						else
							#the post was previously private and is now public
							#this means that all its replies must now be made public, too
							updatePostTreeVisibility(editPost.id, false)
						end
					else
						if isPrivate
							#the post was previously public and is now private
							#this means that all its replies must now be made private, too
							updatePostTreeVisibility(editPost.id, true)
						else
							#the post remains public - no need to do anything
						end
					end
					
					postData[:private_string] = privateString
				end
				#increase the modification counter
				postData[:modification_counter] = editPost.modificationCounter + 1
				postData[:last_modification] = now
				postId = editPost.id
				@posts.where(id: postId).update(postData)
			else
				case mode
				when :reply
					privateString = parentPost.privateString
				when :privateReply
					privateString = parentPost.isPrivate ? getPrivateString : nil
				end
				postData[:private_string] = privateString
				postData[:creation] = now
				postId = @posts.insert(postData)
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
				
				paste_type: pasteType,
			}
			
			if editing
				#increase the modification counter for the unit, too
				unitData[:modification_counter] = editPost.activeUnit.modificationCounter + 1
				unitData[:last_modification] = now
				@units.where(id: editUnitId).update(unitData)
			else
				unitData[:time_added] = now
				@units.insert(unitData)
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
end
