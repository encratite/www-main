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

def serialiseFields(fields)
	return fields.join ':'
end

def hashCheck(fields, security)
	return javaScriptError if security.empty?
	#data = fields.join "\x00"
	data = serialiseFields fields
	hash = fnv1a data
	#debug = fields.join("\\x00")
	debug = fields.join ':'
	#debug["\n"] = "\\n"
	#debug["\r"] = "\\r"
	puts "Data: #{debug.inspect} (#{data.length})"
	puts "#{hash} vs #{security}"
	return hashError if hash != security
	return nil
end


