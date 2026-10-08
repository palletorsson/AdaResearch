extends "point_body.gd"
const START_RINGS := 16
const START_SEGMENTS := 32
const STEP_SECONDS := 0.15
var elapsed := 0.0

func _init() -> void:
    super()
    reset_resolution()

func advance(delta: float) -> void:
    if not is_resolution_held():
        return
    elapsed += delta
    while elapsed + 0.000001 >= STEP_SECONDS:
        elapsed = maxf(0.0, elapsed - STEP_SECONDS)
        sphere.rings = maxi(1, sphere.rings - 1)
        sphere.radial_segments = maxi(4, sphere.radial_segments - 1)

func reset_resolution() -> void:
    elapsed = 0.0
    sphere.rings = START_RINGS
    sphere.radial_segments = START_SEGMENTS

func is_resolution_held() -> bool:
    return is_picked_up()
