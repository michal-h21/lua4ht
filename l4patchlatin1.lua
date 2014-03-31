-- file html4.4ht is saved in latin1 encoding, which causes
-- troubles with unicode engines. I don't know whether it is safe
-- to convert this file to utf8, so we use `open_input_file` callback
-- for the conversion on the fly

local latin1_to_utf8 = require "l4latin1"
local function readFile(fn)
  local file = assert(io.open(fn, "r"))
  local contents = file:read("*a")
  file:close()
	-- this is not really flexible solution :)
  if fn:match "html4.4ht" then
    contents = contents:gsub("([\127-\255])", function(c)
      local x = string.byte(c)
      return latin1_to_utf8[x]
    end)
  end
  return contents
end

local function processInputFile(contents)
  -- Process the file: Return each line
	if not contents then 
		print ("nil content")
		return nil 
	end
  for line in contents:gmatch("(.-)[\n\r]") do
    coroutine.yield(line)
  end
	while true do
	  coroutine.yield(nil)
	end
end

-- return callabck function
return function(fileName)
  local contents = readFile(fileName)
  return {
    reader = coroutine.wrap(function()
      processInputFile(contents)
    end)
  }
end

