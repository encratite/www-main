def requireConfiguration(name)
	begin
		require "my-configuration/#{name}"
	rescue LoadError
		require "configuration/#{name}"
	end
end
