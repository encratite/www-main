require 'SiteContainer'
require 'PastebinForm'

class PastebinHandler < SiteContainer
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
end
