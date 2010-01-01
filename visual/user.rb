require 'HashFormWriter'
require 'PathMap'
require 'UserForm'
require 'site/HTML'
require 'visual/general'
require 'configuration/site'

def accountExplanation
	output =
<<END
The primary purpose of user accounts on this site is currently all about offering more convenient access to the pastebin.
It allows you to edit/delete your old pastebin entries even after your IP has changed which can be of importance to users with dynamic IPs.
The login sessions depend on cookies so you will not be able to use this feature unless you enable them in your browser.
END
end

def getFieldLength(symbol)
	return {maxlength: SiteConfiguration.const_get(symbol)}
end

def visualLoginForm(request)
	output = ''
	writer = HashFormWriter.new(output, request)
	writer.p do
		writer.write accountExplanation
		writer.write 'If you do not have an account yet you may register one:'
	end
	
	writer.p class: 'indent' do
		path = PathMap.getPath :Register
		writer.a href: path do 'Register a new account' end
	end
	
	writer.p { 'Specify your username and your password in the following writer and submit the data in order to log into your account.' }

	writer.hashForm PathMap::SubmitLogin, UserForm::LoginFields do
		writer.text('User name', UserForm::User, nil, getFieldLength(:UserNameLengthMaximum))
		writer.password('Password', UserForm::Password, nil, getFieldLength(:PasswordLengthMaximum))
		writer.hashSubmit
	end
	
	['Log in', output]
end

def visualRegisterForm(request, error = nil, user = nil, email = nil)
	output = ''
	writer = HashFormWriter.new(output, request)
	
	if error != nil
		writer.p do
			writer.b { 'Registration error:' }
			'An error occured while your request was being processed:'
		end
		
		writer.ul class: 'error' do
			error.each { |message| writer.li { message } }
		end
		writer.p 'Please go over the writer again and correct the invalid entries.'
	else
		writer.p do
			lines =
<<END
Fill out the following writer and submit the data in order to create a new account.
It is not necessary to specify an e-mail address but it may be useful to do so in case you forget your password.
END
			writer.write lines
		end
	end
	
	writer.hashForm(PathMap::SubmitRegistration, UserForm::RegistrationFields) do
		writer.text('User name', UserForm::User, user, getFieldLength(:UserNameLengthMaximum))
		writer.password('Password', UserForm::Password, nil, getFieldLength(:PasswordLengthMaximum))
		writer.password('Type your password again', UserForm::PasswordAgain, nil, getFieldLength(:PasswordLengthMaximum))
		writer.text('Email address', UserForm::Email, email, getFieldLength(:EmailLengthMaximum))
		writer.hashSubmit
	end
	
	['Register a new account', output]
end

def visualRegistrationSuccess(userName)
	userName = HTMLEntities::encode userName
	title = 'Registration succesful'
	content = visualMessage "Your account <b>#{userName}</b> has been created successfully. You have been automatically logged into your account."
	[title, content]
end

def visualLoginError
	title = 'Invalid login'
	content = visualError('The user name or the password you have specified is invalid. Please try again.') + visualLoginForm[1]
	[title, content]
end

def visualLoginSuccess(user)
	title = 'Login successful'
	content = visualMessage "You are now logged in as <b>#{user.htmlName}</b>."
	[title, content]
end

def visualLogout
	title = 'Logout successful'
	content = visualMessage 'You have successfully logged out of your account.'
	[title, content]
end

def visualAlreadyLoggedIn(currentUser, message)
	visualError "You are already logged into your account <b>#{currentUser.name}</b>. #{message}"
end
