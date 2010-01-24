$:.concat ['..', 'application']

require 'MainSite'

require 'IndexHandler'
require 'PastebinHandler'

$mainSite = MainSite.new
indexHandler = IndexHandler.new $mainSite
pastebinHandler = PastebinHandler.new $mainSite
