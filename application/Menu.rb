require 'visual/menu'

class MenuItem
	attr_reader :description, :path, :condition
	def initialize(description, path, condition)
		@description = description
		@path = path
		@condition = condition
	end
end

class Menu
	def initialize
		@items = []
	end
	
	def add(description, path, condition)
		@items << MenuItem.new(description, path, condition)
	end
	
	def render(request)
		return renderMenu @items, request
	end
end
