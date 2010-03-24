require 'SiteContainer'
require 'site/RequestHandler'
require 'visual/index'

class IndexHandler < SiteContainer
	Description = 'Index'
	
	def installHandlers
		mainHandler = RequestHandler.new(@prefix)
		indexHandler = RequestHandler.menu(Description, nil, method(:getIndex))
		mainHandler.add(indexHandler)
		installHandler(mainHandler)
		@site.mainHandler = mainHandler
	end
	
	def getIndex(request)
		@generator.get([Description, visualIndex], request)
	end
end
