# Fractals — complete tutorial

8 October 2026. All seven current canonical manuscripts in spine order. Full code retained; source snapshots are included.



---

<a id="Fractal_Recursion"></a>

**01 / 07 · Recursion**

## Recursion — one more frame

**Learning elements**

- A function calling itself
- A smaller argument and a stopping condition
- A finite construction budget

In the museum, press MORE at the frame study. Another frame appears, smaller than the last. Change its arrangement and try the doorway version. A frame your eye can follow may be too small for your body. We will reconstruct the repeated frame; the room's doors and controls already exist.

### Continue with the line

You bring positions, lists, loops and functions from earlier halls. Keep the `LineSkin` supplied in Point Lines. Four segments make one square. The new operation is to call the square-making function again with a smaller size and one fewer step available.

Keep your previous study as a working version. Save `frames.gd` and `line_skin.gd` together and attach `frames.gd` to your existing, empty `PointStudy` Node3D in the prepared museum workspace. Use unit scale; position and rotate the station to face you. The museum supplies the camera, lights and player. This script creates only the study. Do not attach it to the museum's generator or remove the room's existing artifact.

### frames.gd

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

The loop in `draw_frame()` constructs four sides. Recursion repeats the whole construction. `(i + 1) % 4` returns to the first corner after the fourth; the last line closes the square.

`depth` controls how many frames may be made. `ratio` controls their relative sizes. They are separate choices. The small-size cutoff is another stopping condition: raising the depth does not guarantee that every allowed frame will be drawn. `clampi()` also caps scripted depth requests at seven; the limit applies beyond the Inspector slider.

### Supplied line skin — line_skin.gd

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

### Make a prediction of your own

Change `ratio` to 0.5 and keep `depth` at 3. Before running, write down the three sizes. They should be 1.8, 0.9 and 0.45. Explain why there are still three frames. Now set depth to zero: no frame should be created. Restore depth to three.

You should be able to change the reduction and predict the result without replacing the drawing function. The next hall keeps the stopping condition but lets a call make two children. Shorter pieces can then produce many more pieces.


---

<a id="Fractal_RecursiveTrees"></a>

**02 / 07 · Recursive Trees**

## Recursive Trees — turn one fork

**Learning elements**

- Two recursive calls from one branch
- Parent and child transforms
- Inherited direction and length
- A local edit that preserves the other subtree

Press GROW beside the small tree. Hold one of its two points and turn the first branch. Its descendants follow. The other side stays. Look up: the large canopy receives the same edit. Release the point, then add another generation. Its new branches begin at the tips you moved.

The sphere still acts as a point you can hold. The line still gives two positions a visible span. We now arrange those spans in a hierarchy, so you can change a family of branches without dragging every endpoint.

### What continues

Keep the museum workspace, XR hands and the `LineSkin` from the previous lesson. Save `tree.gd`, `point_body.gd` and `line_skin.gd` together. On your empty `PointStudy` node, replace `frames.gd` with `tree.gd`; keep the frame script as your previous working version. Use unit scale and place the station with clear space in front of you. The script creates a small tree and two grips inside the existing museum environment.

This is the minimal reconstruction of the fork interaction. The museum artifact additionally supplies the growth buttons, readout, large solid canopy and alternative branching settings. Our study uses two children and a fixed 35-degree turn. Its `generations` Inspector value sets the whole tree before running. Re-run to rebuild; the study does not add another set of museum controls.

### tree.gd

<!-- student-code:tree.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
@export_range(1, 4) var generations := 3
@export_range(0.4, 0.8) var ratio := 0.7
const TURN := PI * 35.0 / 180.0
var tree: Node3D
var first_forks: Array[Node3D] = []
var points: Array = []
var segment_count := 0

func _ready() -> void:
    tree = branch(0.7, clampi(generations, 1, 4))
    tree.position = Vector3(0, 0.60, 0)
    add_child(tree)
    for child in tree.get_children():
        if child.has_meta("length"):
            first_forks.append(child)
    for i in range(2):
        var point = PointBody.new()
        point.tint = Color("e99db8") if i == 0 else Color("25212a")
        add_child(point)
        points.append(point)
        park_point(i)

func branch(length: float, remaining: int) -> Node3D:
    var joint := Node3D.new()
    joint.set_meta("length", length)
    var line := LineSkin.new()
    joint.add_child(line)
    line.show_segment(Vector3.ZERO, Vector3.UP * length, length)
    segment_count += 1
    if remaining <= 0:
        return joint
    for sign_value in [-1.0, 1.0]:
        var child := branch(length * clampf(ratio, 0.4, 0.8), remaining - 1)
        child.position = Vector3.UP * length
        child.rotation.z = TURN * sign_value
        joint.add_child(child)
    return joint

func _process(_delta: float) -> void:
    for i in range(2):
        if points[i].held():
            var fork := first_forks[i]
            var parent: Node3D = fork.get_parent()
            var displacement := parent.to_local(points[i].global_position) - fork.position
            turn_fork(i, displacement)
        else:
            park_point(i)

func turn_fork(index: int, displacement: Vector3) -> void:
    if not displacement.is_finite() or displacement.length() < 0.001:
        return
    var horizontal := Vector3(displacement.x, 0, displacement.z)
    if horizontal.length() < 0.001:
        return
    var angle := clampf(atan2(horizontal.length(), displacement.y), deg_to_rad(12), deg_to_rad(65))
    var direction := Vector3.UP * cos(angle) + horizontal.normalized() * sin(angle)
    first_forks[index].basis = Basis(Quaternion(Vector3.UP, direction))

func park_point(index: int) -> void:
    var fork := first_forks[index]
    var tip := Vector3.UP * float(fork.get_meta("length"))
    points[index].global_position = fork.to_global(tip)
