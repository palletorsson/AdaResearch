# L-systems — complete tutorial

Eight halls in canonical spine order. Current source texts collected on 9 October 2026. See REVIEW.md and evidence.html for the scope of the accompanying checks.


---

<!-- hall: LSystems_Grammar_Lab -->

# A sentence and a reading

**Learning elements**

- A string, an axiom and a dictionary of replacement rules.
- Parallel rewriting: read the old sentence, build a separate next sentence.
- Interpret symbols as forward movement and turns.
- Keep a reading while changing its angle.
- Distinguish construction, interpretation and display fitting.

## The route through this sequence

Fractals made the seed, repeated operation and stopping condition explicit. Here a rule first constructs a description: a sentence we can keep before another function reads it as movement. That separation lets us change an instruction or its interpretation independently. Later halls give the resulting path boundaries, let growth meet shared resources, and turn design values into rules. Shape Grammars transfers replacement to mesh faces; Assemblage uses random samples and asks which connections a viewer finds. Those last studies extend the inquiry beyond L-systems. The familiar point stays in the hand while the records and operations gain new uses.

## In the museum

At the editor desk, two upright lines begin with the same letter, `F`. Press NEXT once. Count the live segments before reading its counter. HOLD keeps that reading on the right. Now take the small black point and move it along the four angle positions. What changes when the sentence stays the same?

The point is the one we have carried through earlier lessons. Here its held trigger means NEXT: rewrite once. HOLD remains a nearby button. TURN offers the same angles without picking up the point. The cyan drawing is live; the rose drawing keeps its sentence and angle until you press HOLD again. This comparison lasts for the current visit, not between runs.

Start with RESET. The first rewrite has five `F` commands and four turning signs: nine symbols. Another rewrite has twenty-five drawing commands and forty-nine symbols. The turns take places in the sentence without drawing additional segments. A line can overlap another, so the visible outline alone cannot tell us the command count.

The desk's preset called **Koch** uses `F → F+F-F-F+F`. It is a different replacement from the four-piece, sixty-degree Koch construction we explored earlier. Read the production before assuming what the familiar name means.

## Continue from the recipe

In Fractal Synthesis, a recipe named the seed, operation and stopping depth. Here a **string** records the intermediate result. A **dictionary** says which string replaces each symbol. We reuse loops, functions, independent old/next data, PointBody and the cylinder that gives a line its thickness.

Use the prepared Endless Museum workspace. Place the four complete files below together. Attach `sentence.gd` to an empty, unit-scale Node3D on its floor, facing local +Z. The museum supplies the player, camera, lighting and installed XRTools. The script creates its own point, drawings and labels; there are no named scene children to prepare. This is a compact reconstruction of the existing desk's opening interaction, beside which you can compare your result.

Move the held point to choose 30, 60, 90 or 120 degrees. Trigger or Enter rewrites once; H keeps a reading; R resets only the live sentence and generation. C switches the live rules between the turning curve and Cantor, restarting from `F`. H is the desktop equivalent of the museum's HOLD button. The museum desk also includes other presets, rule readouts and furniture, supplied by its existing interface. The learner program has no virtual keyboard or hidden button helpers.

## Write first; read afterwards

Read `rewrite()` first. `rules.get(symbol, symbol)` looks up a replacement; the second argument keeps the symbol itself when no rule names it. The first loop checks the length of the proposed result against a 4,096-symbol budget. The second loop writes `next`. Only after the function returns does `advance()` replace the live sentence and increment its generation. New letters are never processed during the pass that produced them. This is a logical parallel replacement; it does not require multiple threads.

Read `read()` next. The turtle starts at zero, heading up. Each `F` or `G` stores two endpoints and advances one model unit. Lowercase `f` advances without storing a segment. `+` and `-` turn around the plane's normal, Godot's negative Z direction. These are planar drawings inside our three-dimensional room.

A symbol such as `X` can remain in the sentence without a drawing action. Brackets are deliberately rejected in this small reader: saving and restoring a branch state is the next hall's lesson. The full museum editor already supports them.

`grammar.gd`

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

func read(sentence: String, angle: float) -> Array[Vector3]:
	var ends: Array[Vector3] = []
	var position := Vector3.ZERO
	var heading := Vector3.UP
	for symbol in sentence:
		match symbol:
			"F", "G":
				ends.append(position)
				position += heading
				ends.append(position)
			"f": position += heading
			"+": heading = heading.rotated(Vector3.FORWARD, deg_to_rad(angle))
			"-": heading = heading.rotated(Vector3.FORWARD, -deg_to_rad(angle))
			"[", "]": assert(false, "Branch states belong to the next lesson.")
	return ends
```

## Keep one reading; change another

`keep()` constructs a fresh dictionary containing the text, angle and generation. These values are sufficient to reconstruct this reader's output. Later LIVE edits do not change HELD. We do not store mesh nodes as the record. The installed desk also keeps a copy of its already fitted endpoints; our smaller example redraws the saved sentence with its saved angle.

`choose()` changes the live angle without calling `rewrite()`. `_physics_process()` reads the held point in the study's **local frame**, so turning or moving the entire study does not change what the hand positions mean. Release parks the point by the current angle. Pressing the trigger calls `advance()`, which is a separate operation.

Each drawing is independently fitted to a 1.4-metre span. `draw_reading()` finds the endpoint bounds, centres the drawing and gives both axes the same scale. It changes neither the sentence nor its model endpoints. Thus the pictures are useful for comparing bends, but their apparent height does not measure growth. The cylinder thickness is also a display choice. The drawing has no collision surface.

The sentence readout shows at most forty symbols and names that truncation. The 4,096-symbol construction budget and four-generation limit are separate. Reaching the budget retains the previous complete generation. The full museum desk shows a longer, labelled 120-symbol prefix.

`sentence.gd`

<!-- student-code:sentence.gd -->
```gdscript
extends Node3D
const Grammar = preload("grammar.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const TURNS := [30.0, 60.0, 90.0, 120.0]
const CURVE := {"F": "F+F-F-F+F"}
const CANTOR := {"F": "FfF", "f": "fff"}
var model = Grammar.new()
var rules: Dictionary = CURVE.duplicate()
var sentence := "F"
var angle := 90.0
var generation := 0
var held: Dictionary = {}
var limited := false
var point: XRToolsPickable
var drawing: Node3D
var captions: Array[Label3D] = []
var title: Label3D

func _ready() -> void:
	drawing = Node3D.new()
	add_child(drawing)
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(advance)
	for x in [-0.85, 0.85]:
		captions.append(label("", Vector3(x, 1.08, 0)))
	title = label("", Vector3(0, 3.05, 0))
	label("TRIGGER / ENTER: NEXT     H: HOLD     R: RESET     C: CURVE / CANTOR", Vector3(0, 0.78, 0.5))
	for i in TURNS.size():
		label(str(int(TURNS[i])), Vector3((i - 1.5) * 0.35, 0.99, 0.55))
	keep()
	park()

func advance(_body = null) -> void:
	if generation >= 4:
		return
	var result: Dictionary = model.rewrite(sentence, rules)
	limited = not result.accepted
	if result.accepted:
		sentence = result.text
		generation += 1
	redraw()

func keep() -> void:
	held = {"text": sentence, "angle": angle, "generation": generation}
	redraw()

func reset_live() -> void:
	sentence = "F"
	generation = 0
	limited = false
	redraw()

func choose(index: int) -> void:
	var selected: float = TURNS[clampi(index, 0, TURNS.size() - 1)]
	if angle != selected:
		angle = selected
		redraw()

func _physics_process(_dt: float) -> void:
	if point.held():
		choose(roundi(to_local(point.global_position).x / 0.35 + 1.5))
	else:
		park()

func park() -> void:
	var x := (TURNS.find(angle) - 1.5) * 0.35
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(x, 1.15, 0.55))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ENTER: advance()
		KEY_H: keep()
		KEY_R: reset_live()
		KEY_C:
			rules = CANTOR.duplicate() if rules == CURVE else CURVE.duplicate()
			reset_live()

func redraw() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	var live := {"text": sentence, "angle": angle, "generation": generation}
	for i in 2:
		var reading: Dictionary = live if i == 0 else held
		var ends: Array[Vector3] = model.read(reading.text, reading.angle)
		draw_reading(ends, Vector3(-0.85 if i == 0 else 0.85, 1.42, 0), Color("78dccc") if i == 0 else Color("f0b3db"))
		var prefix: String = reading.text.substr(0, 40)
		if reading.text.length() > 40:
			prefix += " ... (first 40)"
		captions[i].text = "%s / gen %d / %.0f deg\n%d symbols / %d segments\n%s" % ["LIVE" if i == 0 else "HELD", reading.generation, reading.angle, reading.text.length(), ends.size() / 2, prefix]
	title.text = ("SAME SENTENCE" if sentence == held.text else "DIFFERENT SENTENCES") + "\nEach drawing fitted independently"
	if limited:
		title.text += "\nSYMBOL LIMIT: previous complete generation retained"

func draw_reading(ends: Array[Vector3], origin: Vector3, colour: Color) -> void:
	if ends.is_empty():
		return
	var low := ends[0]
	var high := ends[0]
	for end in ends:
		low = low.min(end)
		high = high.max(end)
	var fit := 1.4 / maxf((high - low).x, (high - low).y)
	var anchor := Vector3((low.x + high.x) * 0.5, low.y, 0)
	for i in range(0, ends.size(), 2):
		var a := origin + (ends[i] - anchor) * fit
		var b := origin + (ends[i + 1] - anchor) * fit
		var rod = LineSkin.new()
		rod.material_override.albedo_color = colour
		drawing.add_child(rod)
		rod.show_segment(a, b - a, a.distance_to(b))

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

