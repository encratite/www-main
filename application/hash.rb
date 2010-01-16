require 'configuration/database'
require 'digest/sha2'
require 'sequel'
require 'error'

def hashWithSalt(input)
	hash = Digest::SHA256.hexdigest(DatabaseConfiguration::PasswordSalt + input)
	hash = hash.unpack('a2' * (hash.size / 2)).map{|x| x.hex}
	hash = hash.pack('c' * hash.size)
	hash = hash.to_sequel_blob
	return hash
end

def fnv1a(input)
	hash = 2166136261
	shifts = [1, 4, 7, 8, 24]
	mask = 0xffffffff
	input.each_byte do |byte|
		next if byte < 32
		hash ^= byte
		shiftedHash = hash
		shifts.each do |shift|
			summand = (hash << shift) & mask
			shiftedHash = (shiftedHash + summand) & mask
		end
		hash = shiftedHash
	end
	return hash.to_s(16).upcase
end
