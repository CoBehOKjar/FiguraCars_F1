--TODO Разобраться с отображением фпв
--TODO Разобраться со звуком при ливе
--TODO кчау
local state = require("state")
local stopwatch = require("lib.stopwatch")
local action_wheel = require("ui.action_wheel")
local render = require("ui.render")
local physic = require("core.physic")
local sound = require("core.sound")


local obj = state.Objects

--*Entity initialization process
function events.entity_init()
    vanilla_model.PLAYER:setVisible(false)
    obj.Driver:setPrimaryTexture("SKIN")
    obj.DriverFP:setPrimaryTexture("SKIN")

    action_wheel.init()
    sound.init()
end



--*Tick process
function events.tick()
    if not player:isLoaded() then return end
    physic.tick()
    render.tick()
    stopwatch.tick()
end



--*Render process
function events.world_render(delta)
    if not player:isLoaded() then return end
    render.render(delta)
end



--. Еврейская мудрость
-- local outfitEnabled = false

-- function pings.setOutfit(state) -- this state is provided by the host
-- --                  input                 ^
-- --                  vvvvv                 |
--     outfitEnabled = state --              |
-- --  ^^^^^^^^^^^^^                         |
-- --     output                             |
-- end--                                     |
-- --                                        |
-- action:setOnLeftClick(function()--        |
--     pings.setOutfit(not outfitEnabled)----+
-- end)