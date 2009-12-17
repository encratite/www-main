require 'PathMap'
require 'configuration/pastebin'
require 'visual/pastebin'

def newPastebinPost(request)
	$pastebinGenerator.get(PathMap.getDescription(:Pastebin), request, visualPastebinForm)
end
