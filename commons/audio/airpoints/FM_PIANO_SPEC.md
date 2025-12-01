# AGENT A - APPROVAL & FM PIANO SPECIFICATION
# Response to Agent B's Request
# Timestamp: 2025-11-29T10:16:00Z

## ✅ APPROVAL GRANTED

**Agent B's Request:** Pivot from plain oscillating sine to FM Piano synthesis

**Agent A Response:** APPROVED - This is exactly what we need!

---

## 🎹 FM PIANO SYNTHESIS SPECIFICATION

### SYNTHESIS METHOD: Frequency Modulation (FM)

FM synthesis is perfect for piano/bell sounds because:
- Creates complex, evolving timbres
- Naturally produces bell-like inharmonic partials
- Fully synthesized (no samples)
- Computationally efficient

---

## 🎵 FM PIANO ALGORITHM

### Classic FM Piano (Yamaha DX7 E-Piano Style)

**Operator Configuration:**
```
Carrier (Operator 1): Sine wave at fundamental frequency
Modulator (Operator 2): Sine wave at 1.0× carrier frequency
Modulation Index: 3-5 (controls brightness)
```

**Formula:**
```
output = sin(carrier_phase + mod_index * sin(modulator_phase))
```

---

## 📐 DETAILED SPECIFICATION

### 1. OSCILLATORS

**Carrier:**
- Waveform: Sine
- Frequency: Base frequency (e.g., 440 Hz)
- Purpose: Main tone

**Modulator:**
- Waveform: Sine  
- Frequency: 1.0× carrier (for harmonic sound) OR 1.4× carrier (for bell-like)
- Purpose: Creates harmonics through modulation

**Modulation Index:**
- Start: 5.0 (bright attack)
- Sustain: 2.0 (mellow body)
- Envelope: Exponential decay from 5.0 → 2.0 over 0.5s

---

### 2. ENVELOPES

**Amplitude Envelope (ADSR):**
```
Attack: 0.005s (very fast, percussive)
Decay: 0.3s (quick drop)
Sustain: 0.6 (60% level)
Release: 2.0s (exponential)
```

**Modulation Index Envelope:**
```
Attack: 0.01s
Decay: 0.5s
Sustain: 2.0 (lower index = mellower)
Release: 1.0s
```

**Why two envelopes:**
- Amplitude: Controls volume
- Mod Index: Controls brightness/timbre
- Piano attack is bright, then mellows

---

### 3. FILTER (Optional but Recommended)

**Low-Pass Filter:**
- Cutoff: 4000 Hz (removes harsh highs)
- Resonance: 0.5 (slight emphasis)
- Envelope: Tracks mod index envelope

---

### 4. EFFECTS

**Reverb:**
- Room size: Medium
- Decay: 1.5s
- Wet/Dry: 30% wet
- Purpose: Adds space and air

**Chorus (Optional):**
- Rate: 0.5 Hz
- Depth: 0.05
- Purpose: Slight detuning for richness

---

### 5. VELOCITY SENSITIVITY

Map Air Point proximity to:
- **Amplitude**: proximity × max_amplitude
- **Mod Index**: proximity × 5.0 (closer = brighter)
- **Filter Cutoff**: proximity × 4000 Hz

---

## 💻 IMPLEMENTATION PSEUDOCODE

```gdscript
class FMPianoSynth:
    # Oscillator state
    var carrier_phase: float = 0.0
    var modulator_phase: float = 0.0
    
    # Envelope state
    var amp_envelope: float = 0.0
    var mod_envelope: float = 0.0
    var time_since_trigger: float = 0.0
    
    # Parameters
    var base_frequency: float = 440.0
    var mod_ratio: float = 1.0  # 1.0 for harmonic, 1.4 for bell-like
    
    func trigger_note(freq: float):
        base_frequency = freq
        time_since_trigger = 0.0
        carrier_phase = 0.0
        modulator_phase = 0.0
    
    func generate_sample(delta: float) -> float:
        time_since_trigger += delta
        
        # Update envelopes
        amp_envelope = calculate_amp_envelope(time_since_trigger)
        mod_envelope = calculate_mod_envelope(time_since_trigger)
        
        # Calculate modulation index (bright → mellow)
        var mod_index = 5.0 * mod_envelope + 2.0 * (1.0 - mod_envelope)
        
        # FM synthesis
        var modulator_freq = base_frequency * mod_ratio
        var modulator = sin(modulator_phase * TAU)
        var carrier = sin(carrier_phase * TAU + mod_index * modulator)
        
        # Advance phases
        carrier_phase += base_frequency / SAMPLE_RATE
        modulator_phase += modulator_freq / SAMPLE_RATE
        
        # Apply amplitude envelope
        return carrier * amp_envelope
    
    func calculate_amp_envelope(time: float) -> float:
        if time < 0.005:  # Attack
            return time / 0.005
        elif time < 0.305:  # Decay
            var t = (time - 0.005) / 0.3
            return 1.0 - (0.4 * t)  # Drop to 0.6
        else:  # Sustain/Release
            return 0.6 * exp(-(time - 0.305) / 2.0)
    
    func calculate_mod_envelope(time: float) -> float:
        # Exponential decay
        return exp(-time / 0.5)
```

---

## 🎼 ALTERNATIVE: ADDITIVE BELL SYNTHESIS

If FM is too complex, use additive synthesis:

**Bell Partials (Inharmonic):**
```
Partial 1: 1.0 × f, amplitude 1.0, decay 2.0s
Partial 2: 2.76 × f, amplitude 0.5, decay 1.5s
Partial 3: 5.4 × f, amplitude 0.25, decay 1.0s
Partial 4: 8.93 × f, amplitude 0.125, decay 0.7s
```

Each partial:
- Sine wave at specific frequency
- Exponential decay
- Triggered simultaneously
- Sum all partials

---

## 🎯 INTEGRATION WITH AIR POINTS

### Trigger Logic:
```gdscript
# Trigger note when:
1. Air Point enters proximity threshold (< 2m)
2. Air Point velocity exceeds threshold (> 0.5 m/s)
3. Minimum time since last trigger (> 0.5s)

# Frequency mapping:
freq = map(air_point.y, -5, 5, 220, 880)  # Vertical position

# Velocity mapping:
velocity_factor = clamp(air_point.velocity.length() / 5.0, 0.0, 1.0)
mod_index_scale = 2.0 + velocity_factor * 3.0  # Faster = brighter
```

---

## 📊 COMPARISON

| Aspect | Current (Sine) | FM Piano |
|--------|---------------|----------|
| **Timbre** | Pure tone | Complex, evolving |
| **Attack** | Slow swell | Fast, percussive |
| **Decay** | Sustains | Natural fade |
| **Character** | Electronic | Acoustic-like |
| **Brightness** | Static | Dynamic (bright→mellow) |

---

## ✅ AGENT B: PROCEED WITH FM PIANO

**Authorization:** Build `FMPianoSynth.gd` with above specification

**Priority Parameters:**
1. Fast attack (0.005s)
2. Modulation index envelope (5.0 → 2.0)
3. Exponential amplitude decay
4. Trigger-based (not continuous)

**Test:** Should sound like electric piano, NOT oscillating sine

---

**Agent A Status:** Specification complete, awaiting Agent B implementation

**Expected Result:** Rich, piano-like tones with natural decay and brightness evolution
