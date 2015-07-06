local M = {}

local styles = require "l4fontstyles"
local glyph_id = node.id "glyph"
local whatsit_id = node.id "whatsit"
local math_id = node.id "math"
local nofonts = 0 
local normalfont = 0
local normalinfo = nil
local usedfonts = {}
local char  = unicode.utf8.char
local spanlevel = 0

local function htspecial(c)
	local p = node.new("whatsit",3)
	p.data = "t4ht"..c
	return p
end

local function hcode(c)
	return htspecial("="..c)
end

local add_nofonts = function()
  nofonts = nofonts + 1
end

local sub_nofonts = function()
  if nofonts > 0 then
    nofonts = nofonts - 1
  end
end

local function css(c)
	return htspecial("+@Css: "..c)
end

local font_name = function(id) 
	return 'font-'..id
end


local start_font = function(n, id)
	if id~=normalfont and nofonts < 1 then
    spanlevel = spanlevel + 1
    print("vkladame start font", id)
		head = node.insert_before(head, n, hcode("<span class='"..font_name(id).."'>"))
	end
end

local stop_font = function(n, id, s)
	local s = s or "</span>"
  s = s .. "<!-- ".. spanlevel .. " -->"
	if id and id~= normalfont and nofonts < 1 and spanlevel > 0 then
    spanlevel = spanlevel - 1
		print("vkladame endfont" ..id)
		head = node.insert_after(head, n, hcode(s))
	end
end

local pending_fonts = {}

local proces_pending = function()
	for _, info in ipairs(pending_fonts) do
		make_css(info)
	end
	pending_fonts = {}
end

local make_css = function(id, info)
	if not normalinfo then table.insert(pending_fonts, info)
	else
		proces_pending()
	end
	local normsize = normalinfo.size
	local cssinfo = {}
	local family = info.family or info.name
	-- if family name contains quotes, we should add quotes
	if family:match " " then family = '"'..family..'"' end
	cssinfo['font-family'] = family ..', serif'
	local size = info.size or normsize
	cssinfo['font-size'] =  size / normsize .. "em"
	cssinfo['font-style'] = info.style 
	cssinfo['font-weight'] = info.weight
	local c = '{'
	for k, v in pairs(cssinfo) do 
		c = c .. k..': '..v..';'
	end
	return css('.'..font_name(id)..c .. '}')
end


function font_clb(head)
  local stop_tex4ht = function()
    stop_font(node.prev(node.prev(n)),cf, "<!-- 4ht --></span>")
    cf = nil
    start = true
  end
	local mn = {}
	local current = nil
	local cf = nil
	local t=""
	local start = true
  local pf = cf
  spanlevel = 0
	for n in node.traverse(head) do
		local id = n.id
		if id == glyph_id then
			local f = n.font
			if start then 
				start_font(n, f)
        pf = f
			end
			start = false
			cf = f
			if cf ~= pf then
				if t:len()>0 then
					stop_font(n.prev, pf)
					start_font(n, cf)
				end
        print(t)
				t=""
			end
			t = t .. char(n.char)
			if not usedfonts[f] then
				local s = styles.get_fontinfo(f)
				usedfonts[f] = true
				local cssnode = make_css(f,s)
				node.insert_after(head, n, cssnode)
			end
    elseif id == math_id then
      if n.subtype == 0 then
				stop_tex4ht()
        add_nofonts()
      else
        sub_nofonts()
        start = true
      end
		elseif id == whatsit_id and n.subtype == 3 then 
			--print "tex4ht node"
			local data = n.data
			local t,rest = data:match "t4ht(.)(.*)"
			if t == "=" then
				--print("Stop font 4ht")
				stop_tex4ht()
			elseif t== ";" then
				-- support for \NoFonts and \EndNoFonts
				stop_tex4ht()
				if rest == "8" then
          add_nofonts()
					print("nofonts",nofonts)
				elseif rest=="9" then
          sub_nofonts()
          start = true
					print ("endnofonts", nofonts)
				end
			else
				--stop_font(n.prev, cf, "<!-- "..data.." -->")
			end
		end
		pf = cf
	end
	--table.insert(mn,{id=pf, text=t})
  if not start then
    print(t)
	  stop_font(node.tail(head), cf, "<!-- stop --></span>")
  end
	return head
end 
luatexbase.add_to_callback("pre_linebreak_filter",font_clb,"Hello")

local normal = function(font)
	normalfont = font
	normalinfo = styles.get_fontinfo(normalfont)
end

M.normal = normal
return M

