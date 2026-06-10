config:setName("BolidF1")
local State = {}


State.Settings = {
    notFirstLaunch = config:load("notFirstLaunch") or false,
    AWPage = config:load("AWPage") or 1,
    --.Any seetings for action wheel
    camHeight = config:load("camHeight") or -0.3,   --?Camera height in car
    renderDist = 9216,  --?Distance of render boxes in blocks^2

    engineVolume = config:load("engineVolume") or 1,
    isMuted = config:load("isMuted") or false,

    --.Debugging
    debugEvent = false,
    debugTick = false,
    debugTickTo = "ab", --?"ab" to actionbar, "ch" to chat
}


--*Objects
State.Objects = {
    AW = {},

    Driver = models.car.F1.Driver,                                                   --?Driver model
    DriverFP = models.car.F1.WorldRoot.DriverFP,                                     --?Driver model for firs person render
    F1 = models.car.F1.WorldRoot,                                                    --?Car model
    Tens = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUITens,      --?Speedometer tens display part
    Units = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUIUnits,    --?Speedometer units display part
    Gear = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUIGear,      --?Speedometer gear display part
    RPM = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUIRPM,        --?Speedometer RPM display part
    Fuel = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUIFuel,      --?Speedometer Fuel display part
    Sec1 = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUISec1,
    Sec2 = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUISec2,
    Sec3 = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUISec3,

    --?Input keys
    ACKEY = keybinds:fromVanilla("key.forward"),
    BKKEY = keybinds:fromVanilla("key.back"),
    LFKEY = keybinds:fromVanilla("key.left"),
    RTKEY = keybinds:fromVanilla("key.right"),

    ALTKEY = keybinds:newKeybind("AltM", "key.keyboard.left.alt"),
    CTRLKEY = keybinds:newKeybind("CtrlM", "key.keyboard.left.control"),
    SHIFTKEY = keybinds:newKeybind("ShiftM", "key.keyboard.left.shift"),

    ACTIONKEY = keybinds:newKeybind("Kchau", "key.keyboard.k"),

    --?Textures
    ICO_PAGES = textures["ui.icons.iconPages"] or textures["car.F1.iconPages"],
    ICO_SELECT = textures["ui.icons.iconSelect"] or textures["car.F1.iconSelect"],
    ICO_BOX_RENDER = textures["ui.icons.iconBoxRender"] or textures["car.F1.iconBoxRender"],
    ICO_AUTO_CLOCK = textures["ui.icons.iconAutoClock"] or textures["car.F1.iconAutoClock"],
    ICO_STOPWATCH = textures["ui.icons.iconStopwatch"] or textures["car.F1.iconStopwatch"],
    ICO_PRESETS = textures["ui.icons.iconPresets"] or textures["car.F1.iconPresets"],
    ICO_HELP = textures["ui.icons.iconHelp"] or textures["car.F1.iconHelp"],
    ICO_CAMERA = textures["ui.icons.iconCamera"] or textures["car.F1.iconCamera"],
    ICO_SOUND = textures["ui.icons.iconSound"] or textures["car.F1.iconSound"],
    ICO_DEBUG_EVENT = textures["ui.icons.iconDebugEvent"] or textures["car.F1.iconDebugEvent"],
    ICO_DEBUG_TICK = textures["ui.icons.iconDebugTick"] or textures["car.F1.iconDebugTick"], 
    ICO_POTOM = textures["ui.icons.iconPotom"] or textures["car.F1.iconPotom"],
}


