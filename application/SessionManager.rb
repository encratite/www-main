require 'site/random'
require 'configuration/site'
require 'configuration/cookie'
require 'User'

class SessionManager
	def initialize(database)
		@database = database
	end
	
	def getSessionUser(request)
		@database.transaction do
			cookie = request.cookies[CookieConfiguration::Session]
			return nil if cookie == nil
			cleanSessions
			result = @database[:login_session].filter(session_string: cookie, ip: request.address).join(getTableSymbol(:User), id: :user_id).first
			return nil if result == nil
			return User.new result
		end
	end
	
	def cleanSessions
		@database.run "delete from login_session where session_begin + interval '#{SiteConfiguration::SessionDurationInDays} days' < now()"
	end
	
	def generateSessionString
		dataset = @database[:login_session]
		while true
			sessionString = RandomString.get SiteConfiguration::SessionStringLength
			break if dataset.where(session_string: sessionString).count == 0
		end
		return sessionString
	end
	
	def createSession(userId, address)
		sessionString = generateSessionString
		dataset = @database[:login_session]
		dataset.insert(user_id: userId, session_string: sessionString, ip: address)
		return sessionString
	end
end
