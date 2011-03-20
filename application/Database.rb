require 'nil/symbol'

class Database
  include SymbolicAssignment

  TableMap =
    {
    user: :site_user,
    loginSession: :login_session,
    post: :pastebin_post,
    unit: :pastebin_unit,
    floodProtection: :flood_protection,

    instruction: :instruction,
    instructionOpcode: :instruction_opcode,
    instructionOpcodeEncoding: :instruction_opcode_encoding,
    instructionOpcodeEncodingDescription: :instruction_opcode_encoding_description,
    instructionExceptionCategory: :instruction_exception_category,
    instructionException: :instruction_exception,
  }

  def initialize(database)
    TableMap.each do |memberSymbol, tableSymbol|
      value = database[tableSymbol]
      setMember(memberSymbol, value)
    end

    @connection = database

    Database.createReaders
  end

  def self.createReaders
    TableMap.each do |memberSymbol, tableSymbol|
      define_method(memberSymbol) do
        getMember(memberSymbol)
      end
    end
  end

  def transaction(&block)
    @connection.transaction do
      block.call
    end
  end
end
