require 'www-library/random'

require 'configuration/loader'
requireConfiguration 'site'
requireConfiguration 'cookie'

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
      result = @database.loginSession.filter(session_string: cookie, ip: request.address).join(:site_user, id: :user_id).first
      return nil if result == nil
      return User.new result
    end
  end

  def cleanSessions
    @database.connection.run "delete from login_session where session_begin + interval '#{SiteConfiguration::CookieDurationInDays} days' < now()"
  end

  def generateSessionString
    while true
      sessionString = WWWLib::RandomString.get(SiteConfiguration::SessionStringLength)
      break if @database.loginSession.where(session_string: sessionString).count == 0
    end
    return sessionString
  end

  def createSession(userId, address)
    sessionString = generateSessionString
    @database.loginSession.insert(user_id: userId, session_string: sessionString, ip: address)
    return sessionString
  end
end