## The carried parts

These two files are unchanged from our Fractals studies. Keep them available, but concentrate this reading on the new `rewrite()` and `read()` functions. PointBody supplies pickup, the action signal and the desktop-held query. LineSkin places a finite cylinder between the endpoints. Neither supplies a camera or rebuilds the museum.

`point_body.gd`

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

`line_skin.gd`

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

## Predict, run, then change the rule

1. Start with the printed curve. Advance once, press H, then move the point from 90 to 120. Predict which values and endpoints can change. Verify that both sentences and segment counts stay equal, while HELD retains 90 degrees.
2. Advance again. Explain why the live sentence now contains forty-nine symbols rather than forty-five. The four turning signs from the previous generation pass through unchanged.
3. Change only `CURVE` in your own file to `{"F": "F+F"}`. Before running, predict the generation-two sentence, drawn count and path at 90 degrees. Keep the reader and renderer unchanged. The supplied test executes this edited file, not just the function from the original.

After making your prediction: the changed rule gives `F+F+F+F`, four segments and seven symbols. At 90 degrees its endpoint returns to the origin. Its bounds contain a square; at another angle the same sentence need not close. Closure is a property of this interpretation, not of the string alone.

## Return to the thirds

Press C for Cantor. The rules are `F → FfF` and `f → fff`. All symbols advance the turtle, but only uppercase F draws. After three rewrites, the twenty-seven advances contain eight drawn intervals. Divide every endpoint by twenty-seven: the positions and lengths match the third-cut, unit-normalized thirds construction from Fractal Synthesis. After four rewrites there are sixteen drawn intervals in eighty-one advances. The turn angle has no effect because this sentence has no turning commands.

Find the same preset at the museum desk: RESET, then PRESET seven times. The first seven named presets still occupy their previous positions; Cantor is now reachable as the eighth. This connects two implementations of one construction. The table's quarters and two-fifths recipes require different rules or step lengths; they are not produced by these F/f rules.

Carry the sentence and reader into **Growth**. At present the turtle has one position and one heading. A branch needs somewhere to keep those values while another line continues.


---

<!-- hall: LSystems_Growth -->

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


---

<!-- hall: LSystems_Grammars_And_Curves -->

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

The tube bay remains available as a separate [optional application reading](applications.html): continue a hand-drawn path, give it a skin, make connections and compose a canopy. Those works have their own supplied builders and interfaces. They are not prerequisites for Architecture, and this lesson does not transfer its generated path into them. The four-file reader tests cover the main lesson; the optional applications have separate evidence.

<!-- @ -->


---

<!-- hall: LSystems_Architecture -->

# A path is not yet a passage

<!-- @lsystem_dungeon -->

## Learning elements

- Record a place without moving: R.
- Keep instructions separate from unique spatial addresses.
- Give a path a footprint on a construction grid.
- Union overlapping footprints; wall only exposed edges.
- Test a declared opening against a particular collision body.

Grammars and Curves separated the instruction from its interpretation. Keep that distinction. Here one fixed sentence supplies four segments. We add width, room footprints and collision boundaries without rewriting the path.

## First walk the existing work

Four pale lines lie inside a brass frame. The original miniature dungeon remains behind this study, among the retained collection. The tutorial follows the full-size construction at the front.

Take the dark point outside the frame. Its held trigger switches BUILD and PLAN. Move it between the three width marks: 0.4, 1.4 and 2.2 metres. The existing six buttons remain beside it. Start at 1.4, build, put down the point, then enter. Follow a side branch and return. The junction is open; its side ends are closed. The main stem has two deliberately chosen openings.

Leave the frame before changing the construction. ROOMS widens the junction into a 2.8-metre square. WIDTH changes the passages while their centrelines stay fixed. RULE reveals why two room instructions share one address. RESET restores PLAN, width 1.4 and rooms off.

The grammar is `F[+RF][-RF]F`. At each R, ask where the turtle is. Both branches save and return to the same junction. R records that position; it does not move. Two list entries can name one place.

## Continue the reader on the floor

Keep the previous study intact; create a sibling folder for the four complete files below. Attach `architecture.gd` to an empty, unit-scale Node3D in a clear museum study bay. Its local +Z side faces the visitor. Reserve the brass frame’s 11.6 by 11.6 metres, plus the controls in front and a route around the frame. The existing museum supplies the continuous floor, player, camera, lighting and XRTools. Do not put a duplicate construction over the installed one.

The same PointBody returns. The replacement function and copied-state stack return. This reader uses the horizontal plane: Vector2 stores **local x and z**, then the display gives those coordinates a height. Initial heading is (0,-1). Every F advances four metres. Plus turns (x,z) into (-z,x); minus does the reverse. These choices reproduce the dungeon’s raw XZ reading after the installed mapping `(raw.z,-raw.x)*4`. They replace the last hall’s vertical plane, 0.32-metre stride and variable angle. Reflection is not active here.

We need segments and room records for the whole plan, so this version does not retain a frame for every symbol. The grammar remains small: one replacement, four moves, two markers. Making the construction easier to inspect matters more here than adding generations.

### grammar.gd

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

func read(sentence: String) -> Dictionary:
	var balance := 0
	for symbol in sentence:
		if symbol == "[": balance += 1
		if symbol == "]": balance -= 1
		if balance < 0: return {"accepted": false}
	if balance != 0: return {"accepted": false}
	var state := {"pos": Vector2.ZERO, "heading": Vector2.UP}
	var stack: Array[Dictionary] = []
	var segments: Array = []
	var rooms: Array[Vector2] = []
	for symbol in sentence:
		match symbol:
			"F":
				var next: Vector2 = state.pos + state.heading * 4.0
				segments.append([state.pos, next])
				state.pos = next
			"R": rooms.append(state.pos)
			"+": state.heading = Vector2(-state.heading.y, state.heading.x)
			"-": state.heading = Vector2(state.heading.y, -state.heading.x)
			"[": stack.append(state.duplicate(true))
			"]": state = stack.pop_back()
	return {"accepted": true, "segments": segments, "rooms": rooms}
```

## Give the records a footprint

`make()` receives the records, width and room choice. Each orthogonal segment gets a rectangle, extended by half the width on both sides and at its ends. Each distinct room address gets a 2.8-metre square. The original room list keeps both Rs. A dictionary keyed by position keeps each address once.

Another dictionary stores occupied grid cells. Adding a cell already present changes nothing: overlapping corridors and rooms form a union. The 0.1-metre pitch represents all three chosen half-widths exactly. Other dimensions would need a declared rounding policy. Grid resolution is a construction decision, not a property of the grammar.

At every occupied cell, inspect four neighbours. If the neighbour is occupied, the edge is internal and gets no wall. This keeps the junction open. Exposed edges get walls, except at the two main ends. A grammar does not choose those doors for us.

The remaining helper groups adjacent cells into rectangles and collinear edges into wall runs. It reduces the number of meshes and colliders without filling holes. Read the first three functions closely; the complete grouping code follows so the example has no missing builder. Wall thickness extends outward from the footprint, preserving the measured clear width.

### footprint.gd

<!-- student-code:footprint.gd -->
```gdscript
extends RefCounted
const PITCH := 0.1
const DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

func add_rectangle(target: Dictionary, low: Vector2, high: Vector2) -> void:
	for z in range(floori((low.y + 0.0001) / PITCH), ceili((high.y - 0.0001) / PITCH)):
		for x in range(floori((low.x + 0.0001) / PITCH), ceili((high.x - 0.0001) / PITCH)):
			target[Vector2i(x, z)] = true

func make(records: Dictionary, width: float, rooms_on: bool) -> Dictionary:
	var occupied := {}
	var room_cells := {}
	var addresses := {}
	for at in records.rooms: addresses[at] = true
	for ends in records.segments:
		var a: Vector2 = ends[0]
		var b: Vector2 = ends[1]
		add_rectangle(occupied, a.min(b) - Vector2.ONE * width / 2, a.max(b) + Vector2.ONE * width / 2)
	if rooms_on:
		for at in addresses:
			add_rectangle(room_cells, at - Vector2.ONE * 1.4, at + Vector2.ONE * 1.4)
		occupied.merge(room_cells)
	return {"occupied": occupied, "rooms": room_cells, "addresses": addresses,
		"floors": rectangles(occupied), "walls": boundaries(occupied, width)}

func boundaries(occupied: Dictionary, width: float) -> Array:
	var edges := {}
	for cell: Vector2i in occupied:
		for direction in DIRECTIONS:
			if occupied.has(cell + direction): continue
			var center := (Vector2(cell) + Vector2.ONE * 0.5 + Vector2(direction) * 0.5) * PITCH
			# Only the two main ends are doors; branch ends stay closed.
			if direction.x == 0 and absf(center.x) < width / 2 and (center.y >= width / 2 - 0.001 or center.y <= -8.0 - width / 2 + 0.001): continue
			var constant: int = cell.x + (1 if direction.x > 0 else 0) if direction.x != 0 else cell.y + (1 if direction.y > 0 else 0)
			var key := Vector3i(direction.x, direction.y, constant)
			if not edges.has(key): edges[key] = []
			edges[key].append(cell.y if direction.x != 0 else cell.x)
	var walls: Array = []
	for key: Vector3i in edges:
		var values: Array = edges[key]
		values.sort()
		var start: int = values[0]
		var previous := start
		for i in range(1, values.size() + 1):
			if i < values.size() and values[i] == previous + 1:
				previous = values[i]
				continue
			var length := (previous + 1 - start) * PITCH
			var middle := (start + previous + 1) * PITCH * 0.5
			var center := Vector3(key.z * PITCH + key.x * 0.05, 0.93, middle) if key.x != 0 else Vector3(middle, 0.93, key.z * PITCH + key.y * 0.05)
			var size := Vector3(0.1, 1.7, length) if key.x != 0 else Vector3(length, 1.7, 0.1)
			walls.append({"center": center, "size": size})
			if i < values.size(): start = values[i]; previous = start
	return walls

