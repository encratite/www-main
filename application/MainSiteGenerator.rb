require 'visual/MainSiteGenerator'

require 'www-library/SiteGenerator'

class MainSiteGenerator < WWWLib::SiteGenerator
  def initialize(main, manager)
    super(manager)
    @main = main
  end

  def get(data, request)
    title, content = data
    content = wrapContent(request, content)
    super(title, content)
  end
end
