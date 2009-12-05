require 'UserForm'
require 'visual/user'

def loginFormRequest(request)
	return $generator.get('Log in', request, visualLoginForm)
end

def performLoginRequest(request)
end

def registerFormRequest(request)
	return $generator.get('Register a new account', request, visualRegisterForm)
end

def performRegistrationRequest(request)
end

def logoutRequest(request)
end