func rectangles(cells: Dictionary) -> Array[Rect2i]:
	var remaining := cells.duplicate(); var result: Array[Rect2i] = []
	while not remaining.is_empty():
		var origin: Vector2i = remaining.keys()[0]
		for key: Vector2i in remaining:
			if key.y < origin.y or (key.y == origin.y and key.x < origin.x): origin = key
		var width := 1
		while remaining.has(origin + Vector2i(width, 0)): width += 1
		var height := 1
		while true:
			var full := true
			for x in width:
				if not remaining.has(origin + Vector2i(x, height)): full = false; break
			if not full: break
			height += 1
		for z in height:
			for x in width: remaining.erase(origin + Vector2i(x,z))
		result.append(Rect2i(origin, Vector2i(width,height)))
	return result

```

## Build the same plan twice

PLAN draws without adding collision. BUILD adds floor slabs and wall colliders with the same sizes as their meshes. The museum floor remains underneath both states. Pale centrelines are guides, not walls.

The compact program creates its point and labels. B builds; P returns to plan; W cycles width; O toggles room footprints; R resets. The point’s held trigger also switches BUILD/PLAN, and its local X chooses width. The installed museum retains its six-button desk; rebuilding those button scenes is not part of this example.

Before any change, `people_inside()` checks the prepared player groups in local coordinates. A visitor anywhere inside the fixed brass frame refuses the change, including in PLAN. A refused hand choice is remembered as already attempted: leaving the frame does not apply it later. Move to another mark or press again. This is a bounded local guard for the museum’s declared player groups, not a multiplayer occupancy system.

### architecture.gd

<!-- student-code:architecture.gd -->
```gdscript
extends Node3D
const Grammar = preload("grammar.gd")
const Footprint = preload("footprint.gd")
const PointBody = preload("point_body.gd")
const RULE := {"F": "F[+RF][-RF]F"}
const WIDTHS := [0.4, 1.4, 2.2]
var records: Dictionary
var floor_model = Footprint.new()
var layout: Dictionary
var width_index := 1
var built := false
var rooms_on := false
var revealed := false
var drawing: Node3D
var point: XRToolsPickable
var title: Label3D
var last_slot := -1

func _ready() -> void:
	var grammar = Grammar.new()
	var result: Dictionary = grammar.rewrite("F", RULE)
	assert(result.accepted)
	records = grammar.read(result.text)
	assert(records.accepted)
	drawing = Node3D.new(); add_child(drawing)
	point = PointBody.new(); add_child(point)
	point.action_pressed.connect(func(_body): act("PLAN" if built else "BUILD"))
	title = label("", Vector3(0, 1.6, 2))
	label("TRIGGER: BUILD / PLAN   W: WIDTH   O: ROOMS   R: RESET", Vector3(0, 0.9, 2.55))
	for i in 3: label(str(WIDTHS[i]), Vector3((i - 1) * 0.35, 1.02, 2.55))
	# Fixed frame marks the occupation check, outside the changing footprint.
	for x in [-5.8, 5.8]: box(self, Vector3(x, 0.01, -4), Vector3(0.025, 0.02, 11.6), Color("bfa875"), false)
	for z in [-9.8, 1.8]: box(self, Vector3(0, 0.01, z), Vector3(11.6, 0.02, 0.025), Color("bfa875"), false)
	rebuild()
	park()

func people_inside() -> bool:
	for group in ["em_walker", "player_body", "player"]:
		for person in get_tree().get_nodes_in_group(group):
			if person is Node3D:
				var p := to_local(person.global_position)
				if absf(p.x) < 5.8 and p.z > -9.8 and p.z < 1.8 and p.y > -1 and p.y < 4: return true
	return false

func act(id: String, selected: int = -1) -> void:
	if people_inside():
		title.text = "Leave the brass frame, then act again."
		return
	match id:
		"PLAN": built = false
		"BUILD": built = true
		"WIDTH": width_index = (width_index + 1) % 3 if selected < 0 else clampi(selected, 0, 2)
		"ROOMS": rooms_on = not rooms_on; revealed = true
		"RESET": width_index = 1; built = false; rooms_on = false; revealed = false
	rebuild()

func _physics_process(_dt: float) -> void:
	if point.held():
		var slot := clampi(roundi(to_local(point.global_position).x / 0.35 + 1), 0, 2)
		if slot != last_slot:
			last_slot = slot # Remember even a refused choice; do not queue it.
			if slot != width_index: act("WIDTH", slot)
	else:
		last_slot = -1
		park()

func park() -> void:
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3((width_index - 1) * 0.35, 1.18, 2.55))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var commands := {KEY_B: "BUILD", KEY_P: "PLAN", KEY_W: "WIDTH", KEY_O: "ROOMS", KEY_R: "RESET"}
	if commands.has(event.keycode): act(commands[event.keycode])

func rebuild() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child); child.queue_free()
	layout = floor_model.make(records, WIDTHS[width_index], rooms_on)
	for rect in layout.floors: slab(rect, 0.04 if built else 0.008, 0.08 if built else 0.016, Color("729d9c"), built)
	for rect in floor_model.rectangles(layout.rooms): slab(rect, 0.085 if built else 0.019, 0.006, Color("c19875"), false)
	if built:
		for wall in layout.walls:
			box(drawing, wall.center, wall.size, Color(0.52, 0.73, 0.76, 0.24), true)
			box(drawing, Vector3(wall.center.x, 0.34, wall.center.z), Vector3(wall.size.x, 0.52, wall.size.z), Color("c6c4ae"), false)
	for ends in records.segments:
		var a: Vector2 = ends[0]; var b: Vector2 = ends[1]; var c := (a + b) / 2
		box(drawing, Vector3(c.x, 0.096, c.y), Vector3(absf(b.x - a.x) + 0.025, 0.015, absf(b.y - a.y) + 0.025), Color("fff0bb"), false)
	title.text = "%s / width %.1f m / rooms %s\n%d moves / %d room records" % ["BUILT" if built else "PLAN", WIDTHS[width_index], "ON" if rooms_on else "OFF", records.segments.size(), records.rooms.size()]
	if revealed: title.text += " / %d addresses" % layout.addresses.size()

func slab(rect: Rect2i, y: float, height: float, colour: Color, solid: bool) -> void:
	var c := (Vector2(rect.position) + Vector2(rect.size) * 0.5) * Footprint.PITCH
	box(drawing, Vector3(c.x, y, c.y), Vector3(rect.size.x * Footprint.PITCH, height, rect.size.y * Footprint.PITCH), colour, solid)

func box(parent: Node3D, at: Vector3, size: Vector3, colour: Color, solid: bool) -> void:
	var mesh := MeshInstance3D.new(); var skin := BoxMesh.new(); skin.size = size; mesh.mesh = skin
	var material := StandardMaterial3D.new(); material.albedo_color = colour
	if colour.a < 1: material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = material; mesh.position = at; parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new(); body.collision_layer = 1; mesh.add_child(body)
		var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size
		collision.shape = shape; body.add_child(collision)

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new(); tag.text = text; tag.position = at
	tag.font_size = 32; tag.pixel_size = 0.0012; tag.outline_size = 6; add_child(tag)
	return tag
```

### point_body.gd — unchanged carried class

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

## Make one change of your own

Before editing, leave the frame. Replace only RULE’s production `F[+RF][-RF]F` with `F[+FR][-FR]F`. You moved each R to the other side of its branch’s F.

Predict the four segments first: they should not move. Predict the room addresses next: they should now be (4,-4) and (-4,-4) in the plan’s local x/z coordinates. Run the edited script and enable ROOMS. Two separate squares replace the shared square at the junction. The list still has two records; the number of unique addresses has changed from one to two. Returning to the original rule restores the shared room.

Then compare the 0.4 and 1.4-metre entrances. A test capsule 0.6 metres across should stop at the narrow opening and pass the wider one. The code tests that particular body against actual colliders; your avatar has its own dimensions and movement behavior. A connected line alone is not a passage test. Moving the room markers does not widen the entrance.

## What travels onward

Keep three things separate: the grammatical record, the occupied footprint and the boundary a body meets. This example builds one orthogonal plan; its two door exceptions and fixed guard bounds are specific to that plan. It does not join arbitrary angles, repair any generated building, simulate structural loads or save a design between visits. The miniature and eight companion works remain outside this required reconstruction.

In Competition, a proposed next step will meet a place that is already occupied. We now have a concrete way to ask which part of that decision belongs to a rule and which part belongs to its surroundings.


---

<!-- hall: LSystems_Competition -->

# Competition — the next turn

## Learning elements

- A shared resource grid
- Sequential updates and execution order
- Consumption before a conditional rewrite
- Independent before/after records

Architecture gave a sentence width and boundaries. Here two copies of a sentence meet the same changing field. You bring the rewrite function, saved turtle state, indexed records, and the point you can hold. The new question is **what has already happened when the next instruction runs?**

## Look at the existing pair

At the front of Competition, both stems start with F and use the same rule. Hold the black point beside the console. A trigger press gives one tree a turn; the next press gives the other its turn. STEP does the same. Take two turns: A receives 2.250 and B receives 1.980. ORDER restores the starting field and makes B first. Repeat: the allocation reverses. These are model values, not measured quantities of food.

SEASON restores the comparison in winter. Consumption still happens, but the sentence stays F. Look at the soil as well as the stem. The unchanged shape does not mean that nothing happened.

## Rebuild the relation

Continue in the prepared museum project. Put the five files below in one folder and attach `competition.gd` to an empty, unit-scale Node3D in a clear working bay. The existing museum supplies the floor, camera, player and XRTools. Run the project as before. Do not attach this script to the running ForestCompetition object: it makes a separate small study. For comparison, place its host at the front study's transform in a working copy with the existing primary hidden; leave the visitor route clear. Its visual field spans x −3.5…3.5 and z −6.5…0.5; the control is at z 2.3.

The point, cylinder renderer and grammar reader are unchanged from Curves. The branches return to that reader's vertical plane, 25° turns and 0.32-metre steps. Each copy starts at a separate display position; its soil address is recorded elsewhere. Moving a display is not moving a root.

We isolate the opening resource experiment. Each root keeps a fixed five-by-five sampling square. Health, diameter growth, diffusion and automatic seasons are left to the installed forest. Consequently, the first pair of resource requests agrees with the museum; later resource histories and branch dimensions need not. The installed forest enlarges its sampling area as its estimated crown grows. This small study keeps the area fixed so that order stays visible.

### 1. Keep one soil field

`soil.gd` gives each row its own array. `patch()` turns a root address into valid cell addresses. `consume()` reads each current value, takes fifteen percent and writes the remainder back to **the shared grid**.

<!-- student-code:soil.gd -->
```gdscript
extends RefCounted
const SIDE := 20
const SUPPLY := 0.6
const ROOTS := [Vector2i(9, 10), Vector2i(10, 10)]
const RADIUS := 2
const FRACTION := 0.15
var cells: Array = []

