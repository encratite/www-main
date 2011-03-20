require 'www-library/RequestManager'

require 'SiteContainer'
require 'error'

require 'visual/InstructionSetReferenceHandler'

class InstructionSetReferenceHandler < SiteContainer
  MainTitle = 'x86/x64 Instruction Set Reference'

  def initialize(site)
    super
  end

  def installHandlers
    referenceHandler = WWWLib::RequestHandler.menu('x86/x64 Reference', 'reference', method(:instructionList))
    addMainHandler referenceHandler
    @instructionHandler = WWWLib::RequestHandler.handler('instruction', method(:viewInstruction), 1)
    referenceHandler.add(@instructionHandler)
  end

  def instructionList(request)
    instructions = @database.instruction.select(:instruction_name, :summary)
    content = printInstructionList(instructions)
    return generate(MainTitle, content, request)
  end

  def generate(title, content, request)
    return @referenceGenerator.get([MainTitle, content], request)
  end

  def viewInstruction(request)
    instructionName = request.arguments.first
    instructionRows = @database.instruction.where(instruction_name: instructionName).all
    if instructionRows.empty?
      argumentError
    end
    instruction = instructionRows.first
    instructionId = instruction[:id]
    opcodes = @database.instructionOpcode.where(instruction_id: instructionId)
    content = printViewInstruction(instruction, opcodes)
    return generate("#{instruction} - #{MainTitle}", content, request)
  end
end
