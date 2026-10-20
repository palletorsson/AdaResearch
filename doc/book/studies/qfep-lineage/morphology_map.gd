extends RefCounted
var values: Array[float] = [0.5, 0.0]
var elapsed := 0.0
var pulsing := true
var kept: Dictionary = {}

func set_value(term: int, value: float) -> void:
    if term == 0: values[0] = clampf(value,0.0,1.0)
    elif term == 1: values[1] = clampf(value,-1.0,1.0)

func active() -> bool:
    return pulsing and values[0] > 0.3 and values[0] < 0.7

func reading() -> Dictionary:
    var l := values[0]
    var u := (values[1]+1.0)*0.5
    var base := 1.0+0.5*(1.0-absf(l-0.5)*2.0)
    var pressure := base
    if active():
        pressure *= 1.0+sin(elapsed*lerpf(0.5,2.0,l))*lerpf(0.02,0.1,l)
    return {"values":values.duplicate(), "stiffness":lerpf(0.9,0.1,l),
        "damping":lerpf(0.2,0.001,u), "drag":lerpf(0.3,0.0,u),
        "baseline":base, "pressure":pressure, "elapsed":elapsed,
        "enabled":pulsing, "active":active()}

func apply_to(body: SoftBody3D) -> void:
    var r := reading()
    body.linear_stiffness = r.stiffness
    body.damping_coefficient = r.damping
    body.drag_coefficient = r.drag
    body.pressure_coefficient = r.pressure

func advance(delta: float) -> void:
    elapsed += maxf(delta,0.0)

func toggle() -> void:
    pulsing = not pulsing
    elapsed = 0.0

func keep() -> void:
    kept = reading()
