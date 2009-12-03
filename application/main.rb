$:.concat ['..', 'application']

def loadModules
	require 'site/RequestManager'
	require 'site/SiteGenerator'

	require 'configuration/database'

	applicationFiles =
	[
		'index',
		'user',
		
		'UserManager',
		'Menu',
		'PathMap',
		
		#Tests
		'environment',
		'test'
	]

	applicationFiles.each { |name| require name }
end

def createRequestManager
	handlers =
	[
		[PathMap::Index, :getIndex],
		
		[PathMap::Login, :loginFormRequest],
		[PathMap::SubmitLogin, :performLoginRequest],
		[PathMap::Register, :registerFormRequest],
		[PathMap::SubmitRegistration, :performRegistrationRequest],
		
		[PathMap::Logout, :logoutRequest],
		
		#Tests
		['environment', :visualiseEnvironment],
		['post', :postTest],
	]

	prefix = '/main/'

	requestManager = RequestManager.new
	handlers.each { |path, symbol| requestManager.addHandler(prefix + path, symbol) }
	return requestManager
end

def getDatabaseObject
	database = Sequel.connect
	(
		adapter: DatabaseConfiguration.Adapter,
		host: DatabaseConfiguration.Host,
		user: DatabaseConfiguration.User,
		password: DatabaseConfiguration.Password,
		database = DatabaseConfiguration.Database
	)
	return database
end

loadModules

$requestManager = createRequestManager
$generator = SiteGenerator.new

$database = getDatabaseObject
$userManager = UserManager.new
