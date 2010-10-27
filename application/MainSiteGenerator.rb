require 'www-library/SiteGenerator'
require 'visual/body'

class MainSiteGenerator < WWWLib::SiteGenerator
	def get(data, request)
		title, content = data
		content += visualFoot
		additionalHeader = visualHead request
		super(title, content, additionalHeader)
	end
end
