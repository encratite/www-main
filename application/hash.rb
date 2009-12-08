require 'configuration/database'
require 'digest/md5'

def hashWithSalt(input)
	Digest::MD5.hexdigest(DatabaseConfiguration::PasswordSalt + input)
end
