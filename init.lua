local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)

mcl_shields = {
        types = {
		mob = true,
		player = true,
		arrow = true,
		fireball = true,
		explosion = true,
        },
}

minetest.register_tool("mcl_shields:shield",{
        description = S("Shield"),
        _doc_items_longdesc = S("A shield is a tool used for protecting the player against attacks."),
        inventory_image = "mcl_shield.png",
        stack_max = 1,
        groups = { weapon = 1 },
        sound = { breaks = "default_tool_breaks" },
	_repair_material = "group:wood",
        wield_scale = { x = 2, y = 2, z = 2 },
})

function mcl_shields.wielding_shield(obj)
        return obj:get_wielded_item():get_name():find("mcl_shields:shield")
end

function mcl_shields.is_blocking(obj)
        return mcl_shields.wielding_shield(obj) and obj:get_player_control().RMB
end

mcl_damage.register_modifier(function(obj, damage, reason)
        local type = reason.type
        if obj:is_player()
        and mcl_shields.is_blocking(obj)
        and mcl_shields.types[type]
        and reason.direct then
                if vector.dot(obj:get_look_dir(), vector.subtract(reason.direct:get_pos(), obj:get_pos())) >= 0
                or (type == "arrow" or type == "fireball") then
                        local item = obj:get_wielded_item()
                        item:add_wear(65535 / 336)
                        obj:set_wielded_item(item)
                        return 0
                end
        end
end)

minetest.register_craft({
	output = "mcl_shields:shield",
	recipe = {
		{ "group:wood", "mcl_core:iron_ingot", "group:wood" },
                { "group:wood", "group:wood", "group:wood" },
                { "", "group:wood", ""},
	}
})

local shield_hud = {}

local function add_shield(player)
        if mcl_shields.wielding_shield(player) then
                shield_hud[player] = player:hud_add({
                        hud_elem_type = "image",
                        position = { x = 0.5, y = 0.5 },
                        scale = { x = -100, y = -100 },
                        text = "mcl_shield_hud.png",
                })
                player:hud_set_flags({ wielditem = false })
                playerphysics.add_physics_factor(player, "speed", "shield_speed", 0.5)
        end
end

local function remove_shield(player)
        if shield_hud[player] then
                player:hud_remove(shield_hud[player])
                shield_hud[player] = nil
                player:hud_set_flags({ wielditem = true })
                playerphysics.remove_physics_factor(player, "speed", "shield_speed")
        end
end

controls.register_on_press(function(player, key)
        if key ~= "RMB" then return end
        add_shield(player)
end)

controls.register_on_release(function(player, key, time)
        if key ~= "RMB" then return end
        remove_shield(player)
end)

controls.register_on_hold(function(player, key, time)
        if key ~= "RMB" then return end
        if mcl_shields.wielding_shield(player) then
                if shield_hud[player] == nil then
                        add_shield(player)
                end
        else 
                remove_shield(player)
        end
end)

minetest.register_on_dieplayer(function(player)
        if not minetest.settings:get_bool("mcl_keepInventory") then
                remove_shield(player)
        end
end)

minetest.register_on_leaveplayer(function(player)
        shield_hud[player] = nil
end)

local player_set_animation = mcl_player.player_set_animation
local player_attached = mcl_player.player_attached

local function get_mouse_button(player)
	local controls = player:get_player_control()
	if controls.RMB or controls.LMB then
		return true
	else
		return false
	end
end

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
                if mcl_shields.is_blocking(player) then
                        local name = player:get_player_name()
                        local controls = player:get_player_control()
                        local sneak = controls.sneak
			local walking = false
			local speed = 15
			if controls.up or controls.down or controls.left or controls.right then
				walking = true
			end
			if sneak then
				speed = speed / 2
			end
			local head_in_water = minetest.get_item_group(mcl_playerinfo[name].node_head, "water") ~= 0
			local is_sprinting = mcl_sprint.is_sprinting(name)
			local velocity = player:get_velocity() or player:get_player_velocity()
			if player:get_hp() == 0 then
				player_set_animation(player, "die")
			elseif walking and velocity.x > 0.35
			or walking and velocity.x < -0.35
			or walking and velocity.z > 0.35
			or walking and velocity.z < -0.35 then
				if not sneak and head_in_water and is_sprinting then
					player_set_animation(player, "swim_walk", speed)
				elseif is_sprinting and not sneak and not head_in_water then
					player_set_animation(player, "run_walk", speed)
				elseif sneak then
					player_set_animation(player, "sneak_walk", speed)
				else
					player_set_animation(player, "walk", speed)
				end
			elseif not get_mouse_button(player) and not sneak and head_in_water and is_sprinting then
				player_set_animation(player, "swim_stand")
			elseif not sneak and head_in_water and is_sprinting then
				player_set_animation(player, "swim_stand", speed)
			elseif not sneak then
				player_set_animation(player, "stand", speed)
			else
				player_set_animation(player, "sneak_stand", speed)
			end
		end
	end
end)
