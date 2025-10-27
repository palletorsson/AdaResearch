# Mario Sound Controller

A 3D interactive sound synthesizer for creating Mario-style pickup sounds using a ball controller.

## Overview

This controller uses a 3D ball interface (ValueMapper3D) to control three parameters of a Mario-style pickup sound in real-time:

- **X Axis (Red)**: Start Frequency (200-800 Hz)
- **Y Axis (Green)**: End Frequency (400-1200 Hz)
- **Z Axis (Blue)**: Decay Rate (2.0-12.0) - how fast the sound fades out

## Files

- `MarioSoundController.gd` - Main controller script
- `MarioSoundController.tscn` - Complete scene with ball and button
- `PlaySoundButton.gd` - Trigger button to play the sound
- `README.md` - This file

## How It Works

### Sound Synthesis

The Mario pickup sound is generated using:

1. **Rising Frequency**: Frequency sweeps from `freq_start` to `freq_end` over the duration
2. **Square Wave**: Classic retro "chip tune" sound using a square wave oscillator
3. **Exponential Decay**: Volume fades out exponentially using `decay_rate`

Formula:
```gdscript
freq(t) = freq_start + (freq_end - freq_start) * progress
envelope(t) = exp(-progress * decay_rate)
wave(t) = square_wave(freq(t))
output = wave * envelope * 0.3
```

### Classic Mario Values

The original Super Mario Bros pickup sound uses approximately:
- Start Frequency: 440 Hz
- End Frequency: 880 Hz (one octave up)
- Decay Rate: 8.0

Move the ball to these positions to recreate the classic sound!

## Usage

### In VR

1. Grab the ball and move it around the 3D space
2. X (Red) controls where the sound starts
3. Y (Green) controls where the sound ends
4. Z (Blue) controls how quickly it fades
5. Touch or grab the green "PLAY" button to hear your sound

### Programmatic Usage

```gdscript
# Get reference
var sound_controller = $MarioSoundController

# Play with current ball position
sound_controller.play_sound()

# Get current parameters
var params = sound_controller.get_sound_parameters()
print("Start: ", params.freq_start)
print("End: ", params.freq_end)
print("Decay: ", params.decay_rate)

# Trigger button programmatically
$MarioSoundController/PlayButton.trigger()
```

## Instantiation in Grid System

To use in your grid-based game, add to `grid_artifacts.json`:

```json
{
  "mario_sound_controller": {
    "scene_path": "res://algorithms/wavefunctions/mariocontrol/MarioSoundController.tscn",
    "description": "Interactive 3D sound synthesizer for Mario-style sounds"
  }
}
```

Then place in map with:
```json
"interactables": [
  ["mario_sound_controller", " ", " "]
]
```

## Extending

You can create additional sound controllers for different curves:

1. **Decay Curve Controller**: Control attack, decay, sustain, release (ADSR)
2. **Filter Sweep Controller**: Control low-pass filter cutoff and resonance
3. **Vibrato Controller**: Control vibrato depth, rate, and delay

Each controller can control a different aspect of the sound synthesis!

## Technical Details

- **Sample Rate**: 44,100 Hz
- **Format**: 16-bit PCM mono
- **Duration**: 0.5 seconds (configurable)
- **Waveform**: Square wave (retro chip tune style)
- **3D Audio**: AudioStreamPlayer3D with spatial positioning
- **Real-time**: Sound is generated on-demand when you press PLAY

## Future Enhancements

- [ ] Add waveform visualizer showing the actual wave shape
- [ ] Add oscilloscope display
- [ ] Add frequency spectrum analyzer
- [ ] Save/load presets
- [ ] Record and export sounds as .wav files
- [ ] Multi-segment envelope (not just decay)
- [ ] Add filters (low-pass, high-pass, band-pass)

## See Also

- `res://commons/interfaces/nail_color_controller.gd` - Similar 3D controller pattern
- `res://commons/audio/generators/AudioSynthesizer.gd` - More sound types
- `res://algorithms/wavefunctions/unit_circle/UnitCircle.gd` - Unit circle visualization
