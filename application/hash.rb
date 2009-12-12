require 'configuration/database'
require 'digest/sha2'
require 'sequel'

def hashWithSalt(input)
	hash = Digest::SHA256.hexdigest(DatabaseConfiguration::PasswordSalt + input)
	hash = hash.unpack('a2' * (hash.size / 2)).map{|x| x.hex}
	hash = hash.pack('c' * hash.size)
	hash = hash.to_sequel_blob
	return hash
end
