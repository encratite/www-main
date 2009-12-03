$:.concat ['..', 'application']

require 'site/RequestManager'
require 'site/SiteGenerator'

require 'configuration/database'

applicationFiles =
[
	'index',
	'environment',
	'test'
]

applicationFiles.each { |name| require name }

handlers =
[
	['', :getIndex],
	['environment', :visualiseEnvironment],
	['post', :postTest],
]

prefix = '/main/'

manager = RequestManager.new
handlers.each { |path, symbol| manager.addHandler(prefix + path, symbol) }

$generator = SiteGenerator.new

$database = Sequel.connect
(
	adapter: DatabaseConfiguration.Adapter,
	host: DatabaseConfiguration.Host,
	user: DatabaseConfiguration.User,
	password: DatabaseConfiguration.Password,
	database = DatabaseConfiguration.Database
)
