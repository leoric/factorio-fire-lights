require("__data-utils__.data.util")
require("data.settings")
local FIRES_TO_ENHANCE = {"eb-fire"}
local FIRES = {"fire", "flam"}
local EXTRA_FIRE_SIZE = 18
local EXTRA_FIRE_INTENSITY = 1.2
local EXTRA_FIRE_CLAMP = 1.7
local EXPLOSIONS_SKIP = {"blood", "nuke"}
local EXPLOSIONS_SKIP_PERF = {"hit"}
local EXPLOSION_LIGHT_SIZE_MULT = 5
local EXPLOSION_DEATH_LIGHT_SIZE_MULT = 7
local EXPLOSIONS_BUILDING = {
  "furnace",
  "inserter",
  "electric-pole",
  "car",
  "robot",
  "engine",
  "mining-drill",
  "assembling-machine",
  "lab",
  "turret",
  "radar",
  "train",
  "locomotive",
  "cargo",
  "solar",
  "accumulator",
  "substation",
  "wagon",
  "tank",
  "reactor",
  "spidertron",
  "refinery",
  "chemical-plant",
  "centrifuge",
  "beacon",
  "silo",
  "land-mine",
  "radar",
  "boiler",
  "roboport",
  "steam-turbine",
  "heat-exchanger",
  "pumpjack",
  "space-platform-foundation",
  "foundry",
  "agricultural-tower",
  "biochamber",
  "electromagnetic-plant",
  "cryogenic-plant",
  "fusion-generator",
  "captive-spawner",
  "asteroid",
  "boompuff",
  "locomotive",
  "wagon",
  "heating-tower",
}
local EXPLOSIONS_BUILDING_SKIP = {"storage"}
local function modify_fire(name, fire, light)
  if light then
    fire.light = light
  else
    local power = math.abs(fire.damage_per_tick.amount) / EXTRA_FIRE_CLAMP
    if power > 1 then power = 1 end
    if not fire.light then fire.light = {} end
    set_attribs(fire, {
      ["light.intensity"] = 0.4 + power * EXTRA_FIRE_INTENSITY,
      ["light.size"] = 19 + power * EXTRA_FIRE_SIZE,
      ["light.color"] = set_colour {0.7 + power * 0.7, 0.6 - power * 0.4, 0.4 - power * 0.3},
    }, fire.name .. " fire")
  end
  set_attribs(fire, {
    ["light.flicker_interval"] = fire.light.flicker_interval or 30,
    ["light.flicker_min_modifier"] = fire.light.flicker_min_modifier or 0.8,
    ["light.flicker_max_modifier"] = fire.light.flicker_max_modifier or 1.3,
    ["light.size"] = math.ceil(fire.light.size * FL_FIRE_SIZE_MULTIPLIER),
    spread_delay = fire.spread_delay and fire.spread_delay / FL_FIRE_SPREAD_MULTIPLIER or 300,
    fire_spread_radius = fire.fire_spread_radius and fire.fire_spread_radius * FL_FIRE_SPREAD_MULTIPLIER or 0.75,
    maximum_spread_count = fire.maximum_spread_count and fire.maximum_spread_count * FL_FIRE_SPREAD_MULTIPLIER or 100,
  }, fire.name .. " " .. fire.type)
end
local function calculate_average_width_scale(explosion)
  local anims = explosion.animations
  if not anims then return nil end
  if anims.width then return anims.width * (anims.scale or 1) / 32 end
  local total_width_scale, num_animations = 0, 0
  for _, anim in ipairs(anims) do
    if anim.width then
      total_width_scale = total_width_scale + (anim.width * (anim.scale or 1))
      num_animations = num_animations + 1
    end
  end
  if num_animations > 0 then return total_width_scale / num_animations / 32 end
  return nil
end
local function set_explosion_light(explosion, size)
  set_attribs(explosion, {
    light = {intensity = 0.6, size = size, color = {r = 1.0, g = 0.85, b = 0.7}},
    light_intensity_peak_end_progress = 0.2,
    light_size_peak_start_progress = 0.125,
    light_size_peak_end_progress = 0.3,
    scale_out_duration = 0.1,
    scale_end = 0.1,
    scale_animation_speed = true,
  }, nil, {silent = true})
  adjust_attr(explosion, "light.size", FL_EXPL_SIZE_MULTIPLIER, function(v, m) return math.ceil(v * m) end,
    explosion.name, true)
