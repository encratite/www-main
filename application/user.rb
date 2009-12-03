require 'visual/user'

def loginFormRequest(request)
	return $generator.get('Log in', visualLoginForm())
end

def performLoginRequest(request)
end

def registerFormRequest(request)
	return $generator.get('Register a new account', visualRegisterForm())
end

def performRegistrationRequest(request)
end

def logoutRequest(request)
end