```

`branch()` makes a joint and draws one line upwards from it. It returns that joint, including anything attached below it. When `remaining` is zero, the visible branch is the last one: it gets no children. Here `generations` counts the generations **after the trunk**. Three gives 1 + 2 + 4 + 8 = 15 segments; four gives 31.

The two loop values give opposite turns. Each loop iteration calls `branch()` again with a shorter length and one fewer generation. The returned child is placed at the parent's tip, turned, then attached to that parent. Its children have already been made by the same rule. This is a depth-first construction: finish one subtree, then make its sibling.

Earlier, local and world coordinates described a point relative to a room. Here every child has a local position relative to its parent branch. `child.position = Vector3.UP * length` puts its origin at that parent's end. Moving or turning the parent carries the children through their existing attachments. The scene tree performs that inheritance; we do not recalculate every descendant in `_process()`.

The two grips control only the first fork. While one is held, we convert its world position into its branch parent's coordinates, subtract the attachment position and obtain a direction. `turn_fork()` aligns the branch's local Y axis to that direction. The quaternion line is a supplied alignment operation: it turns one axis towards another. Length is unchanged. The 12–65-degree limit keeps this particular hand study within a manageable arc; it is an interface choice, not a law of recursion. Pulling farther does not lengthen a branch.

On release, `park_point()` places the grip back at the represented endpoint. Its handle is an editing tool; it is not a free endpoint that stretches the branch. The other first fork has a different parented subtree, so turning one does not turn both.

### The familiar point — point_body.gd

This keeps the sphere, matching collider and frozen XRTools pickup construction from Point Lines. The radius is reduced to 8.5 cm for this small model. A material distinguishes the two grips. The small `held()` adapter also recognises the museum's existing desktop pickup and drop hooks. XR Tools still supplies the actual hand attachment; the tutorial does not rebuild the player.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

### The same line skin — line_skin.gd

Keep this supplied renderer unchanged. The new work is the relationship between branches.

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

### Test a different tree

Set `generations` to 4. Predict 31 segments, then run. Turn the rose point out of the original plane. Follow one of its terminal twigs and compare it with a twig on the black side. The first must move; the second must stay. Release the point and check that no branch has gained length or lost its attachment.

Change `ratio` from 0.7 to 0.5 and run again. Predict which property changes and which stays: the tree reaches less far but still has 31 segments. This is the independent test of the lesson: distinguish a change in geometry from a change in the number of branches.

### Back at the large canopy

The museum source evaluates its branching rule through a queue of unfinished tips. GROW advances a complete generation; it does not use the depth-first call order of our small study. It also stores branch positions in one shared local frame. Its hand editor explicitly turns the selected branch records, their descendants and their pending tips. Our nested nodes make the same inheritance visible with less machinery. These are two implementations of the relation, not identical scripts or an exact geometric copy.

The small museum model and large canopy, however, really do share the source's branch records. Their scale differs; their branching decisions do not. ANGLE and LENGTH on the original desk change the whole rule and rebuild the specimen. The point grips make a local edit. Release both before using those controls or RESET.

Carry the bounded self-call onward. In Cantor Set, the next decision will be which part of an interval is retained, removed and passed to another call.


---

<a id="Fractal_CantorSet"></a>

**03 / 07 · Cantor Set**

## Cantor Set — keep the two ends

**Learning elements**

- An interval recorded as a start and a length
- Replacing each entry with two entries
- Separate current and next arrays
- Retained length and generation history

Take the rose point above the small bar. Pull its middle towards you, past the rose mark, and release. The large bar becomes two. Repeat: every interval loses its own middle third. Your hand makes one gesture; the rule applies it across the current row.

The small bar is **one interval enlarged**, not the whole row in miniature. Its apparent size stays useful for your hand while the represented length falls. NEXT beside it performs the same cut. BACK and RESET return to earlier states. HISTORY shows the saved rows; GHOST marks removals without giving them collision.

### What continues

Keep the museum workspace and the small `PointBody` from Recursive Trees. There it turned a branch; here it carries the middle third. We already know arrays from Trace and loops from Arrays. Now a loop constructs a new array from an old one.

Save `cantor.gd` beside the unchanged `point_body.gd`. Replace the script on your empty, unit-scale `PointStudy` node with `cantor.gd`; keep the earlier tree script. Place the study where you can stand in front of its positive Z side. The existing museum supplies the camera, light, player and XR pickup functions. The script creates all its own objects and looks up no scene nodes.

This small reconstruction makes the interval rows and the hand control. The production artifact adds the plinth, comparison buttons, ghosts and full-size bars. The pagoda remains a second encounter with the same rule; rebuilding its architecture is not another assignment here.

### A record for one span

`Vector2(0, 6)` stores **start = 0, length = 6 metres** along a local horizontal line. These two numbers are data, not an XY position. The interval ends at `start + length`.

For its first cut, `kept` is 2. The new records are `(0, 2)` and `(4, 2)`. They cover 0–2 and 4–6. We never construct a solid for 2–4. On the next cut, use each record's own start and length.

The new function reads `intervals` and fills a separate `next` array. Only when that loop finishes does `advance()` replace `current`. Appending children to the array we are still reading would mix generations. `original.duplicate()` preserves the starting record; another copy records each completed row in `history`. `Vector2` entries are values, so these array copies are sufficient here.

### cantor.gd

Read `replace_intervals()` first. The rest connects that operation to the point you already hold and gives the numbers a visible form.

<!-- student-code:cantor.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const HOME := Vector3(0, 1.27, 0.45)
const VIEW_SCALE := 0.2
@export var show_history := false
var original: Array[Vector2] = [Vector2(0, 6)]
var current: Array[Vector2] = []
var history: Array = []
var rows: Node3D
var point: XRToolsPickable
var readout: Label3D
var was_held := false

func _ready() -> void:
    current = original.duplicate()
    history.append(current.duplicate())
    rows = Node3D.new()
    add_child(rows)
    point = PointBody.new()
    point.tint = Color("e99db8")
    add_child(point)
    for x in [-0.4, 0.4]:
        bar(self, Vector3(x, 1.15, 0.45), 0.4, Color("28252c"))
    bar(point, Vector3(0, -0.12, 0), 0.4, Color("e99db8"))
    readout = Label3D.new()
    readout.position = Vector3(0, 1.98, 0)
    readout.font_size = 24
    readout.pixel_size = 0.001
    add_child(readout)
    park()
    redraw()

func replace_intervals(intervals: Array[Vector2], fraction: float = 1.0 / 3.0) -> Array[Vector2]:
    assert(fraction > 0.0 and fraction < 0.5)
    var next: Array[Vector2] = []
    for interval in intervals:
        var start := interval.x
        var length := interval.y
        var kept := length * fraction
        next.append(Vector2(start, kept))
        next.append(Vector2(start + length - kept, kept))
    return next

func advance() -> void:
    if point.held() or history.size() >= 6:
        return
    current = replace_intervals(current)
    history.append(current.duplicate())
    redraw()

func kept_length(intervals: Array[Vector2]) -> float:
    var total := 0.0
    for interval in intervals:
        total += interval.y
    return total

func _physics_process(_delta: float) -> void:
    var holding: bool = point.held()
    if was_held and not holding:
        var release := to_local(point.global_position)
        if release.z - HOME.z >= 0.30:
            advance()
    if not holding:
        park()
    was_held = holding

func park() -> void:
    point.global_transform = global_transform * Transform3D(Basis.IDENTITY, HOME)

func redraw() -> void:
    for child in rows.get_children():
        rows.remove_child(child)
        child.queue_free()
    var first := 0 if show_history else history.size() - 1
    for generation in range(first, history.size()):
        for interval: Vector2 in history[generation]:
            var centre := (interval.x + interval.y / 2.0 - 3.0) * VIEW_SCALE
            var at := Vector3(centre, 1.8 - generation * 0.16, 0)
            bar(rows, at, interval.y * VIEW_SCALE, Color("28252c"))
    readout.text = "cut %d / 5 | %d pieces | %.3f m kept\nPull the middle towards you 30 cm, then release" % [history.size() - 1, current.size(), kept_length(current)]

func bar(host: Node3D, at: Vector3, width: float, colour: Color) -> void:
    var surface := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = Vector3(width, 0.05, 0.06)
    surface.mesh = shape
    var finish := StandardMaterial3D.new()
    finish.albedo_color = colour
    surface.material_override = finish
    surface.position = at
    host.add_child(surface)
```

