require 'www-library/SiteGenerator'
require 'visual/body'

class MainSiteGenerator < WWWLib::SiteGenerator
	def get(data, request)
		title, content = data
		content += visualFoot
		super(title, content, visualHead request)
	end
end
