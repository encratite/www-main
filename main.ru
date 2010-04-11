$:.concat ['..', 'application']

require 'MainSite'

require 'IndexHandler'
require 'UserHandler'
require 'PastebinHandler'
require 'EnvironmentHandler'

mainSite = MainSite.new

IndexHandler.new mainSite
userHandler = UserHandler.new mainSite
PastebinHandler.new mainSite

userHandler.addLogoutMenu

EnvironmentHandler.new mainSite

handler = lambda do |environment|
	mainSite.requestManager.handleRequest(environment)
end

run(handler)
