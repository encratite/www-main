require 'SessionManager'
require 'MainSiteGenerator'
require 'SiteRequest'
require 'hash'
require 'error'
require 'SecuredFormWriter'
require 'Database'

require 'sequel'

require 'configuration/loader'
requireConfiguration 'database'
requireConfiguration 'site'

require 'www-library/RequestManager'
require 'www-library/RequestHandler'
require 'www-library/debug'

class MainSite
  attr_accessor :requestManager, :mainHandler

  Icon = 'caput'

  MetaKeywords = 'assembly,asm,programming,optimization,optimisation,c,c++,x86,pastebin,opcode,opcodes,dictionary,intel,amd,download,downloads,tutorial'
  MetaDescription = 'x86 assembly tutorials, x86/x64 opcode reference, programming, pastebin with syntax highlighting'
  MetaRobots = 'index, follow'

  def initialize
    @database = getDatabaseObject
    @sessionManager = SessionManager.new @database

    @requestManager = WWWLib::RequestManager.new(lambda { |environment| SiteRequest.new(@sessionManager, environment) } )
    @mainHandler = WWWLib::RequestHandler.new('main')
    @requestManager.addHandler @mainHandler

    @generator = getSiteGenerator
    @generatorMethod = method(:getSiteGenerator)

    #set up additional addresses which will be able to view debugging output on exceptions thrown by scripts right in the browser
    SiteConfiguration::DebuggingAddresses.each do |address|
      WWWLib::PrivilegedAddresses.add(address)
    end
  end

  def getDatabaseObject
    database =
      Sequel.connect(
                     adapter: DatabaseConfiguration::Adapter,
                     host: DatabaseConfiguration::Host,
                     user: DatabaseConfiguration::User,
                     password: DatabaseConfiguration::Password,
                     database: DatabaseConfiguration::Database
                     )
    return Database.new(database)
  end

  def getSiteGenerator(stylesheets = [], scripts = [])
    stylesheets = ['base'] + stylesheets
    scripts = ['hash'] + scripts
    output = MainSiteGenerator.new(self, @requestManager)
    output.setIcon(getIcon(Icon))
    output.setMeta('keywords', MetaKeywords)
    output.setMeta('description', MetaDescription)
    output.setMeta('robots', MetaRobots)
    stylesheets.each { |path| output.addStylesheet(getStylesheet path) }
    scripts.each { |script| output.addScript(getScript script) }
    return output
  end

  def getCookie(name, value)
    sessionCookie = WWWLib::Cookie.new(name, value, mainHandler.getPath)
    sessionCookie.expirationDays SiteConfiguration::CookieDurationInDays
    return sessionCookie
  end

  def getStaticPath(base, file)
    return @mainHandler.getPath(SiteConfiguration::StaticDirectory, base, file)
  end

  def getStylesheet(name)
    return getStaticPath(SiteConfiguration::StylesheetDirectory, name + '.css')
  end

  def getImage(file)
    return getStaticPath(SiteConfiguration::ImageDirectory, file)
  end

  def getIcon(name)
    return getStaticPath(SiteConfiguration::IconDirectory, name + '.ico')
  end

  def getScript(name)
    return getStaticPath(SiteConfiguration::ScriptDirectory, name + '.js')
  end
end
