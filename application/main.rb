$: << '../..'

require 'utility/RequestManager'
require 'index'

manager = RequestManager.new
manager.addHandler('/', method(:getIndex))
