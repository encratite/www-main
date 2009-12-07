require 'UserForm'
require 'site/MIMEType'
require 'configuration/site'
require 'configuration/table'
require 'site/EMailValidator'
require 'visual/user'

def plainError(message)
	[MIMEType::Plain, message]
end

def fieldError
	plainError 'Not all required fields have been specified.'
end

def loginFormRequest(request)
	title, content = visualLoginForm
	$generator.get title, request, content
end

def performLoginRequest(request)
end

def registerFormRequest(request)
	title, content = visualRegisterForm
	$generator.get title, request, content
end

def performRegistrationRequest(request)
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
	
	dataset = $database[TableConfiguration::User]
	
	$database.transaction do
		error 'The user name you have chosen is already taken. Please choose another one.' if dataset.where(name: user).count > 0
		
		return printErrorForm if errorOccured
		
		dataset.insert(name: user, password: password, email: email)
		
		#Create a session
	end
	
end

def logoutRequest(request)
end
