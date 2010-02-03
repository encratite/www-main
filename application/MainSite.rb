require 'IndexHandler'
require 'PastebinHandler'
require 'UserHandler'

require 'SessionManager'
require 'Menu'
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
	attr_accessor :requestManager
	
	def initialize
		@database = getDatabaseObject
		@menu = Menu.new
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
		output = MainSiteGenerator.new @menu
		stylesheets.each { |path| output.addStylesheet(getStylesheet path) }
		scripts.each { |script| output.addScript(getScript script) }
		output
	end
	
	def processFormFields(request, names)
		randomString = request.getPost(SecuredFormWriter::RandomString)
		formHash = request.getPost(SecuredFormWriter::HashField)
		
		fields = names.map { |name| request.getPost(name) }
		fieldError if fields.include?(nil) || randomString == nil || formHash == nil
		
		addressHash = fnv1a(request.address)
		
		input = randomString + addressHash
		hash = fnv1a(input)
		if hash != formHash
			raise RequestManager::Exception.new(@generator.get(hashError, request))
		end
		
		return fields
	end
end
