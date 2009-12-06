class SiteConfiguration
	SitePrefix = '/main/'
	StaticPath = SitePrefix + 'static/'
	
	StylesheetDirectory = 'style'
	ImageDirectory = 'image'
	
	GeneralStringLengthMaximum = 64
	
	UserNameLengthMaximum = GeneralStringLengthMaximum
	PasswordLengthMaximum = GeneralStringLengthMaximum
	
	SessionStringLength = 128
	SessionDurationInDays = 30
end
