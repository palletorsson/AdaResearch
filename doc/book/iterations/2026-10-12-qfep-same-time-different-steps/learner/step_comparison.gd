extends RefCounted
const Field = preload("timed_field.gd")
var coarse := Field.new()
var fine := Field.new()
var weight := 0.4
var dt := 0.3
var seed_value := Field.START_SEED
var kept: Dictionary = {}

func set_weight(value: float) -> bool:
    if not is_finite(value): return false
    weight = clampf(value,0.0,1.0)
    return true

func restart() -> void:
    coarse.reset(seed_value)
    fine.reset(seed_value)

func new_seed() -> void:
    seed_value += 1
    restart()

func toggle_step() -> void:
    dt = 0.15 if dt > 0.2 else 0.3
    restart()

func advance() -> bool:
    # A batch is six model-time units, for either timestep pair.
    if not coarse.fault.is_empty() or not fine.fault.is_empty(): return false
    for i in roundi(6.0/dt):
        if not coarse.step(dt,weight): return false
        for half in 2:
            if not fine.step(dt*0.5,weight): return false
    return true

func difference() -> float:
    var squared := 0.0
    for i in Field.N*Field.N:
        squared += pow(coarse.b[i]-fine.b[i],2)
    return sqrt(squared/(Field.N*Field.N))

func reading() -> Dictionary:
    return {"weight":weight,"seed":seed_value,"dt":dt,
        "coarse_ticks":coarse.ticks,"fine_ticks":fine.ticks,
        "coarse_time":coarse.ticks*dt,"fine_time":fine.ticks*dt*0.5,
        "rms":difference(),"fault":coarse.fault+fine.fault}

func keep() -> void:
    kept = reading()
    kept["coarse_b"] = coarse.b.duplicate()
    kept["fine_b"] = fine.b.duplicate()
