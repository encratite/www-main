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
		
		fields = names.map { |name| request.getPost(name) }
		fieldError if fields.include?(nil) || randomString == nil || formHash == nil
		
		addressHash = fnv1a(request.address)
		
		input = randomString + addressHash
		hash = fnv1a(input)
		if hash != formHash
			raise RequestManager::Exception.new(@generator.get(hashError, request))
		end
		
		return fields
	end
end
