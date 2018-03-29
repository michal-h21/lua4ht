kpse.set_program_name("luatex")
local M = {}

local writer = require "l4writer"


local glyph_id = node.id("glyph")
local hlist_id = 0
local vlist_id = node.id("vlist")
local disc_id = 7
local whatsit_id = 8
local glue_id = 10
local kern_id = 11
local noad_id = node.id("noad")
local sub_mlist_id = node.id("sub_mlist")
local sub_box_id = node.id("sub_box")
local frac_id = node.id("fraction")
local radical_id = node.id("radical")
local delim_id = node.id("delim")
local fence_id = node.id("fence")
local utfchar = unicode.utf8.char
local types = node.types()
local math_char_id = node.id("math_char") 
local input =  nil --io.open(tex.jobname .. ".txt","w")
local opened_files = {}
local file_stack = {}

function bit(p) 
  return 2 ^ (p - 1) -- 1-based indexing 
end -- Typical call: if hasbit(x, bit(3)) then ... i
function hasbit(x, p) 
  return x % (p + p) >= p 
end



local open_file = function(filename)
  --if input then input:close() end
  if filename then
    table.insert(file_stack, filename)
  else
    filename = file_stack[#file_stack] 
  end
  local i = opened_files[filename] or io.open(filename,"w")
  opened_files[filename] = i
  input = i
end


w = writer()
--open_file(tex.jobname..".txt")
w:open(tex.jobname..".txt")
process =  function(head)
  local current = {}  
  for n in node.traverse(head) do
    local id = n.id
    if id == glyph_id then
      local chr = ""
      if n.subtype > 0 and n.components then
        chr = process(n.components)
      else
        local s = n.subtype
        if not hasbit(s,bit(1)) then
          chr = utfchar(n.char)
        else
          print("Bit 1 set",n.char,s)
        end
      end
      w:write(chr)
      table.insert(current, chr)
    elseif id == glue_id and n.subtype == 0 then 
      w:write(" ")
      table.insert(current, " ")
    elseif id == hlist_id then
      table.insert(current, process(n.head))
    elseif id == vlist_id then 
      table.insert(current, process(n.head))
    elseif id == sub_mlist_id then
      w:all("sub_mlist[")
      table.insert(current, process(n.head))
      w:all "]"
    elseif id == sub_box_id then
      w:all("sub_box[")
      table.insert(current, process(n.head))
      w:all("]")
    elseif id == noad_id then
      w:all  ("\nnoad["..n.subtype.."\n")
      table.insert(current, process(n.nucleus))
      w:all "\n noad sup: "
      process(n.sup)
      process(n.sub)
      w:all "]\n"
    elseif  id == math_char_id then
      w:all(utfchar(n.char)..":"..n.fam)
    elseif id == frac_id then
      w:all "\nfraction[\n"
      process(n.left)
      process(n.num)
      process(n.denom)
      process(n.right)
      w:all "]\n"
    elseif id == whatsit_id and n.subtype == 3 then
      local k =  process_tex4ht(n.data) -- "<!-- " .. n.data .. " -->"
      --w:write(k)
      table.insert(current, k)
    elseif id == radical_id then
      w:all "radical[\n"
      w:all "sub:" 
      process(n.sub)
      w:all " sup:"
      process(n.sup)
      w:all " nucleus:"
      process(n.nucleus)
      w:all " left:"
      process(n.left)
      w:all " degree:"
      process(n.degree)
      w:all "\n]\n"
    elseif id == fence_id then
      w:all ("fence["..n.subtype.."\n")
      process(n.delim)
      w:all "\n]\n"
    elseif id==delim_id then
      w:all "delim[\n"
      local small_char = n.small_char
      local large_char = n.large_char
      w:all(small_char .. ":"..large_char)
      w:all "\n]\n"
    else
      local subtype = n.subtype or ""
      w:all("["..id..":"..types[id]..":"..subtype .."]")
    end
  end
  return table.concat(current)
end

process_tex4ht = function(data)
   local action, rest = data:match("t4ht(.)(.*)") 
   action=action or ""
   rest = rest or ""
   local msg = ""
   if action == ">" then
     local filename = rest
     if filename == "" then filename = nil end
     --open_file(filename)
     w:open(filename)
     filename = filename or ""
     msg =  "<!-- open file:" ..filename.." -->"
   elseif action == "<" then 
     table.remove(file_stack)
     --input:close()
     --local current_filename = file_stack[#file_stack]
     --print("Close file, current:", current_filename)
     --input = opened_files[current_filename]
     w:close()
     msg =  "close file:" ..rest
   elseif action == "." then
     local filename = tex.jobname .."."..rest
     w:open(filename)
     msg =  "extension: "..rest 
   elseif action == "=" then 
     w:write(rest)
     return rest
   elseif action == "+" then
     local subaction, lrest = rest:match("(.)(.*)")
     if subaction == "@" then
       w:lg(lrest)
       return rest
     else
       msg = action..rest
     end
   elseif action == "@" then 
     local subaction, lrest = rest:match("(.)(.*)")
     if subaction == "[" then
       w:skip_char()
       msg = "Skip characters"
     elseif subaction == "]" then
       w:noskip_char()
       msg = "Stop skip"
     else 
       msg = action..rest
     end
   else
     msg =  action..rest
   end
   msg = "<!-- "..msg .. "-->" 
   w:all(msg)
   return msg
end

local callback = function(head)
    --input:write(process(head))
  process(head)
  return head
end

local finish = function()
  --[[
  for name, file in pairs(opened_files) do
    print("Closing file", name, type(file))
    file:close()
  end
  input = nil
  --]]
  w:finish()
end

M.callback = callback
M.process  = process
M.finish   = finish

return M



