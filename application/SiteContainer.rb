require 'www-library/RequestManager'

class SiteContainer
  def initialize(site)
    site.instance_variables.each do |variable|
      symbol = variable.to_s
      value = site.instance_variable_get symbol
      instance_variable_set(symbol, value)
    end

    @site = site

    installHandlers
  end

  def installHandler(handler)
    @requestManager.addHandler handler
    return nil
  end

  def addMainHandler(handler)
    @site.mainHandler.add handler
  end

  def processFormFields(request, names)
    randomString = request.getPost(SecuredFormWriter::RandomString)
    formHash = request.getPost(SecuredFormWriter::HashField)

    fieldError if randomString == nil || formHash == nil
    missingSymbols = []
    fields = names.map do |name|
      output = request.getPost(name)
      if output == nil
        missingSymbols << name
      end
      output
    end

    if !missingSymbols.empty?
      puts "Missing symbols: #{missingSymbols.inspect}"
      fieldError
    end

    addressHash = fnv1a(request.address)

    input = randomString + addressHash
    hash = fnv1a(input)
    raiseError(hashError, request) if hash != formHash

    return fields
  end

  def raiseError(error, request)
    raise WWWLib::RequestManager::Exception.new(@generator.get(error, request))
  end
end
