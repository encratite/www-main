require 'www-library/SiteGenerator'
require 'visual/body'

class MainSiteGenerator < WWWLib::SiteGenerator
	def head(title, request)
		return super(title) + visualHead(request)
	end
	
	def foot
		return visualFoot + super
	end
	
	def get(data, request)
		title, content = data
		return head(title, request) + content + foot
	end
end
