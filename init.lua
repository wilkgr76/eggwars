----------------------------------------------------
-- Eggwars by wilkgr
-- Licensed under the AGPL v3
-- You MUST make any changes you make open source
-- even if you just run it on your server without publishing it
-- Supports a maximum of 8 players currently
----------------------------------------------------

--[[
Shop formspec:

button[0,0;10,1;upgradespeed;Upgrade speed]
button[0,2;10,1;upgradejump;Upgrade jump]
button[0,6;10,1;thug;Order execution (cost: 99 diamonds)]


]]
eggwars = {}
eggwars.MP = minetest.get_modpath("eggwars")

dofile(eggwars.MP.."/register_nodes.lua")

minetest.set_mapgen_params({mgname = "singlenode"})
local i = 1;
local players_waiting = {};
local waiting_area = {x=0,y=150,z=0};
local centre = {x=0,y=100,z=0}
local player_i = {};
local players_alive = {};
local allowed_colours = {
  {r = 0, g = 0, b = 255},
  {r = 0, g = 255, b = 0},
  {r = 255, g = 0, b = 0},
  {r = 200, g = 0, b = 200},
  {r = 255, g = 255, b = 0},
  {r = 0, g = 255, b = 255},
  {r = 255, g = 165, b = 0},
  {r = 0, g = 0, b = 0}
}
local player_colours = {};
eggwars.islands = {
  {x=50,y=100,z=0},
  {x=-50,y=100,z=0},
  {x=0,y=100,z=50},
  {x=50,y=100,z=50},
  {x=-50,y=100,z=50},
  {x=-50,y=100,z=-50},
  {x=0,y=100,z=-50},
  {x=50,y=100,z=-50}
}

function StartsWith (String, Start)
    return string.sub (String, 1, string.len (Start)) == Start
end

function EndsWith (String, End)
    return End == '' or string.sub (String, -string.len (End)) == End
end

removeDrops = function ()
  local pos  = {x=0,y=100,z=0}
  local ent  = nil
  local tnob = minetest.get_objects_inside_radius (pos, 60)
  local nnob = table.getn(tnob)

  if (nnob > 0) then
    for foo,obj in ipairs (tnob) do
      ent = obj:get_luaentity()
      if ent ~= nil and ent.name ~= nil then
        if StartsWith (ent.name, "__builtin:item") then
          obj:remove()
        end
      end
    end
  end
end

reset = function ()
  removeDrops();
  minetest.delete_area({x=-80, y=50, z=-80}, {x=80,y=150, z=80})
  players_alive = {};

end

-- Set spawnpoint to y-1, x-10, z-10
spawncentre = function ()
  local centre_transformed = table.copy(centre)
  centre_transformed.y = centre_transformed.y - 1
  centre_transformed.x = centre_transformed.x - 10
  centre_transformed.z = centre_transformed.z - 10
  local schempath = minetest.get_modpath("eggwars").."/schems";
  local name = "centre"
    minetest.debug("spawncentre: " .. minetest.pos_to_string(centre_transformed))
  minetest.place_schematic(centre_transformed, schempath.."/"..name..".mts")
end

islandspawn = function (n)
  --minetest.set_node(eggwars.islands[n],{name = "eggwars:egg"})
  local schem_l = table.copy(eggwars.islands[n]);
  schem_l.y = schem_l.y - 6
  schem_l.x = schem_l.x -7
  schem_l.z = schem_l.z -7
  local schempath = minetest.get_modpath("eggwars").."/schems";
  local name = "eggwars.island"
  minetest.debug("spawn eggwars.island: " .. minetest.pos_to_string(schem_l))
  minetest.place_schematic(schem_l, schempath.."/"..name..".mts")
end



minetest.register_on_dieplayer(function(player)
  local block = minetest.get_node(player_i[player:get_player_name()]).name
  minetest.chat_send_all(minetest.pos_to_string(player_i[player:get_player_name()]))
  minetest.chat_send_all(minetest.get_node(player_i[player:get_player_name()]).name)

  if minetest.get_node(player_i[player:get_player_name()]).name ~= "eggwars:egg" then
      minetest.chat_send_all("*** "..player:get_player_name().." is " .. minetest.colorize('red','OUT'))
    --minetest.set_player_privs(player:get_player_name(),{fly=true,fast=true,noclip=true}) --Give player fly, fast and noclip. Revokes other privs.
    player:set_nametag_attributes({color = {a = 255, r = 0, g = 0, b = 0}}) --Make nametag invisible
    player:set_properties({visual_size={x=0, y=0}}) --Make player invisible
    for j=1,#players_alive do
      if players_alive[j] == player:get_player_name() then
        table.remove(players_alive[j])
      end
    end
    if #players_alive == 1 then
      minetest.chat_send_all(minetest.colorize("green", "*** " .. players_alive[1] .. " has won!"))
      reset();
    end
  else
    minetest.chat_send_all("*** "..player:get_player_name().." paid Hades a visit.")
    --player:set_player_privs({interact=true,shout=true})
  end
end)

minetest.register_on_respawnplayer(function(player)
  local respawn_pos = table.copy(player_i[player:get_player_name()])
  respawn_pos.y = respawn_pos.y + 2
  minetest.after(0.1,function () player:setpos(respawn_pos) end)
end)

minetest.register_on_joinplayer(function(player)
  local player_n = player:get_player_name()
  local privs = minetest.get_player_privs(player_n)
  privs.fly = true
  minetest.set_player_privs(player_n, privs)
  player:set_nametag_attributes({color = allowed_colours[i]})
  if i == 1 then
    spawncentre();
    minetest.chat_send_all("Unfortunately, more than one player is required to play. Please wait for another player to join.")
  end
  if i >= 8 then
    minetest.set_node(waiting_area, {name = "default:dirt_with_grass"})
    player:setpos(waiting_area)
    players_alive[i] = player_n;
    i = i + 1;
  else
    player:setpos(eggwars.islands[i])
    player_i[player_n] = eggwars.islands[i];
    islandspawn(i)
    i = i + 1;
  end
end)

local shop_fs = [[
size[10,3]
button[0,0;10,1;upgradespeed;Upgrade speed (cost: 20 diamonds)]
button[0,1;10,1;upgradejump;Upgrade jump (cost: 20 diamonds)]
button[0,2;10,1;thug;Order execution (cost: 99 diamonds)]
]]

minetest.register_chatcommand("shop", {
	params = "",
	description = "Open shop",
	func = function(name, param)
    minetest.show_formspec(name, "eggwars:shop", shop_fs)
		return true
	end,
})



minetest.debug('[LOADED] Eggwars')
