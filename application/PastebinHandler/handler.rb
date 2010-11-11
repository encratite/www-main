require 'SiteContainer'
require 'PastebinForm'

class PastebinHandler < SiteContainer
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
	
	def createNewPost(request)
		form = PastebinForm.new(request)
		form.mode = :new
		return @pastebinGenerator.get(['Pastebin', pastebinForm(form)], request)
	end
	
	def createReply(request, isPrivate, target)
		#check if the target is valid
		if isPrivate
			posts = @posts.where(private_string: target)
		else
			posts = @posts.where(id: target, private_string: nil)
		end
		mode = :reply
		posts = posts.all
		argumentError if posts.empty?
		replyPost = PastebinPost.new
		replyPost.transferSymbols(posts.first)
		form = PastebinForm.new(request)
		form.mode = mode
		form.replyPost = replyPost
		return @pastebinGenerator.get(['Reply to post', pastebinForm(form)], request)
	end
	
	def submitNewPost(request)
		return processPostSubmission(request, :new)
	end
	
	def submitUnitModification(request, isPrivate, target)
		return processPostSubmission(request, :edit, isPrivate, target)
	end
	
	def submitReply(request, isPrivate, target)
		return processPostSubmission(request, :reply, isPrivate, target)
	end
	
	def viewPost(request)
		return processPostView(request, false)
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
	
	def download(request, isPrivate, target)
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
				argumentError
			end
			#return the actual code as plain text
			reply = WWWLib::HTTPReply.new(unitContent)
			reply.plain
			return reply
		end
	end
end
