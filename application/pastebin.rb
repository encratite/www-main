require 'sequel'
require 'configuration/database'
require 'configuration/pastebin'

class Pastebin
	def initialize()
		@database = Sequel.connect
		(
			adapter: DatabaseConfiguration.Adapter,
			host: DatabaseConfiguration.Host,
			user: DatabaseConfiguration.User,
			password: DatabaseConfiguration.Password,
			
			database = PastebinConfiguration.Database
		)
	end
	
	def processRequest(request)
	end
end
