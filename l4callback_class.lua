-- inheritanced method from http://stackoverflow.com/a/6927969/2467963

local writer = require "l4writer"
local callback = {}

local mt_callback = {
  writer = writer(),
}

mt_callback.__index = {
	new = function(self,t)
		return setmetatable(t or {}, {__index=self})
	end,
	inherit=function (self,t,methods)
		local mtnew={__index=setmetatable(methods,{__index=self})}
		return setmetatable(t or {},mtnew)
	end,
	hej = function(self)
		print(self.hello)
	end,
	hello = "world"
	
}

setmetatable(callback, mt_callback)

local k = callback:new()
k:hej()

local j = k:inherit({hello = "dd jj  aa"},{})
j:hej()
