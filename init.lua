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
        _mcl_toollike_wield = true,
})

local function wield_item(obj)
        return obj:get_wielded_item():get_name()
end

mcl_damage.register_modifier(function(obj, damage, reason)
        local type = reason.type
        if obj:is_player()
        and wield_item(obj) == "mcl_shields:shield"
        and obj:get_player_control().RMB
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
        if wield_item(player) == "mcl_shields:shield" then
                shield_hud[player] = player:hud_add({
                        hud_elem_type = "image",
                        position = { x = 0.5, y = 0.5 },
                        scale = { x = -100, y = -100 },
                        text = "mcl_shields_hud.png",
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
        if wield_item(player) == "mcl_shields:shield" then
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
