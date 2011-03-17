class SiteConfiguration
  StaticDirectory = 'static'
  StylesheetDirectory = 'style'
  ImageDirectory = 'image'
  ScriptDirectory = 'script'

  GeneralStringLengthMaximum = 128

  UserNameLengthMaximum = GeneralStringLengthMaximum
  PasswordLengthMaximum = GeneralStringLengthMaximum
  EmailLengthMaximum = 1024

  SessionStringLength = 128
  CookieDurationInDays = 30

  DebuggingAddresses = []
end
