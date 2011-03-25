require 'nil/file'

require 'www-library/RequestManager'

require 'SiteContainer'
require 'error'

require 'visual/DocumentHandler'

class DocumentHandler < SiteContainer
  Title = 'Documents'

  Documents = [
    ['x86 Assembly for Userland Applications: A Hands-On Approach', 'A practical introduction to writing 32-bit userland applications for common operating systems such as Windows and Linux on IA-32 hardware using the low-level assembly programming language.', 'x86-assembly'],
  ]

  def installHandlers
    listHandler = WWWLib::RequestHandler.menu(Title, 'documents', method(:documentList))
    @viewDocumentHandler = WWWLib::RequestHandler.handler('document', method(:viewDocument), 1)
    addMainHandler listHandler
    listHandler.add(@viewDocumentHandler)
  end

  def documentList(request)
    content = renderDocumentList
    return @generator.get([Title, content], request)
  end

  def viewDocument(request)
    document = request.arguments.first
    Documents.each do |title, description, base|
      next if base != document
      content = Nil.readFile(Nil.joinPaths('static', 'document', base, "#{base}.html"))
      return @generator.get([title, content], request)
    end
    argumentError
  end
end
