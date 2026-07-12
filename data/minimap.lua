require("__data-utils__.data.util")
require("data.settings")
local minimap = {}
local function evaluate(player)
  if not player or not player.game_view_settings or not player.surface or not player.surface.darkness then
    return
  end
  if player.surface.platform then
    player.game_view_settings.show_minimap = not FL_DISABLE_PLATFORM_MINIMAP
    return
  end
  if FL_DISABLE_NIGHT_MINIMAP then
    player.game_view_settings.show_minimap = player.surface.darkness < 0.5
    return
  end
  player.game_view_settings.show_minimap = true
end
local function reset()
  for _, player in pairs(game.connected_players) do player.game_view_settings.show_minimap = true end
end
local function update() for _, player in pairs(game.connected_players) do evaluate(player) end end
minimap.initialise = function()
  storage.fire_lights = {}
  storage.fire_lights.night_minimap = FL_DISABLE_NIGHT_MINIMAP
  storage.fire_lights.platform_minimap = FL_DISABLE_PLATFORM_MINIMAP
  update()
end
minimap.on_configuration_changed = function(event)
  if not storage.fire_lights then
    minimap.initialise()
    return
  end
  if (FL_DISABLE_NIGHT_MINIMAP == storage.fire_lights.night_minimap and FL_DISABLE_PLATFORM_MINIMAP ==
      storage.fire_lights.platform_minimap) then
    update()
    return
  end
  storage.fire_lights.night_minimap = FL_DISABLE_NIGHT_MINIMAP
  storage.fire_lights.platform_minimap = FL_DISABLE_PLATFORM_MINIMAP
  reset()
end
minimap.player_connected = function(event) evaluate(game.players[event.player_index]) end
minimap.surface_changed = function(event) evaluate(game.players[event.player_index]) end
minimap.tick = function(event) update() end
return minimap
