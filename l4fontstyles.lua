-- 

local fontcache  = {}
local M          = {}
local used_fonts = {}
local namecache  = {}
local fonts = fonts or {}
fonts.hashes = fonts.hasher or {}
local fontdata = fonts.hashes.identifiers or {}
local my_getfont = function (id)
	local f = fontdata[id]
	if f then
		return f
	end
	return font.fonts[id]
end

local function make_info(name,size, weight, style)
	local weight = weight or "normal"
	local style= style or "normal"
	return {name= name, size=size, weight = weight, style=style}
end

local function get_opentype(name)
	local styles  = {["[iI]talic"]="italic", ["[Oo]blique"]="oblique"}
	local weights = {["[bB]old"]="bold"}
	local style = "normal"
	local weight= "normal"
	for reg, s in pairs(styles) do
		if name:match(reg) then style = s end
	end
	for reg, w in pairs(weights) do
		if name:match(reg) then weight = w end
	end
	return {weight, style}
end

local function get_tex(name)
	-- todo: parse TeX font names
	return nil
end

local function get_fontinfo(font_id)
	local info = fontcache[font_id]
  if info then return info end
	local f = my_getfont(font_id)
	local full = f.fullname
	local name = f.name
	local both = full or name
	if not both then return nil, "Cannot get font name for font id: "..font_id end
	local info = namecache[both] or get_opentype(full) or get_tex(name) or {}
	namecache[both] = info
	return make_info(both, f.size, info[1],info[2]) 
end

M.get_fontinfo = get_fontinfo
return M
