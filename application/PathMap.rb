require 'configuration/site'

def newPath(path)
	return SiteConfiguration::SitePrefix + path
end

class PathMapEntry
	attr_reader :description, :path
	
	def initialize(description, path)
		@description = description
		@path = newPath path
	end
end

class PathMap
	Index = PathMapEntry.new('Index', '')
	Login = PathMapEntry.new('Login', 'login')
	Register = PathMapEntry.new('Registration', 'register')
	Logout = PathMapEntry.new('Log out', 'logout')
	
	SubmitLogin = newPath 'submitLogin'
	SubmitRegistration = newPath 'submitRegistration'
	
	def self.getPath(symbol)
		pathOrMapEntry = self.const_get symbol
		return pathOrMapEntry if pathOrMapEntry.class == String
		pathOrMapEntry.path
	end
	
	def self.getDescription(symbol)
		self.const_get(symbol).description
	end
end
