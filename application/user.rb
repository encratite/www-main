id serial primary key,

	name text unique,
	password text,
	
	email text,
	
	is_administrator boolean default false

class User
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
	end
end
