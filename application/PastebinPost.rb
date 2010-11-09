require 'User'
require 'PastebinHandler'
require 'PastebinUnit'
require 'error'
require 'string'

require 'visual/highlight'

require 'www-library/SymbolTransfer'

class PastebinPost < WWWLib::SymbolTransfer
	AnonymousAuthor = 'Anonymous'
	NoDescription = 'No description'
	
	attr_reader(
		:id,
		:userId,
		:user,
		:units,
		:name,
		:author,
		:bodyAuthor,
		:noDescription,
		:description,
		:bodyDescription,
		:pasteType,
		:creation,
		:contentSize,
		:ip,
		:activeUnit,
		:modificationCounter,
		:expiration,
		:expirationIndex,
		:privateString,
		:editAuthor,
		:replyTo,
		:children,
	)
	
	attr_accessor :pasteTypes, :isPrivate
	
	def initialize
		@bodyAuthor = ''
		@bodyDescription = ''
		#used by PostTree
		@children = []
	end
	
	def simpleInitialisation(id, database, fullPostInitialisation)
		@id = id
		#just select all the fields for now, it's too much of a mess otherwise
		#the data per row are rather small anyways, the actual problem is the content within the units
		postData = database.post.where(id: id)
		argumentError if postData.empty?
		transferSymbols postData.first
		initialiseMembers(fullPostInitialisation)
		return
	end
	
	def deletePostQueryInitialisation(id, database)
		simpleInitialisation(id, database, false)
		return
	end
	
	def unitInitialisation(unitId, database, fields, fullPostInitialisation = false, fullUnitInitialisation = true)
		row = database.unit.where(id: unitId).select(*fields)
		argumentError if row.empty?
		unitData = row.first
		unitData[:id] = unitId
		@activeUnit = PastebinUnit.new(unitData, fullUnitInitialisation)
		postId = @activeUnit.postId
		simpleInitialisation(postId, database, fullPostInitialisation)
		return postId
	end
	
	def deleteUnitQueryInitialisation(unitId, database)
		return unitInitialisation(unitId, database, [:post_id, :description, :paste_type])
	end
	
	def editUnitQueryInitialisation(unitId, database)
		return unitInitialisation(unitId, database, [:post_id, :description, :content, :paste_type], true)
	end
	
	def editPermissionQueryInitialisation(unitId, database)
		output = unitInitialisation(unitId, database, [:post_id, :modification_counter], false, false)
		@isPrivate = @privateString != nil
		return output
	end
	
	def showPostQueryInitialisation(target, handler, request, database)
		dataset = database.post
		
		if target.class == String
			postData = dataset.where(private_string: target)
		else
			postData = dataset.where(id: target, private_string: nil)
		end
		
		handler.pastebinError('You have specified an invalid post identifier.', request) if postData.empty?
		
		postData = postData.first
		transferSymbols postData
		
		if @userId != nil
			userData = database.user.where(id: @userId)
			internalError 'Unable to retrieve the user associated with this post.' if userData.empty?
			@user = User.new(userData.first)
		end
		
		initialiseMembers
		
		unitData = database.unit.where(post_id: @id)
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
				@editAuthor = nil
				if @user != nil
					@author = @user.name
				elsif @name != nil
					#name from the post listing joins
					@author = @name
				end
				@bodyAuthor = makeBold @author
			else
				#the dup is necessary because the editAuthor field would get ruined by the processDescription down there otherwise
				@editAuthor = @author.dup
				isAnonymous = @author.empty?
				processDescription(isAnonymous, @author, @bodyAuthor, AnonymousAuthor)
			end
		end
		
		@noDescription = @description.empty?
		processDescription(@noDescription, @description, @bodyDescription, NoDescription)
		
		@units = []
		
		@isPrivate = !@privateString.nil?
		
		return
	end
	
	def loadChildren(database)
		puts "Loading children of ID #{@id}"
		children = database.post.where(reply_to: @id).all
		children.each do |child|
			childPost = PastebinPost.new
			childPost.transferSymbols(child)
			childPost.initialiseMembers
			#perform depth first search
			childPost.loadChildren(database)
			@children << childPost
		end
		#sort the children according to their age so the oldest ones pop up first in the post tree output
		@children.sort do |a, b|
			a.creation <=> b.creation
		end
		
		return
	end
end

