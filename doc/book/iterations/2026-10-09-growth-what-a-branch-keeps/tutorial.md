# What a branch keeps

<!-- @parametric_lsystem -->

## Learning elements

- State stored in a dictionary.
- Copies rather than shared mutable records.
- A stack: last saved, first restored.
- Nested branches and balanced brackets.
- Replaying recorded states without rewriting the sentence.

In Grammar Lab we rewrote a sentence and read it as a path. Here the path forks. We keep the same point, cylinder renderer and replacement function. The reader gains a memory: it can leave a position, draw a branch, and return with its earlier direction and stride.

## Follow the existing drawing

At the desk in Growth, the first F has already drawn 0.8 metres. Its pale tip is the reader's position; the dark sphere in front of the controls is your handle. These have different jobs. The eleven-symbol sentence is `F[+F]F[-F]F`.

Press STEP, or hold the dark point and press its trigger. `[` saves a state. The tip stays where it is. The stack count becomes one; the next length becomes 0.576 metres. Step through `+` and F: turn, then draw. HOLD this reading before the closing bracket. Predict where `]` will put the live tip. It returns to the fork, while the branch remains visible. The next F resumes the trunk.

Finish the sentence and HOLD it. Move the dark point across the four ratios: 0.45, 0.72, 1.00, 1.15. At one, a branch has its parent's stride. Above one, it is longer. You are re-reading the same sentence. Both views use metres; neither fits itself to its plinth. The nearby RATIO button offers the same choices.

## Continue the student's code

Use the prepared Endless Museum project from Day Zero, with its player, camera, light and XRTools already running. Keep the Grammar Lab study in its own folder. Make a sibling folder for Growth containing these four files, and attach `growth.gd` to a new, empty Node3D on a clear museum floor patch. Keep the host at unit scale, its local +Z facing the visitor; allow about eleven metres of width and eight metres of height for the two full-size readings. The script builds its objects and labels itself. It has no named scene-child dependencies.

This is your reconstruction of the existing desk, not another hall. Keep the original artifact available for comparison. PointBody and LineSkin are unchanged carried files, printed at the end for completeness. The new code is the saved-state reader and its view. The drawings have no collision shapes; the small dark PointBody does.

The installed desk has six nearby VR buttons. The compact reconstruction uses the same held-point trigger for STEP, point movement for RATIO, and desktop Enter/H/T/R for STEP/HOLD/TREE/RESET. It does not recreate those six button scenes. Both versions begin after the first F; RESET restores that opening and its held copy. STEP reveals an already computed trace. TREE switches between one and two complete rewrites, showing the whole result.

## Save before changing

The reader's dictionary holds position, heading, length, turning angle and branch depth. `stack.append(state.duplicate(true))` stores a separate record. Appending `state` itself would retain a reference to the dictionary we are about to change: the supposed memory would change with it.

On entering a branch, length is multiplied by the chosen ratio and angle by 0.95. Here, 0.8 × 0.72 = 0.576 metres and 40 × 0.95 = 38 degrees. These are this artifact's choices, not requirements of every L-system. The fixed rotation axis keeps this reader planar. The production reader also carries orientation axes for its broader implementation; they reduce to this fixed plane in the zero-variation lesson.

`pop_back()` retrieves the most recent saved dictionary. That restores all its fields at once. A branch inside a branch returns to the inner fork first. Restoring the turtle does not remove endpoints already stored in `ends`.

The bracket check runs before drawing: a closing bracket needs a saved state, and every opening needs a return. This is an explicit learner-edit check. The production interpreter is more permissive with malformed strings; we compare their valid sentences, not their error policy. Unrecognized symbols pass through rewriting and draw nothing, as before.

### grammar.gd

`rewrite()` is unchanged from Grammar Lab. `read()` now returns endpoint data and independent frames, including START. Each frame records the state after one symbol and how many segments have been drawn. The endpoint array stores each segment's two ends; the return jump adds no segment.

