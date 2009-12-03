require 'visual/menu'

class MenuItem
	attr_reader :description, :path
	def initialize(description, path)
		@description = description
		@path = path
	end
end

class Menu
	def initialize
		@items = []
	end
	
	def add(description, path)
		@items << MenuItem.new(description, path)
	end
	
	def render
		return renderMenu @items
	end
end