The transition from held to released triggers one cut. Crossing the threshold while still holding changes nothing. Return the point before releasing to cancel. `to_local()` measures the withdrawal in the study's frame, even if you turn the whole station. `park()` returns the control after release. Five cuts is our deliberate limit.

`bar()` reuses the box mesh we already know. `VIEW_SCALE` fits six represented metres into a 1.2-metre drawing. The counts and lengths use the interval data, not that display scale. These small bars have no collision: they are a drawing of intervals. The point still has its pickup shape.

The two recursive child calls in Trees and the two appends here share a branching pattern. This script uses a loop to make one complete generation per gesture. It does not call itself; the hand decides when the next generation begins.

### Predict, then cut

After two releases you should have four records, each 2/3 metre long, with 8/3 metres retained in total. After five: 32 pieces, each 6/243 metre, retaining 64/81 metre. More entries, less material.

Enable `show_history` in the Inspector and run again. Make the same cuts. The drawing now includes the old rows, but the latest count and retained length must stay the same. At five cuts there are 63 drawn bars across the history and 32 current intervals. `original` is still `[(0, 6)]`.

For an independent variation, change the call to `replace_intervals(current, 0.25)`. Predict the two records after one cut before running: `(0, 1.5)` and `(4.5, 1.5)`. This keeps the outer quarters and removes the middle half. It is a different rule from the middle-third Cantor construction. The small hand model still depicts thirds; resize its three parts before presenting your variant as a matching exhibit. A legal fraction here is greater than zero and less than one half.

### Bring the question to the pagoda

Walk up the existing ramp and try its broad opening. Two presses of CUT add smaller openings alongside it. The same interval rule has been given height, depth and collision. A positive gap width does not guarantee a passage for the player's collision body.

What travels onward is the replacement function and the distinction between a current result and its record. These arrays live for the study's lifetime; this lesson does not save them across halls. Koch will replace each segment with a detour and increase length instead. Before changing the rule, keep this version so you can compare what each replacement preserves.

### The carried point file

This is the same `point_body.gd` as in Recursive Trees, included so the two-file example is complete. Its XR pickup and desktop hooks are existing knowledge; they are not new steps in the interval algorithm.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```


---

<a id="Fractal_KochSierpinski"></a>

**04 / 07 · Koch / Sierpinski**

## Koch / Sierpinski — the distance between

**Learning elements**

- An ordered path of positions
- Replacing one segment with four
- Current and next arrays
- A turn in a declared plane
- Endpoint distance and path length

Hold the black point on the small line beside the Koch desk. Move it along the drawing. Its partner follows the larger line on the floor. Press the trigger once: the line takes a detour. Find the two ends again. They are still four represented metres apart.

NEXT beside your hand makes the same replacement. BACK and RESET let you compare stages; the original desk also offers TURN and FORM. Each step replaces **every current segment**, including those already climbing or descending. The readout gives the distance between the ends, the complete path length, and your point's place along that path.

### What continues

Keep the museum workspace. We bring `PointBody` from Cantor and `LineSkin` from Recursion. Trace taught us to keep positions in order and connect neighbouring entries. Cantor taught us to read `current`, construct a separate `next`, then change which record is current. Here that pattern adds a detour instead of removing a middle.

Save the three files below together. Put `koch.gd` on your existing empty, unit-scale `PointStudy` node, facing its positive Z side. Keep the previous lesson's script. The museum already supplies the light, camera, player and XR pickup functions. This script creates its own drawing and point, with no scene-node references.

Hold the point and press its trigger to replace once. On desktop, press Enter (`ui_accept`); use the existing pickup/drop interaction to move the point. The complete small study stops after four steps. Run it again to return to the seed. Its purpose is the open Koch path; the production hall adds the table, floor receiver, BACK/RESET controls and closed-triangle comparison.

### Four segments from two ends

The seed is `(-2, 0, 0)` to `(2, 0, 0)`. These are positions in a **local XY construction plane**. `third = (end - a) / 3` is a displacement, with both direction and length.

Place `b` one third from `a`, and `d` two thirds from `a`. From `b`, turn that displacement sixty degrees about positive Z (`Vector3.BACK`) to find `c`. The path goes **a → b → c → d → end**. Its middle makes two sides of an equilateral triangle. Each of the four new segments has a third of the old length.

`replace_path()` appends `a`, `b`, `c` and `d` for every old segment. The next segment supplies the shared endpoint; only the very last endpoint needs a separate append. One segment therefore needs two positions, four segments need five, and 256 segments need 257. This list describes connections through order.

### koch.gd

Read `replace_path()`, `advance()` and `path_length()` first. The remaining functions connect the known point to the drawing. The closest-point reader is supplied in full below those operations.

<!-- student-code:koch.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const VIEW_SCALE := 0.3
const ORIGIN := Vector3(0, 1.2, 0.2)
var original: Array[Vector3] = [Vector3(-2, 0, 0), Vector3(2, 0, 0)]
var current: Array[Vector3] = []
var generation := 0
var point: XRToolsPickable
var drawing: Node3D
var readout: Label3D
var cursor := Vector3.ZERO
var along := 0.0

func _ready() -> void:
    current = original.duplicate()
    drawing = Node3D.new()
    add_child(drawing)
    point = PointBody.new()
    add_child(point)
    point.action_pressed.connect(func(_body): advance())
    readout = Label3D.new()
    readout.position = Vector3(0, 1.85, -0.3)
    readout.font_size = 24
    readout.pixel_size = 0.001
    add_child(readout)
    redraw()

func replace_path(path: Array[Vector3], side: float = 1.0) -> Array[Vector3]:
    assert(path.size() >= 2 and absf(side) == 1.0)
    var next: Array[Vector3] = []
    for i in path.size() - 1:
        var a := path[i]
        var end := path[i + 1]
        var third := (end - a) / 3.0
        var b := a + third
        var c := b + third.rotated(Vector3.BACK, side * PI / 3.0)
        var d := a + third * 2.0
        next.append_array([a, b, c, d])
    next.append(path[-1])
    return next

func advance() -> void:
    if generation == 4:
        return
    current = replace_path(current)
    generation += 1
    redraw()

func path_length(path: Array[Vector3]) -> float:
    var total := 0.0
    for i in path.size() - 1:
        total += path[i].distance_to(path[i + 1])
    return total

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_accept"):
        advance()

func _physics_process(_delta: float) -> void:
    if point.held():
        var local := (to_local(point.global_position) - ORIGIN) / VIEW_SCALE
        var reading := nearest_on_path(Vector3(local.x, -local.z, 0))
        cursor = reading.point
        along = reading.along
    else:
        point.global_transform = global_transform * Transform3D(Basis.IDENTITY, display(cursor))
    readout.text = "step %d / 4 | %d segments\nends %.3f m | path %.3f m | at %.3f m along" % [generation, current.size() - 1, current[0].distance_to(current[-1]), path_length(current), along]

# Supplied reader: closest point on the finite drawing, with distance from its start.
# This does not measure the length of the player's hand movement.
func nearest_on_path(query: Vector3) -> Dictionary:
    var best := INF
    var prefix := 0.0
    var answer := {"point":current[0], "along":0.0}
    for i in current.size() - 1:
        var a := current[i]
        var delta := current[i + 1] - a
        var t := clampf((query - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
        var p := a + delta * t
        if p.distance_squared_to(query) < best:
            best = p.distance_squared_to(query)
            answer = {"point":p, "along":prefix + t * delta.length()}
        prefix += delta.length()
    return answer

func display(p: Vector3) -> Vector3:
    return ORIGIN + Vector3(p.x, 0, -p.y) * VIEW_SCALE

func redraw() -> void:
    for child in drawing.get_children():
        drawing.remove_child(child)
        child.queue_free()
    for i in current.size() - 1:
        var start := display(current[i])
        var displacement := display(current[i + 1]) - start
        var line = LineSkin.new()
        drawing.add_child(line)
        line.mesh.top_radius = 0.002
        line.mesh.bottom_radius = 0.002
        line.show_segment(start, displacement, displacement.length())
    cursor = current[0]
    along = 0.0
```

