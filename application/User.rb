require 'site/HTML'

class User
	attr_accessor :id, :name, :password, :email, :isAdministrator
	
	def initialize(data = nil)
		return if data == nil
		
		memberHash =
		{
			user_id: :@id,
			name: :@name,
			password: :@password,
			email: :@email,
			is_administrator: :@isAdministrator,
		}
		
		data.each do |key, value|
			ourKey = memberHash[key]
			next if ourKey == nil
			instance_variable_set(ourKey, value)
		end
		
		fixName
	end
	
	def fixName
		@htmlName = HTMLEntities::encode @name if @name != nil
	end
end
