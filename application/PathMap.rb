class PathMapEntry
	attr_reader :description, :path
	
	def initialize(description, path)
		@description = description
		@path = path
	end
end

class PathMap
	Index = PathMapEntry.new('Index', '')
	Login = PathMapEntry.new('Login', 'login')
	Register = PathMapEntry.new('Registration', 'register')
	Logout = PathMapEntry.new('Log out', 'logout')
	
	SubmitLogin = 'submitLogin'
	SubmitRegistration = 'submitRegistration'
	
	def self.getPath(symbol)
		pathOrMapEntry = self.const_get symbol
		return pathOrMapEntry if pathOrMapEntry.class == String
		return pathOrMapEntry.path
	end
	
	def self.getDescription(symbol)
		return self.const_get(symbol).description
	end
end
