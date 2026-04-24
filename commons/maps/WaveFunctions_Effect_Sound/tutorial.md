# Effect Sound

Waves become bleeps. Build the audio lab where sine drives a speaker and FFT reveals the harmonics.

Declare the tone player.

```gdscript
class_name TonePlayer
extends AudioStreamPlayer

@export var frequency: float = 440.0
@export var kind: int = 0
```

The player extends Godot's AudioStreamPlayer. Frequency defaults to A4. Kind selects waveform.

Generate a sine buffer.

```gdscript
func generate_sine_buffer(sample_rate: int, seconds: float) -> PackedFloat32Array:
    var out := PackedFloat32Array()
    var n: int = int(sample_rate * seconds)
    for i in n:
        var t := float(i) / float(sample_rate)
        out.append(sin(TAU * frequency * t))
    return out
```

A sample buffer at the given sample rate. Each sample is the sine displacement at that moment. Godot plays the buffer when fed.

Push the buffer to the playback stream.

```gdscript
func push_buffer(playback: AudioStreamGeneratorPlayback, buffer: PackedFloat32Array) -> void:
    for sample in buffer:
        playback.push_frame(Vector2(sample, sample))
```

Stereo frame with the same sample in left and right. The speaker reproduces the sine as pressure waves.

Shape the waveform.

```gdscript
func shape(sample: float, k: int) -> float:
    match k:
        0: return sample
        1: return sign(sample)
        2: return 2.0 * (fmod(sample + 1.0, 2.0) - 1.0)
        3: return abs(sample) * 2.0 - 1.0
    return sample
```

Four waveform shapes from a single sine source.

Square is sign. Sawtooth is fmod. Triangle is absolute value.

Chiptune from one function.

Compute the FFT.

```gdscript
func fft(samples: PackedFloat32Array) -> PackedVector2Array:
    var bins := PackedVector2Array()
    for k in samples.size() / 2:
        var re := 0.0
        var im := 0.0
        for n in samples.size():
            var angle := -TAU * k * n / samples.size()
            re += samples[n] * cos(angle)
            im += samples[n] * sin(angle)
        bins.append(Vector2(re, im))
    return bins
```

Direct DFT, not FFT, but fast enough for teaching. Each bin holds a real and imaginary part. Magnitude is sqrt of the sum of squares.

Render the spectrum on a panel.

```gdscript
func draw_spectrum(line: Line2D, bins: PackedVector2Array) -> void:
    line.clear_points()
    for i in bins.size():
        var mag := bins[i].length()
        line.add_point(Vector2(i * 2.0, -mag * 20.0))
```

Height per bin shows how much of that frequency is present. The spectrum is a fingerprint of the waveform.

Expose a knob for frequency.

```gdscript
func _on_frequency_knob(v: float) -> void:
    frequency = lerp(110.0, 1760.0, v)
    reload_buffer()
```

Two octaves from A2 to A6. The knob sweeps the audible range in that band. Pitch follows the hand.

You have turned waves into sound. The next map, Bernini, wraps oscillation around columns.
<<</MAP>>>
