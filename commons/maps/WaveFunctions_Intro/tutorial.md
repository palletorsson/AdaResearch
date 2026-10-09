# The cube returns

**Learning elements**

- Periodic movement
- Amplitude
- Frequency and period
- Phase

Start with the cube moving up and down near the entrance. Follow it from the middle to the top, through the middle to the bottom, then back. Its direction changes while its shape remains familiar.

Three questions travel through this sequence. **Movement:** what changes, and what makes it change? **Record:** what do we keep when the movement has passed? **Composition:** what can those parts make together? We will return to these questions through a swing, a surface, a sound and a sum. Begin with one cube and one returning height.

## What you bring

Keep the cube from Transformation: one `MeshInstance3D`, a `BoxMesh`, and a position updated from elapsed time. There we made a body travel, turn and change size. Here we open the rule for a movement that keeps returning. We do not need to rebuild its faces or introduce a new body.

**Build:** use a sine function to place the cube along one vertical axis.

**Investigate:** change how far it moves, how often it returns, and where in the cycle it begins. Keep these three decisions separate.

## Work inside the museum

Use your existing `PointStudy` Node3D, under this hall, upright at unit scale. The working bay is hall-local `(6.3, 0, 16.5)` metres. The name of the study node does not restrict it to spheres. The museum supplies floor, lighting, camera and player.

Save `01_cube_return.gd` and attach it to the study. This is the complete program; no companion scripts or named scene children are required. It uses the same cube construction as Transformation, displayed at 0.4 metres across. The overlap sensor from the collection exercise is left out so the cube remains available to observe.

## Complete code — 01_cube_return.gd

<!-- student-code:01_cube_return.gd -->

```gdscript
extends Node3D

@export var amplitude := 0.4
@export var frequency := 0.5
@export var phase := 0.0
var centre := Vector3(0, 1.3, 0)
var elapsed := 0.0
var cube := MeshInstance3D.new()
var label := Label3D.new()

func _ready() -> void:
    assert(amplitude >= 0.0 and frequency >= 0.0)
    cube.mesh = BoxMesh.new()
    cube.scale = Vector3.ONE * 0.4
    add_child(cube)
    label.position = centre + Vector3(0, 0.8, 0)
    label.font_size = 36
    label.pixel_size = 0.0025
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)
    draw_state()

func _process(delta: float) -> void:
    elapsed += delta
    draw_state()

func height_at(seconds: float) -> float:
    return centre.y + amplitude * sin(TAU * frequency * seconds + phase)

func draw_state() -> void:
    cube.position = Vector3(centre.x, height_at(elapsed), centre.z)
    label.text = "time %.2f s   height %.2f m\nA %.2f m   f %.2f Hz   phase %.2f rad" % [
        elapsed, cube.position.y, amplitude, frequency, phase]
```


## Read the movement

`elapsed += delta` keeps time in seconds, as before. `height_at` turns that time into a height. The cube receives the resulting position every frame.

Sine returns a value between −1 and +1. Multiplying by `amplitude` gives the displacement above or below `centre.y`. With amplitude 0.4 metres, the cube's centre travels between 0.9 and 1.7 metres: a total span of 0.8 metres. Amplitude is half that span.

`frequency` counts complete cycles per second, in hertz. At 0.5 Hz, a cycle takes two seconds. `TAU` is one full turn in radians; multiplying it by frequency and time turns elapsed cycles into the angle that sine reads. The Unit Circle hall will make that relationship visible around a circle.

`phase` adds a starting angle, in radians. At phase zero the cube begins at its middle and rises. At `PI / 2.0` it begins at the top. At `PI` it begins in the middle and falls. That middle position alone does not tell us which way the cube is travelling.

The `@export` lines expose these values in the Inspector for each study instance. The instances can share one script while using different parameters.

## Predict one cycle

With the original values and phase zero, predict these heights before running:

| Time | Position in the cycle | Height of the cube's centre |
| --- | --- | --- |
| 0 s | Middle, rising | 1.3 m |
| 0.5 s | Top | 1.7 m |
| 1 s | Middle, falling | 1.3 m |
| 1.5 s | Bottom | 0.9 m |
| 2 s | Middle, rising again | 1.3 m |

Watch the readout in your study. Then change one parameter. Double amplitude: the span doubles while the cycle still takes two seconds. Restore it and double frequency: the span stays the same while the cycle takes one second. Restore frequency and set phase to `PI`: the starting height stays the same, but the first direction reverses.

The formula assigns a height from the centre each time. It does not keep adding the sine value to the previous height. The cube therefore stays within the same band instead of drifting away.

## Build a comparison

Make a second study instance beside the first and attach the same script. Keep their amplitude and frequency equal; give the second a phase of `PI`. Predict when they share a height and when one is at the top while the other is at the bottom. Each instance owns its clock and parameters.

Next give the second cube frequency 1.0 Hz while the first keeps 0.5 Hz. Count both cycles over the same two seconds. Explain which value changed the rate and which only changed the starting part of a cycle.

## Compare with the hall

The installed `y_oscillation_cube` uses this same sine-of-time operation with its own dimensions, rail, markers and trail. Your smaller program isolates the moving cube and its readout. The surrounding rotating and transforming cubes let you recognise other kinds of return without making all of them part of this lesson.

This movement is prescribed by a clock. It does not calculate gravity, collision or a hand's release. A push cannot change a movement rule that never reads it. The pendulum elsewhere in the hall offers a comparison: its next movement depends on its current angle and angular velocity. We will work with that distinction as the sequence continues.

## What travels onward

Keep the cube, elapsed time and the three parameters. The next hall, Pendulum, lets us compare a responding swing with a prescribed cycle and keep a timestamped record. Trace's earlier list returns with another job: making the history of a movement visible.

## Four distinctions for the journey

Return to these names as the encounters change. A similar outline can come from a different operation.

| Operation | What changes | Where we will meet it |
| --- | --- | --- |
| Oscillation | A quantity changes periodically in time. | This returning cube. |
| Spatial pattern | A periodic rule places geometry across space; it can remain still. | Sine Space and Bernini. |
| Propagation through coupling | A disturbance affects neighbouring locations through their relations. | The coupled lattice. |
| Composition | Components combine to produce a result. | Two signed waves in Beats; five weighted harmonics in Synthesis. |

These are distinctions to inspect, not four separate blocks of rooms. A composition can oscillate; a moving pattern can be prescribed without neighbour coupling. Ask what the program reads to produce its next value.
