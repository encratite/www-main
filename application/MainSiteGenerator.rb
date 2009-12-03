require 'site/SiteGenerator'
require 'visual/body'

class MainSiteGenerator < SiteGenerator
	def head(title, request)
		return super(title) + visualHead(request)
	end
	
	def foot
		return visualFoot + super
	end
	
	def get(title, request, content)
		return head(title, request) + content + foot
	end
end
