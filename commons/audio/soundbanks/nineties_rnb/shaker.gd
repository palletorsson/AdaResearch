# 90s R&B Shaker - 16th Note Groove

class_name NinetiesRnBShaker
extends RefCounted

const LEVEL = 0.25


static func generate(t: float, trigger_time: float = 0.0) -> float:
    var dt = t - trigger_time
    if dt < 0.0 or dt > 0.04:
        return 0.0
    
    var noise = fmod(sin(t * 11111.1111) * 43758.5453, 1.0) * 2.0 - 1.0
    var amp = pow(max(0.0, 1.0 - dt / 0.04), 1.5)
    
    return clampf(noise * amp * LEVEL, -1.0, 1.0)
