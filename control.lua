require("__data-utils__.data.util")
require("data.settings")
local minimap = require("data.minimap")
script.on_init(minimap.initialise)
script.on_configuration_changed(minimap.on_configuration_changed)
script.on_event(defines.events.on_player_joined_game, minimap.player_connected)
if FL_DISABLE_NIGHT_MINIMAP or FL_DISABLE_PLATFORM_MINIMAP then
  script.on_event(defines.events.on_player_changed_surface, minimap.surface_changed)
end
if FL_DISABLE_NIGHT_MINIMAP then script.on_nth_tick(14, minimap.tick) end
