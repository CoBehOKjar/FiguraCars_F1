local state = require("state")

local Utility = {}

local boats = {
    ["minecraft:oak_boat"] = true,
    ["minecraft:birch_boat"] = true,
    ["minecraft:spruce_boat"] = true,
    ["minecraft:jungle_boat"] = true,
    ["minecraft:dark_oak_boat"] = true,
    ["minecraft:mangrove_boat"] = true,
    ["minecraft:cherry_boat"] = true,
    ["minecraft:pale_oak_boat"] = true,
}

local chest_boats = {
    ["minecraft:oak_chest_boat"] = true,
    ["minecraft:birch_chest_boat"] = true,
    ["minecraft:spruce_chest_boat"] = true,
    ["minecraft:jungle_chest_boat"] = true,
    ["minecraft:dark_oak_chest_boat"] = true,
    ["minecraft:mangrove_chest_boat"] = true,
    ["minecraft:cherry_chest_boat"] = true,
    ["minecraft:pale_oak_chest_boat"] = true,
}

function Utility.getVehicleType(v)
    if not v then return "none" end

    local t = v:getType()

    if boats[t] then return "boat" end
    if chest_boats[t] then return "chest_boat" end
    if t == "minecraft:bamboo_raft" then return "raft" end
    if t == "minecraft:bamboo_chest_raft" then return "chest_raft" end

    if t == "minecraft:horse" then return "horse" end
    if t == "minecraft:donkey" then return "donkey" end
    if t == "minecraft:mule" then return "mule" end
    if t == "minecraft:camel" then return "camel" end

    if t == "minecraft:pig" then return "pig" end
    if t == "minecraft:strider" then return "strider" end

    if t == "minecraft:minecart" then return "minecart" end

    return "unknown"
end



function Utility.tprint(t, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)

    for k, v in pairs(t) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. " = {")
            Utility.tprint(v, indent + 1)
            print(prefix .. "}")
        else
            print(prefix .. tostring(k) .. " = " .. tostring(v))
        end
    end
end



function Utility.smooth(a, b, k)
    return a + (b - a) * k
end



local last = {}
function Utility.dbg(key, text)
  if not state.Settings.debug then return end

  if last[key] == text then return end
  last[key] = text

  print("§5[DBG]§f "..text)
end


return Utility