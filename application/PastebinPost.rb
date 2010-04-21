require 'User'
require 'PastebinHandler'
require 'error'
require 'string'

require 'site/HTMLWriter'
require 'site/SymbolTransfer'

class PastebinPost < SymbolTransfer
	AnonymousAuthor = 'Anonymous'
	NoDescription = 'No description'
	
	attr_reader :userId, :user, :units, :name, :isAnonymous, :author, :bodyAuthor, :noDescription, :description, :bodyDescription, :pasteType, :creation, :contentSize, :ip, :unitToDelete
	
	attr_accessor :pasteTypes
	
	def simpleInitialisation(id, database)
		dataset = database[:pastebin_post]
		postData = dataset.where(id: id).select(:user_id, :ip, :description)
		argumentError if postData.empty?
		transferSymbols postData.first
		initialiseMembers false
		return nil
	end
	
	def deletePostQueryInitialisation(id, database)
		simpleInitialisation(id, database)
		return nil
	end
	
	def deleteUnitQueryInitialisation(id, database)
		units = database[:pastebin_unit]
		unitData = dataset.where(id: id).select(:post_id, :description, :post_type)
		argumentError if unitData.empty?
		unitToDelete = PastebinUnit.new(unitData.first)
		postId = unitData.postId
		simpleInitialisation(postId, database)
		return postId
	end
	
	def showPostQueryInitialisation(target, handler, request, database)
		dataset = database[:pastebin_post]
		
		if target.class == String
			postData = dataset.where(anonymous_string: target)
		else
			postData = dataset.where(id: target, anonymous_string: nil)
		end
		
		handler.pastebinError('You have specified an invalid post identifier.', request) if postData.empty?
		
		postData = postData.first
		transferSymbols postData
		
		if @userId != nil
			dataset = database[:site_user]
			userData = dataset.where(id: @userId)
			internalError 'Unable to retrieve the user associated with this post.' if userData.empty?
			@user = User.new(userData.first)
		end
		
		initialiseMembers
		
		dataset = database[:pastebin_unit]
		unitData = dataset.where(post_id: @id)
		internalError 'No units are associated with this post.' if unitData.empty?
		unitData.each { |unit| @units << PastebinUnit.new(unit) }
		
		return nil
	end
	
	def initialiseMembers(fullMode = true)
		if fullMode
			if @userId == nil
				@user = nil
			end
			
			@pasteTypes = []
			
			if @author == nil
				if @user != nil
					@author = @user.name
				elsif @name != nil
					#name from the post listing joins
					@author = @name
				end
			end
			@isAnonymous = @author.empty?
			processDescription(@isAnonymous, @author, @bodyAuthor, AnonymousAuthor)
		end
		
		@noDescription = @description.empty?
		processDescription(@noDescription, @description, @bodyDescription, NoDescription)
		
		@units = []
		
		return nil
	end
end

