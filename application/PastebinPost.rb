require 'User'
require 'error'

class PastebinPost
	def initialize(target)
		dataset = getDataset :PastebinPost
		
		if target.class == String
			postData = dataset.where(anonymous_string: target)
			
		else
			postData = dataset.where(id: target, anonymous_string: nil)
		end
		
		pastebinError 'You have specified an invalid post identifier.' if postData.empty?
		
		postData = postData.first
		postId = postData[:id]
		
		userId = postData[:user_id]
		if userId == nil
			@user = nil
		else
			dataset = getDataset :SiteUser
			userData = datast.where(id: userId)
			internalError 'Unable to retrieve the user associated with this post.' if userData.empty?
			@user = User.new(userData.first)
		end
		
		dataset = getDataset :PastebinUnit
		unitData = dataset.where(post_id: postId)
		internalError 'No units are associated with this post.' if unitData.empty?
	end
end
