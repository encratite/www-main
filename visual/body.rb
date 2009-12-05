def visualHead(request)
	output = $menu.render request
	output += "<div id=\"siteContent\">\n"
end

def visualFoot()
	return "</div>\n"
end
