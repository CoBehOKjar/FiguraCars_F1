local state = require("state")
local stopwatch = require("lib.stopwatch")
local util = require("lib.utilities")

local ActionWheel = {}

local cfg = state.Config
local obj = state.Objects
local stgs = state.Settings
local data = state.Data

function ActionWheel.titleUpdate(action, title)
    action:setTitle(title)
end

function ActionWheel.init()
    --.Creating action wheels
    local wheels = {
        action_wheel:newPage("Секундомер"),
        action_wheel:newPage("Утилиты"),
        action_wheel:newPage("Дебаг"),
    }

    action_wheel:setPage(wheels[1]) --?Default active wheel


    --.Adding navigation buttons to wheels
    for i, wheel in ipairs(wheels) do       --?Calculating next and prevous wheel
        local prevIndex = (i - 2) % #wheels + 1     --?Pervous
        local nextIndex = i % #wheels + 1           --?Next

        local nav = wheel:newAction()   --?Creating navigation button
            :title("§6< §fПред / След §6>\n§7ПКМ/ЛКМ | Скролл\n§6"..wheel:getTitle())
            :setTexture(obj.ICO_PAGES, 0, 0, 16, 16)
            :setHoverTexture(obj.ICO_PAGES, 16, 0, 16, 16)
            :onLeftClick(function()
                action_wheel:setPage(wheels[prevIndex])
                util.dbgEvent("AW", "Perv page")
            end)
            :onRightClick(function()
                action_wheel:setPage(wheels[nextIndex])
                util.dbgEvent("AW", "Next page")
            end)
            :setOnScroll(function(dir)
                if dir > 0 then
                    action_wheel:setPage(wheels[nextIndex])
                    util.dbgEvent("AW", "Next page")
                else
                    action_wheel:setPage(wheels[prevIndex])
                    util.dbgEvent("AW", "Perv page")
                end
            end)
        obj.AW["Nav"..i] = nav
    end


    --.Adding buttons
    --.Stopwatch wheel
    local setBox = wheels[1]:newAction()
        :title(
            "Выбрать зону секундомера\n" ..
            "§7ПКМ/ЛКМ§f - Выбор углов\n" ..
            "§6Скролл§f - Выбрать зону 3х3 вокруг себя\n" ..
            "§6Скролл§f - Изменить размер вдоль оси взгляда\n" ..
            "§aShift§f+§6скролл§f - Изменить размер в сторону взгляда\n" ..
            "§eCtrl§f+§6скролл§f - Изменить размер во все стороны\n" ..
            "§9Alt§f+§6скролл§d - Сбросить выделение\n" ..
            "§eCtrl§f+§aShift§f+§6скролл§c - Удалить выделение"
        )

        :setTexture(obj.ICO_SELECT, 0, 0, 16, 16)
        :setHoverTexture(obj.ICO_SELECT, 16, 0, 16, 16)
        :onLeftClick(function() stopwatch.setBox(1, player:getPos(), true) end)
        :onRightClick(function() stopwatch.setBox(2, player:getPos(), true) end)
        :onScroll(stopwatch.changeBox)
    obj.AW.setBox = setBox


    local tglRender = wheels[1]:newAction()
        :title("Постоянный рендер зоны секундомера\n§7ЛКМ")
        :setTexture(obj.ICO_BOX_RENDER, 0, 0, 16, 16)
        :setHoverTexture(obj.ICO_BOX_RENDER, 16, 0, 16, 16)
        :setToggleTexture(obj.ICO_BOX_RENDER, 32, 0, 16, 16)
        :onToggle(function()
            data.renderBox = not data.renderBox
            util.dbgEvent("AW", "Toggled box render")
        end)
    obj.AW.tglRender = tglRender
 
    
    local tglAutoClock = wheels[1]:newAction()
        :title("Запуск секундомера по газу\n§7ЛКМ")
        :setTexture(obj.ICO_AUTO_CLOCK, 0, 0, 16, 16)
        :setHoverTexture(obj.ICO_AUTO_CLOCK, 16, 0, 16, 16)
        :setToggleTexture(obj.ICO_AUTO_CLOCK, 32, 0, 16, 16)
        :onToggle(function()ActionWheel.toggleAutoClock(not data.autoClock) end)
    obj.AW.tglAutoClock = tglAutoClock   


    local tglStopwatch = wheels[1]:newAction()
        :title("Запустить / остановить секундомер\n§7ЛКМ")
        :setTexture(obj.ICO_STOPWATCH, 0, 0, 16, 16)
        :setHoverTexture(obj.ICO_STOPWATCH, 16, 0, 16, 16)
        :setToggleTexture(obj.ICO_STOPWATCH, 32, 0, 16, 16)
        :onToggle(function () ActionWheel.toggleStopwatch(not data.isClocking) end)
    obj.AW.tglStopwatch = tglStopwatch


    local selectPreset = wheels[1]:newAction()
        :title("Выбрать пресет зоны секундомера\n§6Скролл")
        :setTexture(obj.ICO_PRESETS, 0, 0, 16, 16)
        :setHoverTexture(obj.ICO_PRESETS, 16, 0, 16, 16)
        :onScroll(stopwatch.selectPreset)
    obj.AW.selectPreset = selectPreset



    --.Utilities wheel
    local camHeight = wheels[2]:newAction()
        :title("Высота камеры: §e"..stgs.camHeight.."\n§6Скролл")
        :setTexture(obj.ICO_CAMERA, 0, 0, 16, 16)
        :setHoverTexture(obj.ICO_CAMERA, 16, 0, 16, 16)
        :onScroll(ActionWheel.setCamHeight)
    obj.AW.camHeight = camHeight


    
    --.Debug wheel
    local tglDebugEvent = wheels[3]:newAction()
        :title("Debug event\n§7LMB")
        :setTexture(obj.ICO_DEBUG_EVENT, 0, 0, 16, 16)
        :setHoverTexture(obj.ICO_DEBUG_EVENT, 16, 0, 16, 16)
        :setToggleTexture(obj.ICO_DEBUG_EVENT, 32, 0, 16, 16)
        :onToggle(function () ActionWheel.toggleDebugEvent(not stgs.debugEvent) end)
    obj.AW.tglDebugEvent = tglDebugEvent


    local tglDebugTick = wheels[3]:newAction()
        :title("Debug tick\n§7LMB §f- Toggle\n§6Scroll §f- Change output between chat & actionbar")
        :setTexture(obj.ICO_DEBUG_TICK, 0, 0, 16, 16)
        :setHoverTexture(obj.ICO_DEBUG_TICK, 16, 0, 16, 16)
        :setToggleTexture(obj.ICO_DEBUG_TICK, 32, 0, 16, 16)
        :onToggle(function () ActionWheel.toggleDebugTick(not stgs.debugTick) end)
        :onScroll(ActionWheel.changeDebugTickOutput)
    obj.AW.tglDebugTick = tglDebugTick
