$:.concat ['..', 'application']

require 'MainSite'

require 'IndexHandler'
require 'UserHandler'
require 'PastebinHandler'

mainSite = MainSite.new

indexHandler = IndexHandler.new mainSite
#userHandler = UserHandler.new mainSite
#pastebinHandler = PastebinHandler.new mainSite

#userHandler.addLogoutMenu

handler = lambda do |environment|
	mainSite.requestManager.handleRequest(environment)
end

run(handler)
