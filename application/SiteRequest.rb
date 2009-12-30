require 'site/HTTPRequest'
require 'HashFormWriter'

class SiteRequest < HTTPRequest
	attr_accessor :sessionUser
	
	def initialize(environment)
		super environment
		@sessionUser = $sessionManager.getSessionUser self
	end
	
	def postIsSet(names)
		return true if @postInput[HashFormWriter::Security] != nil
		return super(names)
	end
end
