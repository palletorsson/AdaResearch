# One sentence, three readers

<!-- @the_believing_turtle -->

## Learning elements

- Separate a symbol from the operation that interprets it.
- Separate stored heading from drawing direction.
- Compare readers with the sentence and stride held fixed.
- Exchange vector components: reflection and its preserved relations.
- Use a return value without changing the state passed to a function.

Growth gave our reader a memory. Here we reuse its stack, the replacement function, PointBody and LineSkin. One small function now stands between a heading and the next movement. The subject is interpretation: the same F can have another consequence.

## Begin inside the museum

The believing turtle presents three readers of one sentence. All begin after the first F, taking 0.32 metres upward. The green reference stays at 25 degrees. The middle reader can change its turn angle. The blue reader can exchange x and y when it draws.

Take the familiar dark sphere and press its trigger, or press READ F on the desk. The blue line goes sideways. Its gold direction marker still points up; its white marker points across. Gold shows the stored heading. White shows the direction of the next drawing step. You changed the interpretation, not the heading or the sentence.

Move the held sphere to 45; the nearby ANGLE button makes the same choice. The middle reader's first F stays upright. The new angle has not reached a turn yet. Press STEP five times. At symbol six, the first branch segment makes the changed turns visible. The same cursor follows all three readings.

Finish the twenty symbols, then choose TREE. Its second generation has 172 symbols and 64 drawn segments per reader. Find a blue fork and its green counterpart. Every segment retains its length. No drawing is fitted to its case. The map's original lectern, curve gallery and later tube bay have their own conditions; they are not extra copies of this controlled comparison.

## Carry the code, name the changes

Keep Growth's study intact. Make a sibling folder containing the four complete files below. In the prepared Endless Museum project, attach `readers.gd` to an empty Node3D on a clear floor patch, at unit scale with local +Z facing the visitor. Allow about fifteen metres of width and six metres of height for the full-size comparison. The museum supplies its existing player, camera, lighting and XRTools. The script creates its point, drawings and labels, without named scene-child references.

The dark sphere still controls the reader. Its **trigger now means READ F**, exchanging the blue direction; its X position selects the **middle angle**. The installed desk retains STEP, READ F, ANGLE, TREE, RESET and RULE. The compact reconstruction uses Enter for STEP, Space for READ F, T for TREE and R for RESET. It creates no replacement VR button system. STEP wraps from the last frame to START; RESET returns to the first F and the original readers.

Three decisions differ from Growth because we are reconstructing this artifact:

| Decision | Growth | This comparison |
|---|---|---|
| Stride | 0.8 m, multiplied on branch entry | 0.32 m everywhere |
| Turn | `+` turns about negative Z; branch angle shrinks | `+` turns about positive Z; each reader keeps its chosen angle |
| Saved state | Position, heading, length, angle and depth | Position and heading; stride and angle are fixed for that reading |

Here the alphabet is F, +, −, [ and ]. Growth's optional G/f handlers are not used. Other symbols survive rewriting but have no drawing action in this reader. These are declared interpreter choices, not changes to what the symbols universally mean.

The stack still saves a separate dictionary and restores the last one first. The bracket preflight stays. The replacement function is unchanged. PointBody and LineSkin are the same carried files, printed at the end.

## Put the decision in a function

`direction()` receives a heading and returns a vector. In forward mode it returns that heading. In sideways mode it constructs (y, x, 0). Calling it does not assign a new value to `state.heading`. F uses the returned direction to advance; the next turn still changes the stored heading.

The production artifact stores heading as an angle, initially PI/2, and computes (cos heading, sin heading). Our reduced reader keeps Growth's unit vector. Turning that vector about positive Z gives the same directions for this planar lesson. The comparison tests both against the actual artifact.

The swap preserves a planar vector's squared length: x² + y² becomes y² + x². Applied to every step from the same origin, it reflects every endpoint across x=y. Branch returns preserve that correspondence. This does not add joints wherever lines happen to cross. It also does not make a colliding surface.

### grammar.gd