func reset() -> void:
	cells.clear()
	for z in SIDE:
		var row: Array[float] = []
		row.resize(SIDE)
		row.fill(SUPPLY)
		cells.append(row)

func patch(root: Vector2i) -> Array[Vector2i]:
	var addresses: Array[Vector2i] = []
	for dz in range(-RADIUS, RADIUS + 1):
		for dx in range(-RADIUS, RADIUS + 1):
			var cell := root + Vector2i(dx, dz)
			if cell.x >= 0 and cell.x < SIDE and cell.y >= 0 and cell.y < SIDE:
				addresses.append(cell)
	return addresses

func consume(root: Vector2i) -> float:
	var uptake := 0.0
	for cell in patch(root):
		var available: float = cells[cell.y][cell.x]
		var take := minf(available * FRACTION, available)
		cells[cell.y][cell.x] -= take
		uptake += take
	return uptake
```

Both initial squares contain 25 cells. Their roots are one cell apart, so they share 20 cells. The first request receives 25 × 0.6 × 0.15 = 2.25. For the second, those 20 shared cells contain 0.51; five untouched cells still contain 0.6. Its uptake is (20 × 0.51 + 5 × 0.6) × 0.15 = 1.98.

The second request does not read a saved copy of the opening grid. This differs from the cellular automata update that computed an entire next generation from one old state. Both are valid schedules; they compute different relations.

This small experiment is deterministic: the same starting field, season and turn order reproduce the same allocation. In this fixed-patch, fixed-fraction model, reversing the first pair's order exchanges who receives more while leaving the same soil after both requests. That is a property of this model, not a general claim about ecological competition.

### 2. Give one tree a turn

`competition.gd` creates two sentence records, the field, the drawings and the held point. ENTER or its held trigger calls `attempt()`. O resets with the opposite first tree; W resets with the opposite season; R returns to spring with A first. ORDER keeps the selected season, and SEASON keeps the selected first tree.

Read `attempt()` first. `trees[next]` selects a record; editing that dictionary updates the stored tree. Consumption precedes the winter test. A successful test permits the inherited rewrite; it does not invent a new branching algorithm. `next = 1 - next` alternates 0 and 1.

The two `duplicate(true)` calls preserve complete field snapshots. A reference to the same mutable array would keep changing, erasing the evidence of the earlier state. The retained history is bounded to 80 attempts; it lives in this running scene, not across halls or restarts.

<!-- student-code:competition.gd -->
```gdscript
extends Node3D
const Soil = preload("soil.gd")
const Grammar = preload("grammar.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const RULE := {"F": "F[+F]F[-F][F]"}
const CAP := 3
const FIELD := Vector3(0, 0, -3)
const CELL := 0.35
const COLORS := [Color("f0b776"), Color("92d5d9")]
var soil = Soil.new()
var grammar = Grammar.new()
var trees: Array[Dictionary] = []
var history: Array[Dictionary] = []
var first := 0
var next := 0
var winter := false
var drawing: Node3D
var readout: Label3D
var point: XRToolsPickable

func _ready() -> void:
	readout = label("", Vector3(0, 1.85, 1.6))
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): act("STEP"))
	label("HELD TRIGGER / ENTER: STEP\nO: ORDER   W: WINTER   R: RESET", Vector3(0, 1.02, 2.3))
	park()
	reset()

func _physics_process(_dt: float) -> void:
	if not point.held(): park()

func park() -> void:
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.2, 2.3))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ENTER: act("STEP")
		KEY_O: act("ORDER")
		KEY_W: act("SEASON")
		KEY_R: act("RESET")

func act(action: String) -> void:
	match action:
		"STEP": attempt(); return
		"ORDER": first = 1 - first
		"SEASON": winter = not winter
		"RESET": first = 0; winter = false
		_: return
	reset()

func reset() -> void:
	soil.reset()
	trees.clear()
	for i in 2:
		trees.append({"sentence": "F", "generation": 0, "last": 0.0, "total": 0.0})
	next = first
	history.clear()
	redraw()

func attempt() -> void:
	var tree: Dictionary = trees[next]
	var event := {"tree": next, "before": soil.cells.duplicate(true), "uptake": 0.0,
		"generation_before": tree.generation, "reason": "generation limit"}
	if tree.generation < CAP:
		var uptake: float = soil.consume(Soil.ROOTS[next])
		event.uptake = uptake
		event.reason = "winter" if winter else "uptake too small"
		if uptake > 0.05 and not winter:
			var result: Dictionary = grammar.rewrite(tree.sentence, RULE)
			if result.accepted:
				tree.sentence = result.text
				tree.generation += 1
				event.reason = "rewrite allowed"
			else: event.reason = "symbol limit"
	tree.last = event.uptake
	tree.total += event.uptake
	event["after"] = soil.cells.duplicate(true)
	event["generation_after"] = tree.generation
	history.append(event)
	if history.size() > 80: history.pop_front()
	next = 1 - next
	redraw()

func redraw() -> void:
	if is_instance_valid(drawing):
		remove_child(drawing)
		drawing.queue_free()
	drawing = Node3D.new()
	add_child(drawing)
	# One mesh for all 400 tiles. Height and colour show the same value.
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in Soil.SIDE:
		for x in Soil.SIDE:
			var value: float = soil.cells[z][x]
			var p := FIELD + Vector3(-3.5 + x * CELL, 0.025 + value * 0.2, -3.5 + z * CELL)
			mesh.surface_set_color(Color("322837").lerp(Color("6daa85"), value / Soil.SUPPLY))
			for offset in [Vector3.ZERO, Vector3(.33, 0, .33), Vector3(.33, 0, 0),
				Vector3.ZERO, Vector3(0, 0, .33), Vector3(.33, 0, .33)]:
				mesh.surface_add_vertex(p + offset)
	mesh.surface_end()
	var field := MeshInstance3D.new()
	field.mesh = mesh
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	field.material_override = material
	drawing.add_child(field)
	for i in 2:
		var root: Vector2i = Soil.ROOTS[i]
		var centre := FIELD + Vector3(-3.5 + (root.x + .5) * CELL, .18 + i * .025, -3.5 + (root.y + .5) * CELL)
		var half := (2 * Soil.RADIUS + 1) * CELL * .5
		var corners := [Vector3(-half, 0, -half), Vector3(half, 0, -half), Vector3(half, 0, half), Vector3(-half, 0, half)]
		for j in 4: rod(centre + corners[j], centre + corners[(j + 1) % 4], COLORS[i])
		rod(centre, centre + Vector3.UP * .18, COLORS[i])
		# Display position is separate from the soil address. Reader unchanged.
		var origin := Vector3(-2.5 if i == 0 else 2.5, .45, -4.8)
		var reading: Dictionary = grammar.read(trees[i].sentence, 25, false)
		for j in range(0, reading.ends.size(), 2):
			rod(origin + reading.ends[j], origin + reading.ends[j + 1], COLORS[i])
		var caption := label("%s / generation %d\nlast %.3f / total %.3f" % ["A" if i == 0 else "B", trees[i].generation, trees[i].last, trees[i].total], origin + Vector3(0, -.12, .4))
		caption.reparent(drawing)
		caption.modulate = COLORS[i]
	readout.text = "%s / next %s\n%s" % ["WINTER" if winter else "SPRING", "A" if next == 0 else "B", "Same rule. Shared soil." if history.is_empty() else history[-1].reason]

func rod(a: Vector3, b: Vector3, tint: Color) -> void:
	var line = LineSkin.new()
	drawing.add_child(line)
	line.material_override.albedo_color = tint
	line.show_segment(a, b - a, a.distance_to(b))

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.position = at
	tag.font_size = 36
	tag.pixel_size = .002
	tag.outline_size = 8
	add_child(tag)
	return tag
