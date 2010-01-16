require 'site/HTTPRequest'
require 'SecuredFormWriter'

class SiteRequest < HTTPRequest
	attr_accessor :sessionUser
	
	def initialize(environment)
		super environment
		@sessionUser = $sessionManager.getSessionUser self
	end
	
	def postIsSet(names)
		return true if @postInput[SecuredFormWriter::Security] != nil
		return super(names)
	end
end
