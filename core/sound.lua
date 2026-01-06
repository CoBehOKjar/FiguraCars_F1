local state = require("state")

local Sound = {}

local cfg = state.Config
local data = state.Data
local obj = state.Objects

local engineLoop = sounds["car.sounds.EngineLoop"]     --?Sounds path
local ignitionSound = sounds["car.sounds.Ignition"]
local kchauSound = sounds["car.sounds.Kchau"]

local targetPitch = 1   --?Engine sound target pitch for smooth changing
local currentPitch = 1  --?Current sound pitch
local currentVolume = 1 --?Current sound volume

local isEnginePlaying = false   --?Current engine sound state
local fadeOutActive = false     --?Fade out engine volume, when exit from vehicle
local fadeSpeed = 0.08          --?Speed of fade out


--*Smooth.
local function smooth(a, b, k)
    return a + (b - a) * k
end


--*Meme
function pings.kchau(pos, pitch)
    if player:isLoaded() then
        kchauSound:setPos(pos):setPitch(pitch):play()
    end
end
obj.ACTIONKEY.press = function () pings.kchau(player:getPos(), math.random(8, 15) / 10) end


--*Stop engine sound
function Sound.stopEngine()
    fadeOutActive = true
end


--*For immedantly stop
function Sound.forceStop()
    if isEnginePlaying then
        engineLoop:stop()
        isEnginePlaying = false
        fadeOutActive = false
        currentVolume = 0
    end
end



--*Play ignition sound, when you sit in vehicle
function Sound.playIgnition(pos)
    if ignitionSound then
        ignitionSound:setPos(pos):play()
    end
end



--*Engine starting
function Sound.startEngine(pos)
    if not engineLoop or isEnginePlaying then return end
    
    fadeOutActive = false
    currentVolume = 1

    engineLoop:setPos(pos)
        :setVolume(currentVolume)
        :setPitch(currentPitch)
        :play()

    isEnginePlaying = true
end



--*Engine sound properties update
function Sound.updateEngine(pos)
    kchauSound:setPos(pos)
    engineLoop:setPos(pos)  --?Updating position


    local norm = (data.engineRPM - cfg.IDLE_RPM) / (cfg.MAX_RPM - cfg.IDLE_RPM)
    targetPitch = 0.8 + norm * 1.2                                  --?Set the pitch depending on the RPM


    if not host:isHost() then   --?Doppler effect for other players
        local vel = player:getVelocity()
        local viewer = client:getViewer()
        local viewerPos = viewer:getPos()
        local viewerVel = viewer:getVelocity()

        local dirVec = viewerPos - pos
        local dist = dirVec:length()
        local dir = vec(0,0,0)
        if dist > 0 then dir = dirVec / dist end

        local rel = (vel - viewerVel):dot(dir)
        local dopplerScale = 10.0

        local dopplerFactor = 1 + (rel / dopplerScale)
        dopplerFactor = math.max(0.8, math.min(1.2, dopplerFactor))

        targetPitch = targetPitch * dopplerFactor
    end

    currentPitch = smooth(currentPitch, targetPitch, 0.2)
    engineLoop:setPitch(currentPitch)


    if fadeOutActive then   --?Engine fade out when exit from car
        currentVolume = currentVolume - fadeSpeed
        if currentVolume <= 0 then
            currentVolume = 0
            fadeOutActive = false
            isEnginePlaying = false
            engineLoop:stop()
            return
        end 
    end
    engineLoop:setVolume(currentVolume)
end



--*Set loop to engine sound on initialization
function Sound.init()
    engineLoop:setLoop(true)
    engineLoop:setAttenuation(5)
    kchauSound:setAttenuation(5)
end



--*Main tick function
function Sound.tick()
    if data.inVehicle and not data.wasInVehicle then
        data.engineRPM = cfg.IDLE_RPM
        Sound.playIgnition(player:getPos())
        Sound.startEngine(player:getPos())

    elseif not data.inVehicle and data.wasInVehicle then
        Sound.stopEngine()
    end
    Sound.updateEngine(player:getPos())
end
return Sound