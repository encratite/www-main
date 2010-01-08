require 'site/HTML'
require 'site/SymbolTransfer'

class User < SymbolTransfer
	attr_accessor :htmlName
	
	def initialize(data = nil)
		return if data == nil
		transferSymbols data
	end
	
	def set(id, name, password, email, isAdministrator)
		@id = id
		@name = HTMLEntities::encode name
		@password = password
		@email = email
		@isAdministrator = isAdministrator
	end
end
