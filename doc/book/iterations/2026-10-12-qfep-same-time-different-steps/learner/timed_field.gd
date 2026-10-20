extends RefCounted
const N := 32
const START_SEED := 0x5EED17
var a := PackedFloat32Array()
var b := PackedFloat32Array()
var ticks := 0
var fault := ""

func _init() -> void:
    reset(START_SEED)

func index(x: int, y: int) -> int:
    return posmod(y,N)*N+posmod(x,N)

func reset(seed_value: int) -> void:
    a.resize(N*N)
    b.resize(N*N)
    a.fill(1.0)
    b.fill(0.0)
    ticks = 0
    fault = ""
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    for spot in 12:
        var x := N/2+rng.randi_range(-N/8,N/8)
        var y := N/2+rng.randi_range(-N/8,N/8)
        for dx in range(-2,3):
            for dy in range(-2,3):
                var i := index(clampi(x+dx,0,N-1),clampi(y+dy,0,N-1))
                a[i] = 0.5
                b[i] = 1.0

func laplacian(values: PackedFloat32Array, x: int, y: int) -> float:
    return (values[index(x-1,y)]+values[index(x+1,y)]
        +values[index(x,y-1)]+values[index(x,y+1)])*0.25-values[index(x,y)]

func step(dt: float, weight: float) -> bool:
    if not fault.is_empty(): return false
    if not is_finite(dt) or dt <= 0.0 or dt > 0.3 or not is_finite(weight) or weight < 0.0 or weight > 1.0:
        fault = "Invalid timestep or parameter"
        return false
    var feed := lerpf(0.01,0.08,weight)
    var kill := lerpf(0.08,0.03,weight)
    var da := lerpf(0.8,1.2,weight)
    var db := lerpf(0.3,0.7,weight)
    var next_a := PackedFloat32Array()
    var next_b := PackedFloat32Array()
    next_a.resize(N*N)
    next_b.resize(N*N)
    for y in N:
        for x in N:
            var i := index(x,y)
            var reaction := a[i]*b[i]*b[i]
            next_a[i] = a[i]+(da*laplacian(a,x,y)-reaction+feed*(1.0-a[i]))*dt
            next_b[i] = b[i]+(db*laplacian(b,x,y)+reaction-(kill+feed)*b[i])*dt
            if not is_finite(next_a[i]) or not is_finite(next_b[i]) or next_a[i] < 0.0 or next_b[i] < 0.0:
                fault = "Invalid concentration; restart the comparison"
                return false
    a = next_a
    b = next_b
    ticks += 1
    return true