The loop finishes before `current` is replaced. The original seed stays intact. Like Cantor, this implementation makes one generation per action rather than calling itself to complete every generation at once.

`path_length()` adds the distance between **each neighbouring pair**. Endpoint distance uses only the first and last positions. After one replacement those readings are 16/3 metres and 4 metres. After four they are about 12.642 metres and 4 metres. The arithmetic is `4 × (4/3)^n`; it belongs to this particular sixty-degree, thirds rule.

### Reading is another operation

`display()` lays the XY construction onto a horizontal XZ drawing. `VIEW_SCALE` makes four represented metres fit into 1.2 physical metres. It does not change the stored positions or the length calculation. The supplied LineSkin gives each connection a thin visible cylinder; it supplies no collision.

The hand remains free while held. The reader finds the nearest point on any segment, then adds the lengths of the preceding segments. On release the ball parks at that reading. It does not drag you or force your hand to follow the path. If you skip from one fold to another, the reading jumps. **“At 3 metres along” is an address on this path, not proof that your hand travelled 3 metres.**

Small folds may become hard to select with this sphere or distinguish in the headset. The exact finite record and the useful size of a gesture have different limits. The larger floor drawing gives the same route another scale; it remains a drawing supported by the existing floor, not a narrow balance beam.

### Predict, then change

Before the second step, predict sixteen segments and seventeen positions. Each segment should be 4/9 metre; their total should be 64/9 metres. Neither endpoint should move. After the fourth step, another trigger should leave the record unchanged.

For your own variation, change the call to `replace_path(current, -1.0)` and run again. Predict which coordinates will change sign. The first peak moves below the starting line. Count, segment lengths and endpoint distance stay the same. This reverses the sixty-degree turn; changing the angle itself would require a new length calculation rather than borrowing the same formula.

Now try a sloping seed in the XY plane, for example `(-1, -1, 0)` to `(1, 1, 0)`. Predict its starting length and its first replacement length. The rule uses each segment's displacement, so the peaks turn with the segment. Arbitrary out-of-plane endpoints need another declared construction plane; this lesson does not supply one.

### Across the aisle

At the existing Sierpinski triangle, press NEXT and find the missing middle. Three midpoint pairs give three corner triangles. Each corner has half the side length and a quarter of the area, so three quarters of the parent's area remain. The next generation applies that same replacement to every retained triangle.

Compare the two operations: Koch keeps the connection and increases length; Sierpinski keeps three corners and reduces area. VIEW changes whether retained corners or removed middles receive meshes, without changing the replacement rule. These are distinct constructions using a familiar current/next pattern. Rebuilding every artifact in this hall is not another assignment.

The optional box-counting desk changes its measurement grid over a held sample. Leave it for a separate investigation if needed. The next main construction is Menger: carry the replacement pattern from a segment and a triangle into cells of a cube.

### The carried files

These are unchanged from the earlier lessons. `PointBody` supplies pickup, release and the trigger signal inherited from XRTools. `LineSkin` places a cylinder between two ends. They are printed here so the example has no missing code dependency; the prepared museum still supplies XRTools and the player.

#### point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

#### line_skin.gd

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


---

<a id="Fractal_MengerSponge"></a>

**05 / 07 · Menger Sponge**

## Menger — a cell and a room

**Learning elements**

- Three-dimensional cell addresses
- A Boolean selection rule
- Replacing each retained cube
- Count, edge length and retained volume
- Model scale and bodily access

The nine-metre cube is still solid. Beside its desk, hold the black point and move it through the transparent hand model. A small frame finds one of twenty-seven cells; a larger frame marks the same address on the cube. Read KEEP or REMOVE. The point is inspecting the rule, not cutting a new hole wherever you put it.

Press its trigger once, or NEXT. The centre and the six face centres disappear. The corner cells and edge middles remain. Follow one of the new openings with your eyes before requesting another cut. The second cut repeats that selection **inside every retained cube**.

### What continues

Keep the museum workspace and the PointBody class from the previous halls. We already have a cube mesh, three coordinates, nested grid loops, and Cantor's pattern of making a separate `next` array. Koch used an ordered position list to connect neighbours. Here the positions locate **cube centres**; their order does not make a path.

Save the two files below together. Attach `menger.gd` to the existing empty, unit-scale `PointStudy` node in your museum workspace. Keep your Koch script separately. The museum supplies its camera, light, player and XR pickup functions. This script creates every node it needs; it does not refer to hidden scene children.

Hold the point and press its trigger, or press Enter (`ui_accept`) on desktop, to replace once. Two cuts are enough. Run the study again to reset. The complete student example makes a small transparent model and a cell reader. The full-size museum adds solid collision, the highlighted cell frames, BACK/RESET and its existing flight enclosure.

### Which cells remain?

Start with one centre at `(0, 0, 0)` and an edge length of nine represented metres. Divide each edge into three. Every child is three metres wide, and its centre is one child width left, central or right of the parent's centre along each axis.

