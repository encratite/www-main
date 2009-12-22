require 'PathMap'
require 'visual/index'

def getIndex(request)
	$generator.get([PathMap.getDescription(:Index), visualIndex], request)
end
