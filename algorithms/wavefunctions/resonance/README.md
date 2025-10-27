# Resonating Metallophone 🎵

A VR musical instrument where you hit resonating bars with a stick and see the combined sound waves!

## Overview

This creates a playable metallophone (like a xylophone) with:
- **8 colorful bars** tuned to C major pentatonic scale
- **Long resonance** - bars ring out for 3 seconds with beautiful decay
- **Visual feedback** - see all the combined sine waves in real-time
- **VR interaction** - use the long stick to hit the bars

## Files

- `ResonatingBar.gd` - Single resonating bar with physics and sound
- `resonating_bar.tscn` - Bar scene
- `CombinedWaveVisualizer.gd` - Visual display of combined waveforms
- `ResonatingMetallophone.gd` - Complete instrument with 8 bars
- `resonating_metallophone.tscn` - Main scene (instantiate this!)
- `README.md` - This file

## How It Works

### Sound Generation

Each bar produces a pure sine wave at its resonant frequency:

```
wave(t) = sin(2π * frequency * t) * amplitude * exp(-t / decay_time)
```

- **Frequency**: Each bar has a different musical note (261 Hz - 659 Hz)
- **Amplitude**: Varies based on how hard you hit it
- **Decay**: Exponential fade over 3 seconds

### Wave Combination

All active resonances are summed together:

```
combined_wave = Σ (sin(2π * f_i * t) * a_i * exp(-t_i / decay))
```

This creates beautiful harmonic interactions - **musical chords!**

### Visual Display

The `CombinedWaveVisualizer` draws the combined waveform using `ImmediateMesh`:
- Shows real-time sum of all resonating bars
- Color intensity shows amplitude
- Based on `exercise_3_12_additive_wave_vr.gd` pattern

## Musical Scale

The bars are tuned to **C major pentatonic** - these notes always sound good together!

```
Bar 1: C4  (261.63 Hz) - Red
Bar 2: D4  (293.66 Hz) - Orange
Bar 3: E4  (329.63 Hz) - Yellow
Bar 4: G4  (392.00 Hz) - Green
Bar 5: A4  (440.00 Hz) - Blue
Bar 6: C5  (523.25 Hz) - Indigo
Bar 7: D5  (587.33 Hz) - Violet
Bar 8: E5  (659.25 Hz) - Pink
```

No wrong notes - everything harmonizes! 🎶

## Usage

### In VR

1. Instantiate `resonating_metallophone.tscn` in your scene
2. Grab the long stick with your VR hand
3. Hit the colorful bars
4. Watch the waveform visualization show combined resonances!
5. Hit multiple bars to create chords

### From Code

```gdscript
# Get reference
var metallophone = $ResonatingMetallophone

# Stop all resonances
metallophone.stop_all_resonances()

# Check active frequencies
var active = metallophone.get_active_frequencies()
print("Currently resonating: ", active)
```

### Individual Bar

```gdscript
# Access a specific bar
var bar = metallophone.bars[3]  # G4

# Check if resonating
if bar.is_resonating:
    print("Amplitude: ", bar.current_amplitude)

# Manually trigger
bar._trigger_resonance(0.8)  # 80% strength

# Get wave contribution
var wave_val = bar.get_current_wave_contribution(time)
```

## Physics

Each bar is a `RigidBody3D` with:
- **Mass**: 0.5 kg
- **Contact monitoring**: Detects stick hits
- **Collision response**: Bars move when hit
- **Visual feedback**: Glows based on resonance amplitude

## Customization

### Different Scale

Edit `PENTATONIC_SCALE` in `ResonatingMetallophone.gd`:

```gdscript
# Blues scale
const BLUES_SCALE = [
    261.63,  # C
    311.13,  # Eb (flat third)
    349.23,  # F
    369.99,  # F# (flat fifth)
    392.00,  # G
    466.16,  # Bb (flat seventh)
]
```

### Longer Decay

```gdscript
metallophone.decay_time = 5.0  # 5 second decay
```

### More Bars

```gdscript
const CHROMATIC_SCALE = [
    261.63, 277.18, 293.66, 311.13,
    329.63, 349.23, 369.99, 392.00,
    415.30, 440.00, 466.16, 493.88
]  # All 12 notes in an octave
```

## Advanced Features

### Damping System

Want to stop resonances by touching bars?

```gdscript
func _on_bar_touched(body: Node) -> void:
    if body.name.contains("Hand"):
        force_stop()  # Damp the vibration
```

### Recording

Save the combined waveform:

```gdscript
# Record amplitude over time
var recording: PackedFloat32Array = []

func _process(delta: float) -> void:
    var combined_amplitude = 0.0
    for bar in bars:
        if bar.is_resonating:
            combined_amplitude += bar.current_amplitude
    recording.append(combined_amplitude)
```

### Frequency Analysis

Analyze which frequencies are active:

```gdscript
func get_frequency_spectrum() -> Dictionary:
    var spectrum = {}
    for bar in bars:
        if bar.is_resonating:
            spectrum[bar.frequency] = bar.current_amplitude
    return spectrum
```

## Educational Value

This demonstrates:
- **Additive synthesis** - combining simple sine waves
- **Harmonic resonance** - how musical notes interact
- **Exponential decay** - natural damping behavior
- **Wave superposition** - sum of multiple waves
- **Musical intervals** - pentatonic scale relationships

## Performance Notes

- Each bar pre-generates its 5-second resonance sound
- Visualization updates at 60 FPS
- Supports up to 8 simultaneous resonances smoothly
- Audio is spatial 3D with distance attenuation

## Inspiration

Based on:
- Real metallophone/xylophone physics
- `exercise_3_12_additive_wave_vr.gd` visualization pattern
- XR Tools grab interactions
- Classic synthesizer subtractive/additive synthesis

## Future Ideas

- [ ] Add pedal for sustain/dampening
- [ ] Mallets instead of stick
- [ ] Tuning mode (adjust frequencies)
- [ ] Frequency spectrum analyzer display
- [ ] MIDI output
- [ ] Different waveforms (sawtooth, square, triangle)
- [ ] Reverb/echo effects
- [ ] Looping/sequencer

## Tips for Fun

1. **Hit softly** for gentle tones, **hard** for loud ones
2. **Hit multiple bars quickly** to create chords
3. **Watch the waveform** - see constructive/destructive interference
4. **Try patterns** - ascending scale, descending, arpeggios
5. **Experiment** - there are no wrong notes in pentatonic!

Enjoy making music! 🎵🎶✨
