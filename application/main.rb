$:.concat ['..', 'application']

require 'site/RequestManager'
require 'index'

$manager = RequestManager.new
$manager.addHandler('/', method(:getIndex))
