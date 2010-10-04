require 'www-library/HTML'
require 'www-library/SymbolTransfer'

class User < SymbolTransfer
	attr_accessor :htmlName
	
	def initialize(data = nil)
		return if data == nil
		transferSymbols data
		@htmlName = HTMLEntities::encode @name
	end
	
	def set(id, name, password, email, isAdministrator)
		@id = id
		@name = name
		@htmlName = HTMLEntities::encode @name
		@password = password
		@email = email
		@isAdministrator = isAdministrator
	end
end