The three nested loops try offsets `-1`, `0` and `1`: twenty-seven combinations. Zero means the middle along that axis. Count how many coordinates are zero. The centre has three; a face centre has two; an edge middle has one; a corner has none. **Keep fewer than two middles.** That keeps twelve edge middles and eight corners: twenty children.

`keep_cell()` is a Boolean function: it answers yes or no. `int(true)` contributes one to the count, and `int(false)` contributes zero. The museum's original generator lists the twenty retained indices explicitly. This predicate makes the same selection. Its addresses run from zero to two; add one to each of our offsets to compare them.

### menger.gd

Read `keep_cell()`, `replace_cells()` and `advance()` first. `redraw()` uses the familiar BoxMesh. The last functions connect the carried point to the first-level address reader.

<!-- student-code:menger.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LIMIT := 2
const VIEW_SCALE := 0.09
const VIEW_CENTER := Vector3(0, 1.43, 0)
var current: Array[Vector3] = [Vector3.ZERO]
var edge := 9.0
var generation := 0
var drawing := Node3D.new()
var point := PointBody.new()
var readout := Label3D.new()
var selected := Vector3i(0, 0, 1)

func _ready() -> void:
	add_child(drawing)
	point.position = Vector3(0, 1.35, 0.56)
	add_child(point)
	point.action_pressed.connect(func(_body): advance())
	readout.position = Vector3(0, 2.05, 0)
	readout.font_size = 32
	readout.pixel_size = 0.001
	add_child(readout)
	redraw()

func keep_cell(offset: Vector3i) -> bool:
	var middles := int(offset.x == 0) + int(offset.y == 0) + int(offset.z == 0)
	return middles < 2

func replace_cells(centres: Array[Vector3], parent_edge: float) -> Array[Vector3]:
	var next: Array[Vector3] = []
	var child_edge := parent_edge / 3.0
	for centre in centres:
		for z in range(-1, 2):
			for y in range(-1, 2):
				for x in range(-1, 2):
					var offset := Vector3i(x, y, z)
					if keep_cell(offset):
						next.append(centre + Vector3(offset) * child_edge)
	return next

func advance() -> void:
	if generation == LIMIT:
		return
	current = replace_cells(current, edge)
	edge /= 3.0
	generation += 1
	redraw()

func retained_volume() -> float:
	return current.size() * edge * edge * edge

func redraw() -> void:
	for old in drawing.get_children():
		drawing.remove_child(old)
		old.queue_free()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * edge * VIEW_SCALE
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.91, 0.89, 0.86, 0.32)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for centre in current:
		var cube := MeshInstance3D.new()
		cube.mesh = mesh
		cube.material_override = material
		cube.position = VIEW_CENTER + centre * VIEW_SCALE
		drawing.add_child(cube)
	update_readout()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		advance()

func _physics_process(_delta: float) -> void:
	if point.held():
		var p := (to_local(point.global_position) - VIEW_CENTER) / VIEW_SCALE
		selected = Vector3i(clampi(roundi(p.x / 3.0), -1, 1), clampi(roundi(p.y / 3.0), -1, 1), clampi(roundi(p.z / 3.0), -1, 1))
		update_readout()
	else:
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.35, 0.56))

func update_readout() -> void:
	readout.text = "%d cubes · %.0f m3 retained · cut %d / 2\nFirst-cell offset %s: %s" % [current.size(), retained_volume(), generation, selected, "KEEP" if keep_cell(selected) else "REMOVE"]
```

`replace_cells()` reads the old centres and returns a new list. Each new position is a parent's centre plus a scaled offset. Only after that list is complete does `advance()` replace `current` and divide `edge` by three. Every current cube has the same size, so one `edge` value describes them all. Mixed-size cells would need a size stored with each centre.

Like Cantor and Koch, one action produces one generation. This is repeated replacement, implemented with loops; a function does not need to call itself to make the finite construction.

### More cubes, less volume

Predict the count and edge length before the second cut. Twenty parents each keep twenty children: four hundred cubes, each one metre wide. Their retained volume is four hundred cubic metres. The previous stage had twenty cubes, each three metres wide: `20 × 3 × 3 × 3 = 540` cubic metres.

| Cut | Cubes | Edge of each cube | Retained volume |
| --- | ---: | ---: | ---: |
| 0 | 1 | 9 m | 729 m³ |
| 1 | 20 | 3 m | 540 m³ |
| 2 | 400 | 1 m | 400 m³ |

The general readings are `20^n` cubes and `729 × (20/27)^n` cubic metres. The outside still spans nine metres: all eight outer corners survive. Count, occupied volume and outer bounds answer different questions.

`VIEW_SCALE` fits those nine represented metres into a hand model 0.81 metres wide. The volume calculation uses the stored geometry, not the display size. Transparency lets you inspect interior addresses; it is a drawing choice. The model has no cube colliders. The large museum sponge does.

### Read a cell, then enter a space

Move the point to a corner of the small model. Its readout says KEEP. Move to the middle of a face: REMOVE. The reader divides by the display scale, then rounds to the nearest first-level cell centre and clamps each coordinate to the three available values. The point stays free in your hand; on release it returns to the near edge so it is available again.

After the second cut, the reader **still names a first-level cell**, not one of the four hundred tiny children. A kept cell now contains its own removals. KEEP describes its role in the first replacement; it does not promise that the whole selected region remains filled.

At the museum desk, GHOST reveals the removed volumes and FRAME keeps the original outer bounds visible. These views change neither the retained cubes nor their collision. Turn GHOST off, enter the ground doorway and rise toward the central opening. In VR, tilt the left controller and use its stick; release to hover. On desktop, use WASD, Space to rise and Ctrl to descend. Leave through a ground doorway to walk again.

The main passage is three metres across. The smaller axial openings after two cuts are one metre across and one metre high. Seeing through an opening does not establish that your body fits. The existing enclosure supplies flight; this lesson does not rebuild the player. The desk refuses solid changes while a visitor remains inside. Leaving does not execute a queued change: press again.

### Make a different selection

Predict what happens if `keep_cell()` returns `middles == 0`. Only the eight corners survive. One cut gives eight cubes; two give sixty-four. Their final edges are still one metre, their total volume is sixty-four cubic metres, and the outside still spans nine metres.

Make that one change in your small study. Compare the result with your prediction, then restore the Menger rule. This produces a different construction, not a more accurate sponge. Its corners preserve the bounds while its face connections disappear. Do not transfer it automatically into the occupied full-size structure.

You now have a selection function that can be stated, changed and checked independently of its display. The next hall changes the recurrence: a new number comes from the previous two. Before treating its drawing as a spiral, we will ask what the sequence itself supplies.

### The carried point

`point_body.gd` is unchanged from Cantor and Koch. It supplies pickup, release and the trigger signal inherited from XRTools. It is printed again as a complete dependency, not as a new assignment. The prepared museum still supplies XRTools and the player.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```


