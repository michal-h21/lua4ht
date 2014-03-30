local clb = require "node-machine"

local mnode = clb:inherit({},{ill=function(self,s) self:all(s.."\n") end })

local char = unicode.utf8.char

mnode:default (16) (function(self)
  local n = self.node
  self:ill("math node "..n.subtype)
  self:ill("ncleus")
  self:run(n.nucleus)
  self:ill("sub")
  self:run(n.sub)
  self:ill("sup")
  self:run(n.sup)
end)

-- math char
mnode:default(31) (function(self)
  local n= self.node
  local id = n.fam
  local families = {"math italic", "symbols", "extension", "it text", "slanted text", "bold text", "typewriter", [0]="roman"}
  local name=families[id] or "Unknown family"
  --local name = fnt.fullname or fnt.name
  self:ill ("math.char: "..char(n.char).." : "..id)
end)

-- sub_box
mnode:default(32) (function(self)
  local n= self.node
  self:ill("sub_box")
  self:run(n.head)
end)

-- sub_mlist
mnode:default (33) (function(self)
  local n = self.node
  self:ill("sub_mlist")
  self:run(n.head)
end)

return mnode
