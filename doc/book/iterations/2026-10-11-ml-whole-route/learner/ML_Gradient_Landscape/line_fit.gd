extends RefCounted
## Parameter space: p.x is slope, p.y is intercept, not a physical location.
const START := Vector2(-1.0, 1.0)
const BOUND := 3.0
var data := PackedVector2Array([
    Vector2(-1, -0.3), Vector2(-0.5, -0.05), Vector2(0, 0.2),
    Vector2(0.5, 0.45), Vector2(1, 0.7)])
var p := START
var robust := false
var rate := 0.1
var steps := 0
var status := "PAUSED"

func prediction(q: Vector2, x: float) -> float:
    return q.x * x + q.y

func loss(q: Vector2) -> float:
    var total := 0.0
    for sample in data:
        var e := absf(prediction(q, sample.x) - sample.y)
        total += (0.5*e*e if e <= 1.0 else e-0.5) if robust else e*e
    return total / data.size()

func gradient(q: Vector2, h: float = 0.001) -> Vector2:
    var x := Vector2(h, 0); var y := Vector2(0, h)
    return Vector2(loss(q+x)-loss(q-x), loss(q+y)-loss(q-y)) / (2.0*h)

func reset() -> void:
    p = START; steps = 0; status = "PAUSED"

func set_outlier(enabled: bool) -> void:
    data[4] = Vector2(1, 4.7 if enabled else 0.7)
    reset()

func step() -> bool:
    var g := gradient(p)
    if g.length() < 0.0001:
        status = "SMALL GRADIENT"; return false
    var proposed := p - rate*g
    if not proposed.is_finite() or absf(proposed.x) > BOUND or absf(proposed.y) > BOUND:
        status = "STEP OUTSIDE WINDOW"; return false
    p = proposed; steps += 1; status = "STEPPED"
    return true
