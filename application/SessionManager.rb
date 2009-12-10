require 'site/Session'
require 'configuration/site'
require 'configuration/cookie'
require 'database'
require 'User'

class SessionManager
	def getSessionUser(request)
		$database.transaction do
			cookie = request.cookies[CookieConfiguration::Session]
			return nil if cookie == nil
			cleanSessions
			result = getDataset(:LoginSession).filter(session_string: cookie, ip: request.address).join(getTableSymbol(:User), id: :user_id).first
			return nil if result == nil
			return User.new result
		end
	end
	
	def cleanSessions
		$database.run "delete from login_session where session_begin + interval '#{SiteConfiguration::SessionDurationInDays} days' < now()"
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
