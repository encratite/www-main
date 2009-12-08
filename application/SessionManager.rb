require 'site/Session'
require 'configuration/site'
require 'configuration/cookie'
require 'database'
require 'htmlentities'

class SessionManager
	def initialize
		@htmlCoder = HTMLEntities.new
	end
	
	def getSessionUser(request)
		$database.transaction do
			cookie = request.cookies[CookieConfiguration::Session]
			return nil if cookie == nil
			cleanSessions
			result = getDataset(:LoginSession).filter(session_string: cookie, ip: request.address).join(getTableSymbol(:User), user_id: id).all
			return nil if result.size == 0
			output = result[0]
			output.name = @htmlCoder.encode output.name
			return output
		end
	end
	
	def cleanSessions
		$database.run "delete from login_session where session_begin + interval '#{SessionDurationInDays} days' > now()"
	end
	
	def generateSessionString
		dataset = getDataset :LoginSession
		while true
			sessionString = SessionString.get SiteConfiguration::SessionStringLength
			break if dataset.where(session_string: sessionString).count == 0
		end
		sessionString
	end
	
	def createSession(userId, address)
		sessionString = generateSessionString
		dataset = getDataset :LoginSession
		dataset.insert(user_id: userId, session_string: sessionString, ip: address)
		sessionString
	end
end
