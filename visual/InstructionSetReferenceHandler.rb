require 'SiteContainer'

require 'www-library/HTMLWriter'

class InstructionSetReferenceHandler < SiteContainer
  def printInstructionList(rows)
    writer = WWWLib::HTMLWriter.new
    writer.p(id: 'instructionListDescription') do
      <<-EOF
This is an unofficial online version of the Intel 64 instruction set reference.
It provides a list of the available instructions for IA-32 and Intel 64 microprocessors, their assembly mnemonics, encodings, descriptions, pseudo code and the exceptions they can throw.
This information is largely compatible with AMD64 processors, except for some minor differences.
EOF
    end
    writer.table(id: 'instructionList') do
      writer.tr do
        writer.th { 'Instruction' }
        writer.th { 'Description' }
      end
      rows.each do |row|
        instruction = row[:instruction_name]
        description = row[:summary]
        writer.tr do
          writer.td do
            writer.a(href: @instructionHandler.getPath(instruction)) { instruction }
          end
          writer.td { description }
        end
      end
      nil
    end
    return writer.output
  end

  def processOpcode(writer, opcode)
    fields = [
      [:opcode, false],
      [:mnemonic_description, false],
      [:encoding_identifier, false],
      [:long_mode_validity, true],
      [:legacy_mode_validity, true],
      [:description, false],
    ]
    colours = {
      'Invalid' => 'invalidField',
      'Valid' => 'validField',
    }
    writer.tr do
      fields.each do |symbol, isValidityField|
        value = opcode[symbol]
        if value == nil
          value = 'None'
        end
        writer.td do
          if isValidityField
            validityClass = colours[value]
            if validityClass == nil
              value
            else
              writer.span(class: validityClass) { value }
            end
          else
            value
          end
        end
      end
    end
  end

  def writeEncodings(writer, encodings)
    encodings.each do |identifier, descriptions|
      writer.tr do
        writer.td { identifier }
        descriptions.each do |description|
          writer.td { description }
        end
        nil
      end
    end
    return
  end

  def writeEncodingTable(writeTitle, writer, encodings)
    return if encodings.empty?
    writeTitle.call('Instruction Operand Encoding')
    writer.table(id: 'instructionEncodingsTable') do
      writer.tr do
        fields = ['Op/En']
        4.times do |i|
          fields << "Operand #{i}"
        end
        fields.each do |field|
          writer.th { field }
        end
      end
      writeEncodings(writer, encodings)
    end
  end

  def printViewInstruction(instruction, opcodes, encodings)
    instructionId = instruction[:id]
    name = instruction[:instruction_name]
    summary = instruction[:summary]
    description = instruction[:description]
    #the following three entries may be NULL
    pseudoCode = instruction[:pseudo_code]
    flagsAffected = instruction[:flags_affected]
    fpuFlagsAffected = instruction[:fpu_flags_affected]
    writer = WWWLib::HTMLWriter.new
    writeTitle = lambda do |title|
      writer.h2(id: 'instructionSectionTitle') { title }
    end
    writer.h1(id: 'instructionTitle') { name }
    writer.p(id: 'instructionSummary') { summary }
    writeTitle.call('Opcodes')
    writer.table(id: 'instructionOpcodeTable') do
      writer.tr do
        headers = [
          'Hex',
          'Mnemonic',
          'Encoding',
          'Long Mode',
          'Legacy Mode',
          'Description',
        ]
        headers.each do |header|
          writer.th { header }
        end
      end
      opcodes.each do |opcode|
        processOpcode(writer, opcode)
      end
      nil
    end
    writeEncodingTable(writeTitle, writer, encodings)
    writeTitle.call('Description')
    writer.div(id: 'instructionDescription') { description }
    if pseudoCode != nil
      writeTitle.call('Pseudo Code')
      writer.pre(id: 'instructionPseudoCode') { pseudoCode }
    end
    if flagsAffected != nil
      writeTitle.call('Flags Affected')
      writer.p(id: 'instructionFlagsAffected') { flagsAffected }
    end
    if fpuFlagsAffected != nil
      writeTitle.call('FPU Flags Affected')
      writer.p(id: 'instructionFPUFlagsAffected') { fpuFlagsAffected }
    end
    return writer.output
  end
end