end
local function slow_anim(name, anims, rate_explosion, rate_normal)
  if not anims then return end
  if anims.animation_speed then
    adjust_attr(anims, "animation_speed", 1 / rate_explosion); return
  else
    find_adjust_values(anims, {usage = "explosion"}, {animation_speed = 1 / rate_explosion}, nil, nil, nil, true)
    if rate_normal then
      find_adjust_values(anims, nil, {animation_speed = 1 / rate_normal}, nil, nil, nil, true)
    end
  end
end
local function change_light_size(name, light, mult)
  if not light then return end
  light.size = math.ceil(light.size * mult)
end
if FL_FIRE_SIZE_MULTIPLIER ~= 0 then
  for name, fire in pairs(data.raw["fire"]) do
    if (fire.damage_per_tick or {}).type == "fire" then
      modify_fire(name, fire)
    elseif contains_any_substring(name, FIRES_TO_ENHANCE) then
      local light = {intensity = 1.0, size = 22, color = {r = 1.0, g = 0.5, b = 0.3}}
      modify_fire(name, fire, light)
    else
    end
  end
  for name, sticker in pairs(data.raw["sticker"]) do
    if not (sticker.damage_per_tick) or not (sticker.spread_fire_entity or sticker.damage_per_tick.type ~= "fire") then
      goto continue
    end
    local light = {intensity = 0.3, size = 10, color = {r = 0.65, g = 0.4, b = 0.3}}
    modify_fire(name, sticker, light)
    if sticker.fire_spread_cooldown then
      adjust_attr(sticker, "fire_spread_cooldown", 1 / FL_FIRE_SPREAD_MULTIPLIER, nil, " ")
    end
    ::continue::
  end
end
if FL_EXPL_SIZE_MULTIPLIER ~= 0 then
  for name, explosion in pairs(data.raw["explosion"]) do
    if explosion.subgroup ~= "explosions" or explosion.light or explosion.scale then
      if explosion.subgroup == "explosions" then
        if name:find("railgun", 1, true) then
          change_light_size(name, explosion.light, 1.6)
        elseif name:find("fissure", 1, true) then
          change_light_size(name, explosion.light, 1.8)
          explosion.light.color = {r = 1.0, g = 0.45, b = 0.35}
          explosion.light.flicker_interval = explosion.light.flicker_interval or 10
          explosion.light.flicker_min_modifier = explosion.light.flicker_min_modifier or 0.8
          explosion.light.flicker_max_modifier = explosion.light.flicker_max_modifier or 1.5
          slow_anim(name, explosion.animations, 1.2, 1.25)
        else
          change_light_size(name, explosion.light, 1.5)
        end
      end
      goto continue
    end
    if not name:find("explosion", 1, true) or contains_any_substring(name, EXPLOSIONS_SKIP) then goto continue end
    if FL_DISABLE_HIT_EXPLOSION and contains_any_substring(name, EXPLOSIONS_SKIP_PERF) then goto continue end
    local scale = calculate_average_width_scale(explosion)
    if not scale then goto continue end
    set_explosion_light(explosion, 5.5 + scale * EXPLOSION_LIGHT_SIZE_MULT)
    if name:find("gunshot", 1, true) then
      change_light_size(name, explosion.light, 1.6)
      slow_anim(name, explosion.animations, 2.2)
    else
      slow_anim(name, explosion.animations, 1.25)
    end
    if name:find("uranium", 1, true) then
      explosion.light.color = {r = 0.42, g = 0.9, b = 0.32}
      explosion.light.intensity = 0.7
    end
    ::continue::
  end
end
if FL_EXPL_SIZE_MULTIPLIER ~= 0 then
  for name, explosion in pairs(data.raw["explosion"]) do
    if explosion.light or explosion.subgroup == "hit-effects" or
      not contains_any_substring(name, EXPLOSIONS_BUILDING) or
      contains_any_substring(name, EXPLOSIONS_BUILDING_SKIP) then
      goto continue
    end
    local scale = calculate_average_width_scale(explosion)
    if not scale then goto continue end
    set_explosion_light(explosion, 7 + scale * EXPLOSION_DEATH_LIGHT_SIZE_MULT)
    ::continue::
  end
