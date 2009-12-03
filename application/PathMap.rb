class PathMapEntry
	attr_reader :description, :path
	
	def initialize(description, path)
		@description = description
		@path = path
	end
end

class PathMap
	Index = PathMapEntry('Index', '')
	Login = PathMapEntry('Login', 'login')
	Register = PathMapEntry('Registration', 'register')
	
	SubmitLogin = 'submitLogin'
	SubmitRegistration = 'submitRegistration'
	Logout = 'logout'
	
	def self.getPath(symbol)
		pathOrMapEntry = self.const_get symbol
		return pathOrMapEntry if pathOrMapEntry.class == String
		return pathOrMapEntry.path
	end
	
	def self.getDescription(symbol)
		return self.const_get(symbol).description
	end
end
