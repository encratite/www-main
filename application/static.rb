require 'configuration/site'

def getStylesheet(name)
	SiteConfiguration::StaticPath + SiteConfiguration::StylesheetDirectory + '/' + name + '.css'
end

def getImage(file)
	SiteConfiguration::StaticPath + SiteConfiguration::ImageDirectory + '/' + file
end
