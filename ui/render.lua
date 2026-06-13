local state = require("state")

local Render = {}

local cfg = state.Config
local data = state.Data
local obj = state.Objects
local stgs = state.Settings

local driverParts = { "LeftLeg", "RightLeg", "LeftArm", "RightArm", "Body" }                                            --?Parts of model for hidding, when in car
local armorParts = { "LEGGINGS_BODY", "LEGGINGS_LEFT_LEG", "LEGGINGS_RIGHT_LEG", "BOOTS_LEFT_LEG", "BOOTS_RIGHT_LEG", "ELYTRA"}   --?Parts of vanilla armor for hidding, when in car
local segmentRPM = cfg.MAX_RPM / (#cfg.RPM_UV - 1)        --?RPM in one pixel of indicator on steering wheel
local hasWheel = obj.Tens and obj.Units and obj.Gear and obj.RPM and obj.Fuel     --?Check, what steering wheel exist

local colors = {
    yellow = vec(0.941, 0.871, 0.11),
    green  = vec(0.137, 0.839, 0.067),
    orange = vec(0.941, 0.675, 0.157),
    red    = vec(0.941, 0.227, 0.157),
    off    = vec(0.961, 0.961, 0.961)
}

local function updateSectors()
    local info = world.avatarVars()
    local light = nil

    for _, d in pairs(info) do
        if d["TrackLights"] then
            light = d["TrackLights"]
            break
        end
    end

    if not light then return end


    if light.Red then 
        obj.Sec1:setColor(colors.red)
        obj.Sec2:setColor(colors.red)
        obj.Sec3:setColor(colors.red)
    elseif light.Orange then 
        obj.Sec1:setColor(colors.orange)
        obj.Sec2:setColor(colors.orange)
        obj.Sec3:setColor(colors.orange)
    else

        if light.Sec1 then obj.Sec1:setColor(colors.yellow)
        elseif light.Green then obj.Sec1:setColor(colors.green)
        else obj.Sec1:setColor(colors.off) end

        if light.Sec2 then obj.Sec2:setColor(colors.yellow)
        elseif light.Green then obj.Sec2:setColor(colors.green)
        else obj.Sec2:setColor(colors.off) end

        if light.Sec3 then obj.Sec3:setColor(colors.yellow)
        elseif light.Green then obj.Sec3:setColor(colors.green)
        else obj.Sec3:setColor(colors.off) end
    end
end


--*Updating speed on speedometer
local function updateSpeed()
    local speed = math.floor(math.abs(state.Data.absSpeedMps)) --?Getting a natural speed number

    if speed > 99 then                                                      --?Max display speed
        speed = 99 
    end

    local tensDigit = math.floor(speed / 10)                    --?Calculating tens and units for display speed
    local unitsDigit = speed % 10

    local tensUV = cfg.SPEED_UV[tensDigit + 1]
    local unitsUV = cfg.SPEED_UV[unitsDigit + 1]

    if hasWheel then                                                        --?Applying speed to speedometer
        obj.Tens:setUV(tensUV)
        obj.Units:setUV(unitsUV)
    end
end


--*Updating RPM on speedometer
local function updateRPM()
    local index = math.floor(data.engineRPM / segmentRPM) + 1
    index = math.min(math.max(index, 1), #cfg.RPM_UV)

    if hasWheel then
        obj.RPM:setUV(cfg.RPM_UV[index])
    end
end


--*Updating Gear on speedometer
local function updateGear()
    if hasWheel then
        obj.Gear:setUV(cfg.GEAR_UV[data.currentGear])
    end
end


--*Updating Fuel on speedometer
local function updateFuel()
    local fuelNorm = data.fuel / cfg.maxFuel
    fuelNorm = math.max(0, math.min(1, fuelNorm))

    if fuelNorm <= 0.2 then
        local flash = (data.worldTime % 20 < 10) and 1 or 0
        obj.Fuel:setColor(flash)
    else
        obj.Fuel:setColor(1)
    end

    if hasWheel then
        obj.Fuel:setScale(nil, fuelNorm, nil)
    end
end



function Render.spawnEdgeParticles(p1, p2, pos)
    local center = (p1 + p2) / 2
    local dist = (pos - center):lengthSquared()
    if dist > stgs.renderDist then return end

    local x1, y1, z1 = p1.x, p1.y, p1.z
    local x2, y2, z2 = p2.x, p2.y, p2.z

    local function line(xa, ya, za, xb, yb, zb)
        local dx = xb - xa
        local dy = yb - ya
        local dz = zb - za

        local steps = math.max(math.abs(dx), math.abs(dy), math.abs(dz))
        if steps < 1 then steps = 1 end

        local sx = dx / steps
        local sy = dy / steps
        local sz = dz / steps

        for i = 0, steps do
            particles["minecraft:wax_on"]
                :spawn()
                :setPos(vec(
                    xa + sx * i,
                    ya + sy * i,
                    za + sz * i
                ))
        end
    end

    line(x1, y1, z1, x1, y2, z1)
    line(x2, y1, z1, x2, y2, z1)
    line(x1, y1, z2, x1, y2, z2)
    line(x2, y1, z2, x2, y2, z2)

    line(x1, y1, z1, x2, y1, z1)
    line(x1, y1, z1, x1, y1, z2)
    line(x2, y1, z1, x2, y1, z2)
    line(x1, y1, z2, x2, y1, z2)

    line(x1, y2, z1, x2, y2, z1)
    line(x1, y2, z1, x1, y2, z2)
    line(x2, y2, z1, x2, y2, z2)
    line(x1, y2, z2, x2, y2, z2)
end



--*Main tick function
function Render.tick()
    --.Model parts visibility update
    obj.F1:setVisible(data.inVehicle)                 --?Show car
    renderer:setRenderVehicle(not data.inVehicle) --?And hide boat

    local driverVisible = not data.inVehicle      --?Hidding parts of model that extend beyond the textures
    for _, part in ipairs(driverParts) do
        if obj.Driver[part] then
            obj.Driver[part]:setVisible(driverVisible)
        end
    end
    for _, part in ipairs(armorParts) do                --?Hidding parts of vanilla armor that extend beyond the textures
        vanilla_model[part]:setVisible(driverVisible)
    end
    vanilla_model.CAPE:setVisible(driverVisible)            --?And cape
    

    if data.inVehicle then
        --.Speedometer update
        updateSpeed()
        updateGear()
        updateRPM()
        updateFuel()
        if data.IS_HOST then
            updateSectors()
        end

        --.Camera position update
        renderer:offsetCameraPivot(0, stgs.camHeight, 0)    --?Set camera height, what needed, when in car
        renderer:setEyeOffset(0, stgs.camHeight, 0)
    else
        renderer:offsetCameraPivot(0, 0, 0)
        renderer:setEyeOffset(0, 0, 0)
    end
end



--*Rendering car in player position
function Render.render(delta)
    local pos = player:getPos(delta)*16
    obj.F1:setPos(pos[1], pos[2]+7, pos[3]) --?+7 because player is under the block the boat is on
        :setRot(0,-player:getBodyYaw(delta)-180,0)
end

return Render