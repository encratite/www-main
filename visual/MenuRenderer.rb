require 'www-library/HTMLWriter'
require 'www-library/string'

class MenuRenderer
  def self.renderMenu(request)
    menu = request.handler.getMenu
    writer = WWWLib::HTMLWriter.new
    level = 1
    menu.each do |menuLevel|
      writer.div(class: 'menu', id: "menu#{level}") do
        menuLevel.each do |item|
          if item.condition.(request)
            path = item.path.reject { |x| x == nil }
            writer.a(href: WWWLib.slashify(path)) { item.description }
          end
        end
      end
      level += 1
    end
    return writer.output
  end
end
