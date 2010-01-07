require 'site/HTML'

class User
	MemberHash =
	{
		user_id: :id,
		name: :name,
		password: :password,
		email: :email,
		is_administrator: :isAdministrator,
	}
	
	attr_accessor(*self.getAccessorSymbols)
	
	attr_accessor :htmlName
	
	def initialize(data = nil)
		return if data == nil
		
		data.each do |key, value|
			ourKey = MemberHash[key]
			next if ourKey == nil
			instance_variable_set(ourKey, value)
		end
		
		fixName
		
		@id = data[:id] if @id == nil
	end
	
	def set(id, name, password, email, isAdministrator)
		@id = id
		@name = name
		@password = password
		@email = email
		@isAdministrator = isAdministrator
		
		fixName
	end
	
	def fixName
		@htmlName = HTMLEntities::encode @name if @name != nil
	end
	
	def self.getAccessorSymbols
	end
end
