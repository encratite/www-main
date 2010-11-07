require 'visual/MenuRenderer'

require 'www-library/HTMLWriter'

def wrapContent(request, content)
	writer = WWWLib::HTMLWriter.new
	menu = MenuRenderer.renderMenu(request)
	writer.write(menu)
	writer.div(id: 'siteContent') do
		content
	end
	return writer.output
end
