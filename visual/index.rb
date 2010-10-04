require 'www-library/HTMLWriter'

def visualIndex()
	writer = HTMLWriter.new
	writer.p { 'After coming into contact with a religious man, I always feel the need to wash my hands.' }
	return writer.output
end
