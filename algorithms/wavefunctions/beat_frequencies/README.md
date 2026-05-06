# Beat Frequencies Interactive Demo

## Overview
Interactive demonstration of wave interference and beat frequencies - when two close frequencies combine, they create periodic amplitude modulation (beats).

## Concept
**Beat Frequency = |f1 - f2|**

When you play two sine waves with slightly different frequencies:
- 440 Hz + 442 Hz = 2 Hz beat frequency (wah-wah-wah, 2 times per second)
- The closer the frequencies, the slower the beats
- When frequencies match perfectly → beats disappear (perfect tuning)

## Controls

### VR Interactables
- **Left Slider:** Frequency 1 (400-500 Hz) - Red wave
- **Right Slider:** Frequency 2 (400-500 Hz) - Blue wave
- **Push Button:** Toggle sound on/off

### Visual Feedback
- **Red wave points:** Frequency 1 oscillation
- **Blue wave points:** Frequency 2 oscillation
- **Yellow wave points:** Combined wave (superposition)
- **Green bars:** Beat envelope (amplitude modulation)
- **Labels:** Current frequencies and beat frequency

## Educational Value

### What You Learn
1. **Wave Interference** - Two waves combine through superposition
2. **Beat Frequencies** - Periodic amplitude modulation
3. **Tuning Concept** - Slowing beats = getting closer to perfect tune
4. **Audible Frequency Differences** - Hear the difference between close pitches

### Real-World Applications
- **Musical tuning** - Orchestras tune by listening for beat elimination
- **Chorus effects** - Slight detuning creates richness in sound
- **Vibrato** - Periodic pitch modulation
- **Radio interference** - AM radio stations too close create beats

## Musical/Game Use

### Sound Characteristics
- **Low beat frequency (< 5 Hz):** Slow wah-wah, eerie drone
- **Medium beat frequency (5-20 Hz):** Tremolo effect, tension
- **High beat frequency (> 20 Hz):** Roughness, dissonance

### Game Audio Applications
- **Sci-fi drones** - Alien atmospheres, spaceship hums
- **Tension music** - Unsettling beats for suspense
- **Eerie effects** - Haunted environments, supernatural presence
- **Tuning mini-games** - Player must match frequencies

## Parameters

### Saved to JSON
```json
{
  "freq1": 440.0,
  "freq2": 442.0,
  "freq_min": 400.0,
  "freq_max": 500.0,
  "beat_frequency": 2.0,
  "is_playing": true
}
```

### Compatible with
- `commons/audio/generators/CustomSoundGenerator.gd`
- `commons/audio/parameters/educational/beat_frequencies.json`

## Usage in Game

```gdscript
# Load beat frequency parameters
var beat_params = load_json("res://commons/audio/parameters/educational/eerie_drone.json")

# Generate sound
var sound_gen = CustomSoundGenerator.new()
sound_gen.set_parameters(beat_params)
var drone_sound = sound_gen.generate_sound()

# Play in game
audio_player.stream = drone_sound
audio_player.play()
```

## Tips

### For Perfect Tuning
1. Start with frequencies far apart (e.g., 440 Hz and 460 Hz)
2. Slowly adjust one slider toward the other
3. Listen as beats slow down
4. When beats disappear completely → frequencies match!

### For Interesting Effects
- **Slow beats (1-3 Hz):** Deep pulsing, meditation sounds
- **Fast beats (10-15 Hz):** Tremolo, vibrato effects
- **Very close (<0.5 Hz):** Subtle shimmer, chorus

## Technical Details

### Audio Generation
- **Sample Rate:** 44100 Hz
- **Buffer Size:** 100ms
- **Waveform:** Pure sine waves
- **Output:** Stereo (mono duplicated)

### Signal Formula
```
output(t) = (sin(2π·f1·t) + sin(2π·f2·t)) × 0.4
beat_envelope(t) = 2|cos(π·|f1-f2|·t)|
```

## Physics Behind It

### Constructive/Destructive Interference
When two waves combine:
- **In phase (peaks align):** Constructive interference → louder
- **Out of phase (peak meets trough):** Destructive interference → quieter
- **Slowly drifting phase:** Creates periodic loud/quiet pattern (beats)

### Why Beats Happen
Two frequencies f1 and f2 have slightly different periods:
- Sometimes peaks align (loud)
- Sometimes cancel (quiet)
- Rate of alignment = beat frequency = |f1 - f2|

## See Also
- `fourier_synthesis_axioms.gd` - Mathematical background
- `wavefunction_form_axioms.gd` - How waves combine
- `MarioSoundController.gd` - Similar procedural audio approach
