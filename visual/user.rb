def visualLoginForm()
	output =
<<END
<p>
The primary purpose of user accounts on this site is currently offering more convenient access to the pastebin.
It allows you to edit/delete your old pastebin entries even after your IP has changed.
The login sessions depend on cookies so you will not be able to use this feature unless you enable them in your browser.
If you do not have an account yet you may register one:
</p>

<p><a href="registerAccount">Register a new account</a></p>

<p>Specify your username and your password in the following form and submit the data in order to log into your account.</p>

<form action="performLogin" method="post">
<p>
<label for="user">User:</label><br />
<input type="text" id="user" name="user" />
</p>
<p>
<label for="password">Password:</label><br />
<input type="text" id="password" name="password" />
</p>
<p>
<input type="submit" />
</p>
</form>
END
	return output
end

def visualRegisterForm()
	output =
<<END
END
	return output
end
