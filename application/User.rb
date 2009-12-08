require 'site/HTML'

class User
	attr_reader :id, :name, :password, :email, :isAdministrator
	
	def initialize(data)
		memberHash =
		{
			id: :@id,
			name: :@name,
			password: :@password,
			email: :@email,
			is_administrator: :@isAdministrator,
		}
		
		data.each { |key, value| set_instance_variable(memberHash[key], value) }
		
		@htmlName = HTMLEntities::encode @name if @name != nil
	end
end
