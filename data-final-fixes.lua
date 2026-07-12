require("__data-utils__.data.util")
require("data.settings")
require("data.flashlight")
local LIT_PROJECTILES = {"magazine", "cannon", "rocket", "strafer", "pellet", "laser", "boompuff"}
local function modify_proj(name, proj, light)
  if proj.light and FL_PROJ_SIZE_MULTIPLIER == 1 then return end
  local new_light = proj.light or light or {intensity = 0.4, size = 5, add_perspective = true}
  new_light.size = new_light.size * FL_PROJ_SIZE_MULTIPLIER
  if name:find("atomic", 1, true) then new_light.size = new_light.size * 3 end
  proj.light = new_light
end
if FL_PROJ_SIZE_MULTIPLIER ~= 0 then
  for name, proj in pairs(data.raw["projectile"]) do
    if not contains_any_substring(name, LIT_PROJECTILES) then goto continue end
    modify_proj(name, proj)
    if (name:find("laser", 1, true)) then proj.light.intensity = 1.0 end
    ::continue::
  end
end
if FL_NERF_NIGHTVISION then
  local night_vision = data.raw["night-vision-equipment"] and
    data.raw["night-vision-equipment"]["night-vision-equipment"]
  if not night_vision then return end
  night_vision.energy_input = "200W"
  night_vision.color_lookup = {
    {0.3,  "__core__/graphics/color_luts/nightvision.png"},
    {0.4,  "__fire-lights__/graphics/nightvision10.png"  },
    {0.45, "__fire-lights__/graphics/nightvision5.png"   },
    {0.5,  "__fire-lights__/graphics/nightvision.png"    },
    {0.55, "__fire-lights__/graphics/nightvision5.png"   },
    {0.6,  "__fire-lights__/graphics/nightvision10.png"  },
    {0.7,  "__core__/graphics/color_luts/nightvision.png"},
  }
  if FL_DARKER_NIGHTVISION then
    night_vision.color_lookup = {
      {0.3,  "__core__/graphics/color_luts/nightvision.png"   },
      {0.37, "__fire-lights__/graphics/nightvision10.png"     },
      {0.41, "__fire-lights__/graphics/nightvision5.png"      },
      {0.47, "__fire-lights__/graphics/nightvision.png"       },
      {0.5,  "__fire-lights__/graphics/nightvision-darker.png"},
      {0.53, "__fire-lights__/graphics/nightvision.png"       },
      {0.59, "__fire-lights__/graphics/nightvision5.png"      },
      {0.63, "__fire-lights__/graphics/nightvision10.png"     },
      {0.7,  "__core__/graphics/color_luts/nightvision.png"   },
    }
  end
  night_vision.shape = {width = 4, height = 2, type = "full"}
end
local UNITS = {"unit", "spider-unit", "spider-leg"}
local SEGMENTED_UNITS = {"segment", "segmented-unit"}
if FL_DISABLE_UNIT_ONMAP then
  for _, unit_name in pairs(UNITS) do add_flags(data.raw[unit_name], "not-on-map") end
end
if FL_DISABLE_SEGMENTED_UNIT_ONMAP then
  for _, unit_name in pairs(SEGMENTED_UNITS) do add_flags(data.raw[unit_name], "not-on-map") end
end
