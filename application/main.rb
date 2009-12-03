$:.concat ['..', 'application']

require 'site/RequestManager'
require 'site/SiteGenerator'

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
