require 'SiteContainer'

require 'visual/index'

class IndexHandler < SiteContainer
	Description = 'Index'
	
	def installHandlers
		installMenuHandler(Description, [], :getIndex)
	end
	
	def getIndex(request)
		@generator.get([Description, visualIndex], request)
	end
end
