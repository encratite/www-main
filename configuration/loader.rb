def requireConfiguration(name)
  begin
    require "myConfiguration/#{name}"
  rescue LoadError
    require "configuration/#{name}"
  end
end
