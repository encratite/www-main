require 'site/HTMLWriter'
require 'site/string'

class MenuRenderer

	def self.renderMenu(request)
		menu = request.handler.getMenu
		output = ''
		writer = HTMLWriter.new output
		level = 1
		menu.each do |menuLevel|
			writer.ul(class: 'menu', id: "menu#{level}") do
				menuLevel.each do |item|
					if item.condition.(request)
						writer.li do
							writer.a(href: slashify(item.path)) { item.description }
						end
					end
				end
			end
			level += 1
		end
		return output
	end
end
