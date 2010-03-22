require 'visual/MenuRenderer'

def visualHead(requestManager, request)
	output = MenuRenderer.renderMenu request
	output += "<div id=\"siteContent\">\n"
end

def visualFoot()
	return "</div>\n"
end
