class PostTree
	attr_reader :root
	
	def initialize(database, post)
		@database = database
		createTree(post)
	end
	
	def createTree(post)
		rootPost = getRootPost(post)
		rootPost.loadChildren
		@root = rootPost
	end
	
	def getRootPost(post)
		parent = post.replyTo
		if parent == nil
			return post
		end
		
		posts = @database.post.where(id: parent).all
		if posts.empty?
			raise "Unable to find the parent of post #{post.id}!"
		end
		
		hash = posts.first
		parent = PastebinPost.new(@database)
		parent.transferSymbols(hash)
		parent.initialiseMembers
		output = getRootPost(parent)
		return output
	end
end
