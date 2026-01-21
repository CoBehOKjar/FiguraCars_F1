local state = require("state")
local sound = require("core.sound")
local util = require("lib.utilities")

local Physic = {}

local cfg = state.Config
local data = state.Data
local input = state.Input
local obj = state.Objects

local lastF, lastB, lastL, lastR = false, false, false, false   --?Pressed keys in last tick

local BOAT_RADIUS = 1.375 / 2



--*Stopping wheels.
local function stopWheels()
    if obj.GAS then obj.GAS:setSpeed(0) end
    if obj.REVERSE then obj.REVERSE:setSpeed(0) end
end


--*Return block id in coords
local function blockIdAt(x, y, z)
    return world.getBlockState(vec(math.floor(x), math.floor(y), math.floor(z))):getID()
end


--*Check block and entity under boat
local function underBoat(vehicle)
    local pos = vehicle:getPos()

    local x1 = pos.x - BOAT_RADIUS
    local z1 = pos.z - BOAT_RADIUS
    local x2 = pos.x + BOAT_RADIUS
    local z2 = pos.z + BOAT_RADIUS

    local y1 = pos.y - 1
    local y2 = pos.y + 1

    --.Check hopper minecart
    local ents = world.getEntities(x1, y1, z1, x2, y2, z2)
    local hopCount = 0
    for _, e in pairs(ents) do
        if e:getType() == "minecraft:hopper_minecart" then
            hopCount = hopCount + 1
        end
    end

    --.Check pit block
    local checkY = pos.y - 1.0
    local step = BOAT_RADIUS

    for ix = -1, 1 do
        for iz = -1, 1 do
            local px = pos.x + ix * step
            local pz = pos.z + iz * step

            local id = blockIdAt(px, checkY, pz)
            if cfg.REFUEL_BLOCKS[id] then
                return hopCount, true
            end
        end
    end

    return hopCount, false
end



--*Update engine RPM and gear
local function updateEngine(isAccelerating)
    --.Gears
    if data.currentGear < #cfg.gearRatio and data.engineRPM >= cfg.SHIFT_UP_RPM then                                                     --?Auto gear up
        data.currentGear = data.currentGear + 1
        data.engineRPM = cfg.SHIFT_UP_TARGET_RPM
        obj.EXFIRE:play()
    end


    if data.currentGear > 1 and math.abs(data.speedMps) < cfg.gearShiftDownSpeed[data.currentGear] then                     --?Auto gear down
        local rpmBeforeShift = data.engineRPM
        data.currentGear = data.currentGear - 1
        obj.EXFIRE:play()
        
        if rpmBeforeShift < cfg.SHIFT_DOWN_BLIP_RPM then                                                                    --?RPM over gas
            data.engineRPM = math.min(cfg.SHIFT_DOWN_BLIP_RPM, cfg.MAX_RPM)
            obj.EXFIRE:play()
        end
    end



    --.RPM
    if isAccelerating then
        local rpmIncrease = cfg.RPM_ACCEL_BASE_RATE * (cfg.gearRatio[data.currentGear] / cfg.gearRatio[1])          --?Increase RPM when pressed gas
        data.engineRPM = data.engineRPM + rpmIncrease
    else
        local targetRPM = cfg.IDLE_RPM + (math.abs(data.speedMps) * 50 / cfg.gearRatio[data.currentGear])           --?Decrease RPM when pressed back or all unpressed
        data.engineRPM = util.smooth(data.engineRPM, targetRPM, 0.3)
    end

    --.Limiter
    local maxRPM = cfg.MAX_RPM
    if data.inWater then
        maxRPM = cfg.WATER_MAX_RPM
    end
    data.engineRPM = math.max(cfg.IDLE_RPM, math.min(maxRPM, data.engineRPM))                  --?Limiting max and min RPM
end



--*Steering angle and animation update
local function updateSteering()
    local steerInput = 0    --?-1 Left, +1 Right

    --.Inputs
    if input.leftState then
        steerInput = steerInput - 1
    end
    if input.rightState then
        steerInput = steerInput + 1
    end


    if input.backState and not input.accelState then    --?Reverse steering if move back
        steerInput = -steerInput
    end


    --.Math
    local targetAngle
    if steerInput ~= 0 then
        targetAngle = steerInput * cfg.MAX_STEER_ANGLE
    else
        local velocity = player:getVelocity()
        local flatVel = vec(velocity.x, 0, velocity.z)

        local yaw = math.rad(player:getBodyYaw())
        local bodyDir = vec(math.sin(yaw), 0, -math.cos(yaw))
        local rightDir = vec(bodyDir.z, 0, -bodyDir.x)

        local sidewaysSpeed = flatVel:dot(rightDir)
        targetAngle = math.max(-cfg.MAX_STEER_ANGLE, math.min(cfg.MAX_STEER_ANGLE, sidewaysSpeed * 20))
    end

    data.steerAngle = util.smooth(data.steerAngle, targetAngle, cfg.STEERING_SMOOTHNESS) --?Smooth changing angle


    local factor = data.steerAngle / cfg.MAX_STEER_ANGLE        --?Applying steer to model
    local targetTime = 1.0 + factor
    obj.STEERING:setTime(targetTime):setSpeed(0):play()
end



