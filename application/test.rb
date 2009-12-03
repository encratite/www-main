def postTest(request)
	content =
<<END
<form action="/main/environment" method="post">
<input type="text" name="text1" /><br />
<input type="text" name="text2" /><br />
<textarea name="textarea" /><br />
<input type="submit" />
</form>
END
	return $generator.get('POST test', content)
end
