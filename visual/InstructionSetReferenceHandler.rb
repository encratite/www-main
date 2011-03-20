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

  def printViewInstruction(instructionRow)
    instructionId = instructionRow[:id]
    name = instructionRow[:instruction_name]
    summary = instructionRow[:summary]
    description = instructionRow[:description]
    #the following three entries may be NULL
    pseudoCode = instructionRow[:pseudo_code]
    flagsAffected = instructionRow[:flags_affected]
    fpuFlagsAffected = instructionRow[:fpu_flags_affected]
    writer = WWWLib::HTMLWriter.new
    writeTitle = lambda do |title|
      writer.h2(id: 'instructionSectionTitle') { title }
    end
    writer.h1(id: 'instructionTitle') { name }
    writer.p(id: 'instructionSummary') { summary }
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