```

The generation cap is checked before consumption. At three generations, a capped tree takes nothing. Winter instead consumes and then refuses rewriting. These two still stems have different histories. The symbol budget in `rewrite()` remains an additional limit; this three-generation example stays below it.

`redraw()` reads the resulting state; it does not take another turn. The tile height and colour expose resource values. Each outline identifies a sampling square, and the small vertical mark identifies its centre cell. The two branching displays use the same reader and stride. Their separate positions help inspection, without separating their resource patches. The drawing has no terrain collision; the supplied museum floor supports the visitor.

### 3. Keep the known tools

These are the exact Curves files. Keep your existing copies if unchanged. They are printed here so the complete program can be reconstructed without hidden helpers. No scene-child references or prepared meshes are required.

`grammar.gd` retains whole-generation rewriting, bracket validation and copied turtle state. This study calls its ordinary reader with sideways set to false.

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

`point_body.gd` retains the frozen pickable sphere and desktop grab hooks. The new behaviour is the action connection in `competition.gd`.

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

`line_skin.gd` gives each segment a finite cylindrical surface, as before.

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

## Predict, change, check

1. Reset, then take two turns. Both generations become one; the last uptake values are 2.250 and 1.980. Reverse the first tree from a reset state and repeat. The allocation reverses. For this fixed-area, fixed-fraction model, the field after the completed pair is the same in either order.
2. Select winter and take two turns. Both sentences remain F while the resource total falls by 4.23. Read the saved `before` and `after` grids. Taking another turn must not change the older event's snapshots.
3. In `soil.gd`, change only the second root from `Vector2i(10, 10)` to `Vector2i(14, 10)`. Predict whether the two sampling squares still overlap. Run the complete edited program: each first request now receives 2.250, whichever acts first. Explain why order stopped changing this allocation without changing the grammar.
4. Restore the original roots. Six spring attempts give both trees three generations. The next two leave the soil unchanged. Contrast this with the winter result.

## Return to the forest

The installed SOIL button advances diffusion and replenishment for one second without giving a tree a turn. Our small program deliberately omits that extra process. Behind the pair, the original five-strategy forest combines soil time, seasons, crown size and crowding. The coral nearby follows a separate recipe; it does not consume this field.

You carry forward an unchanged instruction whose execution depends on a changing situation, and records that let you inspect the difference. In Living, we ask which changes an authored set of controls lets us request from a body.


---

<!-- hall: LSystems_Living -->

# Living — a design kept

## Learning elements

- Design records and parameter ranges
- Rounding and clamping a requested value
- A generated rule and a generated body
- Independent retained specimens

Competition kept the instructions fixed while their conditions changed. Living lets us change the values from which instructions are made. You bring rewriting, a saved turtle state, the point in your hand, and the distinction between an editable record and its copy.

## Start with the existing sculptor

Press RESET, then HOLD. The editing tree now has a witness beside it. Depth starts at 4.000. Press MORE four times. The value reaches 4.800, but both trees still agree. One more press reaches 5.000: the editing tree adds a generation.

The generator halves Depth, rounds, then clamps the result between two and five. At 4.8 it reads 2.4 and selects two generations. At 5 it reads 2.5 and selects three. A changed input does not always make a changed instruction.

The black point on the front rail edits the selected gene through horizontal hand movement. Its held trigger performs HOLD. GENE selects another gene; PLANT keeps a floor specimen. Release before choosing another gene. The original sliders remain at the side. All act on the same editing design.

## Build a small version in the museum

Put these four files together and attach `living.gd` to an empty, unit-scale Node3D in a clear working bay of the prepared museum. The project already supplies the floor, camera, player and XRTools. Keep your existing `point_body.gd` and `line_skin.gd`; their copies below are unchanged. No prepared mesh or named scene child is needed.

The study makes three display positions: editing at (−2,0.78,−2.5), held at (2,0.78,−2.5), planted at (0,0.035,−8). Leave a clear bay around them and a bypass. In a working copy, the original sculptor can be hidden for comparison at its host; this does not require replacing the museum's primary artifact. The small drawing has no branch colliders and does not change the floor.

We keep three inputs: Depth, Forks and Angle. Arrange stays on the source's opposite-branch recipe; taper stays 0.68; the starting step is 1.2 metres. Leaves, roots, twist and droop stay off. The cylinders retain the line's familiar thickness rather than reconstructing the source's tapered bark. This is the same parameter-to-rule relation with a smaller presentation, not every feature of the sculptor.

### The design becomes instructions

In `design.gd`, `parameters()` converts the record to counts and an angle. `rules_for()` makes F become S followed by the requested forks. S becomes FF on the next rewrite. The opposite-branch recipe alternates + and −; later pairs also roll the turtle's frame. The slash is a roll instruction, not division in the sentence.

The rewrite function is unchanged from the earlier lessons. Its symbol budget is raised explicitly to 32,768 so this bounded three-gene range can be generated before the separate 200-command drawing limit is applied. These are different limits: one bounds sentence construction, the other bounds its display.

<!-- student-code:design.gd -->
```gdscript
extends RefCounted
const SYMBOL_LIMIT := 32768
const DRAW_LIMIT := 200

func parameters(record: Dictionary) -> Dictionary:
	return {"generations": clampi(roundi(float(record.depth) * 0.5), 2, 5),
		"forks": clampi(roundi(float(record.forks)), 2, 5),
		"angle": clampf(float(record.angle), 15, 90)}

func rules_for(forks: int) -> Dictionary:
	var replacement := "S"
	for i in forks:
		var turn := "+" if i % 2 == 0 else "-"
		replacement += "[" + turn + "/".repeat(i / 2) + "F]"
	return {"F": replacement, "S": "FF"}

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

func build(record: Dictionary) -> Dictionary:
	var params := parameters(record)
	var rules := rules_for(params.forks)
	var sentence := "F"
	for generation in params.generations:
		var result := rewrite(sentence, rules)
		if not result.accepted:
			return {"accepted": false, "error": "Symbol budget refused this generation."}
		sentence = result.text
	var reading := read(sentence, params.angle)
	reading.merge({"accepted": true, "parameters": params, "sentence": sentence,
		"requested": sentence.count("F") + sentence.count("S")})
	return reading

func read(sentence: String, angle: float) -> Dictionary:
	# The bare, opposite-arranged subset of TreeMorphology's turtle.
	# Fixed inputs: step1.2m, taper.68, no droop, twist, leaves or roots.
	var state := {"pos": Vector3.ZERO, "dir": Vector3.UP,
		"right": Vector3.RIGHT, "up": Vector3.BACK, "length": 1.2}
	var stack: Array[Dictionary] = []
	var ends: Array[Vector3] = []
	var commands := 0
	var radians := deg_to_rad(angle)
	for symbol in sentence:
		if commands >= DRAW_LIMIT: break
		match symbol:
			"F", "S":
				var distance: float = state.length * (0.6 if symbol == "S" else 1.0)
				var finish: Vector3 = state.pos + state.dir * distance
				if distance >= 0.001:
					ends.append(state.pos); ends.append(finish)
				state.pos = finish
				if symbol == "F": state.length *= 0.68
				commands += 1
			"+", "-":
				var sign := 1.0 if symbol == "+" else -1.0
				state.dir = (state.dir * cos(radians) + state.right * sin(radians) * sign).normalized()
				state.right = state.dir.cross(state.up).normalized()
			"/":
				state.right = (state.right * cos(radians) + state.up * sin(radians)).normalized()
				state.up = state.right.cross(state.dir).normalized()
			"[": stack.append(state.duplicate(true))
			"]": state = stack.pop_back()
	return {"ends": ends, "drawn_commands": commands}
```

Read `parameters()` and `rules_for()` first. Those are the new connection between a design and its grammar. The reader continues the saved-state pattern. F advances and shortens the next step; S advances sixty percent of a step without shortening it. A bracket saves position, direction, orientation and current length. Returning restores them all.

This reader handles only sentences made by `rules_for()`. It is not a parser for arbitrary user text. Its added S and roll operations reproduce the bare, opposite-arranged subset of the museum turtle. They do not require a new general grammar language. The readout separates requested commands, commands read, and visible cylinders: a command can be counted even when its segment is too short to draw.

### Keep the record when the design changes

`living.gd` holds three records: the editable one and two optional copies. HOLD replaces the witness; PLANT replaces the floor specimen. Neither edits the other. RESET restores only the editing design.

`keep()` uses `duplicate(true)` to store a separate dictionary. This study rebuilds a specimen from its retained recipe whenever the display refreshes. The installed sculptor instead copies its built geometry and its larger DNA resource. Both preserve the design at the moment of the action. A reproducible record depends on the builder too: these records are recipes for this version of `design.gd`, not a promise that future algorithms will produce identical bodies.

<!-- student-code:living.gd -->
```gdscript
extends Node3D
const Design = preload("design.gd")
const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const START := {"depth": 4.0, "forks": 2.0, "angle": 30.0}
const GENES := ["depth", "forks", "angle"]
const RANGES := [Vector2(2, 10), Vector2(1, 8), Vector2(15, 90)]
const PLACES := [Vector3(-2,.78,-2.5), Vector3(2,.78,-2.5), Vector3(0,.035,-8)]
var model = Design.new()
var editing: Dictionary = START.duplicate(true)
var held: Dictionary = {}
var planted: Dictionary = {}
var preview: Dictionary
var selected := 0
var drawing: Node3D
var readout: Label3D
var point: XRToolsPickable
var last_detent := -1

func _ready() -> void:
	readout = label("", Vector3(0,1.9,1.7))
	label("G: GENE   arrows: LESS / MORE\nH / HELD TRIGGER: HOLD   P: PLANT   R: RESET",Vector3(0,.92,2.75))
	point = PointBody.new(); add_child(point)
	point.action_pressed.connect(func(_body): keep("held"))
	refresh(); park()

func _physics_process(_dt: float) -> void:
	if point.held():
		var detent := clampi(roundi((to_local(point.global_position).x / .8 + .5) * 40), 0, 40)
		if last_detent == -1:
			last_detent = detent
			return
		if detent != last_detent:
			last_detent = detent
			set_normalized(detent / 40.0)
	else:
		last_detent = -1
		park()

