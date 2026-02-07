# 90s R&B Clap
# Character: Tight clap layered with snare

class_name NinetiesRnBClap
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.5


static func generate(t: float, trigger_time: float = 0.0) -> float:
    var dt = t - trigger_time
    if dt < 0.0 or dt > 0.2:
        return 0.0
    
    # Multiple burst envelope for clap character
    var burst = 0.0
    for b in range(4):
        var bt = dt - b * 0.01
        if bt > 0 and bt < 0.015:
            burst += pow(1.0 - bt / 0.015, 2.0)
    
    var noise = fmod(sin(t * 54321.0) * 43758.5453, 1.0) * 2.0 - 1.0
    var body_env = pow(max(0.0, 1.0 - dt / 0.2), 1.5)
    
    return clampf(noise * (burst * 0.4 + body_env * 0.6) * LEVEL, -1.0, 1.0)
