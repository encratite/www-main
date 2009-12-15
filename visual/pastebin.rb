require 'PathMap'
require 'PastebinForm'
require 'SyntaxHighlighting'

require 'site/FormWriter'
require 'site/HTMLWriter'

def visualPastebinNewPost
end

def visualPastebinForm(postDescription = nil, highlightingSelectionMode = 0)
	highlightingGroups =
	[
		'Use no syntax highlighting (plain text)',
		"Common programming languages (#{SyntaxHighlighting::CommonScripts.size} available)",
		"All syntax highlighting types (#{SyntaxHighlighting::AllScripts.size} available)",
		'Expert mode (manually specify the name of a vim script)'
	]
	output = ''
	form = FormWriter.new(output, PathMap::PastebinSubmitPost)
	form.field(label: 'Description', name: PostDescription::Description, value: postDescription)
	writer = HTMLWriter.new output
	writer.div id: 'pastebinPostLeft' do
		writer.p { writer.write 'Specify the syntax highlighting selection method you would like to use:' }
		counter = 0
		highlightingGroups.each do |description|
			arguments = {label: description, name: PastebinForm::HighlightingGroup, onclick: "highlightingMode(#{counter});"}
			arguments[:checked] = true if counter == highlightingSelectionMode
			form.field arguments
			counter += 1
		end
	end
	writer.div id: 'pastebinPostRight' do
		form.field(type: select, name: PastebinForm::CommonHighlighting, options: basicOptions)
		form.field(type: select, name: PastebinForm::AdvancedHighlighting, options: advancedOptions)
		form.field(label: 'Specify the vim script you want to loaded (e.g. "cpp")', name: PastebinForm::ExpertHighlighting)
	end
	form.finish
end
