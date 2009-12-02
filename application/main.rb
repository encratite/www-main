$:.concat ['..', 'application']

require 'site/RequestManager'
require 'site/SiteGenerator'
require 'index'

$manager = RequestManager.new
$manager.addHandler('/', method(:getIndex))

$generator = SiteGenerator.new
