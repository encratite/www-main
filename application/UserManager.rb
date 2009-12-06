require 'site/Session'
require 'configuration/site'
require 'database'

class UserManager
	def isLoggedIn?(request)
		$database.transaction do
			cleanSessions
			dataset = getDataset :LoginSession
			dataset
		end
		return false
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
	
	def createSession(userId, request, duration)
		sessionString = generateSessionString
		
	end
end
