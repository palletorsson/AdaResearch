extends RefCounted
## Dimensionless inputs for this console, ordered F, E, lambda, phi.
const CHANGE := 0.3
var values: Array[float] = [0.4, 0.2, 0.5, 0.5]
var kept: Array[float] = []

func total(parts: Array[float]) -> float:
    return parts[0] - parts[2] * parts[1] + parts[3] * CHANGE

func set_term(index: int, value: float) -> bool:
    if index < 0 or index >= values.size() or not is_finite(value):
        return false
    values[index] = clampf(value, 0.0, 1.0)
    return true

func keep() -> void:
    kept = values.duplicate()
