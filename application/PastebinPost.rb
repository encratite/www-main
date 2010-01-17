require 'User'
require 'error'

require 'site/SymbolTransfer'

class PastebinPost < SymbolTransfer
	attr_reader :units
	
	def initialize(target, request)
		dataset = getDataset :PastebinPost
		
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
			dataset = getDataset :SiteUser
			userData = datast.where(id: @userId)
			internalError 'Unable to retrieve the user associated with this post.' if userData.empty?
			@user = User.new(userData.first)
		end
		
		dataset = getDataset :PastebinUnit
		unitData = dataset.where(post_id: @id)
		internalError 'No units are associated with this post.' if unitData.empty?
		
		@units = []
		unitData.each { |unit| @units << PastebinUnit.new(unit) }
	end
end

class PastebinUnit < SymbolTransfer
	def initialize(input)
		transferSymbols(input, {}, [:highlightingStyle, :highlightedContent])
	end
end
