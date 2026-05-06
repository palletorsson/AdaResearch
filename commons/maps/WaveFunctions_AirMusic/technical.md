# WaveFunctions AirMusic — Technical

Three audio stations produce loops at slightly different intervals, and their phases drift relative to one another over time. A floor of position-triggered notes lets the learner add to the composition by walking across tiles.

```gdscript
class_name AmbientLoop extends AudioStreamPlayer

@export var pattern: Array = [440.0, 523.0, 659.0, 784.0]  # Hz
@export var beat_interval: float = 0.75  # seconds per note
@export var voice: String = "fm_piano"

var beat_index: int = 0
var time_since_beat: float = 0.0

func _process(delta: float) -> void:
    time_since_beat += delta
    if time_since_beat >= beat_interval:
        time_since_beat -= beat_interval
        play_note(pattern[beat_index])
        beat_index = (beat_index + 1) % pattern.size()

func play_note(frequency: float) -> void:
    # Trigger an FM-synthesis voice at the given frequency
    pitch_scale = frequency / 440.0
    play()
```

## Phasing

Two loops with nearly-identical intervals phase against each other over many cycles. A loop at 0.75 sec and a second at 0.77 sec take about (0.75 * 0.77) / (0.77 - 0.75) = 28.9 seconds to return to alignment — about 38 beats of the faster loop.

The effect is most musical when the intervals are close but not identical; Steve Reich's *Piano Phase* uses this technique deliberately.

## Position-Triggered Notes

A grid of floor tiles triggers notes when the learner stands on them. Each tile has an associated pitch, and the ensemble of tiles forms a scale or chord progression.

```gdscript
class_name PitchTile extends Area3D

@export var pitch: float = 440.0  # Hz
@export var voice: String = "sine"

var note_player: AudioStreamPlayer

func _on_body_entered(_body: Node) -> void:
    note_player.pitch_scale = pitch / 440.0
    note_player.play()

func _ready() -> void:
    note_player = AudioStreamPlayer.new()
    note_player.stream = preload("res://audio/reference_note.ogg")
    add_child(note_player)
```

## FM Synthesis

FM synthesis drives one oscillator (the carrier) with the output of another (the modulator), producing complex spectra from simple waveforms.

```gdscript
func fm_synthesis(carrier_freq: float, modulator_freq: float, mod_index: float, time: float) -> float:
    var modulator: float = mod_index * sin(TAU * modulator_freq * time)
    return sin(TAU * carrier_freq * time + modulator)
```

The modulation index controls the spectral richness. At index 0, the output is pure sine at the carrier frequency. At higher indices, the output contains sidebands at the carrier ± integer multiples of the modulator frequency.

## Complexity

Each loop is O(1) per frame. The pitch tiles are passive and only cost CPU when triggered. FM synthesis is O(1) per sample; at 44100 Hz mix rate, that is one multiply-add and two sines per sample, well within budget.

## Spatial Audio

Godot's AudioStreamPlayer3D renders sound with distance attenuation and Doppler shift, making the map's loops spatially located. Standing close to a loop makes it louder; walking past a loop produces a slight pitch shift due to Doppler.

Within the sequence, AirMusic restores sound after Cage's withdrawal but changes its mode. Sound is now emergent rather than composed.

## Phasing Relationships

Steve Reich's *Piano Phase* (1967) uses two pianists playing the same 12-beat pattern at slightly different tempos. Over ~20 minutes, the second pianist moves from in-phase to 1-beat out-of-phase and back, creating shifting harmonic relationships.

The map's loops use simpler phasing: two-voice relationships where one voice is at frequency f and the other at f·(1 + ε). The beat period is 1/ε, so ε = 0.05 produces a 20-second phase cycle.

## Reverb

Spatial audio includes reverberation — multiple reflections off room surfaces producing a tail after the direct sound. Godot's AudioEffectReverb simulates this with adjustable parameters:

```gdscript
var reverb := AudioEffectReverb.new()
reverb.room_size = 0.8
reverb.damping = 0.5
reverb.predelay_msec = 20.0
reverb.predelay_feedback = 0.4
reverb.wet = 0.3
AudioServer.add_bus_effect(music_bus_idx, reverb)
```

The reverb gives the ambient loops a sense of being in a space, which is core to Eno's aesthetic.

## Generative Ambient

Brian Eno coined "generative music" to describe systems that produce ongoing compositions without a fixed duration. The map's three-loop phasing is a minimal generative system; Eno's *Generative Music 1* (1996) used more elaborate multi-voice phasing with dozens of parallel loops.

## Volume Ducking

To preserve dynamic range when multiple loops overlap, the map applies a gentle sidechain-style ducking. When one loop's amplitude spikes, the others dim slightly, preventing the cumulative signal from clipping.

```gdscript
func adjust_loop_volumes(active_loops: Array) -> void:
    var total_amplitude: float = 0.0
    for loop in active_loops:
        total_amplitude += loop.current_amplitude()
    if total_amplitude > 1.0:
        var ducking: float = 1.0 / total_amplitude
        for loop in active_loops:
            loop.apply_ducking(ducking)
```

## Pitch Tile Grid

The floor of pitch tiles is arranged in a grid where horizontal position maps to scale degree and vertical position maps to octave. The scale is configurable — major, minor, pentatonic, or raga-based scales all work with the same tile grid.
