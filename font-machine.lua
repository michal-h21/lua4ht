local M = {}
local glyph_id = node.id "glyph"
local whatsit_id = node.id "whatsit"
normalfont = 0
usedfonts = {}
local char  = unicode.utf8.char
local function hcode(c)
	local p = node.new("whatsit",3)
	p.data = "t4ht="..c
	return p
end
local start_font = function(n, id)
	if id~=normalfont then
		head = node.insert_before(head, n, hcode("<span class='font-"..id.."'>"))
	end
end
local stop_font = function(n, id, s)
	local s = s or "</span>"
	if id and id~= normalfont then
		print("vkladame endfont" ..id)
		head = node.insert_after(head, n, hcode(s))
	end
end

function font_clb(head)
	local mn = {}
	local current = nil
	local cf = nil
	local t=""
	local start = true
	for n in node.traverse(head) do
		local id = n.id
		if id == glyph_id then
			local f = n.font
			if start then 
				start_font(n, f)
			end
			start = false
			cf = f
			if cf ~= pf then
				if t:len()>0 then
					stop_font(n.prev, pf)
					start_font(n, cf)
				end
				t=""
			end
			t = t .. char(n.char)
			if not usedfonts[f] then
				usedfonts[f] = true
			end
		elseif id == whatsit_id and n.subtype == 3 then 
			print "tex4ht node"
			local data = n.data
			local t = data:match "t4ht(.)"
			if t == "=" then
				print("Stop font 4ht")
				stop_font(node.prev(node.prev(n)),cf, "<!-- 4ht --></span>")
				cf = nil
				start = true
			else
				stop_font(n.prev, cf, "<!-- "..data.." -->")
			end
		end
		pf = cf
	end
	--table.insert(mn,{id=pf, text=t})
	stop_font(node.tail(head), cf, "<!-- stop --></span>")
	return head
end 
luatexbase.add_to_callback("pre_linebreak_filter",font_clb,"Hello")

local normal = function(font)
	normalfont = font
end

M.normal = normal
return M

