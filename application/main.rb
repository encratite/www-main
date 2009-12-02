['..', 'application'].each { |path| $: << path }

require 'site/RequestManager'
require 'index'

$manager = RequestManager.new
$manager.addHandler('/', method(:getIndex))
