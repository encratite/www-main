require 'site/HTMLWriter'

class MenuRenderer
	def self.convertPath(input)
		separator = '/'
		return separator + input.join(separator)
	end

	def self.renderMenu(request)
		menuStructure = request.manager.getMenu
		output = ''
		writer = HTMLWriter.new output
		writer.ul(id: 'menu') do
			menuStructure.each do |item|
				if item.condition.(request)
					writer.li do
						writer.a(href: convertPath(item.path)) { item.description }
					end
				end
			end
		end
		return output
	end
end
