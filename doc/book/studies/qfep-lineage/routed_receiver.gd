extends RefCounted
var values: Array[float] = [0.4,0.0]
var elapsed := 0.0
var distance := 0.0

func set_value(term: int, value: float) -> bool:
    if term < 0 or term > 1 or not is_finite(value): return false
    values[term] = clampf(value,0.0 if term == 0 else -1.0,1.0)
    return true

func speed() -> float:
    return 0.1+0.4*values[0]

func colour() -> Color:
    var blue := Color(0.2,0.4,1.0)
    var green := Color(0.2,1.0,0.5)
    var red := Color(1.0,0.3,0.2)
    var l := values[0]
    var base := blue.lerp(green,l/0.3) if l < 0.3 else green
    if l >= 0.5: base = green.lerp(red,(l-0.5)/0.5)
    var p := values[1]
    return base.lightened(p*0.3) if p > 0 else base.darkened(-p*0.3)

func advance(delta: float) -> bool:
    if not is_finite(delta) or delta < 0: return false
    elapsed += delta
    distance = fposmod(distance+speed()*delta,1.0)
    return true

func repeat() -> void:
    elapsed = 0.0
    distance = 0.0
