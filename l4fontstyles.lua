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

local function make_info(name,size, info)
	local info = info or {}
	info.weight = info.weight or "normal"
	info.style= info.style or "normal"
  info.name = name
	info.size = size
	return info
end

local function get_opentype(f)
	local name = f.fullname
	if not name then return nil end
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
	local family = f.family_name or name:match("([^%-]+)") or name
	family = family:match("(.-)[0-9]*$") or family
	print("family",family)
	return {weight = weight, style = style, family = family}
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
	local info = namecache[both] or get_opentype(f) or get_tex(name) or {}
	namecache[both] = info
	return make_info(both, f.size, info) 
end

M.get_fontinfo = get_fontinfo
return M