<!-- student-code:grammar.gd -->
```gdscript
extends RefCounted
const SYMBOL_LIMIT := 4096
const STRIDE := 0.32

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

func direction(heading: Vector3, sideways: bool) -> Vector3:
	return Vector3(heading.y, heading.x, 0) if sideways else heading

func read(sentence: String, angle: float, sideways: bool) -> Dictionary:
	var balance := 0
	for symbol in sentence:
		if symbol == "[": balance += 1
		if symbol == "]": balance -= 1
		if balance < 0:
			return {"accepted": false, "error": "Closing bracket has no saved state."}
	if balance != 0:
		return {"accepted": false, "error": "An opening bracket has no return."}
	var state := {"pos": Vector3.ZERO, "heading": Vector3.UP}
	var stack: Array[Dictionary] = []
	var ends: Array[Vector3] = []
	var frames: Array[Dictionary] = []
	frames.append(record(state, "START", 0, 0, sideways))
	for symbol in sentence:
		match symbol:
			"F":
				ends.append(state.pos)
				state.pos += direction(state.heading, sideways) * STRIDE
				ends.append(state.pos)
			"+", "-":
				var sign := 1.0 if symbol == "+" else -1.0
				state.heading = state.heading.rotated(Vector3.BACK, deg_to_rad(angle) * sign).normalized()
			"[": stack.append(state.duplicate(true))
			"]": state = stack.pop_back()
		frames.append(record(state, symbol, stack.size(), ends.size() / 2, sideways))
	return {"accepted": true, "frames": frames, "ends": ends}

func record(state: Dictionary, symbol: String, count: int, segments: int, sideways: bool) -> Dictionary:
	var frame := state.duplicate(true)
	frame.merge({"symbol": symbol, "stack_depth": count, "segments": segments,
		"direction": direction(state.heading, sideways)})
	return frame
```

## Three results from one input

`reinterpret()` sends one stored sentence to the three readers. Changing the middle angle or the blue mapping does not rewrite it. `set_tree()` is the separate operation that builds one or two generations, checks the result, then commits it.

Each reading records a frame after every symbol. The shared cursor selects the same symbol in all three. As in Growth, STEP replays stored results; it is not a paused interpreter. The marker positions are calculated in local coordinates before adding three display origins. Those offsets separate the views; they are not part of the reflection.

The pale tip marks position. The gold and white short rods show heading and next drawing direction, with small Z offsets so both remain visible. The installed museum uses arrowheads; the reduced view reuses LineSkin. Rod length is a display choice; it does not change the 0.32-metre stride. All three origins sit 2.2 metres above the study floor so the reflected downward branches remain visible.

### readers.gd

