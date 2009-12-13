require 'PathMap'
require 'configuration/pastebin'
require 'visual/pastebin'

def newPastebinPost(request)
	$generator.get(PathMap.getDescription(:Index), request, visualIndex)
end