---

<a id="Fractal_GoldenSpiral"></a>

**06 / 07 · Golden Spiral**

## Two values, two views

**Learning elements**

- Numerical recurrence: add the previous two values.
- Append to an ordered array; retain its earlier entries.
- Pass the same record to two height functions.
- Detect one contact; release before accepting another.

### In the museum

Menger replaced each cube with a new generation. Here a new entry joins a record whose earlier values remain. At the first desk, two points carry the last two numbers. They begin at one and one. Predict the sum, then move one point against the other. Two appears in the row. Holding them together adds only once. Release both before asking for another sum; one hand can move a point to its resting partner. The held trigger also requests one step. NEXT, BACK and RESET stay beside you.

The points have the same size. Their labels carry quantities; their distance is only an interaction threshold. The new row on the left gives height a fixed unit. The row on the right compresses the larger values. Both read the same list. The large towers retain HEIGHT, SUM and RULE: SUM provides a fixed-unit witness of the last addition.

### Continue with the point and the cube

Use the prepared Endless Museum workspace. Save the two files below together and attach `sum_points.gd` to an empty, unit-scale Node3D on the floor of the workspace. Its front is local +Z. The museum supplies the camera, lighting, player and installed XRTools. This example creates its own points, labels and two rows; it needs no named scene children or dollar references. Keep your existing PointBody file if it is identical to the included version.

The installed artifact uses this same construction through a small adapter. Its values come from the existing Fibonacci desk, and adding calls that desk's NEXT. Your small script owns its list and computes each new value itself. The museum supplies the plinth and nearby buttons. You do not rebuild the surrounding helix, rectangle or player.

### Read two entries, append one

`values` begins as `[1, 1]`. Negative indices count backwards: `values[-1]` is the last entry; `values[-2]` is the preceding one. `advance()` reads both **before** appending their sum. The first request gives `[1, 1, 2]`; the next reads 1 and 2, giving `[1, 1, 2, 3]`. No earlier entry is replaced.

This is a recurrence: the next value depends on earlier values. The function does not call itself. Each gesture or Enter press asks for one more entry, up to ten. The interaction's `latched` Boolean keeps a contact lasting many physics frames from producing many sums. Releasing both points returns them to their places and clears the latch. This reuses the threshold and state reasoning from Trace and the interaction lessons.

`redraw()` loops over this record twice. `height_for(value, true)` gives each unit 0.05 metres. The other call uses the supplied natural logarithm `log`: `0.5 * log(value) + 0.5`. For 1, 2 and 55, those unscaled heights are approximately 0.500, 0.847 and 2.504 metres, compared with 0.050, 0.100 and 2.750 in the linear view. Logarithms need no derivation in this lesson; inspect what this declared mapping does.

Both rows then use the same `DISPLAY_SCALE = 0.2` to fit the hand table. The small linear row therefore gives one unit **one centimetre**. This common display reduction is separate from the choice of height rule. Neither mapping writes into `values`. A BoxMesh gives each entry a body; moving its centre by half its height keeps every base at the same level.

### The complete small construction

Hold a point and bring it to its partner, press its trigger, or use Enter. Release both points between held requests. Run the small study again to reset; the museum installation also has the nearby BACK and RESET buttons. A value is revealed by either request method, never by an automatic timer.

#### sum_points.gd

<!-- student-code:sum_points.gd -->
```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const LIMIT := 10
const DISPLAY_SCALE := 0.2
var values: Array[int] = [1, 1]
var points: Array[XRToolsPickable] = []
var names: Array[Label3D] = []
var drawing: Node3D
var readout: Label3D
var latched := false

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	for i in 2:
		var point = PointBody.new()
		point.tint = Color("76d9d1") if i == 0 else Color("ffa366")
		add_child(point)
		point.position = home(i)
		point.action_pressed.connect(request_step)
		points.append(point)
		names.append(label("", home(i) + Vector3.UP * 0.18, self))
		names[i].pixel_size = 0.0012
	readout = label("", Vector3(0, 1.82, -0.08), self)
	readout.pixel_size = 0.0012
	redraw()

func home(i: int) -> Vector3:
	return Vector3(-0.32 + i * 0.64, 1.25, 0.46)

func any_held() -> bool:
	return points[0].held() or points[1].held()

func _physics_process(_dt: float) -> void:
	for i in 2:
		if not points[i].held():
			points[i].global_transform = global_transform * Transform3D(Basis.IDENTITY, home(i))
		names[i].global_position = points[i].global_position + global_basis.y * 0.18
	if not any_held():
		latched = false
		show_pair()
	elif not latched and points[0].position.distance_to(points[1].position) < 0.19:
		request_step()

func _process(_dt: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		request_step()

func request_step(_body = null) -> void:
	if latched:
		return
	latched = any_held()
	advance()

func advance() -> void:
	if values.size() >= LIMIT:
		readout.text = "Ten terms. Keep this record; run again to reset."
		return
	var a := values[-2]
	var b := values[-1]
	values.append(a + b)
	redraw()
	names[0].text = str(a)
	names[1].text = str(b)
	readout.text = "%d + %d = %d\nRelease both points for the next pair." % [a, b, a + b]

func height_for(value: int, linear: bool) -> float:
	if linear:
		return 0.05 * value
	return 0.5 * log(float(value)) + 0.5

func redraw() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	for row in 2:
		var center_x := -0.64 if row == 0 else 0.64
		var linear := row == 0
		for i in values.size():
			var height := height_for(values[i], linear) * DISPLAY_SCALE
			var bar := MeshInstance3D.new()
			var shape := BoxMesh.new()
			shape.size = Vector3(0.075, height, 0.075)
			bar.mesh = shape
			bar.position = Vector3(center_x + (i - 4.5) * 0.10, 1.02 + height * 0.5, 0)
			var finish := StandardMaterial3D.new()
			finish.albedo_color = Color("76d9d1") if i == values.size() - 2 else Color("ffa366") if i == values.size() - 1 else Color("b3c0e6")
			bar.material_override = finish
			drawing.add_child(bar)
			label(str(values[i]), bar.position + Vector3(0, height * 0.5 + 0.05, 0), drawing)
		var heading := label("LINEAR" if linear else "LOGARITHMIC", Vector3(center_x, 1.67, 0), drawing)
		heading.pixel_size = 0.0011
	show_pair()

func show_pair() -> void:
	names[0].text = str(values[-2])
	names[1].text = str(values[-1])
	readout.text = "Same values / two height rules\n%d terms · bring the last pair together" % values.size()
	if values.size() == LIMIT:
		readout.text = "Ten terms · same record in both views\nRun again to reset."

func label(text: String, at: Vector3, host: Node3D) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 32
	tag.pixel_size = 0.00065
	tag.outline_size = 7
	host.add_child(tag)
	return tag
```