--*Const
State.Config = {
    v = "v1.2",
    helloMsg = [[§nМикро гайд по UI§r:
§60. Персонаж§r
  • Что бы видеть руки и тело в машине от 1 лица, нужно в §eFigura§r в разделе §n'Paperdoll'§r включить настройки §n'Enable paperdoll'§r и §n'Always on'§r
§61. Руль§r
  • §eСпидометр§r - Циферки: Показывает текущую скорость
  • §eИндикаторы§r - 6 точек по краям руля: Показывает текущий сигнал светофора на секторе трассы §7(Всего 3 сектора, индикаторы объединены попарно)§r
  • §eТопливо§r - Оранжевая полоска: Показывает §oпримерное§r кол-во топлива (6 ст). Восполняется на бетоне пит-стопа §7(Фигура не имеет доступ к инвентарю лодки)§r
  • §eПередача§r - Вертикальный столбик: Показывает текущую передачу 1-8 §7(Просто декор)§r
  • §eОбороты§r - Последняя полоска: Показывает текущие обороты 4-13k §7(Просто декор)§r

§62. Колесо действий§r
  • §eСекундомер§r: Настройки секундомера. Паузы нет, при остановке время сбрасывается.
  • §eУтилиты§r: Настройки высоты камеры в лодке и звука §lтвоей§r машины §7(Звуки других игроков возможно уменьшить только в настройках игры)§r
  • §eДебаг§r: дебаг §7(дебаг)§r

§7Если это сообщение не перестаёт показываться после первого использования модели и ты не менял сборку, то напиши в дс §6§o@cobehok.jar§r§r и в §f6-й строке§r файла §fstate.lua:§r
    §3notFirstLaunch §f= §9config:§dload(§b"notFirstLaunch"§d) §for §4false
§fзамени §4false§f на §atrue§f и заново загрузи аватар в облако]],

    --?Numbers UV coordinates for speedometer
    SPEED_UV = {
        vec(125/128,40/128),
        vec(125/128,45/128),
        vec(125/128,50/128),
        vec(125/128,55/128),
        vec(125/128,60/128),
        vec(125/128,65/128),
        vec(125/128,70/128),
        vec(125/128,75/128),
        vec(125/128,80/128),
        vec(125/128,85/128)
    },

    --?RPM scale UV coordinates for speedometer
    RPM_UV = {
        vec(113/128,40/128),
        vec(113/128,41/128),
        vec(113/128,42/128),
        vec(113/128,43/128),
        vec(113/128,44/128),
        vec(113/128,45/128),
        vec(113/128,46/128),
        vec(113/128,47/128),
        vec(113/128,48/128),
        vec(113/128,49/128),
        vec(113/128,50/128)
    },

    --?Gears indicator UV coordinates for speedometer
    GEAR_UV = {
        vec(113/128,51/128),
        vec(113/128,52/128),
        vec(113/128,53/128),
        vec(113/128,54/128),
        vec(113/128,55/128),
        vec(113/128,56/128),
        vec(113/128,57/128),
        vec(113/128,58/128)
    },

    --?Pit stop blocks
    REFUEL_BLOCKS = {
        ["minecraft:black_concrete"] = true,
        ["minecraft:yellow_concrete"] = true,
    },
    maxFuel = 384,  --?Max fuel

    --.RPM const
    IDLE_RPM = 4000,                    --?RPM when idle
    MAX_RPM = 13000,                    --?RPM up limit
    WATER_MAX_RPM = 7000,
    RPM_ACCEL_BASE_RATE = 300,          --?RPM acceleration speed
    RPM_DECEL_RATE = 0.3,               --?RPM deceleration speed
    RPM_TO_WHEEL_SPEED_FACTOR = 0.0005, --?RPM to wheels rotation speed multipler
    COASTING_WHEEL_FACTOR = 0.1,        --?Multipler wheels rotation, when gas unpressed
    REVERSE_SLOWDOWN_FACTOR = 0.2,      --?Wheels animation speed multiplier when reversing
    
    --.Gear changing RPM
    SHIFT_UP_RPM = 11500,               --?Gear shift up RPM
    SHIFT_UP_TARGET_RPM = 7000,         --?RPM after gear shift up
    SHIFT_DOWN_BLIP_RPM = 9000,         --?Gas afted gear shift down
    gearShiftDownSpeed = {              --?Speed for gear shit down
        [1] = 0,
        [2] = 10,
        [3] = 20,
        [4] = 30,
        [5] = 40,
        [6] = 50,
        [7] = 60,
        [8] = 70
    },
    gearRatio = {
        [1] = 4.5,
        [2] = 3.2,
        [3] = 2.5,
        [4] = 2.0,
        [5] = 1.6,
        [6] = 1.3,
        [7] = 1.1,
        [8] = 0.9
    },

    --.Steering config
    STEERING_SMOOTHNESS = 0.1,          --?Smoothness for steering animation
    MAX_STEER_ANGLE = 18,               --?Max frames for one side

    --.Sounds
    CAM_MAX_HEIG = 0.5,
    CAM_MIN_HEIG = -0.9,

    --...
    --wait what!?
}


--*Runtime
State.Data = {
    IS_HOST = host:isHost(),

    --.Car states
    fuel = 384,             --?Current fuel
    lastUnderStatus = nil,

    engineRPM = 0,          --?Current RPM
    prevEngineRPM = 0,      --?RPM in last tick
    currentGear = 1,        --?Current gear
    
    speedMps = 0,           --?Current speed
    absSpeedMps = 0,
    prevSpeedMps = 0,       --?Speed in last tick
    acceleration = 0,       --?Current acceleration
    
    steerAngle = 0,         --?Current steer angle

    --.Driver states
    inVehicle = false,      --?Is player sit in wehicle
    wasInVehicle = false,   --?Is player sitting in wehicle on last tick
    isDriving = false,      --?Is now pressed gas or back

    inWater = false,
    wasInWater = false,

    --.Stopwatch states
    autoClock = false,
    isClocking = false,
    currentTime = 0,
    currentLap = 0,
    lastTime = 0,
    

    checkBox = {vec(0,0,0), vec(0,0,0)},
    isCheckBoxCreated = false,
    inCheckBox = false,
    wasInCheckBox = false,

    renderBox = false,

    lastPreset = 1,

    lastEngineVolume = State.Settings.engineVolume,
    lastCamHeight = State.Settings.camHeight,
}

State.Input = {
    --.Current keys pressed
    accelState = false, --?Froward  (W)
    backState = false,  --?Backward (S)
    leftState = false,  --?Left     (A)
    rightState = false  --?Right    (D)
}


--*Nil protect
function State.init()
    --?Initial animations after entity init
    for k, v in pairs(animations["car.F1"]) do
        State.Objects[k:upper()] = v
    end
end

return State