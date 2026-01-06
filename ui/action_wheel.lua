local state = require("state")
local stopwatch = require("lib.stopwatch")

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
            :setTexture(textures["ui.icons.iconPages"], 0, 0, 16, 16)
            :setHoverTexture(textures["ui.icons.iconPages"], 16, 0, 16, 16)
            :onLeftClick(function()
                action_wheel:setPage(wheels[prevIndex])
            end)
            :onRightClick(function()
                action_wheel:setPage(wheels[nextIndex])
            end)
            :setOnScroll(function(dir)
                if dir > 0 then
                    action_wheel:setPage(wheels[nextIndex])
                else
                    action_wheel:setPage(wheels[prevIndex])
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

        :setTexture(textures["ui.icons.iconSelect"], 0, 0, 16, 16)
        :setHoverTexture(textures["ui.icons.iconSelect"], 16, 0, 16, 16)
        :onLeftClick(function() stopwatch.setBox(1, player:getPos(), true) end)
        :onRightClick(function() stopwatch.setBox(2, player:getPos(), true) end)
        :onScroll(stopwatch.changeBox)
    obj.AW.setBox = setBox


    local tglRender = wheels[1]:newAction()
        :title("Постоянный рендер зоны секундомера\n§7ЛКМ")
        :setTexture(textures["ui.icons.iconBoxRender"], 0, 0, 16, 16)
        :setHoverTexture(textures["ui.icons.iconBoxRender"], 16, 0, 16, 16)
        :setToggleTexture(textures["ui.icons.iconBoxRender"], 32, 0, 16, 16)
        :onToggle(function() ActionWheel.toggleRender(not data.renderBox) end)
    obj.AW.tglRender = tglRender
 
    
    local tglAutoClock = wheels[1]:newAction()
        :title("Запуск секундомера по газу\n§7ЛКМ")
        :setTexture(textures["ui.icons.iconAutoClock"], 0, 0, 16, 16)
        :setHoverTexture(textures["ui.icons.iconAutoClock"], 16, 0, 16, 16)
        :setToggleTexture(textures["ui.icons.iconAutoClock"], 32, 0, 16, 16)
        :onToggle(function() ActionWheel.toggleAutoClock(not data.autoClock) end)
    obj.AW.tglAutoClock = tglAutoClock   


    local tglStopwatch = wheels[1]:newAction()
        :title("Запустить / остановить секундомер\n§7ЛКМ")
        :setTexture(textures["ui.icons.iconStopwatch"], 0, 0, 16, 16)
        :setHoverTexture(textures["ui.icons.iconStopwatch"], 16, 0, 16, 16)
        :setToggleTexture(textures["ui.icons.iconStopwatch"], 32, 0, 16, 16)
        :onToggle(function () ActionWheel.toggleStopwatch(not data.isClocking) end)
    obj.AW.tglStopwatch = tglStopwatch


    local selectPreset = wheels[1]:newAction()
        :title("Выбрать пресет зоны секундомера\n§6Скролл")
        :setTexture(textures["ui.icons.iconPresets"], 0, 0, 16, 16)
        :setHoverTexture(textures["ui.icons.iconPresets"], 16, 0, 16, 16)
        :onScroll(stopwatch.selectPreset)
    obj.AW.selectPreset = selectPreset



    --.Utilities wheel
    local camHeight = wheels[2]:newAction()
        :title("Высота камеры: §e"..stgs.camHeight.."\n§6Скролл")
        :setTexture(textures["ui.icons.iconCamera"], 0, 0, 16, 16)
        :setHoverTexture(textures["ui.icons.iconCamera"], 16, 0, 16, 16)
        :setOnScroll(ActionWheel.setCamHeight)
    obj.AW.camHeight = camHeight

    --.Debug wheel
    local tglDebug = wheels[3]:newAction()
        :title("ПОТОМ\nСкоро\nКогда-нибудь\nЗавтра в 3")
        :setTexture(textures["ui.icons.iconPotom"], 0, 0, nil, nil, 0.5)
    obj.AW.camHeight = camHeight
end



function ActionWheel.setCamHeight(dir)
    if dir > 0 then
        stgs.camHeight = math.min(stgs.camHeight + 0.05, cfg.CAM_MAX_HEIG)
    else
        stgs.camHeight = math.max(stgs.camHeight - 0.05, cfg.CAM_MIN_HEIG)
    end

    ActionWheel.titleUpdate(obj.AW.camHeight, "Высота камеры: §e"..stgs.camHeight.."\n§6Скролл")
end


function ActionWheel.toggleRender(tgl)
    data.renderBox = tgl
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
end

return ActionWheel