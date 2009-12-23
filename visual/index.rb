require 'site/HTMLWriter'

def visualIndex()
	output = ''
	writer = HTMLWriter.new output
	writer.p { 'After coming into contact with a religious man, I always feel the need to wash my hands.' }
	return output
end
