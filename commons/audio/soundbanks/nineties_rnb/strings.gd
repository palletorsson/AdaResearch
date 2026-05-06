# 90s R&B Strings - Lush Orchestral Swell
# Character: Warm string ensemble for chorus/bridge swells

class_name NinetiesRnBStrings
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.22
const DEFAULT_DURATION = 3.0


static func generate(t: float, chord_freqs: Array = [], trigger_time: float = 0.0) -> float:
    var dt = t - trigger_time
    if dt < 0.0 or dt > DEFAULT_DURATION:
        return 0.0
    
    if chord_freqs.is_empty():
        return 0.0
    
    var output = 0.0
    
    # Vibrato
    var vibrato = sin(2.0 * PI * 5.0 * t) * 0.003
    
    for freq in chord_freqs:
        # Detuned voices for ensemble
        for detune in [-6.0, -2.0, 2.0, 6.0]:
            var detune_ratio = pow(2.0, detune / 1200.0) * (1.0 + vibrato)
            var f = freq * detune_ratio
            
            var phase = fmod(f * t, 1.0)
            var saw = phase * 2.0 - 1.0
            
            output += saw
    
    output /= chord_freqs.size() * 4.0 * 1.5
    
    # Slow swell attack (strings should bloom)
    var attack = min(dt / 0.6, 1.0)
    var release_start = DEFAULT_DURATION - 0.5
    var release = 1.0 if dt < release_start else max(0.0, 1.0 - (dt - release_start) / 0.5)
    var env = attack * release
    
    return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, chord_freqs: Array) -> float:
    return generate(t, chord_freqs, 0.0)
