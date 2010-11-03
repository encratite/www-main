require 'nil/symbol'

class Database < SymbolicAssignment
	attr_read :user, :loginSession, :post, :unit, :floodProtection
	
	def initialize(database)
		tableMap =
		{
			user => :site_user,
			loginSession => :login_session,
			post => :pastebin_post,
			unit => :pastebin_unit,
			floodProtection => :flood_protection,
		}
		
		tableMap.each do |member, tableSymbol|
			value = database[tableSymbol]
			setMember(member, value)
		end
	end
end
