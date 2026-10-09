# WaveFunctions Effect Sound — Technical

Four synthesiser stations drive oscillators at different waveforms and pipe their output to Godot's audio bus. An FFT station decomposes live input into frequency components.

```gdscript
class_name Synthesizer extends AudioStreamPlayer

@export var frequency: float = 440.0  # Hz
@export var waveform: String = "sine"

var stream_generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback

func _ready() -> void:
    stream_generator = AudioStreamGenerator.new()
    stream_generator.mix_rate = 44100.0
    stream_generator.buffer_length = 0.1
    stream = stream_generator
    play()
    playback = get_stream_playback()
    fill_buffer()

func fill_buffer() -> void:
    var sample_rate: float = stream_generator.mix_rate
    while playback.can_push_buffer(1):
        var phase_step: float = frequency / sample_rate * TAU
        var sample: float = waveform_sample(phase)
        playback.push_frame(Vector2(sample, sample))
        phase = fmod(phase + phase_step, TAU)

func waveform_sample(phase: float) -> float:
    match waveform:
        "sine": return sin(phase)
        "square": return 1.0 if sin(phase) > 0.0 else -1.0
        "sawtooth": return 2.0 * (phase / TAU) - 1.0
        "triangle":
            var t: float = phase / TAU
            return 2.0 * abs(2.0 * (t - floor(t + 0.5))) - 1.0
    return 0.0
```

## FFT

The FFT monitor decomposes the live audio signal into frequency bins. Godot's `AudioServer.get_bus_peak_volume_left_db` exposes bus levels but not full spectra; a custom FFT implementation reads the audio buffer and transforms it.

```gdscript
class_name FFTMonitor extends Node

@export var buffer_size: int = 1024

var samples: PackedFloat32Array

func compute_fft() -> PackedFloat32Array:
    # Cooley-Tukey radix-2 FFT
    var n: int = samples.size()
    if n <= 1: return samples
    # Bit-reverse permutation
    var real: PackedFloat32Array = samples.duplicate()
    var imag: PackedFloat32Array = []; imag.resize(n)
    bit_reverse_permute(real)
    # Butterfly stages
    var stage: int = 1
    while stage < n:
        var angle_step: float = -PI / stage
        for k in range(0, n, stage * 2):
            for j in range(stage):
                var angle: float = angle_step * j
                var wr: float = cos(angle)
                var wi: float = sin(angle)
                # butterfly
                var tr: float = wr * real[k + j + stage] - wi * imag[k + j + stage]
                var ti: float = wr * imag[k + j + stage] + wi * real[k + j + stage]
                real[k + j + stage] = real[k + j] - tr
                imag[k + j + stage] = imag[k + j] - ti
                real[k + j] += tr
                imag[k + j] += ti
        stage *= 2
    var spectrum: PackedFloat32Array = []
    for i in range(n / 2):
        spectrum.append(sqrt(real[i] * real[i] + imag[i] * imag[i]))
    return spectrum
```

## Complexity

The FFT is O(N log N) for N samples. At N=1024, that is roughly 10,000 operations per transform; at 30 Hz update rate the total cost is 300,000 operations per second, well within budget.

Per-sample synthesis is O(1). The per-frame audio buffer fill is O(buffer_size); at 44100 Hz mix rate and 0.1s buffer, that is 4410 samples per 100 ms, running continuously.

## Latency

Every audio stage adds latency. Buffer size directly affects latency: a 100 ms buffer adds 100 ms of delay between a key press and the first sample of audible sound. Interactive audio applications minimise buffer size at the cost of higher CPU usage and occasional underruns.

Within the sequence, Effect_Sound is the pivot from visible waves to audible ones. Bernini will next treat wave geometry as sculptural form.

## Additive Synthesis

Any periodic waveform can be built by adding sinusoids. The Fourier series expansion of a square wave is Σ (1/n) sin(nωt) for odd n. A sawtooth is Σ (1/n) sin(nωt) for all n. Truncating the series to a finite number of harmonics produces band-limited waveforms that avoid aliasing at high pitches.

```gdscript
func band_limited_square(phase: float, harmonics: int) -> float:
    var result: float = 0.0
    for k in range(1, harmonics + 1, 2):  # odd harmonics only
        result += sin(phase * k) / k
    return result * 4.0 / PI
```

## Sample Rate and Aliasing

Generating audio at 44100 Hz restricts the signal's frequency content to half that rate — the Nyquist frequency at 22050 Hz. Any signal component above Nyquist folds back into the audible range as aliased frequencies. Band-limited synthesis techniques (windowed sinc interpolation, polyBLEP correction) prevent aliasing at the cost of additional computation.

## Subtractive Synthesis

The complementary technique filters a harmonically rich source through lowpass, highpass, or bandpass filters. An analog-style lowpass filter is a resonant biquad section:

```gdscript
func biquad_lowpass(input: float, state: Array, cutoff: float, q: float, sr: float) -> float:
    var omega: float = 2.0 * PI * cutoff / sr
    var sin_w: float = sin(omega)
    var cos_w: float = cos(omega)
    var alpha: float = sin_w / (2.0 * q)
    var b0: float = (1.0 - cos_w) / 2.0
    var b1: float = 1.0 - cos_w
    var b2: float = (1.0 - cos_w) / 2.0
    var a0: float = 1.0 + alpha
    var a1: float = -2.0 * cos_w
    var a2: float = 1.0 - alpha
    var output: float = (b0 / a0) * input + (b1 / a0) * state[0] + (b2 / a0) * state[1] - (a1 / a0) * state[2] - (a2 / a0) * state[3]
    state[1] = state[0]; state[0] = input
    state[3] = state[2]; state[2] = output
    return output
```

## Envelope Generators

An amplitude envelope shapes each note's volume over time. The classical ADSR model has four phases: Attack (rise to peak), Decay (drop to sustain), Sustain (held level), Release (drop to zero).
