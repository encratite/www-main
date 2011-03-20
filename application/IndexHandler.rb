require 'SiteContainer'
require 'www-library/RequestHandler'
require 'visual/index'

class IndexHandler < SiteContainer
  Description = 'Index'

  def installHandlers
    indexHandler = WWWLib::RequestHandler.menu(Description, nil, method(:getIndex))
    @mainHandler.add(indexHandler)
    WWWLib::RequestHandler.newBufferedObjectsGroup
  end

  def getIndex(request)
    @generator.get([Description, visualIndex()], request)
  end
end
