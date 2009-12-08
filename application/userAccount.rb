require 'UserForm'
require 'site/MIMEType'
require 'site/HTTPReply'
require 'site/Cookie'
require 'configuration/site'
require 'configuration/table'
require 'configuration/cookie'
require 'site/EMailValidator'
require 'visual/user'
require 'visual/general'
require 'digest/md5'

def plainError(message)
	[MIMEType::Plain, message]
end

def fieldError
	plainError 'Not all required fields have been specified.'
end

def sessionCheck(request, title, message)
	currentUser = request.sessionUser
	return nil if if currentUser == nil
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
	
	dataset = getDataset :User
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
		
		passwordHash = Digest::MD5.hexdigest password
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
end
