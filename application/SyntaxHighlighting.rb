require 'fileutils'

require 'SecuredFormWriter'
require 'error'

require 'configuration/loader'
requireConfiguration 'VimSyntax'

require 'nil/file'

require 'www-library/HTML'
require 'www-library/string'

class SyntaxHighlighting
  def self.generateList(isCommon)
    output = []
    VimSyntax::Scripts.each do |script|
      value = script[0]
      description = WWWLib::HTMLEntities.encode script[1]
      if !isCommon || (script.size >= 3 && script[2])
        output << WWWLib::SelectOption.new(description, value)
      end
    end
    output
  end

  def self.isValidScript(script)
    VimSyntax::Scripts.each do |file, description|
      return true if file == script
    end
    return fakse
  end

  def self.getSelectionList(isCommon, selection)
    source = isCommon ? CommonScripts : AllScripts
    return source if selection == nil
    output = []
    source.each do |option|
      if option.value != selection
        output << option
        next
      end
      newOption = option.clone
      newOption.selected = true
      output << newOption
    end
    return output
  end

  def self.highlight(script, input)
    outputFile = Tempfile.new('outputFile')
    outputFile.close

    input = input.delete("\r")
    inputFile = Tempfile.new('inputFile')
    inputFile << input
    inputFile.close

    flags = ['f', 'n', 'X', 'e', 's']

    vimDirectory = Nil.joinPaths(Dir.home, '.vim')
    #scriptFile = 'pastebin.vim'
    scriptFile = 'pastebin.vim'
    localPath = Nil.joinPaths('vim', scriptFile)
    scriptPath = Nil.joinPaths('syntax', scriptFile)
    fullPath = Nil.joinPaths(vimDirectory, scriptPath)

    FileUtils.mkdir_p(File.dirname(fullPath))
    FileUtils.cp(localPath, fullPath)

    vimCommands =
      [
       "set filetype=#{script}",
       'set background=light',
       'set wrap linebreak textwidth=0',
       'syntax on',
       'let html_use_css=1',
       "run #{scriptPath}",
       "wq! #{outputFile.path}",
       'q',
      ]

    flags = flags.map { |flag| "-#{flag}" }
    flags = flags.join ' '

    vimCommands = vimCommands.map { |cFlag| "-c \"#{cFlag}\"" }
    vimCommands = vimCommands.join ' '

    #output = system "#{PastebinConfiguration::VimPath} #{flags} #{vimCommands} #{inputFile.path}"
    #plainError 'A vim error occured' if !output
    line = "#{PastebinConfiguration::VimPath} #{flags} #{vimCommands} #{inputFile.path}"
    output = `#{line}`

    markup = outputFile.open.read

    code = WWWLib.extractString(markup, "<pre>\n", "</pre>")
    if code == nil
      plainError 'Unable to extract code from vim output.'
    end

    return code
  end

  def self.getScriptDescription(script)
    return 'Plain text' if script == nil
    AllScripts.each do |option|
      return option.description if option.value == script
    end
    raise 'Encountered an invalid script name in a unit.'
  end

  CommonScripts = self.generateList true
  AllScripts = self.generateList false
end
