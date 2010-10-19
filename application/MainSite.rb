require 'SessionManager'
require 'MainSiteGenerator'
require 'SiteRequest'
require 'hash'
require 'error'
require 'SecuredFormWriter'

require 'sequel'

require 'configuration/loader'
requireConfiguration 'database'
requireConfiguration 'site'

require 'www-library/RequestManager'
require 'www-library/RequestHandler'

class MainSite
	attr_accessor :requestManager, :mainHandler
	
	def initialize
		@database = getDatabaseObject
		@sessionManager = SessionManager.new @database
		
		@requestManager = WWWLib::RequestManager.new(lambda { |environment| SiteRequest.new(@sessionManager, environment) } )
		@mainHandler = WWWLib::RequestHandler.new('main')
		@requestManager.addHandler @mainHandler
		
		@generator = getSiteGenerator
		@pastebinGenerator = getSiteGenerator(['pastebin'], ['pastebin'])
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
	
	def getCookie(name, value)
		sessionCookie = Cookie.new(name, value, mainHandler.getPath)
		sessionCookie.expirationDays SiteConfiguration::CookieDurationInDays
		return sessionCookie
	end
	
	def getStaticPath(base, file)
		return @mainHandler.getPath(SiteConfiguration::StaticDirectory, base, file)
	end

	def getStylesheet(name)
		getStaticPath(SiteConfiguration::StylesheetDirectory, name + '.css')
	end

	def getImage(file)
		getStaticPath(SiteConfiguration::ImageDirectory, file)
	end

	def getScript(name)
		getStaticPath(SiteConfiguration::ScriptDirectory, name + '.js')
	end
end
