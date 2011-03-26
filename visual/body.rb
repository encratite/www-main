require 'visual/MenuRenderer'

require 'www-library/HTMLWriter'

def wrapContent(request, content)
  writer = WWWLib::HTMLWriter.new
  menu = MenuRenderer.renderMenu(request)
  writer.div(id: 'siteContent') do
    writer.div(id: 'menuContainer') do
      writer.write(menu)
    end
    content
  end
  return writer.output
end
