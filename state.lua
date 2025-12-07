local State = {}


--*Objects
State.Objects = {
    Driver = models.car.F1.Driver,                                                   --?Driver model
    DriverFP = models.car.F1.WorldRoot.DriverFP,                                     --?Driver model for firs person render
    F1 = models.car.F1.WorldRoot,                                                    --?Car model
    Tens = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUITens,      --?Speedometer tens display part
    Units = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUIUnits,    --?Speedometer units display part
    Gear = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUIGear,      --?Speedometer gear display part
    RPM = models.car.F1.WorldRoot.Car.Frame.SteeringWheel.SteeringWheelUIRPM,        --?Speedometer RPM display part

    --?Input keys
    ACKEY = keybinds:fromVanilla("key.forward"),
    BKKEY = keybinds:fromVanilla("key.back"),
    LFKEY = keybinds:fromVanilla("key.left"),
    RTKEY = keybinds:fromVanilla("key.right"),

    ALTKEY = keybinds:newKeybind("ResetBox", "key.keyboard.left.alt"),
    CTRLKEY = keybinds:newKeybind("ResetBox", "key.keyboard.left.control"),
    SHIFTKEY = keybinds:newKeybind("ResetBox", "key.keyboard.left.shift"),

    --?Animations path
    GAS = animations["car.F1"].Gas,
    REVERSE = animations["car.F1"].Reverse,
    STEERING = animations["car.F1"].Steering,

    AW = {}
}


--*Const
State.Config = {
    --?Numbers UV coordinates for speedometer
    SPEED_UV = {
        vec(123/128,40/128),
        vec(123/128,45/128),
        vec(123/128,50/128),
        vec(123/128,55/128),
        vec(123/128,60/128),
        vec(123/128,65/128),
        vec(123/128,70/128),
        vec(123/128,75/128),
        vec(123/128,80/128),
        vec(123/128,85/128)
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

    --.RPM const
    IDLE_RPM = 4000,                    --?RPM when idle
    MAX_RPM = 13000,                    --?RPM up limit
    RPM_ACCEL_BASE_RATE = 300,          --?RPM acceleration speed
    RPM_DECEL_RATE = 0.3,               --?RPM deceleration speed
    RPM_TO_WHEEL_SPEED_FACTOR = 0.0005, --?RPM to wheels rotation speed multipler
    COASTING_WHEEL_FACTOR = 0.1,        --?Multipler wheels rotation, when gas unpressed
    REVERSE_SLOWDOWN_FACTOR = 0.5,      --?Wheels animation speed multiplier when reversing
    
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
    gearRatio = {                       --?Gear ratios
        [1] = 4.5,
        [2] = 3.2,
        [3] = 2.4,
        [4] = 1.9,
        [5] = 1.5,
        [6] = 1.2,
        [7] = 1.0,
        [8] = 0.9
    },

    --.Steering config
    STEERING_SMOOTHNESS = 0.1,          --?Smoothness for steering animation
    MAX_STEER_ANGLE = 18,               --?Max frames for one side

    --.Sounds
    CAM_MAX_HEIG = 0.5,
    CAM_MIN_HEIG = -0.9,    
}


--*Runtime
State.Data = {
    --.Car states
    engineRPM = 0,          --?Current RPM
    prevEngineRPM = 0,      --?RPM in last tick
    currentGear = 1,        --?Current gear
    
    speedMps = 0,           --?Current speed
    prevSpeedMps = 0,       --?Speed in last tick
    acceleration = 0,       --?Current acceleration
    
    steerAngle = 0,         --?Current steer angle

    --.Driver states
    inVehicle = false,      --?Is player sit in wehicle
    wasInVehicle = false,   --?Is player sitting in wehicle on last tick
    isDriving = false,      --?Is now pressed gas or back

    --.Stopwatch states
    isClocking = false,
    currentTime = 0,
    currentLap = 0,
    lastTime = 0,
    

    checkBox = {vec(0,0,0), vec(0,0,0)},
    isCheckBoxCreated = false,
    inCheckBox = false,
    wasInCheckBox = false,

    renderBox = false
}

State.Input = {
    --.Current keys pressed
    accelState = false, --?Froward  (W)
    backState = false,  --?Backward (S)
    leftState = false,  --?Left     (A)
    rightState = false  --?Right    (D)
}

State.Settings = {
    --.Any seetings for action wheel
    camHeight = -0.3,   --?Camera height in car
}

return State