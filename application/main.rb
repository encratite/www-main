$:.concat ['..', 'application']

require 'site/RequestManager'
require 'site/SiteGenerator'
require 'index'

handlers =
[
	['/', :getIndex]
]

prefix = '/main'

$manager = RequestManager.new
handlers.each { |path, symbol| $manager.addHandler(prefix + path, symbol) }

$generator = SiteGenerator.new
