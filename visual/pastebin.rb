require 'PathMap'
require 'PastebinForm'
require 'site/FormWriter'

def visualPastebinNewPost
end

def visualPastebinForm(postDescription = nil, 
	fields =
	[
		['Description', PostDescription::Description, postDescription],
	]
	
	output = ''
	form = FormWriter.new(output, PathMap::PastebinSubmitPost)
	form.finish
end
