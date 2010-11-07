require 'visual/body'

require 'www-library/SiteGenerator'

class MainSiteGenerator < WWWLib::SiteGenerator
	def get(data, request)
		title, content = data
		content = wrapContent(request, content)
		super(title, content)
	end
end
