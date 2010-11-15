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
		new = mode == :new
		editing = mode == :edit
		replying = mode == :reply
		addingUnit = mode == :addUnit
		modifyingPost = editing || addingUnit
		
		sourceMap =
		{
			new: :NewSubmissionPostFields,
			edit: :EditPostFields,
			reply: :ReplyPostFields,
			addUnit: :AddUnitPostFields,
		}
		
		sourceSymbol = sourceMap[mode]
		raise 'Invalid process submission mode specified' if sourceSymbol == nil
		source = PastebinForm.const_get(sourceSymbol)
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
		expirationIndex = getIntPost(request, :Expiration)
		
		#for private submissions
		privateString = getPostValue(request, :PrivateString)
		
		isPrivate = privateString != nil
		
		stringLengthChecks = getStringLengthChecks(author, postDescription, unitDescription, content, expertHighlighting)
		
		errors = []
		
		validValues = getValidValues(highlightingGroup, privatePost, expirationIndex)
		
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
				form.isPrivate = isPrivate
				form.expirationIndex = expirationIndex
				form.editUnitId = editUnitId
				if modifyingPost
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
			
			postData =
			{
				user_id: postUser,
				
				author: postAuthor,
				ip: request.address,
				
				description: postDescription,
			}
			
			useReplyId = lambda { |id| postData[:reply_to] = id }
			
			case mode
			
			when :new
				useReplyId.call(nil)
				
			when :edit
				#check if the unit ID is valid and determine the post associated with it
				editUnitId = getIntPost(request, :EditUnitId)
				argumentError if editUnitId == nil
				editPost = PastebinPost.new(@database)
				editPost.editPermissionQueryInitialisation(isPrivate, editUnitId)
				argumentError if privateString != editPost.privateString
				writePermissionCheck(request, editPost)
				useReplyId.call(editPost.replyTo)
				
			when :reply
				target = isPrivate ? privateString : getPostInt(request, :ReplyPostId)
				argumentError if target == nil
				parentPost = PastebinPost.new(@database)
				parentPost.postInitialisation(isPrivate, target)
				useReplyId.call(parentPost.id)
				
			when :addUnit
				target = isPrivate ? privateString : getPostInt(request, :ReplyPostId)
				argumentError if target == nil
				addUnitPost = PastebinPost.new(@database)
				addUnitPost.postInitialisation(isPrivate, target)
			end
			
			editingPrimaryPost = modifyingPost && editPost.replyTo == nil
			argumentError if editingPrimaryPost && [privatePost, expirationIndex].include?(nil)
			
			privateString = nil
			
			if new || editingPrimaryPost
				expirationTime = now + PastebinConfiguration::ExpirationOptions[expirationIndex][1]
				postExpiration = expirationIndex == 0 ? nil : expirationTime
			
				postData[:expiration] = postExpiration
				postData[:expiration_index] = expirationIndex
				
				isPrivate = privatePost == 1
				privateString = isPrivate ? getPrivateString : nil
			end
			
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
				
			if modifyingPost
				#increase the modification counter
				postData[:modification_counter] = editPost.modificationCounter + 1
				postData[:last_modification] = now
				postId = editPost.id
				@posts.where(id: postId).update(postData)
			else
				if replying
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
			
			postPath = post.getPostPath(@viewPostHandler)
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
