local state = require("state")

local Render = {}

local cfg = state.Config
local data = state.Data
local obj = state.Objects
local stgs = state.Settings

local driverParts = { "LeftLeg", "RightLeg", "LeftArm", "RightArm", "Body" }                                            --?Parts of model for hidding, when in car
local armorParts = { "LEGGINGS_BODY", "LEGGINGS_LEFT_LEG", "LEGGINGS_RIGHT_LEG", "BOOTS_LEFT_LEG", "BOOTS_RIGHT_LEG", "ELYTRA"}   --?Parts of vanilla armor for hidding, when in car
local segmentRPM = cfg.MAX_RPM / (#cfg.RPM_UV - 1)        --?RPM in one pixel of indicator on steering wheel
local hasWheel = models.car.F1.WorldRoot.Car.Frame.SteeringWheel ~= nil     --?Check, what steering wheel exist



--*Updating speed on speedometer
local function updateSpeed()
    local speed = math.floor(math.abs(state.Data.speedMps)) --?Getting a natural speed number

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
    host:setActionbar(data.fuel)
    --.Speedometer update
    updateSpeed()
    updateGear()
    updateRPM()


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
    

    --.Camera position update
    if data.inVehicle then    --?Set camera height, what needed, when in car
        renderer:offsetCameraPivot(0, stgs.camHeight, 0)
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