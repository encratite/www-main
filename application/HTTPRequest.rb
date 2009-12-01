require 'cgi'

class HTTPRequest
	attr_reader :path, :method, :accept
	def initialize(environment)
		pathTokens = environment['REQUEST_PATH'].split('/')[1..-1]
		@path = pathTokens.map { |token| CGI.unescape(token) }
		
		requestMethods =
		{
			'GET' => :get,
			'POST' => :post
		}
		
		@method = requestMethods[environment['REQUEST_METHOD']]
		
		@accept = []
		environment['HTTP_ACCEPT'].split(', ').each do |token|
			@accept <<= token.split(';')[0]
		end
	end
end
