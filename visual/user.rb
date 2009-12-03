require 'site/FormWriter'
require 'PathMap'

def visualLoginForm()
	output =
<<END
<p>
The primary purpose of user accounts on this site is currently all about offering more convenient access to the pastebin.
It allows you to edit/delete your old pastebin entries even after your IP has changed which can be of importance to users with dynamic IPs.
The login sessions depend on cookies so you will not be able to use this feature unless you enable them in your browser.
If you do not have an account yet you may register one:
</p>
<p><a href="registerAccount">Register a new account</a></p>
<p>Specify your username and your password in the following form and submit the data in order to log into your account.</p>
END

	form = FormWriter.new(output, PathMap::SubmitLogin)
	['User name', 'Password'].each { |label| form.label label }
	form.finish
	
	return output
end

def visualRegisterForm()
	output =
<<END
<p>
Fill out the following form and submit the data in order to create a new account.
It is not necessary to specify an e-mail address but it may be useful to do so in case you forget your password.
</p>
END
	form = FormWriter.new(output, PathMap::SubmitRegistration)
	form.label 'User'
	form.label 'Password'
	form.label 'Type your password again', name = 'passwordAgain'
	form.label 'Email address', name = 'email'
	form.finish

	return output
end
