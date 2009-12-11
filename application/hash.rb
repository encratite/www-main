require 'configuration/database'
require 'digest/sha2'
#require 'pg'
require 'sequel'

def hashWithSalt(input)
	hash = Digest::SHA256.hexdigest(DatabaseConfiguration::PasswordSalt + input)
	size = hash.size
	hash = hash.unpack('a2' * size).map{|x| x.hex}.pack('c' * size)
	#PGconn.escape_bytea hash
	hash = hash.to_sequel_blob
	return hash
end
