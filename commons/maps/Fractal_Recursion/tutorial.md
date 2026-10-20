# Recursion — one more frame

**Learning elements**

- A function calling itself
- A smaller argument and a stopping condition
- A finite construction budget

In the museum, press MORE at the frame study. Another frame appears, smaller than the last. Change its arrangement and try the doorway version. A frame your eye can follow may be too small for your body. We will reconstruct the repeated frame; the room's doors and controls already exist.

## Continue with the line

You bring positions, lists, loops and functions from earlier halls. Keep the `LineSkin` supplied in Point Lines. Four segments make one square. The new operation is to call the square-making function again with a smaller size and one fewer step available.

Recursion lets us describe a construction in terms of smaller constructions of the same kind. We write what one frame does and how it asks for the next; we do not write a separate function for every size. This row of nested frames could also be made with a loop. It is our first, simple self-call. In the next hall, one call will ask for two whole subtrees: the same short recipe will organise a branching family. That is the power we are learning to use.

Keep your previous study as a working version. Save `frames.gd` and `line_skin.gd` together and attach `frames.gd` to your existing, empty `PointStudy` Node3D in the prepared museum workspace. Use unit scale; position and rotate the station to face you. The museum supplies the camera, lights and player. This script creates only the study. Do not attach it to the museum's generator or remove the room's existing artifact.

## frames.gd

Run it with `depth = 3`. Predict the sizes before counting the visible frames.

<!-- student-code:frames.gd -->
```gdscript
extends Node3D

const LineSkin = preload("line_skin.gd")
const MAX_DEPTH := 7
const MIN_SIZE := 0.08
@export_range(0, 7) var depth := 3
@export_range(0.25, 0.85) var ratio := 0.65
var sizes: Array[float] = []
var frames: Node3D

func _ready() -> void:
    frames = Node3D.new()
    add_child(frames)
    rebuild()

func rebuild() -> void:
    for child in frames.get_children():
        frames.remove_child(child)
        child.queue_free()
    sizes.clear()
    repeat_frame(Vector3(0, 1.3, 0), 1.8, clampi(depth, 0, MAX_DEPTH))

func repeat_frame(centre: Vector3, size: float, remaining: int) -> void:
    if remaining <= 0 or size < MIN_SIZE:
        return
    sizes.append(size)
    draw_frame(centre, size)
    repeat_frame(centre, size * clampf(ratio, 0.25, 0.85), remaining - 1)

func draw_frame(centre: Vector3, size: float) -> void:
    var half := size * 0.5
    var corners: Array[Vector3] = [
        centre + Vector3(-half, -half, 0),
        centre + Vector3(half, -half, 0),
        centre + Vector3(half, half, 0),
        centre + Vector3(-half, half, 0)
    ]
    for i in range(4):
        var start := corners[i]
        var displacement := corners[(i + 1) % 4] - start
        var line := LineSkin.new()
        frames.add_child(line)
        line.show_segment(start, displacement, displacement.length())
```

`repeat_frame()` receives the centre, the current size and the steps remaining. Its first `if` is the base case: when no step remains, or the square is smaller than our chosen limit, return without drawing.

Otherwise it draws one frame. The last line calls the same function with the same centre, a smaller size and `remaining - 1`. With the default values, the sizes are 1.8, 1.17 and 0.7605 metres. The next call receives zero remaining steps and returns. Each earlier call then finishes.

Trace those calls before changing the code. Each call has its own parameter values; making a child call does not overwrite its parent's `size` or `remaining`.

| Call | Size in metres | Steps remaining | What it does |
| --- | --- | --- | --- |
| First | 1.8 | 3 | Draw; call again with smaller arguments |
| Second | 1.17 | 2 | Draw; call again |
| Third | 0.7605 | 1 | Draw; call again |
| Fourth | 0.494325 | 0 | Return without drawing |

While a child runs, its caller waits at the call. When the fourth returns, the third resumes just after its self-call and finishes; then the second and first finish. The engine keeps these unfinished calls on a **call stack**. A short recipe can therefore require many calls and much geometry. The stopping condition makes the job finite; it does not make that work free.

Either test can stop this example. If one remains reachable, the calls can still finish. If both tests are removed, each call proceeds into another with no programmed end to the chain. The depth clamp only limits the starting value; counting down does not stop a self-call unless the function checks that count.

The loop in `draw_frame()` constructs four sides. Recursion repeats the whole construction. `(i + 1) % 4` returns to the first corner after the fourth; the last line closes the square.

`depth` controls how many frames may be made. `ratio` controls their relative sizes. They are separate choices. The small-size cutoff is another stopping condition: raising the depth does not guarantee that every allowed frame will be drawn. `clampi()` also caps scripted depth requests at seven; the limit applies beyond the Inspector slider.

## Supplied line skin — line_skin.gd

This is the same finite cylinder renderer from Point Lines, printed here so the example has no missing helper. Its thickness makes an abstract segment visible. Keep it unchanged for this lesson.

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

## Make a prediction of your own

Change `ratio` to 0.5 and keep `depth` at 3. Before running, write down the three sizes. They should be 1.8, 0.9 and 0.45. Explain why there are still three frames. Now set depth to zero: no frame should be created. Restore depth to three.

You should be able to change the reduction and predict the result without replacing the drawing function. The next hall keeps the stopping condition but lets a call make two children. Shorter pieces can then produce many more pieces.
