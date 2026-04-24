# Synthesis Lab

Fourier said any signal is a sum of sines. Build the room where stacking harmonics rebuilds the world.

Declare a harmonic.

```gdscript
class_name Harmonic
extends Resource

@export var harmonic_number: int = 1
@export var amplitude: float = 0.0
@export var phase: float = 0.0
```

One harmonic, three numbers. The harmonic number is the integer multiple of the fundamental.

Sum a harmonic bank.

```gdscript
func sample_bank(harmonics: Array[Harmonic], fundamental: float, t: float) -> float:
    var out := 0.0
    for h in harmonics:
        out += h.amplitude * sin(TAU * fundamental * h.harmonic_number * t + h.phase)
    return out
```

Each harmonic contributes its weighted sine. The bank is the Fourier sum. Fundamental sets the base note.

Build the adjustable bank.

```gdscript
func build_bank(n: int) -> Array[Harmonic]:
    var bank: Array[Harmonic] = []
    for i in n:
        var h := Harmonic.new()
        h.harmonic_number = i + 1
        bank.append(h)
    return bank
```

Ten harmonics is a usable bank. More is possible but adds little audible difference for most shapes.

Wire sliders to amplitudes.

```gdscript
func _on_slider_moved(index: int, v: float) -> void:
    bank[index].amplitude = lerp(0.0, 1.0, v)
    rebuild_waveform()
```

Each slider controls one amplitude. Raising the odd harmonics produces a square wave; raising all produces a sawtooth. The learner sees the wave grow.

Render the live waveform.

```gdscript
func update_trace(line: Line2D) -> void:
    line.clear_points()
    for i in 256:
        var t := float(i) / 256.0
        var y := sample_bank(bank, 1.0, t)
        line.add_point(Vector2(i * 2.0, -y * 40.0))
```

The trace redraws each frame. Moving a slider changes the shape immediately. The room responds at the speed of thought.

Play the bank audibly.

```gdscript
func feed_audio(playback: AudioStreamGeneratorPlayback) -> void:
    var frames_needed: int = playback.get_frames_available()
    for i in frames_needed:
        var t := audio_time
        audio_time += 1.0 / 44100.0
        var s: float = sample_bank(bank, 220.0, t) * 0.3
        playback.push_frame(Vector2(s, s))
```

Fundamental at 220 Hz gives a low A. The timbre changes as sliders move. Seeing and hearing align.

Map harmonics to biological oscillators.

```gdscript
func link_bio_example(name: String, h: int, a: float) -> void:
    var entry := Label3D.new()
    entry.text = "%s: harmonic %d at %.2f" % [name, h, a]
    bio_panel.add_child(entry)
```

A side panel lists heartbeats, DNA rotation, circadian rhythms. Each entry names a harmonic pattern from biology. The lab is not only a synthesizer.

Trigger chords from harmonic presets.

```gdscript
func load_preset(preset_name: String) -> void:
    match preset_name:
        "square": _load_odd_only()
        "sawtooth": _load_all_inverse()
        "triangle": _load_odd_inverse_squared()
```

Presets set common waveforms instantly. The learner can start from any of them and adjust.

You have synthesized the whole sequence. The final map, Chamber Waves, turns oscillation into contact.
<<</MAP>>>