<!-- student-code:grammar.gd -->
```gdscript
extends RefCounted
const SYMBOL_LIMIT := 4096

func rewrite(sentence: String, rules: Dictionary) -> Dictionary:
	var size := 0
	for symbol in sentence:
		size += str(rules.get(symbol, symbol)).length()
		if size > SYMBOL_LIMIT:
			return {"accepted": false, "text": sentence}
	var next := ""
	for symbol in sentence:
		next += str(rules.get(symbol, symbol))
	return {"accepted": true, "text": next}

func read(sentence: String, ratio: float) -> Dictionary:
	# Check bracket pairs before accepting any drawing.
	var balance := 0
	for symbol in sentence:
		if symbol == "[": balance += 1
		if symbol == "]": balance -= 1
		if balance < 0:
			return {"accepted": false, "error": "Closing bracket has no saved state."}
	if balance != 0:
		return {"accepted": false, "error": "An opening bracket has no return."}
	var state := {"pos": Vector3.ZERO, "heading": Vector3.UP,
		"length": 0.8, "angle": 40.0, "depth": 0}
	var stack: Array[Dictionary] = []
	var ends: Array[Vector3] = []
	var frames: Array[Dictionary] = []
	frames.append(record(state, "START", 0, 0))
	for symbol in sentence:
		match symbol:
			"F", "G":
				ends.append(state.pos)
				state.pos += state.heading * state.length
				ends.append(state.pos)
			"f": state.pos += state.heading * state.length
			"+", "-":
				var sign := 1.0 if symbol == "+" else -1.0
				state.heading = state.heading.rotated(Vector3.FORWARD, deg_to_rad(state.angle) * sign).normalized()
			"[":
				stack.append(state.duplicate(true))
				state.depth += 1
				state.length *= ratio
				state.angle *= 0.95
			"]": state = stack.pop_back()
		frames.append(record(state, symbol, stack.size(), ends.size() / 2))
	return {"accepted": true, "frames": frames, "ends": ends}

func record(state: Dictionary, symbol: String, count: int, segments: int) -> Dictionary:
	var frame := state.duplicate(true)
	frame.merge({"symbol": symbol, "stack_depth": count, "segments": segments})
	return frame
```

## Read the same record in the room

`cursor` chooses a recorded frame. `snapshot()` copies that frame and the endpoints up to its segment count. HOLD saves this small reading, including its sentence, ratio and generation. Moving the point recomputes the live frames; it leaves the held copy intact. The hand is read in the study's local coordinates, so turning the study does not reverse its controls.

`set_tree()` first builds and checks a candidate. Only an accepted result replaces the live sentence and reading. The generation bound is two here; the inherited replacement function also refuses a whole rewrite above 4096 symbols. Neither limit measures biological growth.

The view uses the old cylinder renderer without fitting. Its pale tip is a visual marker, not another grabbable object. The short text window is labelled by symbol index; ellipses mean the display is abbreviated, not that the stored sentence has been cut.

### growth.gd

