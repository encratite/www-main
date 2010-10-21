require 'User'
require 'PastebinHandler'
require 'PastebinUnit'
require 'error'
require 'string'

require 'www-library/SymbolTransfer'

class PastebinPost < WWWLib::SymbolTransfer
	AnonymousAuthor = 'Anonymous'
	NoDescription = 'No description'
	
	attr_reader :id, :userId, :user, :units, :name, :isAnonymous, :author, :bodyAuthor, :noDescription, :description, :bodyDescription, :pasteType, :creation, :contentSize, :ip, :activeUnit, :modificationCounter, :expiration, :expirationIndex, :privateString
	
	attr_accessor :pasteTypes, :isPrivate
	
	def initialize
		@bodyAuthor = ''
		@bodyDescription = ''
	end
	
	def simpleInitialisation(id, database)
		@id = id
		posts = database[:pastebin_post]
		#just select all the fields for now, it's too much of a mess otherwise
		#the data per row are rather small anyways, the actual problem is the content within the units
		postData = posts.where(id: id)
		argumentError if postData.empty?
		transferSymbols postData.first
		initialiseMembers false
		return
	end
	
	def deletePostQueryInitialisation(id, database)
		simpleInitialisation(id, database)
		return
	end
	
	def unitInitialisation(unitId, database, fields, fullUnitInitialisation = true)
		units = database[:pastebin_unit]
		row = units.where(id: unitId).select(*fields)
		argumentError if row.empty?
		unitData = row.first
		unitData[:id] = unitId
		@activeUnit = PastebinUnit.new(unitData, fullUnitInitialisation)
		postId = @activeUnit.postId
		simpleInitialisation(postId, database)
		return postId
	end
	
	def deleteUnitQueryInitialisation(unitId, database)
		return unitInitialisation(unitId, database, [:post_id, :description, :paste_type])
	end
	
	def editUnitQueryInitialisation(unitId, database)
		return unitInitialisation(unitId, database, [:post_id, :description, :content, :paste_type])
	end
	
	def editPermissionQueryInitialisation(unitId, database)
		output = unitInitialisation(unitId, database, [:post_id, :modification_counter], false)
		@isPrivate = @privateString != nil
		return output
	end
	
	def showPostQueryInitialisation(target, handler, request, database)
		dataset = database[:pastebin_post]
		
		if target.class == String
			postData = dataset.where(private_string: target)
		else
			postData = dataset.where(id: target, private_string: nil)
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
		#unit ID will be transferred from the select * query
		unitData.each { |unit| @units << PastebinUnit.new(unit) }
		
		return
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
		
		@isPrivate = !@privateString.nil?
		
		return
	end
end

