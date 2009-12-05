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
end

def visualRegisterForm()
	output =
<<END
<p>
Fill out the following form and submit the data in order to create a new account.
It is not necessary to specify an e-mail address but it may be useful to do so in case you forget your password.
</p>
END

	fields =
	[
		['User name', UserForm::User],
		['Password', UserForm::Password],
		['Type your password again', UserForm::PasswordAgain],
		['Email address', UserForm::Email]
	]
	
	form = FormWriter.new(output, PathMap::SubmitLogin)
	fields.each { |description, fieldName| form.label label: description, name: fieldName }
	form.finish
end
