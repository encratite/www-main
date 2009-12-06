require 'site/FormWriter'
require 'PathMap'
require 'UserForm'

def visualLoginForm()
	output =
<<END
<p>
The primary purpose of user accounts on this site is currently all about offering more convenient access to the pastebin.
It allows you to edit/delete your old pastebin entries even after your IP has changed which can be of importance to users with dynamic IPs.
The login sessions depend on cookies so you will not be able to use this feature unless you enable them in your browser.
If you do not have an account yet you may register one:
</p>
END
	output += "<p class=\"indent\"><a href=\"#{PathMap.getPath :Register}\">Register a new account</a></p>\n"
	output +=
<<END
<p>Specify your username and your password in the following form and submit the data in order to log into your account.</p>
END

	fields =
	[
		['User name', UserForm::User],
		['Password', UserForm::Password]
	]

	form = FormWriter.new(output, PathMap::SubmitLogin)
	fields.each { |description, fieldName| form.label label: description, name: fieldName }
	form.finish
	
	'Log in', output
end

def visualRegisterForm(error = nil, user = nil, email = nil)
	if error != nil do
		output =
<<END
<p><b>Registration error:</b> An error occured while your request was being processed:</p>
<ul class="error">
END
		error.each { |message| output += "<li>#{message}</li>\n" }
		output +=
<<END
</ul>
<p>Please go over the form again and correct the invalid entries.</p>
END
	else
		output =
<<END
<p>
Fill out the following form and submit the data in order to create a new account.
It is not necessary to specify an e-mail address but it may be useful to do so in case you forget your password.
</p>
END
	end

	fields =
	[
		['User name', UserForm::User, user],
		['Password', UserForm::Password],
		['Type your password again', UserForm::PasswordAgain],
		['Email address', UserForm::Email, email]
	]
	
	form = FormWriter.new(output, PathMap::SubmitLogin)
	fields.each do |field|
		description = field[0]
		fieldName = field[1]
		labelHash = label: description, name: fieldName
		if field.size == 3
			value = field[2]
			labelHash[:value] = value if value != nil
		end
		form.label labelHash
	end
	form.finish
	
	'Register a new account', output
end