func normalized() -> float:
	var span: Vector2 = RANGES[selected]
	return inverse_lerp(span.x, span.y, editing[GENES[selected]])

func park() -> void:
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3((normalized()-.5)*.8,1.18,2.55))

func set_normalized(value: float) -> void:
	var span: Vector2 = RANGES[selected]
	editing[GENES[selected]] = lerpf(span.x, span.y, clampf(value,0,1))
	refresh()

func keep(slot: String) -> void:
	# Retain the recipe, not a reference to the editable dictionary.
	var snapshot := editing.duplicate(true)
	if slot == "held": held = snapshot
	elif slot == "planted": planted = snapshot
	refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_G: selected = (selected+1) % GENES.size(); refresh()
		KEY_LEFT: set_normalized(snappedf(normalized()-.025,.025))
		KEY_RIGHT: set_normalized(snappedf(normalized()+.025,.025))
		KEY_H: keep("held")
		KEY_P: keep("planted")
		KEY_R: editing = START.duplicate(true); selected = 0; refresh()

func refresh() -> void:
	preview = model.build(editing)
	if is_instance_valid(drawing): remove_child(drawing); drawing.queue_free()
	drawing = Node3D.new(); add_child(drawing)
	var records := [editing, held, planted]
	for i in 3:
		if records[i].is_empty(): continue
		var result: Dictionary = model.build(records[i])
		if not result.accepted: continue
		for j in range(0,result.ends.size(),2):
			var line = LineSkin.new(); drawing.add_child(line)
			var a: Vector3 = PLACES[i]+result.ends[j]
			var b: Vector3 = PLACES[i]+result.ends[j+1]
			line.show_segment(a,b-a,a.distance_to(b))
		var caption := label("%s / depth %.3f\n%d generations / %d commands" % [["EDITING","HELD","PLANTED"][i],records[i].depth,result.parameters.generations,result.requested],PLACES[i]+Vector3(0,-.15,.6))
		caption.reparent(drawing)
	if not preview.accepted: readout.text = preview.error; return
	readout.text = "%s %.3f / %d generations / %d forks\n%d requested / %d read / %d visible cylinders" % [GENES[selected],editing[GENES[selected]],preview.parameters.generations,preview.parameters.forks,preview.requested,preview.drawn_commands,preview.ends.size()/2]

func label(text: String, at: Vector3) -> Label3D:
	var tag := Label3D.new(); tag.text=text; tag.position=at
	tag.font_size=36; tag.pixel_size=.002; tag.outline_size=8; add_child(tag)
	return tag
```

G selects a gene; the arrow keys decrease or increase it on the same normalized 0.025 grid as the museum buttons. H holds, P plants, R resets. In VR, move the point along the rail and use its held trigger to keep a witness. Picking it up without moving leaves the value alone, including values between hand detents. Release parks it at the current setting. The small program rebuilds immediately; the museum waits 0.3 seconds after an edit and flushes that pending rebuild before HOLD or PLANT.

### Carry the known point and line

These two files are unchanged from Competition. The action connection and the design record give them their new job.

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

## Make a prediction you can check

1. Hold the opening design. Increase Depth through 4.2,4.4,4.6,4.8. Confirm that the sentence and segment endpoints remain equal to the witness. At 5.0, confirm that the generation count and sentence change while the witness remains at 4.0.
2. Select Angle. Change it and predict which record changes: the sentence, the generation count, or the segment endpoints? Angle changes the interpretation; the sentence and its counts stay fixed.
3. Plant, then edit again. RESET must restore the opening editing design without changing either retained recipe. A later PLANT replaces only the planted recipe.
4. In the START dictionary, change only `"angle": 30.0` to `"angle": 45.0`. Run the complete edited program. Predict the same sentence and number of commands, but different endpoints. Hold this version, change its angle again, then rebuild directly from the held record to verify that the retained body returns.

These snapshots live in this running scene. The small program does not save to disk, export catalyst DNA or move its specimens into the next hall. The installed PLANT also exports an independent DNA resource for an older catalyst consumer, which can mutate and rescale it; that is a separate operation.

## Which changes remain unavailable?

At maximum Depth and Forks the source recipe requests 4,964 F/S commands. This study, like the installed preview at its current detail level, reads at most 200. A complete-looking tree may be a partial reading. Three controls also cannot request a branch reconnecting to an earlier branch, a new alphabet, or a body that remakes the floor. Those need another operation or another builder.

Keep the difference between raw values, compiled instructions and a displayed body. Next, Shape Grammars returns to the cube and makes its face operations available to a design record.


---

<!-- hall: LSystems_Shape_Grammars -->

# Shape Grammars — a face continues

## Learning elements

- Seed-face indices and descendant tags
- Inset towards a centroid
- Extrusion along a face normal
- Selecting once, then replacing in reverse index order
- A saved recipe, repeated operations and their limits

Living separated a design record from the instructions and body made from it. Here the cube returns. We change its face list directly. The point, coordinates, triangles, arrays and loops are already ours; the new question is which faces receive the next operation.

We now extend the sequence beyond L-systems. The earlier rules replaced symbols; these rules replace selected mesh faces. Keep the distinction between choosing what receives an operation and constructing its replacement. The same questions remain useful with a different representation.

## Read the six existing specimens

Start at 01. The top looks square, but the diagonal separates two triangles. At 02, each triangle has drawn towards its own centre. At 03, those smaller triangles have risen 0.4 metres; walls connect them to the edges they left. These are two tips, not one square lid.

At 04, the same pair of operations has run three times. Only the new tips continue. The mint shoulders stay behind. Specimen 05 uses a smaller inset amount. Specimen 06 changes the initial selection from the top pair to all twelve triangles. The museum keeps all six forms so that you can walk back and compare them. They are fixed constructions, not a growing simulation.

## Reconstruct the operation

Put these three files together. Attach `family.gd` to an empty, unit-scale Node3D in your working copy of the prepared museum. A clear bay between the two collections is available at hall-local (10.5,0,21.5), rotated 180 degrees around Y. Keep the existing camera, floor, player and XRTools. The example creates its mesh, readout and familiar point in code. It displays one recipe at a time; the gallery retains the comparisons nearby. The example's surface and edge overlay have no colliders. Its lowest point sits 0.56 metres above the floor, matching the gallery's display height, without adding another plinth.

### The seed and its descendants

`faces.gd` starts with eight cube positions and twelve index triples, as in Primitives. This is the vertex order used by the museum's cube factory. Seed faces 8 and 9 are the upward pair. An index tells us where a record is now; it is not a permanent identity.

Before reading the construction code, follow only the selection:

1. At the cube, choose the two top faces, indices 8 and 9. Both receive the tag `growing`.
2. After inset, find the two smaller pink triangles. They receive that tag; their mint borders do not.
3. Predict the next operation's selection: the two pink tips. Their old list addresses are no longer the way to find them.

`growing` is an eligibility label shared by several faces, not a unique identity for each face. Read the tag check in `operate()` before the corner calculations. It collects the selected indices once, before any replacement.

Why process them backwards? Imagine a list A, B, C, D, E. B and D occupy indices 1 and 3. Removing B first moves D to index 2; the old index 3 now names E. Removing D first leaves B at index 1. Descending index order protects this pass's selection. Giving the new tip its tag prepares the next pass. These are two different jobs.

### Two ways to place three new corners

Inset averages the three corners to find their centroid. Each corner moves a fraction of the way towards it. Extrusion moves each corner along the face's outward normal. Both replace one triangle with seven: one new tip and two triangles along each of its three edges. Each successful replacement therefore adds six face records.

The extrusion keeps the museum's checks for tiny or very elongated triangles. The small builder accepts zero to three rounds and distinct seed indices. It retains the input recipe independently. It does not implement the factory's other metadata, zone inheritance or arbitrary mesh operations.

<!-- student-code:faces.gd -->
```gdscript
extends RefCounted
const VERTICES := [Vector3(-.5,-.5,.5),Vector3(.5,-.5,.5),Vector3(.5,.5,.5),Vector3(-.5,.5,.5),
	Vector3(-.5,-.5,-.5),Vector3(.5,-.5,-.5),Vector3(.5,.5,-.5),Vector3(-.5,.5,-.5)]
const FACES := [[0,1,2],[0,2,3],[5,4,7],[5,7,6],[4,0,3],[4,3,7],
	[1,5,6],[1,6,2],[3,2,6],[3,6,7],[4,5,1],[4,1,0]]

func build(recipe: Dictionary) -> Dictionary:
	if recipe.rounds < 0 or recipe.rounds > 3:
		return {"accepted":false,"error":"Use zero to three rounds."}
	var chosen: Array = recipe.faces
	for id in chosen:
		if not id is int or id < 0 or id >= 12 or chosen.count(id) != 1:
			return {"accepted":false,"error":"Use distinct seed-face indices from zero to eleven."}
	var mesh := {"vertices":PackedVector3Array(VERTICES),"faces":[],"tags":[],
		"accepted":true,"recipe":recipe.duplicate(true)}
	for i in FACES.size():
		mesh.faces.append(PackedInt32Array(FACES[i]))
		mesh.tags.append("growing" if chosen.has(i) else "seed")
	if recipe.get("inset_only",false): operate(mesh,true,recipe.amount)
	for round in int(recipe.rounds):
		operate(mesh,true,recipe.amount)
		operate(mesh,false,recipe.amount)
	return mesh

