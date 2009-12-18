require 'PathMap'
require 'PastebinForm'
require 'SyntaxHighlighting'

require 'site/FormWriter'
require 'site/HTMLWriter'

def visualPastebinNewPost
end

def visualPastebinForm(postDescription = nil, highlightingSelectionMode = 0, lastSelection = nil)
	highlightingGroups =
	[
		'Use no syntax highlighting (plain text)',
		"Common programming languages (#{SyntaxHighlighting::CommonScripts.size} available)",
		"All syntax highlighting types (#{SyntaxHighlighting::AllScripts.size} available)",
		'Expert mode (manually specify the name of a vim script)'
	]
	
	output = ''
	form = FormWriter.new(output, PathMap::PastebinSubmitPost)
	
	radioCounter = 0
	
	radioField = lambda do
		arguments =
		{
			type: :radio,
			label: highlightingGroups[radioCounter],
			name: PastebinForm::HighlightingGroup,
			onClick: "highlightingMode(#{radioCounter});",
			value: PastebinForm::HighlightingGroupIdentifiers[radioCounter]
		}
		
		arguments[:checked] = true if radioCounter == highlightingSelectionMode
		form.field arguments
		radioCounter += 1
	end
	
	basicOptions = lastSelection ? SyntaxHighlighting.getSelectionList(true, lastSelection) : SyntaxHighlighting::CommonScripts
	advancedOptions = lastSelection ? SyntaxHighlighting.getSelectionList(false, lastSelection) : SyntaxHighlighting::AllScripts
	formFields =
	[
		lambda { form.select(name: PastebinForm::CommonHighlighting, options: basicOptions) },
		lambda { form.select(name: PastebinForm::AdvancedHighlighting, options: advancedOptions) },
		lambda { form.text(label: 'Specify the vim script you want to be used (e.g. "cpp")', name: PastebinForm::ExpertHighlighting) }
	]
	
	form.field(label: 'Description', name: PastebinForm::PostDescription, value: postDescription)
	writer = HTMLWriter.new output
	writer.p { writer.write 'Specify the syntax highlighting selection method you would like to use:' }
	writer.table id: 'syntaxTable' do
		formFields.each do |formField|
			writer.tr do
				writer.td { radioField.call }
				writer.td { formField.call }
			end
		end
		writer.tr id: 'contentRow' do
			writer.td colspan: 2 do
				form.textarea(name: PastebinForm::Content)
			end
		end
	end
	form.finish
end