end



function ActionWheel.setCamHeight(dir)
    if dir > 0 then
        stgs.camHeight = math.min(stgs.camHeight + 0.05, cfg.CAM_MAX_HEIG)
    else
        stgs.camHeight = math.max(stgs.camHeight - 0.05, cfg.CAM_MIN_HEIG)
    end

    ActionWheel.titleUpdate(obj.AW.camHeight, "Высота камеры: §e"..stgs.camHeight.."\n§6Скролл")
    util.dbgEvent("AW", "Changed camera height to §9"..tostring(stgs.camHeight))
end


function ActionWheel.toggleStopwatch(tgl)
    if tgl then
        data.isClocking = true
        print("Секундомер §2запущен")
    else
        data.isClocking = false
        data.currentTime = 0
        data.currentLap = 0
        data.lastTime = 0
        print("Секундомер §cостановлен")
    end
    util.dbgEvent("AW", "Toggled stopwatch to §9"..tostring(data.isClocking))
end


function ActionWheel.toggleAutoClock(tgl)
    if tgl then
        data.isClocking = false
        obj.AW.tglStopwatch:setToggled(false)

        data.autoClock = true 
        print("§2Включен §fзапуск секундомера по газу")
    else
        data.autoClock = false
        print("§cВыключен §fзапуск секундомера по газу")
    end
    util.dbgEvent("AW", "Toggled autoclock to §9"..tostring(data.autoClock))
end


function ActionWheel.toggleDebugEvent(tgl)
    if tgl then
        stgs.debugEvent = true
    else
        stgs.debugEvent = false
    end
    util.dbgEvent("AW", "Toggled debug event to §9"..tostring(stgs.debugEvent))
end


function ActionWheel.toggleDebugTick(tgl)
    if tgl then
        stgs.debugTick = true
    else
        stgs.debugTick = false
    end
    util.dbgEvent("AW", "Toggled debug tick to §9"..tostring(stgs.debugTick))
end


function ActionWheel.changeDebugTickOutput(dir)
    if dir > 0 then
        stgs.debugTickTo = "ab"
        print("Debug tick sending to §dactionbar")
    else
        stgs.debugTickTo = "ch"
        print("Debug tick sending to §dchat")
    end
    util.dbgEvent("AW", "Debug tick outout changed to §9"..tostring(stgs.debugTickTo))
end

return ActionWheel