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
	hello  = "world",
	state  = "start",
  events = {},
	-- add callback for given event and state
	-- for callback without state, use `default`
	event  = function(self, event) 
		local ev = self.events[event] or {}
		return function(state)
			return function(fn)
				 print("setting event "..event .. " and state "..state)
				 ev[state] = fn
				 self.events[event] = ev
			end
		end
	end,
	default = function(self, event)
		return self:event(event) "*"
	end,
	run = function(self, events)
		local state = self.state
		local ev = self.events or {}
		for _,e in ipairs(events) do
			local currevent = ev[e] or {}
			local fn = currevent[state] or currevent['*']
			if not fn then print("No callback for ".. e .. " and state "..state) 
			else
				fn(self)
				-- state = fn(self)
			end
		end
	end
}


setmetatable(callback, mt_callback)

local k = callback:new()
k:hej()
k:default "pokus" (function(self)
	print(self.hello)
end)

local function pr(t, s)
	local s = s or ""
	for k, v in pairs(t) do
		if type(v) == "table" then
			print(s,k,":")
			pr(v, s.."  ")
		else
		  print(s,k, v)
		end
	end
end

--  pr(k.events)

local actions = {"pokus", "ahoj"}
k:run(actions)
-- make lua node processing stack machine
-- also stack machine for tex4ht specials
-- possible states
--   ignore output - shoud be stack
--   ignore one char (maybe discard next node directly)
--   math nodes
--   NoFonts -- also stack