<!-- student-code:readers.gd -->
```gdscript
extends Node3D
const Grammar = preload("grammar.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const RULE := {"F": "FF+[+F-F-F]-[-F+F+F]"}
const ANGLES := [25.0, 45.0, 90.0]
const COLOURS := [Color("8bcda4"), Color("efbb68"), Color("92bfe4")]
var model = Grammar.new()
var sentence := ""
var generation := 1
var cursor := 1
var angle := 25.0
var sideways := false
var readings: Array[Dictionary] = []
var point: XRToolsPickable
var drawing: Node3D
var title: Label3D
var captions: Array[Label3D] = []

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(exchange)
	title = label("", Vector3(0, 1.65, 0.3))
	for i in 3:
		captions.append(label("", Vector3((i - 1) * 4.5, 0.7, 0.3)))
	label("TRIGGER / SPACE: READ F   ENTER: STEP   T: TREE   R: RESET", Vector3(0, 0.9, 2.55))
	for i in ANGLES.size():
		label(str(int(ANGLES[i])), Vector3((i - 1) * 0.35, 1.02, 2.55))
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
	if not model.read(next, 25, false).accepted:
		title.text = "Unmatched bracket: previous reading retained."
		return
	sentence = next
	generation = clampi(depth, 1, 2)
	cursor = sentence.length()
	reinterpret()

func reinterpret() -> void:
	readings = [model.read(sentence, 25, false), model.read(sentence, angle, false), model.read(sentence, 25, sideways)]
	redraw()

func exchange(_body = null) -> void:
	sideways = not sideways
	reinterpret()

func choose(index: int) -> void:
	var selected: float = ANGLES[clampi(index, 0, 2)]
	if is_equal_approx(selected, angle): return
	angle = selected
	reinterpret()

func step() -> void:
	cursor = (cursor + 1) % (sentence.length() + 1)
	redraw()

func reset() -> void:
	angle = 25
	sideways = false
	set_tree(1)
	cursor = 1
	redraw()

func _physics_process(_dt: float) -> void:
	if point.held():
		choose(roundi(to_local(point.global_position).x / 0.35 + 1))
	else:
		park()

func park() -> void:
	var x := (ANGLES.find(angle) - 1) * 0.35
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(x, 1.18, 2.55))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ENTER: step()
		KEY_SPACE: exchange()
		KEY_T: set_tree(2 if generation == 1 else 1)
		KEY_R: reset()

func redraw() -> void:
	if readings.is_empty(): return
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	for i in 3:
		var frame: Dictionary = readings[i].frames[cursor]
		var origin := Vector3((i - 1) * 4.5, 2.2, 0)
		for j in range(0, frame.segments * 2, 2):
			rod(origin + readings[i].ends[j], origin + readings[i].ends[j + 1], COLOURS[i])
		var tip: Vector3 = origin + frame.pos
		var marker := MeshInstance3D.new()
		var skin := SphereMesh.new()
		skin.radius = 0.05
		skin.height = 0.1
		marker.mesh = skin
		marker.position = tip
		drawing.add_child(marker)
		# Two short rods share a tip but have distinct Z offsets for visibility.
		var gold := tip + Vector3(0, 0, 0.05)
		var white := tip + Vector3(0, 0, 0.10)
		rod(gold, gold + frame.heading * 0.24, Color("ffc967"))
		rod(white, white + frame.direction * 0.32, Color.WHITE)
		var name: String = ["REFERENCE / 25", "TURN / %.0f" % angle, "READ F / " + ("exchange x,y" if sideways else "forward")][i]
		captions[i].text = name + "\n%d segments / 0.32 m each" % frame.segments
	var current: Dictionary = readings[0].frames[cursor]
	var start := 0 if sentence.length() <= 20 else maxi(0, cursor - 10)
	title.text = ("..." if start > 0 else "") + sentence.substr(start, 20) + ("..." if start + 20 < sentence.length() else "")
	title.text += "\ngen %d / symbol %d of %d: %s / stack %d\ngold: heading / white: next drawing direction" % [generation, cursor, sentence.length(), current.symbol, current.stack_depth]

func rod(a: Vector3, b: Vector3, colour: Color) -> void:
	var line = LineSkin.new()
	line.material_override.albedo_color = colour
	drawing.add_child(line)
	line.show_segment(a, b - a, a.distance_to(b))

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

## Predict a different reader

At RESET, all first endpoints are (0, 0.32, 0) relative to their origins. READ F moves only the blue one to (0.32, 0, 0). Its heading remains (0, 1, 0). Change the middle angle: its first endpoint stays fixed. Advance to the first branch at symbol six to see that angle take effect. Return READ F to forward: the blue and reference endpoints must agree again.

For your own reader, change only the sideways expression in `direction()` from `Vector3(heading.y, heading.x, 0)` to `Vector3(-heading.y, heading.x, 0)`. Predict the first blue step before running: it should go left. The new rule rotates every planar direction a quarter turn. Check an off-axis branch too; an upright line alone cannot distinguish every mapping.

Keep the sentence, stride and stored headings. Compare lengths and the order of endpoints. A reflection reverses the orientation of a pair of directions; this quarter turn preserves it. Applying the original swap twice returns a vector to itself. Applying your new mapping twice points it backwards; four applications return it. Execute the edited file, then explain why changing `state.heading` instead would mix two decisions that this lesson keeps separate.

Repository tests extract these exact files, execute that altered mapping as a separate program, and compare the base reader's valid states and endpoints with the existing artifact. They also exercise the actual XRTools pickup/action/release with supplied poses. This tests the program and the interaction binding; it does not replace a student's explanation or physical headset review.

## Carried files

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

## From a read path to a surface

Carry the sentence, the copied stack and the distinction between heading and displacement. Architecture will ask what an interpreted plan needs before a body can occupy it.

The main lesson is complete when you can change the reader, predict the changed direction and explain what remains fixed. Continue to Architecture with these four files.

The tube bay remains available as a separate [optional application reading](tutorial-applications.md): continue a hand-drawn path, give it a skin, make connections and compose a canopy. Those works have their own supplied builders and interfaces. They are not prerequisites for Architecture, and this lesson does not transfer its generated path into them. The four-file reader tests cover the main lesson; the optional applications have separate evidence.

<!-- @ -->
