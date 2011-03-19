require 'www-library/RequestManager'

require 'SiteContainer'

class InstructionSetReferenceHandler < SiteContainer
  def initialize(site)
    super
  end

  def installHandlers
    pastebinHandler = WWWLib::RequestHandler.menu('AMD64 Reference', 'reference', method(:instructionList))
    addMainHandler pastebinHandler
  end

  def instructionList(request)
    instructions = @database.instruction.select(:instruction_name, :summary)
  end
end
