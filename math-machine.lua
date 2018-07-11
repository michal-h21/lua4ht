local clb = require "node-machine"

local math_char_id = node.id "math_char"
local sub_box_id = node.id "sub_box"
local sub_mlist_id = node.id "sub_mlist"
local noad_id = node.id "noad"

local mnode = clb:inherit({},{ill=function(self,s) 
  local indent = self.indent or 0 
  local rep = string.rep(" ",indent)
  self:all(rep ..s.."\n") 
end ,
inc_indent = function(self)
  self.indent = self.indent or 0
  self.indent = self.indent + 2
end,
dec_indent = function(self, how)
  local how = how or 2
  self.indent = self.indent or 0
  self.indent = self.indent - how
end,
types = {number ="mn", var="mi", op="mo", normal = "mi mathvariant='normal'"},
make_data = function(self, data)
  local typ = data.type
  local tag = self.types[typ]
  local d  = data.char
  if tag then
    local tg, attr = tag:match("([^ ]-)(.*)")
    d = string.format("<%s%s>%s</%s>",tg,attr,d,tg)
  end
  return d
end,
kernel = function(self, head)
  local id = head.id
  self.node = head
  if id == math_char_id then
    local x = self:run_event(id)
    return {event = "char", x}
  elseif id == sub_box_id then
    return {event="sublist"} 
  elseif id == sub_mlist_id then
    print "kernel: math list"
    local n =head.head
    local last = nil
    local typ = nil
    local current = {}
    local records = {type = "list"}
    while n do
      local id = n.id
      self.node = n
      local c = self:run_event(id) or {}
      if c.event then
        for _, data in ipairs(c) do
          if last and data and data.type == last then 
            print "Všechno stejný"
            current.char = current.char .. data.char
            typ=data.typ
          elseif last and data then 
            print "last a data"
            -- current.data = self:make_data(current)
            current.char = self:make_data(current)
            table.insert(records, current)
            current = data
            typ=data.typ
          elseif data then
            print "jen data"
            for k,v in pairs(data) do
              print(k,v)
            end
            current = data
          end
          last = data.type
          print(last)
        end
      end
      n = node.next(n)
    end
    table.insert(records,current)
    print "return records"
    for _,cv in ipairs(records) do
      print "Vracíme records"
      for k,v in pairs(cv) do
        print(k,v)
      end
    end
    return records
  end

end
}
)

local char = unicode.utf8.char

mnode:default (noad_id) (function(self)
  --local indent = self.indent or 0
  --indent = indent + 2
  --self.indent = indent
  self:inc_indent()
  local n = self.node
  self:ill("math node "..n.subtype)
  --self.indent = indent + 2
  self:inc_indent()
  local x = {}
  local x = self:kernel(n.nucleus)
  --[[if x.event == "char" then
  for _,v in ipairs(x) do
  for k,x in pairs(v) do
  if type(x) == "table" then
  print(k, x.char)
  else
  print("no table", k,x)
  end
  end
  end
  end
  --]]
  self:ill("ncleus")
  -- self:run(n.nucleus)
  self:ill("sub")
  self:run(n.sub)
  self:ill("sup")
  self:run(n.sup)
  self:dec_indent(4)

  return nil,x
end)

-- math char
mnode:default(math_char_id) (function(self)
  local n= self.node
  local id = n.fam
  local families = {"math italic", "symbols", "extension", "it text", "slanted text", "bold text", "typewriter", [0]="roman"}
  local name=families[id] or "Unknown family"
  local st = n.subtype
  --local name = fnt.fullname or fnt.name
  --local indent = self.indent 
  --self.indent = indent + 2
  self:inc_indent()
  local nchar = char(n.char)
  self:ill ("math.char: "..nchar.." : "..id)
  self:dec_indent()
  local t= {type = "char", char = nchar, fam = id}
  return nil, t 
end)

-- sub_box
mnode:default(sub_box_id) (function(self)
  local n= self.node
  self:inc_indent()
  self:ill("sub_box")
  self:run(n.head)
  self:dec_indent()
end)

-- sub_mlist
mnode:default (sub_mlist_id) (function(self)
  local n = self.node
  self:inc_indent()
  self:ill("sub_mlist")
  self:run(n.head)
  self:dec_indent()
end)

return mnode
