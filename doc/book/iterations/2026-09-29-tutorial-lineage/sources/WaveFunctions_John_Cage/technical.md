# WaveFunctions John Cage — Technical

The map stages Cage's 4'33" via a controlled audio environment that exposes the ambient noise floor. A toggle switches between "play" mode (a synthesized tone) and "pause" mode (silence from the synth but the room's ambience remains audible).

```gdscript
class_name CageStation extends Node3D

@export var noise_floor_meter: RangeControl
@export var countdown_timer: Timer

var is_playing: bool = false
var tone_player: AudioStreamPlayer

func _ready() -> void:
    countdown_timer.wait_time = 4 * 60 + 33  # 4 minutes 33 seconds
    countdown_timer.timeout.connect(_on_piece_end)

func start_piece() -> void:
    countdown_timer.start()
    begin_noise_floor_recording()

func toggle_tone() -> void:
    is_playing = not is_playing
    if is_playing:
        tone_player.play()
    else:
        tone_player.stop()

func _process(_delta: float) -> void:
    var floor_level: float = measure_ambient_noise()
    noise_floor_meter.value = floor_level
```

## Noise Floor Measurement

The ambient noise floor is measured from the input bus — microphone input, if available, or the system's reported audio baseline otherwise.

```gdscript
func measure_ambient_noise() -> float:
    # dB below reference (typically 0 dBFS)
    var db_left: float = AudioServer.get_bus_peak_volume_left_db(input_bus_idx, 0)
    var db_right: float = AudioServer.get_bus_peak_volume_right_db(input_bus_idx, 0)
    return max(db_left, db_right)
```

In the absence of microphone input, the map uses a simulated noise floor that varies slowly according to a noise function, producing visible variation on the meter.

## Aleatoric Devices

Three chance devices drive aleatoric composition: dice for pitch, coin for rhythm, spinner for duration.

```gdscript
class_name AleatoricDevice extends Node3D

@export var parameter_name: String  # "pitch", "rhythm", "duration"

func roll() -> float:
    match parameter_name:
        "pitch":
            var dice := randi() % 6 + 1
            return dice * 100.0  # Hz, simplified
        "rhythm":
            return randf() < 0.5  # coin toss, returns 0 or 1
        "duration":
            return randf_range(0.1, 2.0)
    return 0.0
```

The rolled values drive a minimal composition engine that plays short tones at the chosen pitches, rhythms, and durations.

## Attention vs Signal

The map's argument about silence operates through the meter rather than through the audio. Cage's piece claims that silence is a reassignment of attention rather than an absence of sound, and the noise-floor meter makes this claim mechanically: the meter never reads zero, and the learner can see that the "silence" contains continuous signal.

## Complexity

Audio measurement is O(1) per frame. Aleatoric devices are O(1) per roll. The map's computational cost is negligible; the entire station runs within a fraction of a millisecond per frame.

Within the sequence, Cage is the philosophical counter-weight. AirMusic will next reintroduce sound as emergent rather than composed.

## Compositional Context

Cage composed 4'33" in 1952. The piece instructs the performer to sit at the piano for the specified duration without playing any notes. The published score divides the duration into three movements (30 seconds, 2 minutes 23 seconds, 1 minute 40 seconds) and instructs "tacet" (silence) for each.

The piece has been performed thousands of times since its premiere. Different performances vary substantially in what is audible, which is the composition's thesis: the performance is whatever the audience is attending to during the specified duration.

## Aleatoric Composition Tools

Cage's later aleatoric works used the I Ching, star charts, and random number tables to generate compositional material. The map's three chance devices are simplified equivalents.

```gdscript
class_name IChing

func hexagram() -> Array:
    var lines: Array = []
    for _i in range(6):
        # Three coin flips per line
        var sum: int = 0
        for _j in range(3):
            sum += 2 if randf() < 0.5 else 3
        lines.append(sum)
    return lines
```

An I Ching hexagram has 64 possible outcomes corresponding to 64 hexagram names and interpretations. Cage mapped these to musical parameters in his *Music of Changes* (1951).

## Dynamic Noise Floor

The ambient noise floor has structure at multiple time scales: fast components (HVAC cycling, ventilation) and slow components (building settling, diurnal temperature variation). The map's simulated noise floor uses layered noise to produce realistic variation over several time scales.

```gdscript
func simulated_noise_floor(time: float) -> float:
    var slow := 0.3 * sin(time * 0.01)  # very slow drift
    var medium := 0.2 * noise.get_noise_1d(time * 0.5)
    var fast := 0.1 * noise.get_noise_1d(time * 5.0)
    return -45.0 + slow + medium + fast  # dB
```

## Silence as Signal

The noise floor meter demonstrates that silence in a recorded environment is never actually zero. The meter's minimum value is set by the recording equipment's inherent noise — typically -60 dB below full scale for consumer microphones, -80 dB for professional equipment.

## Piece Duration Counter

A countdown timer displays the remaining time for the piece. When the timer reaches zero, the piece ends automatically and the station reopens for a new performance.