#### point_body.gd — carried unchanged

This is the same small, frozen pickable point used in the preceding hand models. It supplies pickup, release, the action signal and desktop grab hooks. We reuse that interaction so the new lesson can concern the record and its representations.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

### Check what stays the same

After eight requests beyond the two seeds, read:

`1, 1, 2, 3, 5, 8, 13, 21, 34, 55`

There should be ten bars in each row and the same labels in both. A ninth request changes nothing. The last small linear bar is 0.55 metres high; the corresponding logarithmic bar is about 0.501 metres. Joining the points and keeping them together must append only once. After release, their labels become the new last pair.

At the large display, reveal ten terms and turn on SUM. The 21-unit and 34-unit pieces together match 55 units at a common scale. Switching HEIGHT leaves the values and this witness unchanged. Logarithmic tower heights do not add this way: the mapping changes the relation between height and addition.

**Make one independent change.** Change only the starting array to `[1, 2]`. Predict the first five entries and the tenth before running it. The same addition should produce `1, 2, 3, 5, 8, …, 89`. Both views must receive that new record. You changed the initial conditions, while retaining the operation. Keep positive seeds for this supplied logarithmic mapping.

### A separate geometric comparison

Continue to the upright golden rectangle. NEXT removes a square from the remaining rectangle; MEASURE names actual side lengths. Its five-metre width starts with a height of `5 / phi`, where `phi = (1 + sqrt(5)) / 2`. The remainder turns and keeps the long-side/short-side ratio. The squares get smaller while their cut indices increase. They are not the increasing values from your array.

ARC adds quarter circles through those squares. Turning it off leaves the partition. The joined circular pieces are not an exact logarithmic spiral. The nearby helix, seed pattern and shell-like objects also need their own position and turn rules. Keep their differences visible; this lesson's required construction is the pair, record and two readers.

Carry this distinction into Synthesis: a procedure makes data, and another procedure gives that data a form. Name both when composing the next work.


---

<a id="Fractal_Synthesis"></a>

**07 / 07 · Synthesis**

## A rule kept

**Learning elements**

- Describe a construction with a seed, replacement rule and stopping condition.
- Pass named settings to a function; rebuild from the seed.
- Copy a recipe without linking its later edits to the original.
- Compare two results using the same scale.
- Optional composition: connect one earlier operation to a construction and test what should remain unchanged.

### In the museum

The interval and block tree return in this last Fractals hall. Between their desks, a small black point controls a comparison table. Move it left, centre or right: each surviving interval keeps one quarter, one third or two fifths at **each end**. The middle is omitted. Both descendants are replaced again at the next cut.

The table starts with three cuts. Predict what changes before moving the point. Each choice still makes eight pieces, but their lengths and the gaps differ. KEEP, or the held trigger, holds your current recipe in the rose row. The dark row remains live. Change the fraction and compare. RESTORE returns the live row to what you kept. RESET returns only LIVE to thirds and three cuts. NEXT adds a cut, up to five; release the point before using NEXT, RESTORE or RESET.

This is a return to Cantor's replacement operation. The new work is to make its decisions explicit and keep one version while changing another. The table keeps one comparison during the current run. It does not save a file or send a drawing into another hall.

### Continue with the point and interval list

Use the prepared Endless Museum workspace. Save the two files below together and attach `recipe.gd` to an empty, unit-scale Node3D on its floor. The front is local +Z. Camera, light, player and installed XRTools are already supplied. PointBody is the unchanged small point from the preceding lessons; its complete file is included so the example has no missing dependency or named scene child.

The example makes its own point, two rows and labels. Move the point to choose a fraction; press its held trigger or Enter to keep. Run again to return to the initial recipe. The installed museum table uses this exact script with furniture and four nearby buttons; that adapter calls `advance()`, `keep_current()`, `restore()` and `reset_live()`. It ignores global Enter. You do not reconstruct the room or the block tree.

### Name what another call needs

The `recipe` dictionary groups three settings under names. `seed` is the familiar `Vector2(start, length)`, here `(0, 6)`. `fraction` says how much of each parent survives at each end. `steps` is the number of replacements. A dictionary packages these decisions; it does not prove they are valid. `build()` bounds the depth, and the replacement function requires a fraction strictly between zero and one half.

`replace_intervals()` makes a separate `next` array. For each parent it places one descendant at the original start and another at `start + length - size`. It never appends to the array it is reading. `build()` starts from the seed every time, replacing the current list once per step. Editing a setting therefore reconstructs the requested version rather than applying another cut to yesterday's result.

At three cuts, eight pieces survive. For quarters their combined length is 0.75 metres; for thirds it is about 1.778 metres; for two fifths it is 3.072 metres. The count alone cannot distinguish these constructions.

### Keep a recipe, reconstruct its result

`kept_recipe = recipe` would give two names to the same dictionary. A later edit through one name would reach the same object. `duplicate(true)` creates a separate copy. The fields used here are numbers and a Vector2; the deep-copy option also copies nested arrays or dictionaries if we add them later. It is not a universal copy of every possible resource.

KEEP copies the settings. `rebuild()` then constructs both lists independently. RESTORE also copies: after restoring, a new LIVE edit must leave KEPT alone. The rendered bars are disposable views; they are removed and drawn again without removing the point or changing the saved recipe.

Both rows use the same scale: one model metre represents 0.34 metres on this table. Neither row is stretched to fill the width. The readouts state the **model lengths**. A length written as six metres does not make this miniature six metres wide.

### Complete code

`recipe.gd` contains the replacement, copy, input and drawing. Its hand control offers the three declared fractions; the display is centred on the six-metre seed. Treat that framing as an explicit choice when developing another work.

