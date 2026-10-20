extends RefCounted
const SAMPLES := 64
const DRAW_SEED := 1234
var draws := PackedFloat32Array()
var p := 0.1
var prediction := 0
var kept: Dictionary = {}

func _init() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = DRAW_SEED
    for i in SAMPLES: draws.append(rng.randf())

func set_probability(value: float) -> bool:
    if not is_finite(value): return false
    p = clampf(value, 0.0, 1.0)
    return true

func bits() -> PackedInt32Array:
    var result := PackedInt32Array()
    for draw in draws:
        result.append(int(p >= 1.0 or draw < p))
    return result

func entropy() -> float:
    if p <= 0.0 or p >= 1.0: return 0.0
    var q := 1.0 - p
    return -(p * log(p) + q * log(q)) / log(2.0)

func reading() -> Dictionary:
    var mistakes := 0
    for bit in bits():
        if bit != prediction: mistakes += 1
    return {"p": p, "prediction": prediction, "source_h": entropy(),
        "expected_error": p if prediction == 0 else 1.0-p,
        "mistakes": mistakes, "count": draws.size()}

func keep() -> void:
    kept = reading()
    kept["bits"] = bits()
