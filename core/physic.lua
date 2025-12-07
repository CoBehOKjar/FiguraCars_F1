local state = require("state")
local sound = require("core.sound")
local util = require("lib.utilities")

local Physic = {}

local cfg = state.Config
local data = state.Data
local input = state.Input
local obj = state.Objects

local lastF, lastB, lastL, lastR = false, false, false, false   --?Pressed keys in last tick



--*Function for smooth change of values
local function smooth(current, target, factor)
    return current + (target - current) * factor
end


--*Stopping wheels.
local function stopWheels()
    if obj.GAS then obj.GAS:stop() end
    if obj.REVERSE then obj.REVERSE:stop() end
end



--*Update engine RPM and gear
local function updateEngine(isAccelerating)
    --.Gears
    if data.currentGear < 6 and data.engineRPM >= cfg.SHIFT_UP_RPM then                                                     --?Auto gear up
        data.currentGear = data.currentGear + 1
        data.engineRPM = cfg.SHIFT_UP_TARGET_RPM
    end


    if data.currentGear > 1 and math.abs(data.speedMps) < cfg.gearShiftDownSpeed[data.currentGear] then                     --?Auto gear down
        local rpmBeforeShift = data.engineRPM
        data.currentGear = data.currentGear - 1
        
        if rpmBeforeShift < cfg.SHIFT_DOWN_BLIP_RPM then                                                                    --?RPM over gas
            data.engineRPM = math.min(cfg.SHIFT_DOWN_BLIP_RPM, cfg.MAX_RPM)
        end
    end



    --.RPM
    if isAccelerating then
        local rpmIncrease = cfg.RPM_ACCEL_BASE_RATE * (cfg.gearRatio[data.currentGear] / cfg.gearRatio[1])          --?Increase RPM when pressed gas
        data.engineRPM = data.engineRPM + rpmIncrease
    else
        local targetRPM = cfg.IDLE_RPM + (math.abs(data.speedMps) * 50 / cfg.gearRatio[data.currentGear])           --?Decrease RPM when pressed back or all unpressed
        if data.acceleration < -0.01 and data.engineRPM > targetRPM then
            data.engineRPM = smooth(data.engineRPM, targetRPM, cfg.RPM_DECEL_RATE)
        elseif data.engineRPM > cfg.IDLE_RPM then
            data.engineRPM = data.engineRPM - 100
        end
    end

    --.Limiter
    data.engineRPM = math.max(cfg.IDLE_RPM, math.min(cfg.MAX_RPM, data.engineRPM))                      --?Limiting max and min RPM
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
    local targetAngle = steerInput * cfg.MAX_STEER_ANGLE
    data.steerAngle = smooth(data.steerAngle, targetAngle, cfg.STEERING_SMOOTHNESS) --?Smooth changing angle


    local factor = data.steerAngle / cfg.MAX_STEER_ANGLE        --?Applying steer to model
    local targetTime = 1.0 + factor
    obj.STEERING:setTime(targetTime):setSpeed(0):play()
end



--*Wheels speed and direction animation uodate
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


    if rotationSpeed < 0.01 then    --?If the rotation speed too low, stop the animations and return
        if obj.GAS then obj.GAS:stop() end
        if obj.REVERSE then obj.REVERSE:stop() end
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

    if vehicleType == "boat" and player:getControlledVehicle() then   --?Model can be used only on boat
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



        local velocity = player:getVelocity()                   --?Calc speed and acceleration
        local yaw = math.rad(player:getBodyYaw())               --?Cals directional speed
        local bodyDir = vec(math.sin(yaw), 0, -math.cos(yaw))
        local flatVel = vec(velocity.x, 0, velocity.z)

        data.speedMps = flatVel:dot(bodyDir) * 20           --?Scalar velocity along the direction of motion
        data.acceleration = data.speedMps - data.prevSpeedMps   --?Calc acceleration



        updateEngine(input.accelState)                  --?Updates
        updateSteering()
        updateWheelRotation()
        models.car.F1:setPos(0, 8, 0)
    else
        obj.STEERING:stop()
        data.engineRPM = 0
        stopWheels()

        models.car.F1:setPos(0, 0, 0)
    end

    sound.tick()

    data.wasInVehicle = data.inVehicle
    data.prevSpeedMps = data.speedMps
end

return Physic