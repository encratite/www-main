require 'HashFormWriter'
require 'PathMap'
require 'UserForm'
require 'site/HTML'
require 'site/HTMLWriter'
require 'visual/general'

def accountExplanation
	output =
<<END
The primary purpose of user accounts on this site is currently all about offering more convenient access to the pastebin.
It allows you to edit/delete your old pastebin entries even after your IP has changed which can be of importance to users with dynamic IPs.
The login sessions depend on cookies so you will not be able to use this feature unless you enable them in your browser.
END
end

def visualLoginForm
	output = ''
	writer = HTMLWriter.new output
	writer.p do
		writer.write accountExplanation
		writer.write 'If you do not have an account yet you may register one:'
	end
	
	writer.p class: 'indent' do
		path = PathMap.getPath :Register
		writer.a(href: path) { 'Register a new account' }
	end
	
	writer.p { 'Specify your username and your password in the following form and submit the data in order to log into your account.' }

	fields =
	[
		['User name', UserForm::User],
		['Password', UserForm::Password]
	]

	form = HashFormWriter.new(output, PathMap::SubmitLogin, fields.map { |description, fieldName| fieldName })
	fields.each { |description, fieldName| form.field label: description, name: fieldName }
	form.finish
	
	['Log in', output]
end

def visualRegisterForm(error = nil, user = nil, email = nil)
	output = ''
	writer = HTMLWriter.new output
	
	if error != nil
		writer.p do
			writer.b { 'Registration error:' }
			'An error occured while your request was being processed:'
		end
		
		writer.ul class: 'error' do
			error.each { |message| writer.li { message } }
		end
		writer.p 'Please go over the form again and correct the invalid entries.'
	else
		writer.p do
			lines =
<<END
Fill out the following form and submit the data in order to create a new account.
It is not necessary to specify an e-mail address but it may be useful to do so in case you forget your password.
END
			writer.write lines
		end
	end

	fields =
	[
		['User name', UserForm::User, user],
		['Password', UserForm::Password],
		['Type your password again', UserForm::PasswordAgain],
		['Email address', UserForm::Email, email]
	]
	
	form = HashFormWriter.new(output, PathMap::SubmitRegistration, fields.map { |description, fieldName| fieldName })
	fields.each do |field|
		description = field[0]
		fieldName = field[1]
		labelHash = {label: description, name: fieldName}
		if field.size == 3
			value = field[2]
			labelHash[:value] = value if value != nil
		end
		form.field labelHash
	end
	form.finish
	
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
