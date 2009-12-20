require 'configuration/site'

def getStaticPath(base, file)
	SiteConfiguration::StaticPath + base + '/' + file
end

def getStylesheet(name)
	getStaticPath(SiteConfiguration::StylesheetDirectory, name + '.css')
end

def getImage(file)
	getStaticPath(SiteConfiguration::ImageDirectory, file)
end

def getScript(name)
	getStaticPath(SiteConfiguration::ScriptDirectory, name + '.js')
end
