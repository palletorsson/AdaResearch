# Point Animated Cube

A cube moves through a tween. Keyframes define the targets; interpolation fills the between.

Start with a still cube.

```gdscript
var cube := MeshInstance3D.new()
cube.mesh = BoxMesh.new()
cube.position = Vector3.ZERO
add_child(cube)
```

A default BoxMesh at the origin. Side length 1, sitting on its own axis.

Define two keyframe positions.

```gdscript
const START_POS := Vector3.ZERO
const END_POS := Vector3(3, 1, 0)
const DURATION := 2.0  # seconds
```

The cube will travel from START_POS to END_POS over DURATION seconds.

Create the tween.

```gdscript
var tween := create_tween()
tween.tween_property(cube, "position", END_POS, DURATION)
```

Godot's tween interpolates linearly between the current value and the target. One line replaces a hand-rolled animation loop.

Change the easing.

```gdscript
tween.tween_property(cube, "position", END_POS, DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
```

Elastic transitions produce a bounce at the endpoint. Linear transitions move at constant speed. Each easing has a characteristic rhythm.

Chain transformations.

```gdscript
var tween := create_tween().set_parallel(false)
tween.tween_property(cube, "position", END_POS, 2.0)
tween.tween_property(cube, "rotation", Vector3(0, PI, 0), 1.0)
tween.tween_property(cube, "scale", Vector3(2, 2, 2), 1.5)
```

set_parallel(false) makes the steps sequential. Move, then rotate, then scale — six seconds total.

Run them in parallel.

```gdscript
var tween := create_tween().set_parallel(true)
tween.tween_property(cube, "position", END_POS, 2.0)
tween.tween_property(cube, "rotation", Vector3(0, PI, 0), 2.0)
```

With set_parallel(true), every tween_property starts at the same moment. The cube moves and rotates simultaneously.

Loop the animation.

```gdscript
var tween := create_tween().set_loops()
tween.tween_property(cube, "position", END_POS, 2.0)
tween.tween_property(cube, "position", START_POS, 2.0)
```

set_loops() repeats indefinitely. The cube bounces between the two positions forever.

Read the current animation progress.

```gdscript
func animation_progress(tween: Tween) -> float:
    return tween.get_total_elapsed_time() / tween.get_total_duration()
```

Progress runs from 0 to 1. Useful for triggering side effects at specific moments.

You can now animate a cube between keyframes with custom easing, chain or parallelise transforms, and loop the motion. Primitives_Ignorance will next introduce what a single cube cannot know.

Pause and resume an animation.

```gdscript
var active_tween: Tween

func pause_animation() -> void:
    active_tween.pause()

func resume_animation() -> void:
    active_tween.play()
```

A paused tween freezes at its current value. Resuming picks up where it left off.

Adjust an active tween's target.

```gdscript
func redirect_tween(new_target: Vector3, remaining_time: float) -> void:
    active_tween.stop()
    active_tween = create_tween()
    active_tween.tween_property(cube, "position", new_target, remaining_time)
```

Stopping the current tween and starting a new one retargets the animation mid-flight.
