extends RefCounted
var earlier: float = 0.2
var later: float = 0.7
var interval: float = 2.0
var phi: float = 0.0
var kept: Dictionary = {}

func set_pair(first: float, second: float) -> bool:
    if not is_finite(first) or not is_finite(second): return false
    if first < 0.0 or first > 1.0 or second < 0.0 or second > 1.0: return false
    earlier = first
    later = second
    return true

func set_interval(seconds: float) -> bool:
    if not is_finite(seconds) or seconds <= 0.0: return false
    interval = seconds
    return true

func set_phi(value: float) -> bool:
    if not is_finite(value): return false
    phi = clampf(value, -1.0, 1.0)
    return true

func reverse_pair() -> void:
    set_pair(later, earlier)

func reading() -> Dictionary:
    var difference := later - earlier
    return {"earlier": earlier, "later": later, "interval": interval,
        "phi": phi, "difference": difference,
        "rate": difference / interval, "contribution": phi * difference}

func keep() -> void:
    kept = reading()
