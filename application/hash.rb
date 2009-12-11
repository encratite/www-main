require 'configuration/database'
require 'digest/sha2'

def hashWithSalt(input)
	hash = Digest::SHA256.hexdigest(DatabaseConfiguration::PasswordSalt + input)
	size = hash.size
	unpack('a2' * size).map{|x| x.hex}.pack('c' * size)
end
