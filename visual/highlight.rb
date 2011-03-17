def applyWriter(input, &block)
  writer = WWWLib::HTMLWriter.new
  block.call(writer, input)
  return writer.output
end

def makeCursive(input)
  applyWriter(input) do |writer, input|
    writer.i { input }
  end
end

def makeBold(input)
  applyWriter(input) do |writer, input|
    writer.b { input }
  end
end
