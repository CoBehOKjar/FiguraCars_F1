config:setName("BolidF1")
--TODO Разобраться со звуком при ливе
--TODO интегрировать GNUI
--TODO партиклы
--TODO комменты
--TODO доработать пресеты
--TODO инглиш мазафака
local state = require("state")
local stopwatch = require("lib.stopwatch")
local action_wheel = require("ui.action_wheel")
local render = require("ui.render")
local physic = require("core.physic")
local sound = require("core.sound")
local util = require("lib.utilities")


local obj = state.Objects
local data = state.Data
local stgs = state.Settings
local cfg = state.Config

--*Entity initialization process
function events.entity_init()
    vanilla_model.PLAYER:setVisible(false)
    obj.Driver:setPrimaryTexture("SKIN")
    obj.DriverFP:setPrimaryTexture("SKIN")

    state.init()
    action_wheel.init()
    sound.init()

    if data.IS_HOST and not stgs.notFirstLaunch then
        print("Figura avatar F1 §3"..cfg.v)
        print(cfg.helloMsg)
        config:save("notFirstLaunch", true)
    end
end



--*Tick process
function events.tick()
    if not player:isLoaded() then return end
    physic.tick()
    render.tick()
    stopwatch.tick()

    util.dbgTickFlush()

    if data.IS_HOST then
        if world.getTime() % 200 == 0 then
            if stgs.engineVolume ~= data.lastEngineVolume then
                config:save("engineVolume", stgs.engineVolume)
            end
            if stgs.camHeight ~= data.lastCamHeight then
                config:save("camHeight", stgs.camHeight)
            end

            data.lastEngineVolume = stgs.engineVolume
            data.lastCamHeight = stgs.camHeight
        end
    end
end



--*Render process
function events.world_render(delta)
    if not player:isLoaded() then return end
    render.render(delta)
end