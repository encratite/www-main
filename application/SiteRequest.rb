require 'site/HTTPRequest'

class SiteRequest < HTTPRequest
	attr_accessor :sessionUser
	
	def initialize(environment)
		super environment
		@sessionUser = $sessionManager.getSessionUser self
	end
end
