$:.concat ['..', 'application']

require 'MainSite'

require 'IndexHandler'
require 'PastebinHandler'

"""
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
		[:PastebinSubmitNewPost, :submitNewPastebinPost],
		[:PastebinView, :viewPastebinPost, 1],
		[:PastebinList, :listPastebinPosts, 1],
	]

	requestManager = RequestManager.new SiteRequest
	handlers.each do |arguments|
		pathSymbol, handler = arguments
		path = PathMap.getPath pathSymbol
		argumentCount = arguments.size > 2 ? arguments[2] : nil
		requestHandler = RequestHandler.new(path, handler, argumentCount)
		requestManager.addHandler requestHandler
	end
	
	requestHandler = RequestHandler.new('/main/environment', method(:visualiseEnvironment), 0)
	requestManager.addHandler requestHandler
	
	return requestManager
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
"""

mainSite = MainSite.new
indexHandler = IndexHandler.new mainSite
pastebinHandler = PastebinHandler.new mainSite
