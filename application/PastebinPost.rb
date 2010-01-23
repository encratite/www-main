require 'User'
require 'error'

require 'site/HTMLWriter'
require 'site/SymbolTransfer'

class PastebinPost < SymbolTransfer
	AnonymousAuthor = 'Anonymous'
	NoDescription = 'No description'
	
	attr_reader :units, :isAnonymous, :noDescription
	
	def initialize(target, request, database)
		dataset = database[:pastebin_post]
		
		if target.class == String
			postData = dataset.where(anonymous_string: target)
		else
			postData = dataset.where(id: target, anonymous_string: nil)
		end
		
		pastebinError('You have specified an invalid post identifier.', request) if postData.empty?
		
		postData = postData.first
		transferSymbols postData
		
		if @userId == nil
			@user = nil
		else
			dataset = database[:site_user]
			userData = datast.where(id: @userId)
			internalError 'Unable to retrieve the user associated with this post.' if userData.empty?
			@user = User.new(userData.first)
		end
		
		dataset = database[:pastebin_unit]
		unitData = dataset.where(post_id: @id)
		internalError 'No units are associated with this post.' if unitData.empty?
		
		@units = []
		unitData.each { |unit| @units << PastebinUnit.new(unit) }
		
		@author = @author || @user.name
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
