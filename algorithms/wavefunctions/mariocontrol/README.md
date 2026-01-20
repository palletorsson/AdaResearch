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

1. **Grab the ball and move it** - Sound plays automatically as you move!
2. **X (Red)** controls where the sound starts (200-800 Hz)
3. **Y (Green)** controls where the sound ends (400-1200 Hz)
4. **Z (Blue)** controls how quickly it fades (2.0-12.0 decay rate)
5. **Move the ball around** to hear different sounds continuously
6. Or touch the green "PLAY" button to manually trigger a sound

**NEW: Continuous Playback!** The sound now plays automatically whenever you move the ball. It intelligently spaces plays so they don't overlap.

### Programmatic Usage

```gdscript
# Get reference
var sound_controller = $MarioSoundController

# Play with current ball position (manual trigger)
sound_controller.play_sound()

# Get current parameters
var params = sound_controller.get_sound_parameters()
print("Start: ", params.freq_start)
print("End: ", params.freq_end)
print("Decay: ", params.decay_rate)

# Control continuous playback
sound_controller.set_play_on_move(true)   # Enable auto-play on movement
sound_controller.set_play_on_move(false)  # Disable (manual mode only)

# Adjust playback interval
sound_controller.set_play_interval(0.8)  # 0.8 seconds between plays

# Change sound duration
sound_controller.set_sound_duration(0.7)  # Longer sound

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
- **Real-time Generation**: Sound is synthesized on-the-fly based on ball position
- **Continuous Playback**: Monitors ball movement and plays automatically
- **Smart Spacing**: Prevents audio overlap with configurable intervals (default 0.6s)
- **Movement Detection**: Triggers on 0.01 unit movement threshold

## Future Enhancements

- [ ] Add waveform visualizer showing the actual wave shape
- [ ] Add oscilloscope display
- [ ] Add frequency spectrum analyzer
- [ ] Save/load presets
- [ ] Record and export sounds as .wav files
- [ ] Multi-segment envelope (not just decay)
- [ ] Add filters (low-pass, high-pass, band-pass)

---

# Spatial Musical Instruments

Two additional instruments build on the MarioSoundController's sine_bell mode, positioning musical notes in 3D space.

## MelodySoundBoard

A spatial instrument where notes are positioned in 3D pitch space. Pre-programmed melodies move a point through this space, playing notes as it visits each position.

### Concept

Similar to the vowel_sound_board (which positions phonemes in formant space), this positions musical notes in pitch space:

- **X axis**: Chromatic semitone (0-12, C through B)
- **Y axis**: Octave offset (-1 to +1)
- **Z axis**: Volume/intensity

### Files

- `MelodySoundBoard.gd` - Main script
- `MelodySoundBoard.tscn` - Scene file

### Melodies Included

| Selection | Description |
|-----------|-------------|
| `C Major Scale` | Ascending and descending C major scale |
| `Twinkle Twinkle` | Twinkle Twinkle Little Star |
| `Ode to Joy` | Beethoven's Ode to Joy (simplified) |
| `Mario Theme` | Super Mario Bros opening notes |
| `Pentatonic Jam` | Random pentatonic improvisation |
| `Chromatic Run` | Full chromatic scale up and down |

### Map Usage

```json
"MelodySoundBoard#melody:Twinkle Twinkle#repeat:true#tempo:100"
```

### Config Options

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `melody` | `C Major Scale`, `Twinkle Twinkle`, `Ode to Joy`, `Mario Theme`, `Pentatonic Jam`, `Chromatic Run` | `C Major Scale` | Which melody to play |
| `repeat` | `true`, `false` | `true` | Loop the melody |
| `tempo` | number (BPM) | `120` | Playback speed |
| `octave` | integer | `4` | Base octave (4 = middle C) |

---

## MelodyChaser3D

A "follow the leader" musical instrument. Notes are positioned radially around the center like a clock face. A leader point jumps ahead showing you where to go next. Move your ball to each note position to play it.

### Concept

Notes arranged **radially from center** - easy to reach by moving outward:
- Notes spread around center like clock positions
- Leader point jumps 1-2 beats ahead, showing the next note
- **YOU trigger notes** by moving your ball near them
- Current target note glows brighter and larger

This is like a musical "Simon Says" - watch where the leader goes, then follow.

### Files

- `MelodyChaser3D.gd` - Main script
- `MelodyChaser3D.tscn` - Scene file

### Scale Types

| Scale | Notes | Layout |
|-------|-------|--------|
| `major` | C D E F G A B C | Radial (clock) |
| `minor` | C D Eb F G Ab Bb C | Radial (clock) |
| `pentatonic` | C D E G A C | Radial (clock) |
| `chromatic` | All 12 semitones | Radial (clock) |
| `arpeggio` | C E G C G E (triad up/down) | Radial (clock) |
| `fifths_circle` | C G D A E B F# C# G# D# A# F C | **Flat circle** |
| `fifths_helix` | C G D A E B F# C# G# D# A# F C | **3D spiral** |

### Circle of Fifths Patterns

Two special 3D visualizations of the circle of fifths:

**fifths_circle** - A flat horizontal circle where each adjacent note is a perfect fifth apart. Moving clockwise: C → G → D → A → E → B → F# → C# → G# → D# → A# → F → back to C. Lines connect consecutive fifths.

**fifths_helix** - The "Pythagorean spiral". Same sequence but rising in a 3D helix. After 12 fifths, you're 7 octaves higher! This visualizes why the circle doesn't perfectly close (the Pythagorean comma). The spiral shows the true nature of stacking perfect fifths.

### Map Usage

```json
"MelodyChaser3D#scale:pentatonic#tempo:100"
```

Circle of fifths:
```json
"MelodyChaser3D#scale:fifths_circle#tempo:60"
```

With rotation:
```json
"MelodyChaser3D:90#scale:major#tempo:80"
```

### Config Options

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `scale` | `major`, `minor`, `pentatonic`, `chromatic`, `arpeggio`, `fifths_circle`, `fifths_helix` | `major` | Which scale pattern |
| `tempo` | integer (BPM) | `100` | How fast the leader advances |
| `octave` | integer | `4` | Base octave |

### Visual Elements

- **Orange leader point** - jumps ahead showing next note to play
- **Colored note spheres** - rainbow hue by pitch, positioned radially
- **Target highlight** - current note to play glows brighter and larger
- **Flash effect** - note pulses when you trigger it

### How to Play

1. Notes are arranged in a circle around the center
2. The **orange leader** jumps to show the upcoming note
3. The **brightest/largest note** is the one to play NOW
4. Move your ball to that note position to trigger the sound
5. Keep following the sequence to play the melody

---

## See Also

- `res://commons/interfaces/nail_color_controller.gd` - Similar 3D controller pattern
- `res://commons/audio/generators/AudioSynthesizer.gd` - More sound types
- `res://algorithms/wavefunctions/unit_circle/UnitCircle.gd` - Unit circle visualization
- `res://algorithms/speech/phoneme_cloud/vowel_sound_board.gd` - Spatial phoneme instrument (inspiration for these)
