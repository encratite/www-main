require 'User'
require 'error'

require 'site/HTMLWriter'
require 'site/SymbolTransfer'

class PastebinPost < SymbolTransfer
	AnonymousAuthor = 'Anonymous'
	NoDescription = 'No description'
	
	attr_reader :userId, :user, :units, :name, :isAnonymous, :author, :bodyAuthor, :noDescription, :description, :bodyDescription, :pasteType, :creation
	
	attr_accessor :pasteTypes
	
	def queryInitialisation(target, handler, request, database)
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
	
	def initialiseMembers
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
		if @isAnonymous
			@author = AnonymousAuthor
			@bodyAuthor = markString @author
		else
			@bodyAuthor = @author
		end
		
		@noDescription = @description.empty?
		if @noDescription
			@description = NoDescription
			@bodyDescription = markString @description
		else
			@bodyDescription = @description
		end
		
		@units = []
		
		return nil
	end
	
	def markString(input)
		output = ''
		writer = HTMLWriter.new output
		writer.i { input }
		return output
	end
end

class PastebinUnit < SymbolTransfer
	def initialize(input)
		transferSymbols(input, {}, [:highlightingStyle, :highlightedContent])
	end
end
