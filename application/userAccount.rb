require 'UserForm'
require 'User'
require 'hash'
require 'error'
require 'FormCheck'
require 'site/HTTPReply'
require 'site/Cookie'
require 'configuration/site'
require 'configuration/table'
require 'configuration/cookie'
require 'site/EMailValidator'
require 'visual/user'
require 'visual/general'

def sessionCheck(request, title, message)
	currentUser = request.sessionUser
	return nil if currentUser == nil
	content = visualAlreadyLoggedIn(currentUser, message)
	$generator.get [title, content], request
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
	$generator.get(visualLoginForm(request), request)
end

def performLoginRequest(request)
	content = loginCheck request
	return content if content != nil
	
	FormCheck::Process.call(request, UserForm::LoginFields)
	
	user = request.getPost UserForm::User
	password = request.getPost UserForm::Password
	
	passwordHash = hashWithSalt password
	
	dataset = getDataset :User
	result = dataset.where(name: user, password: passwordHash).first
	if result == nil
		return $generator.get visualLoginError, request
	else
		user = User.new result
		request.sessionUser = user
		
		sessionString = $sessionManager.createSession(user.id, request.address)
		sessionCookie = Cookie.new(CookieConfiguration::Session, sessionString, SiteConfiguration::SitePrefix)
		sessionCookie.expirationDays SiteConfiguration::SessionDurationInDays
		
		fullContent = $generator.get visualLoginSuccess(user), request
		
		reply = HTTPReply.new fullContent
		reply.addCookie sessionCookie
		return reply
	end
end

def registerFormRequest(request)
	content = registrationCheck request
	return content if content != nil
	$generator.get(visualRegisterForm(request), request)
end

def performRegistrationRequest(request)
	content = registrationCheck request
	return content if content != nil
	
	FormCheck::Process.call(request, UserForm::RegistrationFields)
	
	user = request.getPost UserForm::User
	password = request.getPost UserForm::Password
	passwordAgain = request.getPost UserForm::PasswordAgain
	email = request.getPost UserForm::Email
	
	errors = []
	
	error = lambda { |message| errors << message }	
	printErrorForm = lambda { $generator.get visualRegisterForm(errors, user, email), request }
	errorOccured = lambda { !errors.empty? }
	
	error.call 'Your user name may not be empty.' if user.empty?
	error.call 'Your user name is too long.' if user.size > SiteConfiguration::UserNameLengthMaximum
	error.call 'Your passwords do not match.' if password != passwordAgain
	error.call 'Your password is too long.' if password.size > SiteConfiguration::PasswordLengthMaximum
	error.call 'The email address you have specified is invalid.' if !email.empty? && !EMailValidator.isValidEmailAddress(email)
	
	return printErrorForm.call if errorOccured.call
	
	dataset = getDataset :User
	
	reply = nil
	
	$database.transaction do
		error.call 'The user name you have chosen is already taken. Please choose another one.' if dataset.where(name: user).count > 0
		
		return printErrorForm.call if errorOccured.call
		
		passwordHash = hashWithSalt password
		userId = dataset.insert(name: user, password: passwordHash, email: email)
		sessionString = $sessionManager.createSession(userId, request.address)
		sessionCookie = Cookie.new(CookieConfiguration::Session, sessionString, SiteConfiguration::SitePrefix)
		sessionCookie.expirationDays SiteConfiguration::SessionDurationInDays
		output = visualRegistrationSuccess user
		
		newUser = User.new
		newUser.set(userId, user, password, email, false)
		
		request.sessionUser = newUser
		
		fullContent = $generator.get output, request
		reply = HTTPReply.new fullContent
		reply.addCookie sessionCookie
	end
	
	reply
end

def logoutRequest(request)
	currentUser = request.sessionUser
	if currentUser == nil
		title = 'Logout error'
		content = visualError 'You are currently not logged into any account.'
		return $generator.get [title, content], request
	end
	
	sessionString = request.cookies[CookieConfiguration::Session]
	dataset = getDataset :LoginSession
	dataset.filter(session_string: sessionString).delete
	
	request.sessionUser = nil
	
	fullContent = $generator.get visualLogout, request
	reply = HTTPReply.new fullContent
	reply.deleteCookie(CookieConfiguration::Session, SiteConfiguration::SitePrefix)
	reply
end
