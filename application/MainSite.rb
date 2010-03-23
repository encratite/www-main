require 'IndexHandler'
require 'PastebinHandler'
require 'UserHandler'

require 'SessionManager'
require 'MainSiteGenerator'
require 'static'
require 'SiteRequest'
require 'hash'
require 'error'
require 'SecuredFormWriter'

require 'environment'

require 'configuration/database'

require 'site/RequestManager'
require 'site/SiteGenerator'
require 'site/RequestHandler'

require 'sequel'

class MainSite
	attr_accessor :requestManager, :mainHandler
	
	def initialize
		@database = getDatabaseObject
		@sessionManager = SessionManager.new @database
		@requestManager = RequestManager.new(lambda { |environment| SiteRequest.new(@sessionManager, environment) } )
		@generator = getSiteGenerator
		@pastebinGenerator = getSiteGenerator(['pastebin'], ['pastebin'])
		
		@prefix = 'main'
	end
	
	def getDatabaseObject
		database =
		Sequel.connect(
			adapter: DatabaseConfiguration::Adapter,
			host: DatabaseConfiguration::Host,
			user: DatabaseConfiguration::User,
			password: DatabaseConfiguration::Password,
			database: DatabaseConfiguration::Database
		)
		return database
	end
	
	def getSiteGenerator(stylesheets = [], scripts = [])
		stylesheets = ['base'] + stylesheets
		scripts = ['hash'] + scripts
		output = MainSiteGenerator.new @requestManager
		stylesheets.each { |path| output.addStylesheet(getStylesheet path) }
		scripts.each { |script| output.addScript(getScript script) }
		return output
	end
end
