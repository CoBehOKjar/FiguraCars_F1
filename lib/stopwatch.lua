local state = require("state")
local render = require("ui.render")

local Stopwatch = {}

local cfg = state.Config
local data = state.Data
local input = state.Input
local obj = state.Objects

local cbx = data.checkBox

local points = {vec(0,0,0), vec(0,0,0)}



local function isInsideBox(pos)
    return  pos.x >= cbx[1].x and pos.x <= cbx[2].x
    and     pos.y >= cbx[1].y and pos.y <= cbx[2].y
    and     pos.z >= cbx[1].z and pos.z <= cbx[2].z
end

local function vecToString(v)
    return string.format("§cX.%.1f §aY.%.1f §bZ.%.1f§7", v[1], v[2], v[3])
end

local function sendToActionbar(title)
    host:setActionbar(title)
end

local function resetBox(pos)
    Stopwatch.setBox(1, pos - vec(1,1,1))
    Stopwatch.setBox(2, pos + vec(1,1,1))
    render.spawnEdgeParticles(data.checkBox[1], data.checkBox[2])
end



--*Set trigger box on RMB, LMB
function Stopwatch.setBox(point, pos, expand)
    expand = expand or false
    points[point] = pos

    local p1 = points[1]
    local p2 = points[2]

    cbx[1] = vec(
        math.min(p1[1], p2[1]),
        math.min(p1[2], p2[2]),
        math.min(p1[3], p2[3])
    )

    cbx[2] = vec(
        math.max(p1[1], p2[1]),
        math.max(p1[2], p2[2]),
        math.max(p1[3], p2[3])
    )

    if expand then
        cbx[1].y = cbx[1].y -1
        cbx[2].y = cbx[2].y +1
    end

    sendToActionbar("§6Текущая область: "..vecToString(cbx[1]).." / "..vecToString(cbx[2]))
    render.spawnEdgeParticles(data.checkBox[1], data.checkBox[2])

    data.isCheckBoxCreated = true
end



--*Changing trigger box on wheel scroll
function Stopwatch.changeBox(dir)
    local alt = obj.ALTKEY:isPressed()
    local ctrl = obj.CTRLKEY:isPressed()
    local shift = obj.SHIFTKEY:isPressed()

    local pos = player:getPos()
    local look = player:getLookDir():normalize()

    local ax, ay, az = math.abs(look.x), math.abs(look.y), math.abs(look.z)
    local maxAxis = math.max(ax, ay, az)
    local mainAxis = (maxAxis == ax and "x") or (maxAxis == ay and "y") or "z"


    if not data.isCheckBoxCreated then
        resetBox(pos)
        return
    end


    if ctrl and shift then  --?Disable box
        cbx[1] = vec(0,0,0)
        cbx[2] = vec(0,0,0)
        data.isCheckBoxCreated = false
        sendToActionbar("§cЗона удалена")
        return
    end


    if alt then             --?Reset box
        resetBox(pos)
        return
    end


    if ctrl then            --?Change in all directions
        local v = vec(dir, dir, dir)
        cbx[1] = cbx[1] - v
        cbx[2] = cbx[2] + v
        sendToActionbar("§6Текущая область: "..vecToString(cbx[1]).." / "..vecToString(cbx[2]))
        render.spawnEdgeParticles(data.checkBox[1], data.checkBox[2])
        return
    end


    if shift then           --?Change only look direction
        local vz = vec(0,0,0)
        vz[mainAxis] = dir

        if look[mainAxis] > 0 then
            cbx[2][mainAxis] = cbx[2][mainAxis] + dir
        else
            cbx[1][mainAxis] = cbx[1][mainAxis] - dir
        end

        sendToActionbar("§6Текущая область: "..vecToString(cbx[1]).." / "..vecToString(cbx[2]))
        render.spawnEdgeParticles(data.checkBox[1], data.checkBox[2])
        return
    end


    --?Change only look axis
    local vz = vec(0,0,0)
    vz[mainAxis] = dir

    cbx[1] = cbx[1] - vz
    cbx[2] = cbx[2] + vz
    sendToActionbar("§6Текущая область: "..vecToString(cbx[1]).." / "..vecToString(cbx[2]))
    render.spawnEdgeParticles(data.checkBox[1], data.checkBox[2])
end



--*Main tick function
function Stopwatch.tick()
    --.Chechbox frame render
    if data.renderBox and data.isCheckBoxCreated then
        if world.getTime() % 5 == 0 then
            render.spawnEdgeParticles(data.checkBox[1], data.checkBox[2])
        end
    end

    if not data.isClocking then return end

    data.inCheckBox = isInsideBox(player:getPos())

    if data.inCheckBox and not data.wasInCheckBox then
        -- Время круга
        local lapTicks = data.currentTime - data.lastTime
        local lapSec = lapTicks / 20
        local lapMin = math.floor(lapSec / 60)
        local lapSecR = math.floor(lapSec % 60)

        -- Общее время
        local totalSec = data.currentTime / 20
        local totalMin = math.floor(totalSec / 60)
        local totalSecR = math.floor(totalSec % 60)

        -- Обновить последнее время
        data.lastTime = data.currentTime

        print("§fLap §6" .. data.currentLap ..
              " §ftime: §a" .. lapMin .. "m" .. lapSecR ..
              "s. §fTotal: §b" .. totalMin .. "m" .. totalSecR .. "s.")

        data.currentLap = data.currentLap + 1
    end

    data.wasInCheckBox = data.inCheckBox
    data.currentTime = data.currentTime + 1
end


return Stopwatch