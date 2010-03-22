require 'SiteContainer'
require 'site/RequestHandler'
require 'visual/index'

class IndexHandler < SiteContainer
	Description = 'Index'
	
	def installHandlers
		indexHandler = RequestHandler.menu(Description, @prefix, method(:getIndex))
		installHandler(indexHandler)
	end
	
	def getIndex(request)
		@generator.get([Description, visualIndex], request)
	end
end
