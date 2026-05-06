# 90s R&B Fingersnap

class_name NinetiesRnBFingersnap
extends RefCounted

const LEVEL = 0.35


static func generate(t: float, trigger_time: float = 0.0) -> float:
    var dt = t - trigger_time
    if dt < 0.0 or dt > 0.08:
        return 0.0
    
    # High frequency click + noise tail
    var click = sin(2.0 * PI * 2500.0 * dt) * pow(max(0.0, 1.0 - dt / 0.005), 2.0) * 0.5
    var noise = fmod(sin(t * 77777.7777) * 43758.5453, 1.0) * 2.0 - 1.0
    var noise_env = pow(max(0.0, 1.0 - dt / 0.08), 2.0)
    
    return clampf((click + noise * noise_env * 0.4) * LEVEL, -1.0, 1.0)
