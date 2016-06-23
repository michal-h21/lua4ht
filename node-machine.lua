kpse.set_program_name "luatex"
local callback = require "l4callback_class"
local writer   = require "l4writer"

function bit(p)                                                                 
  return 2 ^ (p - 1) -- 1-based indexing                                        
end -- Typical call: if hasbit(x, bit(3)) then ... i                            
function hasbit(x, p)                                                           
  return x % (p + p) >= p                                                       
end   

-- define which glue subtypes will be regarded as spaces
local set_glue_types = function(types)
  local t = {}
  for _,v in ipairs(types) do
    t[v] = true
  end
  return t
end

local j = callback:inherit({},{
	node = {},
	writer = writer(),
	-- normal space, leftskip, rightskip, spaceskip
	allowed_space = set_glue_types{0, 8, 9, 13},
	open   = function(self, filename)
		self.writer:open(filename)
	end,
	write  = function(self,s)
		self.writer:write(s)
	end,
	all    = function(self,s)
		self.writer:all(s)
	end,
	lg     = function(self,s)
		self.writer:lg(s)
	end,
	skip_char = function(self)
		self.writer:skip_char()
	end,
	noskip_char = function(self)
		self.writer:noskip_char()
	end,
	close  = function(self)
		self.writer:close()
	end,
	finish = function(self)
		self.writer:finish()
	end,
	run_event = function(self,id)
		local state = self.state
		local ev = self.events or {}
		local currevent = ev[id] or {}
		local fn = currevent[state] or currevent['*']
		local data = nil
		if not fn then 
			print ("No callback for id "..id.. " and state ".. state)
		else
			local nstate
			nstate, data = fn(self) 
			state = nstate or state
		end
		self.state = state
		return data
	end,
	run = function(self, head)
		--self:open(tex.jobname..".txt")
		--local state = self.state
		--local ev = self.events or {}
		self.head = head
		for n in node.traverse(head) do
			local id = n.id
			self.node = n
			self:run_event(id)
			--local currevent = ev[id] or {}
			--local fn = currevent[state] or currevent['*']
			--if not fn then 
			--	print ("No callback for id "..id.. " and state ".. state)
			--else
			--	state = fn(self) or state
			--end
			--self.state = state
		end
		--self:close()
		return head
	end
})

local char = unicode.utf8.char
local escape = {
	['"'] =   '&quot;',
	["'"] =    '&apos;',
	["<"] =   '&lt;',
	['>'] =  '&gt;',
	['&'] =  '&amp;'
}

j:default (node.id "glyph") (function(self)--(node.type "glyph") (function(self)
	local n = self.node
  local st = n.subtype
  if hasbit(st, bit(2)) then
		self:run(n.components)
	else
		local chr = char(n.char)
		chr = escape[chr] or chr
		--print(chr)
		self:write(chr)
  end
end)

-- glyph
--[[j:event (37) "math_on" (function(self)
	local n = self.node
	print("math: ".. char(n.char))
end)
--]]
-- glue
j:default (node.id "glue") (function(self)
	local n = self.node
	local subtype = n.subtype
	-- test if glue is space
	local allowed = self.allowed_space[subtype]
  if allowed then
		self:write " "
	else
		self:all("<!-- glue: "..n.subtype.." -->")
	end
end)

local run_sub_head = function(obj,id)
	obj:default (id) (function(self)
		local n = self.node
		print(node.type(id).."[")
		self:run(n.head)
		print "]"
	end)
end

run_sub_head(j,0)
run_sub_head(j,1)
run_sub_head(j,3)

j:default (node.id "math") (function(self)
	local n = self.node
	local st = n.subtype
	if st == 0 then
		return "math_on"
	end
	return "math_of"
end)

local tex4ht = callback:inherit({},{
	run = function(self, parent)
		self.parent  = parent
		self.node    = parent.node
		local events = self.events or {}
		self.state = parent.state
		local state = self.state 
		local node   = self.node 
		local data = node.data or ""
		local action, rest = data:match("t4ht(.)(.*)")
		self.rest = rest
		local currevent = events[action] or {}
		local fn = currevent[state] or currevent['*']
		if fn then
			state = fn(self) or state
		else
			self:comment()
		end
	end,
	subtype = function(self)
		local rest = self.rest or ""
		return rest:match("(.)(.*)")
	end,
	comment = function(self)
		local node = self.node
		local data = node.data
		local parent = self.parent
		parent:all("<!-- tex4ht: "..data.." -->")
	end
})

-- write tag
tex4ht:default "=" (function(self)
	local parent = self.parent
	local rest   = self.rest
	parent:write(rest)
end)
--[[
tex4ht:event "=" "math_on" (function(self)
	local parent = self.parent
	local rest = self.rest
	parent:all("math mode on: "..rest)
end)
]]
-- open default file with extension
tex4ht:default "." (function(self)
	local parent = self.parent
	local rest   = self.rest
	local filename = tex.jobname ..".".. rest
	parent:open(filename)
end)

-- open file
tex4ht:default ">" (function(self)
	local parent = self.parent
	local filename = self.rest 
	if filename == "" then filename = nil end
	parent:open(filename)
end)

tex4ht:default "<" (function(self)
	local parent = self.parent
	parent:close()
end)

tex4ht:default "+" (function(self)
	local parent = self.parent
	local subtype, rest = self:subtype()
	if subtype == "@" then
		parent:lg(rest)
	end
end)

tex4ht:default "@" (function(self)
	local parent = self.parent
	local subtype, rest = self:subtype()
	if subtype == "[" then
		parent:skip_char()
	elseif subtype == "]" then
		parent:noskip_char()
	elseif subtype == "+" then
		-- xml entity insertion
		-- maybe char could be also inserted?
		local entity = rest:gsub("{([^}]+)}", function(c)
			return char(tonumber(c))
		end)
		local n = self.node
		node.remove(parent.head,node.next(n))
		parent:write(entity)
	else
		self:comment()
	end
end)

j:default (node.id "whatsit") (function(self)
	local n = self.node
	if n.subtype == 3 then
	  tex4ht:run(self)
	end
end)

--]]
-- j:run {"pokus","ssss","aaa"}
return j