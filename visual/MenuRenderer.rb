require 'www-library/HTMLWriter'
require 'www-library/string'

class MenuRenderer
	def self.renderMenu(request)
		menu = request.handler.getMenu
		writer = WWWLib::HTMLWriter.new
		level = 1
		menu.each do |menuLevel|
			writer.ul(class: 'menu', id: "menu#{level}") do
				menuLevel.each do |item|
					if item.condition.(request)
						writer.li do
							writer.a(href: WWWLib.slashify(item.path)) { item.description }
						end
					end
				end
			end
			level += 1
		end
		return writer.output
	end
end
