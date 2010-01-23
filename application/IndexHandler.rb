require 'PathMap'
require 'SiteContainer'

require 'visual/index'

class IndexHandler < SiteContainer
	Description = 'Index'
	
	def installHandlers
		installMenuHandler(Description, 'index', :getIndex)
	end
	
	def getIndex(request)
		@generator.get([Description, visualIndex], request)
	end
end