func operate(mesh: Dictionary, inset: bool, amount: float) -> void:
	# Select once per operation, before removing any faces.
	var selected: Array[int] = []
	for i in mesh.faces.size():
		if mesh.tags[i] == "growing": selected.append(i)
	selected.reverse()
	for id in selected:
		var face: PackedInt32Array = mesh.faces[id]
		var a: Vector3 = mesh.vertices[face[0]]
		var b: Vector3 = mesh.vertices[face[1]]
		var c: Vector3 = mesh.vertices[face[2]]
		var centre := (a+b+c)/3.0
		var normal := (b-a).cross(c-a)
		if not inset:
			var shortest := minf(a.distance_to(b),minf(b.distance_to(c),c.distance_to(a)))
			var longest := maxf(a.distance_to(b),maxf(b.distance_to(c),c.distance_to(a)))
			# Match the museum's area/aspect guards before extrusion.
			if normal.length()*.5 < .001 or shortest/longest < .05: continue
		var tips: Array[int] = []
		for p in [a,b,c]:
			tips.append(mesh.vertices.size())
			var at: Vector3 = p.lerp(centre,clampf(amount,.01,.99)) if inset else p+normal.normalized()*.4
			mesh.vertices.append(at)
		mesh.faces.remove_at(id); mesh.tags.remove_at(id)
		add_face(mesh,tips,"growing")
		for j in 3:
			var k := (j+1)%3
			var role := "shoulder" if inset else "wall"
			add_face(mesh,[face[j],face[k],tips[k]],role)
			add_face(mesh,[face[j],tips[k],tips[j]],role)

func add_face(mesh: Dictionary, indices: Array, tag: String) -> void:
	mesh.faces.append(PackedInt32Array(indices)); mesh.tags.append(tag)

func surface(mesh: Dictionary) -> ArrayMesh:
	var builder := SurfaceTool.new(); builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in mesh.faces.size():
		var face: PackedInt32Array = mesh.faces[i]
		var a: Vector3 = mesh.vertices[face[0]]
		var b: Vector3 = mesh.vertices[face[1]]
		var c: Vector3 = mesh.vertices[face[2]]
		var normal := (b-a).cross(c-a)
		if normal.length_squared() < 1e-10: continue
		var colour := Color("ddd9ce")
		if mesh.tags[i] == "growing": colour=Color("ea749a")
		elif mesh.tags[i] == "shoulder": colour=Color("84c9be")
		builder.set_normal(normal.normalized()); builder.set_color(colour)
		for p in [a,b,c]: builder.add_vertex(p)
	return builder.commit()
```

The surface builder reads each index triple as three positions. The cross product supplies the same normal used by extrusion. Pink marks `growing`, mint marks `shoulder`, and pale faces include the original body and extrusion walls. The material below shows both sides, like the installed family; two-sided rendering is not a test of watertightness. The thin dark overlay makes the triangle edges visible without changing the faces.

### A recipe you can return to

`family.gd` names the same six comparisons as the gallery. Every selection rebuilds from the cube, so changing the displayed recipe does not accidentally operate on the last result. The inset-only recipe isolates the first operation. The next adds extrusion; the fourth repeats the pair three times. A held trigger or Space advances to the next recipe. R returns to the first. Moving the point does not move vertices or change a recipe; release parks it again.

<!-- student-code:family.gd -->
```gdscript
extends Node3D
const Faces = preload("faces.gd")
const PointBody = preload("point_body.gd")
const RECIPES := [
	{"title":"01 CUBE","faces":[8,9],"rounds":0,"amount":.28},
	{"title":"02 INSET","faces":[8,9],"rounds":0,"amount":.28,"inset_only":true},
	{"title":"03 EXTRUDE","faces":[8,9],"rounds":1,"amount":.28},
	{"title":"04 REPEAT","faces":[8,9],"rounds":3,"amount":.28},
	{"title":"05 WIDER","faces":[8,9],"rounds":3,"amount":.08},
	{"title":"06 ALL","faces":[0,1,2,3,4,5,6,7,8,9,10,11],"rounds":3,"amount":.28}
]
var model = Faces.new()
var index := 0
var record: Dictionary
var body: MeshInstance3D
var wire: MeshInstance3D
var label: Label3D
var point: XRToolsPickable

func _ready() -> void:
	body=MeshInstance3D.new(); add_child(body)
	var finish:=StandardMaterial3D.new(); finish.vertex_color_use_as_albedo=true
	finish.cull_mode=BaseMaterial3D.CULL_DISABLED; finish.roughness=.56
	body.material_override=finish
	wire=MeshInstance3D.new(); body.add_child(wire)
	var ink:=StandardMaterial3D.new(); ink.albedo_color=Color("252d40")
	ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; wire.material_override=ink
	wire.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	label=Label3D.new(); label.position=Vector3(0,1.7,2.8)
	label.font_size=32; label.pixel_size=.0015; label.outline_size=8; add_child(label)
	point=PointBody.new(); point.position=Vector3(0,1.15,2.2); add_child(point)
	point.action_pressed.connect(func(_body): advance())
	show_recipe(0)

func show_recipe(which: int) -> void:
	index=clampi(which,0,RECIPES.size()-1)
	record=model.build(RECIPES[index])
	if not record.accepted: label.text=record.error; return
	body.mesh=model.surface(record)
	var low: float=record.vertices[0].y
	for p in record.vertices: low=minf(low,p.y)
	# Keep metre scale; place the lowest point at the same height as the gallery.
	body.position.y=.56-low
	var lines:=ImmediateMesh.new(); lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for face in record.faces:
		for j in 3:
			lines.surface_add_vertex(record.vertices[face[j]])
			lines.surface_add_vertex(record.vertices[face[(j+1)%3]])
	lines.surface_end(); wire.mesh=lines
	label.text="%s / %d faces / %d growing\nSpace or held trigger: next   R: first" % [RECIPES[index].title,record.faces.size(),record.tags.count("growing")]

func advance() -> void:
	show_recipe((index+1)%RECIPES.size())

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_SPACE: advance()
	elif event.keycode==KEY_R: show_recipe(0)

func _physics_process(_dt: float) -> void:
	if not point.held():
		point.global_transform=global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.15,2.2))
```

### Keep the same point

Use the point from Living unchanged. It supplies pickup, release and the held action signal. That interaction does not need another sphere construction or a new grab system.

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

## Predict, then inspect

1. The cube has 12 faces. Insetting two selected triangles replaces each with seven: predict 24 faces. Adding one extrusion on the two new tips gives 36. Confirm these counts at the readout.
2. Three inset/extrude rounds on those two tips give 84 faces. There are still only two `growing` records. Why do the shoulders not begin growing too?
3. Compare recipes 04 and 05. Both take three steps of 0.4 metres. Their top height is the same, but their tip widths differ. With inset 28%, each tip's linear dimensions shrink by 0.72 per round. Its area shrinks by the square of that factor.
4. Change only recipe 04's `"faces":[8,9]` to `"faces":[8]`. Predict one projection, one continuing tip and 48 total faces after three rounds. Run the complete edited program. The other top triangle stays at the seed height. Return to recipe 01, then 04: the edited recipe should reconstruct the same result.

The selected index list belongs to the seed. The `growing` tag carries selection through replacement. This is the useful lineage: a face gives way to a new face without making every surface eligible for the next step.

## What needs another operation?

At the extreme inset value 0.99, the tip can become too small for the extrusion guard. A requested round need not produce another 0.4-metre rise. Counts describe what ran, not only what was requested. Our tested three-round gallery recipes stay above that guard.

Further on, the petal study and the large canopy add a different builder. More inset/extrude rounds alone do not create those curved strips, a hole through the cube or a bridge joining its tips. Keep those companion works available to reflection without adding their full construction to this lesson.

The current rule acts on faces. Next, Assemblage returns to a field of separate marks and asks what connections we perceive between results the rule made independently.


---

<!-- hall: Assemblage_Same_Desire -->

# Assemblage — the choices remain

## Learning elements

- A recorded sample, a threshold decision and its mark
- Changing interpretation without drawing again
- An independent witness, including its alphabet
- A fixed-size row queue
- Perceived paths, addresses and physical support

In Curves, one sentence passed through different readers. Living kept a design while editing continued. Shape Grammars selected which faces could receive the next operation. Here the earlier two-mark textile returns: keep its choices and change what they draw.

This closing study uses independent random samples rather than L-system rewriting. It brings the sequence's distinctions into another construction: keep the data, change a decision or change its visible interpretation. Recognising that transfer is part of the lesson.

## Begin with the installed comparison

Press RESET and HOLD at the existing desk. Follow a few diagonals. ALPHABET changes them into horizontal and vertical bars, then large and small blocks. Compare the same cells with the witness. Their decisions have not changed; their marks have.

Return to diagonals and press ODDS. At 0.75, more of the same samples can choose A than at 0.5. ALPHABET changes representation. ODDS changes decisions. SEED changes the samples. None of these operations asks whether your eye can find a path.

## Reconstruct that separation

Keep the prepared Endless Museum, camera, floor, player and XRTools. Put these three files together and attach `assemblage.gd` to a unit-scale Node3D in your working copy. The small study fits beside the installed desk at hall-local (3.2,0,7.5), yaw 180 degrees. Its two sheets and floor drawing are smaller than the installed comparison; both use the same 12×12 address order. They add no surface collision.

The familiar point changes ALPHABET when its held trigger is pressed. The keyboard also provides A: alphabet, O: odds, H: hold, Space: one row, N: next seed and R: reset. Pickup and hand movement alone do not edit the sheet. Other keyboard actions can first be tried through the museum's existing six buttons; the small program does not rebuild that console.

### Keep what the choice came from

`sheet.gd` holds twelve rows of twelve cells. Each cell stores a sample and a tint. The source draws both, in that order. Omitting the tint draw would shift all later samples, even if we did not care about the colour variation.

`choices()` compares each sample with the current threshold using strict `<`. It draws nothing. `glyph()` then maps the Boolean result to a size and angle; it also draws nothing. Changing either interpretation leaves the random generator at the same state.

The record's row zero is the oldest row, displayed at the bottom. STEP removes that row and appends one new row at the top. The eleven surviving rows keep their cell values. Their current row addresses change.

<!-- student-code:sheet.gd -->
```gdscript
extends RefCounted
const N := 12
const START_SEED := 1010
const ALPHABETS := ["diagonals", "orthogonals", "blocks"]
const ODDS := [0.5, 0.75, 1.0, 0.0, 0.25]
var rng := RandomNumberGenerator.new()
var data := {"seed":START_SEED, "odds":0.5, "alphabet":"diagonals", "rows":[]}

