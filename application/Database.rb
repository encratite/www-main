require 'nil/symbol'

class Database
	include SymbolicAssignment

	attr_reader :user, :loginSession, :post, :unit, :floodProtection, :connection
	
	def initialize(database)
		tableMap =
		{
			user: :site_user,
			loginSession: :login_session,
			post: :pastebin_post,
			unit: :pastebin_unit,
			floodProtection: :flood_protection,
		}
		
		tableMap.each do |member, tableSymbol|
			value = database[tableSymbol]
			setMember(member, value)
		end
		
		@connection = database
	end
	
	def transaction(&block)
		@connection.transaction do
			block.call
		end
	end
end
