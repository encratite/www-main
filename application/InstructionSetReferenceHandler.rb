require 'www-library/RequestManager'

require 'SiteContainer'
require 'error'

require 'visual/InstructionSetReferenceHandler'

class InstructionSetReferenceHandler < SiteContainer
  MainTitle = 'x86/x64 Instruction Set Reference'

  def initialize(site)
    super
    @referenceGenerator = @generatorMethod.call(['reference'])
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
    opcodeEncodingRows = @database.instructionOpcodeEncoding.where(instruction_id: instructionId)
    encodings = {}
    opcodeEncodingRows.each do |opcodeEncodingRow|
      id = opcodeEncodingRow[:id]
      identifier = opcodeEncodingRow[:identifier]
      descriptions = []
      encodingDescriptionRows = @database.instructionOpcodeEncodingDescription.where(instruction_opcode_encoding_id: id)
      encodingDescriptionRows.each do |encodingDescriptionRow|
        descriptions << encodingDescriptionRow[:description]
      end
      encodings[identifier] = descriptions
    end
    exceptionCategories = {}
    exceptions = @database.instructionException.where(instruction_id: instructionId).left_outer_join(:instruction_exception_category, :id => :category_id).all
    exceptions.each do |exception|
      category = exception[:category_name]
      categoryExceptions = exceptionCategories[category]
      if categoryExceptions == nil
        categoryExceptions = []
      end
      categoryExceptions << exception
      exceptionCategories[category] = categoryExceptions
    end
    content = printViewInstruction(instruction, opcodes, encodings, exceptionCategories)
    return generate("#{instruction} - #{MainTitle}", content, request)
  end
end
