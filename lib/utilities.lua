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



function Utility.smooth(a, b, k)
    return a + (b - a) * k
end


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




function Utility.dbgEvent(tag, msg)
    if not state.Settings.debugEvent then return end
    print(("§5[§dEVT§5]§7 %s: §f%s"):format(tag, msg))
end


local tickBuf = {}
function Utility.dbgTick(lines)
    for k, v in pairs(lines) do
        table.insert(tickBuf, ("§e%s§f: %s"):format(k, tostring(v)))
    end
end

function Utility.dbgTickFlush()
    if not state.Settings.debugTick then
        tickBuf = {}
        return
    end

    if #tickBuf == 0 then return end

    local text = table.concat(tickBuf, "  §5|§f  ")
    tickBuf = {}

    local to = state.Settings.debugTickTo or "ab"
    if to == "ch" then
        print("§5[§dTICK§5]§f " .. text)
    else
        host:setActionbar("§5[§dTICK§5]§f " .. text)
    end
end


return Utility