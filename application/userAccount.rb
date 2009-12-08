require 'UserForm'
require 'User'
require 'site/MIMEType'
require 'site/HTTPReply'
require 'site/Cookie'
require 'configuration/site'
require 'configuration/table'
require 'configuration/cookie'
require 'site/EMailValidator'
require 'visual/user'
require 'visual/general'
require 'hash'

def plainError(message)
	[MIMEType::Plain, message]
end

def fieldError
	plainError 'Not all required fields have been specified.'
end

def sessionCheck(request, title, message)
	currentUser = request.sessionUser
	return nil if currentUser == nil
	content = visualError "You are already logged into your account #{currentUser.name}. #{message}"
	$generator.get title, request, content
end

def loginCheck(request)
	sessionCheck(request, 'Login error', 'You need to log out before you can log into another one.')
end

def registrationCheck(request)
	sessionCheck(request, 'Registration error', 'You need to log out before you can register a new account.')
end

def loginFormRequest(request)
	content = loginCheck request
	return content if content != nil
	title, content = visualLoginForm
	$generator.get title, request, content
end

def performLoginRequest(request)
	content = loginCheck request
	return content if content != nil
	
	requiredFields =
	[
		UserForm::User,
		UserForm::Password
	]
	
	input = request.postInput
	
	requiredFields.each { |field| return fieldError if input[field] == nil }
	
	user = input[UserForm::User]
	password = input[UserForm::Password]
	
	passwordHash = hashWithSalt password
	
	dataset = getDataset :User
	result = dataset.where(name: user, password: passwordHash).first
	if result == nil
		title, content = visualLoginError
		return $generator.get title, request, content
	else
		user = User.new result
		request.sessionUser = user
		
		sessionString = $sessionManager.createSession(user.id, request.address)
		sessionCookie = Cookie.new(CookieConfiguration::Session, sessionString, SiteConfiguration::SitePrefix)
		
		title, content = visualLoginSuccess user
		fullContent = $generator.get title, request, content
		
		reply = HTTPReply.new fullContent
		reply.addCokie sessionCookie
		return reply
	end
end

def registerFormRequest(request)
	content = registrationCheck request
	return content if content != nil
	title, content = visualRegisterForm
	$generator.get title, request, content
end

def performRegistrationRequest(request)
	content = registrationCheck request
	return content if content != nil
	
	requiredFields =
	[
		UserForm::User,
		UserForm::Password,
		UserForm::PasswordAgain,
		UserForm::Email
	]
	
	input = request.postInput
	
	requiredFields.each { |field| return fieldError if input[field] == nil }
	
	user = input[UserForm::User]
	password = input[UserForm::Password]
	passwordAgain = input[UserForm::PasswordAgain]
	email = input[UserForm::Email]
	
	errors = []
	
	error = lambda { |message| errors << message }	
	printErrorForm = lambda do
		title, content = visualRegisterForm errors, user, email
		$generator.get title, request, content
	end
	errorOccured = lambda { !errors.empty? }
	
	error 'Your user name may not be empty.' if user.empty?
	error 'Your user name is too long.' if user.size > SiteConfiguration::UserNameLengthMaximum
	error 'Your passwords do not match.' if password != passwordAgain
	error 'Your password is too long.' if password.size > SiteConfiguration::PasswordLengthMaximum
	error 'The email address you have specified is invalid.' if !email.empty? && !EMailValidator.isValidEmailAddress(email)
	
	return printErrorForm if errorOccured
	
	dataset = getDataset :User
	
	$database.transaction do
		error 'The user name you have chosen is already taken. Please choose another one.' if dataset.where(name: user).count > 0
		
		return printErrorForm if errorOccured
		
		passwordHash = hashWithSalt password
		userId = dataset.insert(name: user, password: passwordHash, email: email)
		sessionString = $sessionManager.createSession(userId, request.address)
		sessionCookie = Cookie.new(CookieConfiguration::Session, sessionString, SiteConfiguration::SitePrefix)
		title, content = visualRegistrationSuccess
		fullContent = $generator.get title, request, content
		reply = HTTPReply.new fullContent
		reply.addCookie sessionCookie
	end
	
	reply
end

def logoutRequest(request)
	currentUser = request.sessionUser
	if currentUser != nil
		title = 'Logout error'
		content = visualError 'You are currently not logged into any account.'
		return $generator.get title, request, content
	end
	
	sessionString = request.cookies[CookieConfiguration::Session]
	dataset = getDataset :LoginSession
	dataset.filter(session_string: sessionString).delete
	
	request.sessionUser = nil
	
	title, content = visualLogout
	fullContent = $generator.get title, request, content
	reply = HTTPReply.new fullContent
	reply.deleteCookie CookieConfiguration::Session
	reply
end
