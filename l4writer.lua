WriterClass = {}
WriterClass.__index = WriterClass

local writer = function()
  local self  = WriterClass --setmetatable({},WriterClass)
	local tex = tex or {}
	tex.jobname = tex.jobname or "noname"
  self.full = io.open(tex.jobname .. ".full","w")
  self.lg_file = io.open(tex.jobname..".lg","w")
  self.skip = false
  self.opened_files = {}
  self.file_stack = {}
  self.input = nil
  return self 
end

WriterClass.open = function(self,filename)
  if filename then
    table.insert(self.file_stack, filename)
  else
    filename = self.file_stack[#self.file_stack] 
  end
  print("Open", filename)
  local i = self.opened_files[filename] or io.open(filename,"w")
  self.opened_files[filename] = i
  self.input = i
end

WriterClass.skip_char= function(self)
  self.skip = true
end

WriterClass.noskip_char = function(self)
  self.skip = false
end

WriterClass.all = function(self, s)
	local input = self.input
	if input then 
    self.full:write(s)
	end
end

WriterClass.lg= function(self,s)
  self.lg_file:write(s.."\n")
  self:all(s)
end

WriterClass.write = function(self, s)
  local input = self.input
  if input then
    if not self.skip then
      input:write(s)
    end
    self:all(s)
  else
    print("Writer closed", s)
  end
end
WriterClass.close = function(self)
  local file_stack = self.file_stack
  table.remove(self.file_stack)
  local current_filename = file_stack[#file_stack]
  print("Close file, current:", current_filename)
  self.input = self.opened_files[current_filename]
end
WriterClass.finish = function(self)
  for name, file in pairs(self.opened_files) do
    print("Closing file", name, type(file))
    file:close()
  end
  self.full:close()
  self.lg_file:close()
  self.input = nil --self.tmp
end

return writer
