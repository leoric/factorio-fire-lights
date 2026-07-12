require("__data-utils__.data.util")
require("data.settings")
local CHAR_FLASHLIGHT_MULT = 1.25
local FLASHLIGHT_MULT = 1.3
local OFFSET_REDUCTION = 1.1
if mods["RealisticFlashlight"] or mods["realistic-flashlight-fixed"] or mods["light-overhaul"] then
  CHAR_FLASHLIGHT_MULT = 1.05
  FLASHLIGHT_MULT = 1.0
  OFFSET_REDUCTION = 1.0
end
local function inc_flashlight(light, mult, name, limit)
  if not light or type(light) ~= "table" or not light.type or light.type ~= "oriented" then return end
  if limit and light.size > limit then return end
  local mult = mult * FL_FLASH_SIZE_MULTIPLIER
  local base_size = light.size
  light.size = light.size * mult
  if not light.shift then return end
  local offset = (light.shift.y or light.shift[2]) / OFFSET_REDUCTION
  if light.shift.y then
    light.shift.y = math.min((offset / base_size) * light.size)
  elseif light.shift[2] then
    light.shift[2] = math.min((offset / base_size) * light.size)
  end
end
local function process_character(character)
  if not character or not character.light then return end
  for _, light in pairs(character.light) do inc_flashlight(light, CHAR_FLASHLIGHT_MULT, "character", 2) end
end
local function process_vehicles(vehicles)
  if not vehicles then return end
  for name, vehicle in pairs(vehicles) do
    if not vehicle or not vehicle.light then goto continue end
    for _, light in ipairs(vehicle.light) do inc_flashlight(light, FLASHLIGHT_MULT, name, 2.5) end
    ::continue::
  end
end
local function process_trains(trains)
  if not trains then return end
  for name, train in pairs(trains) do
    if not train or not train.front_light then goto continue end
    for _, light in ipairs(train.front_light) do inc_flashlight(light, FLASHLIGHT_MULT, name, 2.5) end
    ::continue::
  end
end
local function process_spiders(spiders)
  if not spiders then return end
  local initial_spider_light = {}
  for name, spider in pairs(spiders) do
    if not spider.graphics_set or not spider.graphics_set.light then goto continue end
    for id, light in pairs(spider.graphics_set.light) do
      if type(light) ~= "table" or light.type ~= "oriented" or not light.size or light.size < 0.5 then
        goto continue
      end
      if not initial_spider_light[id] then
        inc_flashlight(light, FLASHLIGHT_MULT, name, 2.7)
        initial_spider_light[id] = light
      elseif initial_spider_light[id].size > light.size then
        light = initial_spider_light[id]
      end
      spider.graphics_set.light[id] = light
      ::continue::
    end
    ::continue::
  end
end
if FL_FLASH_SIZE_MULTIPLIER ~= 0 then
  process_character(data.raw.character and data.raw.character.character)
  process_vehicles(data.raw["car"])
  process_trains(data.raw["locomotive"])
  process_spiders(data.raw["spider-vehicle"])
end
