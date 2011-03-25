require 'www-library/HTMLWriter'

require 'SiteContainer'

class DocumentHandler < SiteContainer
  def renderDocumentList
    writer = WWWLib::HTMLWriter.new
    writer.p do
      writer.write 'I am the author of all of the following documents. They are released under the '
      writer.a(href: 'http://creativecommons.org/licenses/by-sa/3.0/') do
        'Creative Commons Attribution-ShareAlike 3.0 Unported License'
      end
      writer.write '. Just refer to this website to satisfy the attribution clause.'
    end
    writer.ul(class: 'regular') do
      Documents.each do |title, description, base|
        writer.li do
          writer.b do
            writer.a(href: @viewDocumentHandler.getSlashPath(base)) { title }
          end
          writer.write ": #{description}"
        end
      end
    end
    return writer.output
  end

  def renderViewDocument(document)
    writer = WWWLib::HTMLWriter.new
    writer.div(id: 'document') do
      document
    end
    return writer.output
  end
end
