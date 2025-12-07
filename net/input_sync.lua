local state = require("state")

--*Sync pressed keys with other players
function pings.inputSync(f, b, l, r)
    state.Input.accelState = f
    state.Input.backState = b
    state.Input.leftState = l
    state.Input.rightState = r
end
