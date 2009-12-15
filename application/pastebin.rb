require 'PathMap'
require 'configuration/pastebin'
require 'visual/pastebin'

def newPastebinPost(request)
	$generator.get(PathMap.getDescription(:Pastebin), request, visualPastebinForm)
end
