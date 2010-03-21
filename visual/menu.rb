require 'site/HTMLWriter'

def renderMenu(request)
	output = ''
	writer = HTMLWriter.new output
	writer.ul(id: 'menu') do
		items.each do |item|
			if item.condition.(request)
				writer.li do
					writer.a(href: item.path) { item.description }
				end
			end
		end
	end
	return output
end
