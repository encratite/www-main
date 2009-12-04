def renderMenu(items, request)
	output = "<ul class=\"menu\">\n"
	items.each do |item|
		output += "<li><a href=\"#{item.path}\">#{item.description}</a></li>\n" if item.condition.(request)
	end
	output += "</ul>\n"
	return output
end