end
for name, turret in pairs(data.raw["fluid-turret"]) do
  if not name:find("flame", 1, true) then goto continue end
  set_attr(turret, "muzzle_light", {intensity = 0.4, size = 5, color = {r = 0.8, g = 0.55, b = 0.2}})
  ::continue::
end
for name, lab in pairs(data.raw["lab"]) do
  if lab.light then goto continue end
  set_attribs(lab, {
    light = {
      intensity = 0.55,
      size = lab.collision_box and (lab.collision_box[2][1] - lab.collision_box[1][1]) * 3.4 or 8,
    },
    ["light.flicker_interval"] = 20,
    ["light.minimum_darkness"] = 0.25,
    ["light.flicker_min_modifier"] = 0.9,
    ["light.flicker_max_modifier"] = 1.1,
  })
  ::continue::
end
local function light_rocket_ships()
  if FL_SILO_SIZE_MULTIPLIER == 0 then return end
  for name, silo in pairs(data.raw["rocket-silo"]) do
    if not silo.base_engine_light or silo.base_engine_light.size ~= 25 then goto continue end
    set_attribs(silo, {
      ["base_engine_light.size"] = 90 * FL_SILO_SIZE_MULTIPLIER,
      ["base_engine_light.color"] = {r = 0.9, g = 0.64, b = 0.52},
    })
    ::continue::
  end
  for name, rocket in pairs(data.raw["rocket-silo-rocket"]) do
    if not rocket.glow_light or rocket.glow_light.size ~= 30 then goto continue end
    set_attribs(rocket, {
      ["glow_light.size"] = 35 * FL_SILO_SIZE_MULTIPLIER,
      ["glow_light.color"] = {r = 0.85, g = 0.55, b = 0.45, a = 0.7},
      ["glow_light.shift"] = {0, 2.0},
    })
    ::continue::
  end
end
local function adjust_nukes()
  if FL_NUKE_EFFECT_MULTIPLIER == 0 then return end
  local atomic_rocket = data.raw["projectile"]["atomic-rocket"]
  if not atomic_rocket then return end
  local atomic_rocket_effects = atomic_rocket.action.action_delivery.target_effects
  if not atomic_rocket_effects then return end
  find_set_values(atomic_rocket_effects, {type = "camera-effect"}, {
    duration = 60 * 2.2 * FL_NUKE_EFFECT_MULTIPLIER,
    ease_in_duration = 5 * 3 * FL_NUKE_EFFECT_MULTIPLIER,
    ease_out_duration = 60 * 1.5 * FL_NUKE_EFFECT_MULTIPLIER,
    delay = 4,
    full_strength_max_distance = 200 * 1.4 * FL_NUKE_EFFECT_MULTIPLIER,
    max_distance = 800 * 1.5 * FL_NUKE_EFFECT_MULTIPLIER,
  }, atomic_rocket.name .. " camera-effects", true)
end
local function increase_scale(scale, mult)
  if not scale then return end
  if scale[1] and scale[2] then
    scale[1] = scale[1] * mult
    scale[2] = scale[2] * mult
  else
    scale = scale * mult
  end
  return scale
end
local function process_visualisation(visualisation)
  if not visualisation then return end
  local light = visualisation.light
  if not light or light.type == "oriented" then return end
  visualisation.scale = increase_scale(visualisation.scale, 1.2)
  light.size = math.ceil(light.size and light.size * 2.7 * FL_FIRE_SIZE_MULTIPLIER or 10)
  light.color = set_colour({0, -0.15, -0.25}, light.color or {1, 1, 1}, true)
end
for name, tree in pairs(data.raw["tree"]) do
  if not contains_any_substring(name, FIRES) then goto continue end
  process_visualisation(tree.stateless_visualisation)
  for i, visualisation in ipairs(tree.stateless_visualisation_variations) do
    process_visualisation(visualisation)
  end
  ::continue::
end
light_rocket_ships()
adjust_nukes()