--*Wheels speed and direction animation update
local function updateWheelRotation()
    local rotationSpeed = 0
    local absSpeed = math.abs(data.speedMps)
    data.isDriving = input.accelState or input.backState        --?Is pressed gas or back
    

    --.Match motion type
    if data.isDriving then  --?Movement with keys pressed (depending on RPM and gear)
        rotationSpeed = (data.engineRPM * cfg.gearRatio[data.currentGear]) * cfg.RPM_TO_WHEEL_SPEED_FACTOR  --?Wheel speed is proportional to RPM * GearRatio

        if input.backState and not input.accelState then
            rotationSpeed = rotationSpeed * cfg.REVERSE_SLOWDOWN_FACTOR --?If pressed only back - speed down animation
        end

    elseif absSpeed > 0.1 then  --?Inertial motion, when keys unpressed
        rotationSpeed = absSpeed * cfg.COASTING_WHEEL_FACTOR
    end

    if data.inWater then
        rotationSpeed = rotationSpeed * 0.3
    end


    if rotationSpeed < 0.01 then    --?If the rotation speed too low, stop the animations and return
        if obj.GAS then obj.GAS:setSpeed(0) end
        if obj.REVERSE then obj.REVERSE:setSpeed(0) end
        return
    end

    --.Animation control
    local playForward = false   --?Rotate directions
    local playBackward = false


    if input.accelState then --?Input priority
        playForward = true
    elseif input.backState then
        playBackward = true
    else    --?If nothing pressed - use speed
        playForward = data.speedMps < -0.1
        playBackward = data.speedMps > 0.1
    end


    if playForward then --?Applying animation speed and direction
        if obj.GAS then 
            obj.GAS:setSpeed(rotationSpeed)
                :play()
        end
        if obj.REVERSE then obj.REVERSE:stop() end

    elseif playBackward then 
        if obj.REVERSE then
            obj.REVERSE:setSpeed(rotationSpeed)
                :play()
        end
        if obj.GAS then obj.GAS:stop() end

    else
        stopWheels()
    end
end



--*Main tick function
function Physic.tick()
    --.Initial variables
    local vehicle = player:getVehicle()                     --?Getting vehicle type
    local vehicleType = util.getVehicleType(vehicle)

    if vehicleType == "chest_boat" and player:getControlledVehicle() then   --?Model can be used only on boat
        data.inVehicle = true
    else
        data.inVehicle = false
    end

    --.Calculating updates
    if data.inVehicle then
        local f = obj.ACKEY:isPressed()                         --?Check pressed keys
        local b = obj.BKKEY:isPressed()
        local l = obj.LFKEY:isPressed()
        local r = obj.RTKEY:isPressed()
        if f ~= lastF or b ~= lastB or l ~= lastL or r ~= lastR then    --?Sync keys states, if changeg from last tick
            pings.inputSync(f, b, l, r)
            lastF, lastB, lastL, lastR = f, b, l, r
        end


        data.inWater = vehicle:isInWater()
        if data.inWater and not data.wasInWater then
            obj.SWIMMING:play()
            obj.UNSWIMMING:stop()
            util.dbgEvent("PHS", "Swiming: §9"..tostring(data.inWater))
        elseif not data.inWater and data.wasInWater then
            obj.UNSWIMMING:play()
            obj.SWIMMING:stop()
            util.dbgEvent("PHS", "Swiming: §9"..tostring(data.inWater))
        end
        data.wasInWater = data.inWater


        local velocity = player:getVelocity()                   --?Calc speed and acceleration
        local yaw = math.rad(player:getBodyYaw())               --?Cals directional speed
        local bodyDir = vec(math.sin(yaw), 0, -math.cos(yaw))
        local flatVel = vec(velocity.x, 0, velocity.z)

        data.speedMps = flatVel:dot(bodyDir) * 20           --?Scalar velocity along the direction of motion
        data.acceleration = data.speedMps - data.prevSpeedMps   --?Calc acceleration



        updateEngine(input.accelState)                  --?Updates
        updateSteering()
        updateWheelRotation()

        if host:isHost() then
            local hopCount, refueled = underBoat(vehicle)

            util.dbgTick({U = (refueled and ("R("..hopCount..")") or hopCount)})

            local statusKey = (refueled and ("refueled:"..hopCount) or ("hopped:"..hopCount))
            if statusKey ~= data.lastUnderStatus then
                util.dbgEvent("PHS", "Under: "..statusKey)
                data.lastUnderStatus = statusKey
            end

            if refueled then
                data.fuel = cfg.maxFuel
            elseif hopCount > 0 then
                data.fuel = math.max(0, data.fuel - hopCount)
            end
        end

        models.car.F1:setPos(0, 8, 0)
    else
        obj.STEERING:stop()
        data.engineRPM = 0
        stopWheels()

        models.car.F1:setPos(0, 0, 0)
    end

    sound.tick()

    if data.inVehicle ~= data.wasInVehicle then
        util.dbgEvent("PHS", "In boat: §9"..tostring(data.inVehicle))
    end

    util.dbgTick({
        S = string.format("%.2f", data.speedMps),
        G = data.currentGear,
        R = math.floor(data.engineRPM),
        F = data.fuel,
        W = data.inWater,
        A = string.format("%.2f", data.acceleration),
        I = (input.accelState and "W" or "-")..(input.backState and "S" or "-")..(input.leftState and "A" or "-")..(input.rightState and "D" or "-")
    })

    data.wasInVehicle = data.inVehicle
    data.prevSpeedMps = data.speedMps
end

return Physic