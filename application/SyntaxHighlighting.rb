require 'SecuredFormWriter'
require 'error'

require 'configuration/loader'
requireConfiguration 'VimSyntax'

require 'www-library/HTML'
require 'www-library/syntaxHighlighting'

module SyntaxHighlighting
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
    return false
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

  def self.highlight(script, code)
    output = WWWLib.syntaxHighlighting(script, code, 'vim')
    if output == nil
      plainError 'Unable to extract the highlighted code from the vim output.'
    end
    return output
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
