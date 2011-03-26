require 'visual/MenuRenderer'

require 'www-library/HTMLWriter'

require 'www-library/SiteGenerator'

class MainSiteGenerator < WWWLib::SiteGenerator
  def wrapContent(request, content)
    writer = WWWLib::HTMLWriter.new
    menu = MenuRenderer.renderMenu(request)
    writer.div(id: 'siteContent') do
      writer.img(src: @main.getStaticPath('image', 'logo.png'), alt: 'SYBK', id: 'logo')
      writer.div(id: 'menuContainer') do
        writer.write(menu)
      end
      content
    end
    return writer.output
  end
end
