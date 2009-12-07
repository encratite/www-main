require 'site/HTTPRequest'

class SiteRequest < HTTPRequest
	attr_reader :sessionUser
	
	def initialize(request)
		symbols = [:@path, :@pathString, :@method, :@accept, :@address, :@getInput, :@postInput, :@cookies, :@environment]
		symbols.each { |symbol| instance_variable_set(symbol, request.instance_variable_get(symbol)) }
		@sessionUser = $sessionManager.getSessionUser request
	end
end