func _init() -> void:
	reset()

func new_row() -> Array:
	var row: Array=[]
	for c in N:
		# Keep both draws: the museum also draws a tint after each sample.
		var sample:=rng.randf()
		var tint:=rng.randf()
		row.append({"sample":sample, "tint":tint})
	return row

func new_sheet(seed_value: int) -> void:
	rng.seed=seed_value
	data.seed=seed_value
	data.rows=[]
	# Index zero is the oldest, bottom row.
	for r in N: data.rows.append(new_row())

func reset() -> void:
	data.odds=0.5; data.alphabet="diagonals"
	new_sheet(START_SEED)

func step() -> void:
	data.rows.pop_front()
	data.rows.append(new_row())

func keep() -> Dictionary:
	return data.duplicate(true)

static func choices(record: Dictionary) -> Array:
	var result: Array=[]
	for row in record.rows:
		var bits: Array=[]
		for cell in row: bits.append(cell.sample < record.odds)
		result.append(bits)
	return result

static func glyph(a: bool, alphabet: String) -> Dictionary:
	var width:=1.0/N
	if alphabet=="blocks":
		var amount:=0.9 if a else 0.3
		return {"size":Vector3(width*amount,0.07*amount,0.03), "angle":0.0}
	var angle: float=(PI/4 if a else -PI/4)
	if alphabet=="orthogonals": angle=0.0 if a else PI/2
	return {"size":Vector3(width*0.9,0.07*0.42,0.03), "angle":angle}
```

### Keep the witness's interpretation too

`keep()` copies the nested record, including rows, odds and alphabet. A copy of only the outer dictionary would still share its rows. A copy of only the samples would not say which marks the witness used.

The display begins with a witness. HOLD replaces it. Later changes and RESET affect only the editing record. Repainting both sheets reads their separate records. This is a local snapshot of a visible result: it does not save to disk or capture the random generator state for resuming the held sheet's future rows.

On the wall, row zero appears lowest. On the floor, the same row/column address receives a fixed position, with row zero at the far edge. This follows the installed floor mapping; it is not a rigid rotation of the whole wall image. Each mark turns onto the floor individually. No neighbouring cell is consulted and no route is computed.

<!-- student-code:assemblage.gd -->
```gdscript
extends Node3D
const Sheet = preload("sheet.gd")
const PointBody = preload("point_body.gd")
var model = Sheet.new()
var held: Dictionary={}
var drawing: Node3D
var label: Label3D
var point: XRToolsPickable

func _ready() -> void:
	drawing=Node3D.new(); add_child(drawing)
	label=Label3D.new(); label.position=Vector3(0,2.6,0.05)
	label.font_size=28; label.pixel_size=.0018; label.outline_size=8; add_child(label)
	point=PointBody.new(); point.position=Vector3(0,1.15,1.1); add_child(point)
	point.action_pressed.connect(func(_body): act("ALPHABET"))
	held=model.keep(); refresh()

func act(action: String) -> void:
	match action:
		"ALPHABET":
			var i: int=Sheet.ALPHABETS.find(model.data.alphabet)
			model.data.alphabet=Sheet.ALPHABETS[(i+1)%Sheet.ALPHABETS.size()]
		"ODDS":
			var i: int=Sheet.ODDS.find(model.data.odds)
			model.data.odds=Sheet.ODDS[(i+1)%Sheet.ODDS.size()]
		"HOLD": held=model.keep()
		"STEP": model.step()
		"SEED": model.new_sheet(int(model.data.seed)+1)
		"RESET": model.reset()
	refresh()

func refresh() -> void:
	for child in drawing.get_children(): drawing.remove_child(child); child.queue_free()
	draw_sheet(model.data,Vector3(-.85,1.8,0),false)
	draw_sheet(held,Vector3(.85,1.8,0),false)
	draw_sheet(model.data,Vector3(0,.035,-4),true)
	var count:=0
	for row in Sheet.choices(model.data):
		for a in row: if a: count+=1
	label.text="EDITING / %s / p %.2f / %d of 144 A\nHELD / %s / p %.2f\nA or held trigger: alphabet   O: odds   H: hold\nSpace: row   N: seed   R: reset" % [model.data.alphabet,model.data.odds,count,held.alphabet,held.odds]

func draw_sheet(record: Dictionary, at: Vector3, on_floor: bool) -> void:
	var panel:=Node3D.new(); panel.position=at; drawing.add_child(panel)
	var backing:=MeshInstance3D.new(); var board:=BoxMesh.new()
	board.size=Vector3(2.6,.012,2.6) if on_floor else Vector3(1.55,1.4,.04)
	backing.mesh=board
	backing.position=Vector3(0,-.02,0) if on_floor else Vector3(0,0,-.05)
	var dark:=StandardMaterial3D.new(); dark.albedo_color=Color("152a32")
	backing.material_override=dark; panel.add_child(backing)
	var bits: Array=Sheet.choices(record)
	for r in Sheet.N:
		for c in Sheet.N:
			var a: bool=bits[r][c]
			var shape: Dictionary=Sheet.glyph(a,record.alphabet)
			var mesh:=BoxMesh.new(); mesh.size=shape.size
			var mark:=MeshInstance3D.new(); mark.mesh=mesh
			var hue: float=(.07 if a else .58)+float(record.rows[r][c].tint)*.05
			var finish:=StandardMaterial3D.new(); finish.albedo_color=Color.from_hsv(hue,.6,.95)
			finish.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			mark.material_override=finish; panel.add_child(mark)
			if on_floor:
				mark.position=Vector3((c-5.5)*.2,0,(r-5.5)*.2)
				mark.basis=Basis(Vector3.RIGHT,-PI/2)*Basis(Vector3.BACK,shape.angle)
				mark.scale=Vector3(2.4,2.4,.5)
			else:
				mark.position=Vector3((c-5.5)/Sheet.N,(r-5.5)*.07,0)*1.4
				mark.rotation.z=shape.angle; mark.scale=Vector3.ONE*1.4

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var actions: Dictionary={KEY_A:"ALPHABET",KEY_O:"ODDS",KEY_H:"HOLD",KEY_SPACE:"STEP",KEY_N:"SEED",KEY_R:"RESET"}
	if actions.has(event.keycode): act(actions[event.keycode])

func _physics_process(_dt: float) -> void:
	if not point.held():
		point.global_transform=global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.15,1.1))
```

### Carry the point

Use the same PointBody from the preceding halls. Its action signal selects another alphabet. Release returns the point to the front of this study.

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

## Predict, then change the reader

1. HOLD the diagonal sheet, then cycle all three alphabets. Samples, decisions and A count should stay fixed. Returning to diagonals should recover the same marks and tints.
2. Change odds from 0.5 to 0.75. Only samples in `[0.5,0.75)` change from B to A. A half-threshold does not demand exactly 72 of the 144 cells. A sample exactly equal to the threshold is B.
3. STEP once. The old second row becomes row zero; the oldest row disappears. Twelve new samples and twelve new tints enter. The witness stays. RESET restores the opening editable sheet, but keeps the witness you most recently held.
4. In `glyph()`, change only the blocks line from `0.9 if a else 0.3` to `0.3 if a else 0.9`. Now A draws the small block. Predict unchanged samples, choices, count, colour and addresses, with the large and small sizes exchanged. Run the complete edited program and compare it with the original.

The same seed reproduces the same draw sequence in this Godot version and call order. For the result itself, keep the actual samples. A seed alone is not a promise of identical output across engine versions.

## Make one decision without a prescribed edit

Choose one of the small programs you have built in this sequence. Keep its original files, then make a working copy. Choose a variation whose exact value or rule has not been given in the exercises. Use the operations already available: for example, another balanced branch sentence, another valid seed-face selection, or another mark for a retained choice. Stay within that program's declared limits.

Before running, write one sentence predicting what will change and one naming what should remain. Make the edit and compare both programs from the same starting conditions. Add an assertion to the model check for the relation you promised to preserve: a saved branch returns correctly, the original recipe remains unchanged, or a new mark leaves the stored choices intact. Check the visible difference in the museum too; a count alone may miss it.

Keep the two versions and a short account of any surprise. Explain which layer you changed—replacement, interpretation, selection or display—and identify the line of code responsible. Someone reviewing your work should be able to rerun it and challenge your prediction. This is an independent learner task, not an additional result already certified by the supplied receipts.

## Leave room for the other works

Walk across the floor marks. The museum supports you whichever way they lean. Turning them into walls would require collision geometry and an explicit definition and test of connectivity. A maze-like picture has not supplied those things.

The loom, credited pattern galleries, dragon bench and formal-limit objects remain separate encounters. This tutorial reconstructs the two-mark comparison; it does not turn a weaving draft into an L-system or a displayed sentence into a proof.

The sequence has moved from rewriting symbols to reading, building, selecting and retaining results. Here we end by separating what the program chose from the connections we saw. Procedural generation will add another decision: a score used to compare what was made.

