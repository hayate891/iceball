do

if client then
	if not img_fsrect_wpaint then
		img_fsrect_wpaint = client.img_new(client.screen_get_dims())
		client.img_fill(img_fsrect_wpaint, 0x8FFFFFFF)
	end

	local xlen, ylen, zlen = common.map_get_dims()

	local l = {}
	function gen_box(t,x0,y0,z0,x1,y1,z1)
		local i
		local t2 = {
			{x0,y0,z0, 0,0}, {x0,y1,z0, 0,0}, {x0,y0,z1, 0,0},
			{x0,y0,z1, 0,0}, {x0,y1,z0, 0,0}, {x0,y1,z1, 0,0},

			{x1,y1,z1, 0,0}, {x1,y1,z0, 0,0}, {x1,y0,z1, 0,0},
			{x1,y0,z1, 0,0}, {x1,y1,z0, 0,0}, {x1,y0,z0, 0,0},

			{x1,y1,z0, 0,0}, {x0,y1,z0, 0,0}, {x1,y0,z0, 0,0},
			{x1,y0,z0, 0,0}, {x0,y1,z0, 0,0}, {x0,y0,z0, 0,0},
			
			{x0,y0,z1, 0,0}, {x0,y1,z1, 0,0}, {x1,y0,z1, 0,0},
			{x1,y0,z1, 0,0}, {x0,y1,z1, 0,0}, {x1,y1,z1, 0,0},
		}

		for i=1,#t2 do
			t[1+#t] = t2[i]
		end
	end
	gen_box(l, 
		xlen/2-0.2, 0, 15,
		xlen/2+0.2, ylen, zlen-15)
	gen_box(l, 
		14.8, 0, 15,
		15.2, ylen, zlen-15)
	gen_box(l, 
		xlen-15.2, 0, 15,
		xlen-14.8, ylen, zlen-15)
	gen_box(l, 
		15, 0, 14.8,
		xlen-15, ylen, 15.2)
	gen_box(l, 
		15, 0, zlen-15.2,
		xlen-15, ylen, zlen-14.8)

	va_fronts = common.va_make(l, nil, "3v,2t")
	local i
	for i=1,math.floor(#l/2) do
		l[i], l[#l+1-i] = l[#l+1-i], l[i]
	end
	va_backs = common.va_make(l, nil, "3v,2t")
end

local s_new_intel = new_intel
local function wrap_intel(this)
	function this.get_name()
		return "ball"
	end

	local s_render_backpack = this.render_backpack
	function this.render_backpack(...)
		if this.player.tool ~= 2 then
			return s_render_backpack(...)
		end
	end

	function this.spawn()
		local xlen,ylen,zlen
		xlen,ylen,zlen = common.map_get_dims()

		this.x = xlen/2
		this.z = zlen/2
		this.y = (common.map_pillar_get(this.x, this.z))[1+1]

		return this.spawn_at(this.x, this.y, this.z)
	end



	return this
end

function new_intel(settings, ...)
	local this = s_new_intel(settings, ...)
	return wrap_intel(this)
end

function new_ballslot(plr)
	local this = {} this.this = this

	this.plr = plr
	this.gui_x = 0.15
	this.gui_y = 0.35
	this.gui_scale = 0.3
	this.gui_pick_scale = 1.0

	function this.get_model()
		-- WARNING: model index is hardcoded!
		return (plr.has_intel and plr.has_intel.mdl_intel) or miscents[3].mdl_intel
	end

	function this.render(px,py,pz,ya,xa,ya2)
		if plr.has_intel then
			local mdl = this.get_model()
			mdl.render_global(
				px, py, pz, ya, xa, ya2, 1)
		end
	end

	function this.click(button, state)
		if plr.has_intel == this and state then
			if button == 1 then
				-- LMB: throw

			elseif button == 3 then
				-- RMB: punt

			end
		end
	end

	function this.restock()
	end

	function this.tick(sec_current, sec_delta)
	end

	function this.key(key, state, modif)
	end

	function this.free()
	end

	function this.focus()
	end

	function this.unfocus()
	end

	function this.textgen()
		return 0xFFFFFFFF, ""
	end

	return this
end

local s_new_player = new_player
function new_player(...)
	local this = s_new_player(...)

	local s_add_tools_list = this.add_tools_list
	function this.add_tools_list(...)
		if this.mode ~= PLM_NORMAL then return s_add_tools_list(...) end

		this.tools[#(this.tools)+1] = tools[TOOL_SPADE](this)
		this.tools[#(this.tools)+1] = tools[TOOL_BLOCK](this)
		this.tools[#(this.tools)+1] = new_ballslot(this)

		this.tool = 2
		this.tool_last = 0
	end

	local s_show_hud = this.show_hud
	function this.show_hud(sec_current, sec_delta, ...)
		-- this is a bit derpy so dummied out for now
		if false and client.gfx_stencil_test then
			-- Stencil hackery
			client.gfx_stencil_test(true)
			--print("STENC")

			-- PASS 1: increase for front faces, decrease for back faces
			client.gfx_depth_mask(false)
			client.gfx_alpha_test(false)
			client.gfx_stencil_func(">", 255, 255)
			client.gfx_stencil_op(";;+")
			client.va_render_global(va_fronts,
				0,0,0, 0,0,0, 1, nil, "01")
			client.gfx_stencil_func("<", 0, 255)
			client.gfx_stencil_op(";;-")
			client.va_render_global(va_backs,
				0,0,0, 0,0,0, 1, nil, "01")
			client.gfx_alpha_test(true)
			client.gfx_depth_mask(true)

			-- PASS 2: draw white for stencil >= 1; clear stencil
			client.gfx_stencil_func("<=", 1, 255)
			client.gfx_stencil_op("000")
			client.img_blit(img_fsrect_wpaint, 0, 0)

			client.gfx_stencil_test(false)
		end

		-- continue
		return s_show_hud(sec_current, sec_delta, ...)
	end

	local s_wpn_damage = this.wpn_damage
	function this.wpn_damage(part, amt, enemy, dmsg, ...)
		--print("damage",this.name,part,amt)

		if server then
			if (not this.has_intel) and (not enemy.has_intel) then
				return
			end

			if dmsg == "spaded" then
				dmsg = "tackled"
			end
		end

		return s_wpn_damage(part, amt, enemy, dmsg, ...)
	end

	return this
end

local s_new_tent = new_tent
function new_tent(...)
	local this = s_new_tent(...)

	function this.spawn()
		local xlen,ylen,zlen
		xlen,ylen,zlen = common.map_get_dims()

		this.x = 19.5
		this.z = zlen/2
		if this.team == 1 then this.x = xlen - this.x end
		this.y = (common.map_pillar_get(this.x, this.z))[1+1]

		return this.spawn_at(this.x, this.y, this.z)
	end

	return this
end

local s_mode_reset = mode_reset
function mode_reset(...)
	return s_mode_reset(...)
end

if server then
	mode_create_server()
	mode_reset()
else
	mode_create_client()
end

--[[
local i
for i=1,#weapons do
	local s_weapon = weapons[i]
	weapons[i] = function(plr, cfg, ...)
		local this = s_weapon(plr, cfg, ...)

		local s_tick = this.tick
		function this.tick(sec_current, sec_delta, ...)
			if not plr.has_intel then return s_tick(sec_current, sec_delta, ...) end
			this.firing = false
			this.reloading = false
			plr.zooming = false
			this.arm_rest_left = 0
		end

		local s_get_model = this.get_model
		function this.get_model(...)
			if not plr.has_intel then return s_get_model(...) end
			return plr.has_intel.mdl_intel
		end

		local s_render = this.render
		function this.render(px, py, pz, ya, xa, ya2, ...)
			if not plr.has_intel then return s_render(px, py, pz, ya, xa, ya2, ...) end
			return plr.has_intel.mdl_intel.render_global(
				px, py, pz, ya, xa, ya2, 1)
		end

		local s_click = this.click
		function this.click(button, state, ...)
			if not plr.has_intel then return s_click(button, state, ...) end
		end

		return this
	end
end
]]

end