<!-- student-code:growth.gd -->
```gdscript
extends Node3D
const Grammar = preload("grammar.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const RULE := {"F": "F[+F]F[-F]F"}
const RATIOS := [0.45, 0.72, 1.0, 1.15]
var model = Grammar.new()
var sentence := ""
var ratio := 0.72
var generation := 1
var cursor := 1
var reading: Dictionary = {}
var held: Dictionary = {}
var point: XRToolsPickable
var drawing: Node3D
var title: Label3D
var captions: Array[Label3D] = []

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(step)
	title = label("", Vector3(0, 2.2, 0))
	for x in [-3.0, 3.0]:
		captions.append(label("", Vector3(x, 0.18, 0.25)))
	label("TRIGGER / ENTER: STEP   H: HOLD   T: TREE   R: RESET", Vector3(0, 0.9, 2.55))
	for i in RATIOS.size():
		label("%.2f" % RATIOS[i], Vector3((i - 1.5) * 0.35, 1.02, 2.55))
	reset()
	park()

func set_tree(depth: int) -> void:
	var next := "F"
	for i in clampi(depth, 1, 2):
		var result: Dictionary = model.rewrite(next, RULE)
		if not result.accepted:
			title.text = "Symbol limit: previous reading retained."
			return
		next = result.text
	var candidate: Dictionary = model.read(next, ratio)
	if not candidate.accepted:
		title.text = candidate.error
		return
	sentence = next
	generation = clampi(depth, 1, 2)
	reading = candidate
	cursor = sentence.length()
	redraw()

func step(_body = null) -> void:
	cursor = mini(cursor + 1, sentence.length())
	redraw()

func snapshot() -> Dictionary:
	var frame: Dictionary = reading.frames[cursor]
	return {"frame": frame.duplicate(true),
		"ends": reading.ends.slice(0, frame.segments * 2).duplicate(),
		"ratio": ratio, "text": sentence, "cursor": cursor, "generation": generation}

func keep() -> void:
	held = snapshot()
	redraw()

func reset() -> void:
	ratio = 0.72
	set_tree(1)
	if reading.is_empty(): return
	cursor = 1
	keep()

func choose(index: int) -> void:
	var selected: float = RATIOS[clampi(index, 0, RATIOS.size() - 1)]
	if is_equal_approx(selected, ratio): return
	ratio = selected
	reading = model.read(sentence, ratio)
	redraw()

func _physics_process(_dt: float) -> void:
	if point.held():
		choose(roundi(to_local(point.global_position).x / 0.35 + 1.5))
	else:
		park()

func park() -> void:
	var x := (RATIOS.find(ratio) - 1.5) * 0.35
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(x, 1.18, 2.55))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ENTER: step()
		KEY_H: keep()
		KEY_T: set_tree(2 if generation == 1 else 1)
		KEY_R: reset()

func redraw() -> void:
	if reading.is_empty(): return
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	var live := snapshot()
	for i in 2:
		var view: Dictionary = live if i == 0 else held
		if view.is_empty(): continue
		var origin := Vector3(-3 if i == 0 else 3, 0.35, 0)
		for j in range(0, view.ends.size(), 2):
			var a: Vector3 = origin + view.ends[j]
			var b: Vector3 = origin + view.ends[j + 1]
			var rod = LineSkin.new()
			rod.material_override.albedo_color = Color("70d5c2") if i == 0 else Color("edafd3")
			drawing.add_child(rod)
			rod.show_segment(a, b - a, a.distance_to(b))
		var marker := MeshInstance3D.new()
		var skin := SphereMesh.new()
		skin.radius = 0.065
		skin.height = 0.13
		marker.mesh = skin
		marker.position = origin + view.frame.pos
		drawing.add_child(marker)
		captions[i].text = "%s / ratio %.2f / %d segments" % ["LIVE" if i == 0 else "HELD", view.ratio, view.frame.segments]
	var frame: Dictionary = live.frame
	var start := maxi(0, cursor - 6)
	var window := sentence.substr(start, 11)
	title.text = "gen %d / symbol %d of %d: %s\nlength %.3f m / stack %d\n" % [generation, cursor, sentence.length(), frame.symbol, frame.length, frame.stack_depth]
	title.text += ("..." if start > 0 else "") + window + ("..." if start + 11 < sentence.length() else "")

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 32
	tag.pixel_size = 0.0012
	tag.outline_size = 6
	add_child(tag)
	return tag
```

## Check the return

From RESET, take three steps, then HOLD. You have read `[`, `+`, F. The live tip is at the branch end, the stack has one record and the next length is 0.576. One more step restores position (0, 0.8, 0), heading up, length 0.8, angle 40 and depth zero. There are still two drawn segments. One further step ends at (0, 1.6, 0). A diagonal connector between the branch tip and fork would be a bug.

Complete the sentence: eleven symbols make five segments. At ratio 1.15, a child stride is 0.92 metres. T requests generation two: sixty-one symbols, twenty-five segments, a trunk reaching 7.2 metres above its start. A twice-nested stride is 1.058 metres. Rewriting generation and stack depth are different counts.

Now edit only RULE in your copy to `{"F": "F[+F[-F]F]F"}`. Before running it, mark the two returns. The inner `]` must recover the outer branch's heading and 0.576-metre stride; the outer `]` recovers the trunk's 0.8-metre stride. In generation one, predict five segments and a final tip at (0, 1.6, 0). Run it, step through the returns, and explain why restoring position alone would fail. Then remove a closing bracket: the reader must report the unmatched opening instead of presenting a partial drawing as complete.

The repository's native Godot checks extract these exact printed files, run the nested-rule edit as a separate program, compare valid states and endpoints to the installed generator, and exercise the actual XRTools pickup/action/release with supplied poses. Those checks establish executable behavior; a student explaining the return and a physical headset session remain separate evidence.

## Carried files

These files keep their previous jobs. PointBody is the hand-sized grabbable sphere. LineSkin gives two endpoints a visible cylinder. They are included unchanged so the complete reconstruction has no missing helper code.

### point_body.gd

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

### line_skin.gd

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

## What travels onward

Keep the rewritten sentence, the reader and the saved-state operation. The other growth studies remain available in the hall; they are not prerequisites for reconstructing this branch. In Grammars and Curves, the question changes: how much of a form comes from its sentence, and how much from the way we read forward and turn?

<!-- @ -->
