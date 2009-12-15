$:.concat ['..', 'application']

def loadModules
	require 'sequel'
	
	prefix = 'site'
	siteFiles =
	[
		'RequestManager',
		'SiteGenerator',
		'RequestHandler',
	]
	
	siteFiles.each { |name| require "#{prefix}/#{name}" }

	require 'configuration/database'

	applicationFiles =
	[
		'index',
		'userAccount',
		'SessionManager',
		'Menu',
		'PathMap',
		'MainSiteGenerator',
		'static',
		'SiteRequest',
		'pastebin',
		
		'environment'
	]

	applicationFiles.each { |name| require name }
end

def createRequestManager
	handlers =
	[
		[:Index, :getIndex],
		[:Login, :loginFormRequest],
		[:SubmitLogin, :performLoginRequest],
		[:Register, :registerFormRequest],
		[:SubmitRegistration, :performRegistrationRequest],
		[:Logout, :logoutRequest],
		[:Pastebin, :newPastebinPost],
	]

	requestManager = RequestManager.new SiteRequest
	handlers.each do |arguments|
		pathSymbol, handlerSymbol = arguments
		path = PathMap.getPath pathSymbol
		handler = method handlerSymbol
		argumentCount = arguments.size > 2 ? arguments[2] : nil
		requestHandler = RequestHandler.new(path, handler, argumentCount)
		requestManager.addHandler requestHandler
	end
	
	requestHandler = RequestHandler.new('/main/environment', method(:visualiseEnvironment), 0)
	requestManager.addHandler requestHandler
	
	return requestManager
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

def createMenu
	menu = Menu.new
	
	loggedIn = lambda { |request| request.sessionUser != nil }
	notLoggedIn = lambda { |request| request.sessionUser == nil }
	
	items =
	[
		[:Index],
		[:Login, notLoggedIn],
		[:Register, notLoggedIn],
		[:Pastebin],
		[:Logout, loggedIn],
	]
	
	items.each do |item|
		condition = item.size > 1 ? item[1] : lambda { |request| true }
		item = item[0]
		menu.add(PathMap.getDescription(item), PathMap.getPath(item), condition)
	end
	
	return menu
end

def getSiteGenerator
	output = MainSiteGenerator.new
	output.addStylesheet(getStylesheet 'base')
	output
end

loadModules

$sessionManager = SessionManager.new
$requestManager = createRequestManager
$generator = getSiteGenerator
$database = getDatabaseObject
$menu = createMenu