<!-- student-code:recipe.gd -->
```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const FRACTIONS := [0.25, 1.0 / 3.0, 0.4]
const LIMIT := 5
const DISPLAY_SCALE := 0.34
var recipe := {"seed": Vector2(0, 6), "fraction": 1.0 / 3.0, "steps": 3}
var kept_recipe: Dictionary = {}
var live: Array[Vector2] = []
var kept: Array[Vector2] = []
var point: XRToolsPickable
var drawing: Node3D
var live_caption: Label3D
var kept_caption: Label3D

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(keep_current)
	live_caption = label("", Vector3(0, 1.40, 0))
	kept_caption = label("", Vector3(0, 1.79, 0))
	label("CHANGE ONE RULE / KEEP A COMPARISON", Vector3(0, 2.02, 0))
	for i in 3:
		label(["1/4", "1/3", "2/5"][i], Vector3((i - 1) * 0.35, 1.0, 0.55))
	kept_recipe = recipe.duplicate(true)
	rebuild()
	park()

func replace_intervals(intervals: Array[Vector2], fraction: float) -> Array[Vector2]:
	assert(fraction > 0.0 and fraction < 0.5)
	var next: Array[Vector2] = []
	for interval in intervals:
		var size := interval.y * fraction
		next.append(Vector2(interval.x, size))
		next.append(Vector2(interval.x + interval.y - size, size))
	return next

func build(settings: Dictionary) -> Array[Vector2]:
	assert(settings.steps >= 0 and settings.steps <= LIMIT)
	var intervals: Array[Vector2] = [settings.seed]
	for generation in range(settings.steps):
		intervals = replace_intervals(intervals, settings.fraction)
	return intervals

func rebuild() -> void:
	live = build(recipe)
	kept = build(kept_recipe)
	redraw()

func choose(index: int) -> void:
	var fraction: float = FRACTIONS[clampi(index, 0, 2)]
	if is_equal_approx(recipe.fraction, fraction):
		return
	recipe.fraction = fraction
	rebuild()

func keep_current(_body = null) -> void:
	kept_recipe = recipe.duplicate(true)
	rebuild()

func restore() -> void:
	if point.held():
		return
	recipe = kept_recipe.duplicate(true)
	rebuild()

func advance() -> void:
	if point.held():
		return
	recipe.steps = mini(recipe.steps + 1, LIMIT)
	rebuild()

func reset_live() -> void:
	if point.held():
		return
	recipe = {"seed": Vector2(0, 6), "fraction": 1.0 / 3.0, "steps": 3}
	rebuild()

func _physics_process(_dt: float) -> void:
	if point.held():
		var local := to_local(point.global_position)
		choose(clampi(roundi(local.x / 0.35) + 1, 0, 2))
	else:
		park()

func park() -> void:
	var index: int = FRACTIONS.find(recipe.fraction)
	var home := Vector3((index - 1) * 0.35, 1.15, 0.55)
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, home)

func _process(_dt: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		keep_current()

func total(intervals: Array[Vector2]) -> float:
	var length := 0.0
	for interval in intervals:
		length += interval.y
	return length

func redraw() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	draw_row(live, 1.27, Color("28252c"))
	draw_row(kept, 1.66, Color("e99db8"))
	live_caption.text = describe("LIVE", recipe, live)
	kept_caption.text = describe("KEPT", kept_recipe, kept)

func describe(title: String, settings: Dictionary, intervals: Array[Vector2]) -> String:
	return "%s / %d cuts / %.1f%% at each end / %d pieces / %.3f m" % [title, settings.steps, settings.fraction * 100, intervals.size(), total(intervals)]

func draw_row(intervals: Array[Vector2], y: float, colour: Color) -> void:
	for interval in intervals:
		var surface := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(interval.y * DISPLAY_SCALE, 0.045, 0.06)
		surface.mesh = shape
		surface.position = Vector3((interval.x + interval.y * 0.5 - 3) * DISPLAY_SCALE, y, 0)
		var finish := StandardMaterial3D.new()
		finish.albedo_color = colour
		surface.material_override = finish
		drawing.add_child(surface)

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 36
	tag.pixel_size = 0.0016
	tag.outline_size = 7
	add_child(tag)
	return tag
```

`point_body.gd` is carried unchanged. It supplies the sphere and collision shape, XRTools pickup and the museum's desktop-held query.

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

### Make another version

First KEEP the initial thirds recipe. Move the point to quarters. LIVE should retain eight pieces totalling 0.75 metres; KEPT should still show the thirds. RESTORE should recover the initial result. Explain why another edit after RESTORE must not change KEPT.

For an independent code change, change only the initial `recipe` declaration to four steps. Leave the six-metre seed, fraction and drawing untouched. Before running, predict sixteen pieces and a combined length of `6 * (2 / 3)^4`, about 1.185 metres. The supplied automated check executes that edited script as well as the printed version. It checks the calculation; your explanation is still part of the exercise.

### Optional: a question of your own

The table gives you three fractions to compare. Now choose a connection the table does not offer: one construction from this sequence, influenced by one operation you learned earlier. Name the relationship before coding. What receives the value, and what should it change? Keep the question small enough to investigate beside its original in the museum workspace.

One possibility is the tree receiving noise as a branch turn. Noise Columns already asked us to follow a scalar into its receiving function. Here that receiver could be `child.rotation.z` in `branch(length, remaining)`, where the tree currently applies `TURN * sign_value`. Another possibility is a periodic turn from the Waves lessons. Choose one influence; decide what it should let you notice.

For the tree, copy your complete `tree.gd`, `point_body.gd` and `line_skin.gd` from Recursive Trees into a new study folder. Keep the original working folder. Start both study nodes at unit scale, separated on the museum floor. The camera, light and player still belong to the museum. Change the copied tree's turn calculation; retain its two children, shortening ratio and depth limit. Its existing grips continue to turn the first forks after construction.

If you choose noise, create and configure your `FastNoiseLite` before `_ready()` calls `branch()`. Give it an explicit seed and frequency. Decide what coordinates to sample: depth and side can give branches at the same level a shared turn; a distinct branch address can make that relationship different. During construction these nodes have not entered the scene tree, so use your declared coordinates rather than `global_position`. Bound the angle offset. Re-run to rebuild this study. A time-varying influence would also require an update rule; it is a further choice, not something the static generator supplies.

Before running, write down one prediction and one property you intend to preserve. For an angle-only tree edit at three generations, the fifteen segments, their lengths and parent attachments should survive; their endpoints may move. Check finite transforms and the depth cap. Set the influence to zero and compare with the original. Run the same recipe twice before touching the grips: it should reconstruct the same tree. Include your sampling coordinates and noise settings in the recipe you keep.

Then inspect the pair from two positions. What changed that your count could not describe? Revise one choice for a reason found in that encounter. Keep the original script and settings, the changed version, and a short account of the prediction, result and revision. These files are your record; the interval table's KEEP button does not store a tree.

This asks for more than a supplied edit. Your code must run and preserve the properties you declared. Your explanation must identify the relationship you chose. There is no required silhouette, and an unexpected result is not automatically a better one.

### What goes into the next room

At the large interval desk, HISTORY and GHOST change what can be inspected without changing which intervals survive. At the tree, FORM, STRATA, REACH and ENDS give different readings of the same branches. At this table, changing the retained fraction changes the generated intervals themselves. State which kind of change you made.

Carry the **thirds rule** into the next grammar laboratory. Its Cantor preset rewrites `F` as `FfF` and `f` as `fff`: uppercase draws a step, lowercase advances without drawing. After the same number of rewrites, that reading gives the same relative intervals. The lab fits its drawing to its display; compare normalized positions, not its apparent size. Quarters and two fifths are different recipes and do not follow from those same two rewrite rules.

We will build the general rewriting process there. Here, finish by naming the seed, operation, stop and display choices clearly enough that another reader could reconstruct your version.
