require 'index'
require 'userAccount'
require 'SessionManager'
require 'Menu'
require 'PathMap'
require 'MainSiteGenerator'
require 'static'
require 'SiteRequest'
require 'pastebin'

require 'environment'

require 'configuration/database'

require 'site/RequestManager'
require 'site/SiteGenerator'
require 'site/RequestHandler'

require 'sequel'

class MainSite
	def initialize
		@database = getDatabaseObject
		@menu = createMenu
		@sessionManager = SessionManager.new
		@requestManager = RequestManager.new SiteRequest
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
		output = MainSiteGenerator.new
		stylesheets.each { |path| output.addStylesheet(getStylesheet path) }
		scripts.each { |script| output.addScript(getScript script) }
		output
	end
end
