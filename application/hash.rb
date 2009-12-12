require 'configuration/database'
require 'digest/sha2'
require 'sequel'

def hashWithSalt(input)
	hash = Digest::SHA256.hexdigest(DatabaseConfiguration::PasswordSalt + input)
	puts hash
	size = hash.size
	puts size
	hash = hash.unpack('a2' * size).map{|x| x.hex}.pack('c' * size)
	puts hash
	hash = hash.to_sequel_blob
	puts hash
	return hash
end
