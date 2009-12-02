require 'visual/index'

def getIndex(request)
	return $generator.get('Index', visualIndex())
end
