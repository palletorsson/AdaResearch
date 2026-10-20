extends RefCounted
## Shared locomotion tuning. Input adapters do not define different game rules.
const SPEED := 3.0
const JUMP := 4.6
const TRACTION := 30.0
const DRAG := 5.0
const STOP_SPEED := 0.15
const POINTER_DISTANCE := 10.0
const GRAB_DISTANCE := 5.0
const POINTER_MASK := (1 << 18) | (1 << 20) | (1 << 22) # handles, pointables, UI
