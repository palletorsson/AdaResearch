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

The existing tube bay offers an optional return to Trace, rings and mesh faces. Its making notes follow, intact. That larger workbench supplies its own construction and interface; it is not secretly a dependency of the four-file reader above. The code reconstruction and new tests in this pass cover the three readers. Sweeping, frame transport, patching sound and the canopy remain distinct applications with their own existing sources and checks. No automatic transfer of this generated path into the tube workbench is claimed.

<!-- @ -->

## Optional applications — existing tube-bay notes

<!-- study-spine:tube_painting -->

## Return: A line takes up room

Change the middle ring side count from twelve to eight. Keep the path and radius; compare the skin. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This lesson introduces sweep using trace, mesh, refinement, rotation and array. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`tube`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-02-tube-painting-a-line-takes-room/index.html). Finish the current gesture before editing the work. RESET returns the original comparison.

<!-- study-edit:tube_painting -->

### One source change: A line takes up room

Replace the middle value 12 with 8 in SIDE_COUNTS. Restart the prepared study. Each supplied path still has 41 points and the same radius. A capped tube now has 656 triangles instead of 984. Compare PATH, RINGS and TUBE before drawing your own continuation.

```gdscript
const SIDE_COUNTS := [6, 8, 24]
```

Source: `commons/primitives/pipes/swept_tube.gd`. Use the prepared scene to run and compare.

<!-- tube-making -->

## Continue a drawing that has already begun

This is the later **sweep** lesson, in **L-systems → Grammars and Curves**, before Architecture. Point Trace introduced keeping positions. Mesh introduced vertices and triangle connections; refinement introduced circular sampling; rotation supplied changing orientation. Here those tools meet: a path carries a ring, and neighbouring rings carry faces. Point Trace keeps its earlier, simpler encounter.

### First use what is here

Three supplied strokes are suspended in front of the wall. Their six pink end grips are part of the interface. Grab a lower end and move your hand slowly. The old length stays where it was; sampled positions are added beyond it. Release to leave the addition in the air. You can also continue from the other end; the stored path reverses its order before growing there.

Bring an end close to the receiving wall. Its centre snaps to the wall surface and sampling stops until you release. This makes a visible attachment. It is not a structural joint or a gravity simulation. The runs can now join through explicit sockets. Their skins can overlap and do not become a welded solid or block the visitor. Together their paths can compose another, incomplete wall in front of the room's wall.

The pen on the plinth begins a separate stroke. Pick it up, hold its trigger while moving, and release the trigger to keep the line. On desktop, the existing right-click pickup/drop and left-button held action drive the same pen. The artifact adds no player, controller mapping or installation step.

**UNDO** restores the whole drawing before the last completed gesture or geometry edit. Extending a supplied line and undoing leaves the supplied line intact. **CLEAR** removes the strokes; **EXAMPLE** replaces them with the three opening strokes using the current radius and side count. Both can be undone. **RESET** also restores default settings and returns the pen; put it down first. Undo restores geometry, not the pen pose or the next-stroke settings. History keeps the last sixteen states during this visit. Closing or unloading the hall does not save a drawing to disk.

### Inspect the same work three times

**VIEW** cycles TUBE → PATH → RINGS → TUBE. It changes the representation, not the stored positions. PATH is the retained centreline. RINGS shows the sampled cross-sections. TUBE connects them with faces and closes the two ends. The controls are available after you finish a gesture.

**THICKNESS**, **SIDES** and **COLOUR** edit the last stroke in the list and choose the setting for the next new pen stroke. Continuing an earlier stroke preserves that stroke's own material and resolution. Undo an extension before trying a different route. The readout counts the last stroke in the list, not the sum of the whole work.

### What one ring needs

The production builder is `commons/primitives/pipes/swept_tube.gd`. Its `build(path, radius, sides)` function receives positions we already know how to retain. At each position it supplies two perpendicular directions, `frame_normal` and `binormal`, across the path. This is the ring expression, taken from that builder:

```gdscript
var angle := TAU * j / float(sides)
var radial := frame_normal*cos(angle)+binormal*sin(angle)
vertices.append(points[i]+radius*radial)
```

`i` addresses a point along the path; `j` addresses a place around its ring. Changing `sides` changes the second count. It does not take more samples of your hand movement. Changing `radius` moves each ring vertex away from its centre without moving the centre.

The supplied frame transport carries the ring around bends without making it suddenly look towards world-up. Understanding or rewriting quaternion transport is not required for this first edit. First locate the familiar circular rule inside the supplied construction.

### Join two rings

Let `a` and `b` be neighbouring vertices on one ring, and `c` and `d` their corresponding neighbours on the next. This production line adds two triangles:

```gdscript
indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
```

The last address wraps to the first with `% sides`. That closes the seam around a ring. Separate triangles cap the two ends. For N path points and S sides, the body has `2 × (N - 1) × S` triangles and the two caps add `2 × S`. The total is `2 × N × S`.

Make the one source edit above before changing the path: twelve sides become eight. Each opening stroke retains its 41 centres and 0.065 m radius. The capped mesh changes from 984 to 656 triangles. Look near a curved silhouette. Then make your own continuation and compare again. The number is a check on a visible decision, not the reason to prefer one drawing.

### After the first sweep: a connected system

Choose **NETWORK** to load the three-form example. **FORM** cycles the last run and next pen stroke through tube, pipe and cable. A tube retains the path you drew. A pipe uses outer and inner rings with annular rims, leaving an open bore; its sleeves make the mouths visible. A cable redraws between its endpoints and any joined supports with a downward parabolic offset. **SAG** changes that offset while keeping the supports fixed. This is authored drape, not a simulation of gravity or cable length.

Hold the pen trigger beside another run and draw away to start a branch. To join a free end, continue it close to another run, wait for the amber marker, then release. The shared port is recorded only on release. Silver fittings mark these sockets. Connected endpoint grips disappear so extending cannot silently pull a joint apart. Use the pen there to branch, or UNDO to restore both runs and their port records. Merely crossing two skins makes no connection.

`run_network.gd` owns that relationship; `swept_tube.gd` owns the mesh. The reusable `PipeLayout` accepts named anchors and per-run `kind`, radius, sides, sag and optional sampled points. Moving an anchor rebuilds its dependent runs. Its existing glass and drain command builders remain available. See `commons/primitives/pipes/README.md` and `layouts/three_forms.json` for an executable layout example. The hand-drawn runs have no fluid, audio or electrical routing and does not save a drawing between hall visits.

### Explore the form library

**PARTS** cycles four groups from the existing pipe and glass library: straight, 45° and 90° bends, U-bend and S-bend; tee, Y-junction, cross and reducer; coil, wave, flask and beaker; cap, drip and condenser. **CABLES** shows five existing cable arrangements: chord, spline, authored sag, festoon and truss. These are supplied forms to work from, rather than five new algorithms to learn now.

Each group replaces the current drawing; UNDO brings that drawing back. A pink grip marks every declared free port, including the third and fourth arms of a junction. Choose FORM, then take a grip and draw onward. The supplied piece stays in place while a new tube, hollow pipe or cable grows from its port. Release beside another free port to connect two pieces. On supplied parts only the declared ports accept a connection; on drawn runs you can also branch along the path.

The catalogue reuses the existing geometry and port metadata through `part_library.gd`. Some stock pieces are solid display meshes; they are not all hollow plumbing. The new PIPE run has an open bore. Neither kind simulates flow. The supplied pieces keep their shape in PATH and RINGS views while your new runs reveal their construction. THICKNESS and SIDES apply to drawn runs, not the supplied part meshes. COLOUR can recolour the last supplied piece. Eight pieces and runs share the workbench budget, so a five-piece group leaves room for three additions.

### What is supplied, and what is limited

`tube_painting.gd` owns the retained strokes, undo states, view modes and bounded input. `tube_pen.gd` reuses the existing drawing pen. `tube_end.gd` reuses the existing pickup handle. `station.gd` supplies the museum console. Their complete source accompanies this tutorial; keep them intact for the first ring edit.

New samples are actual nib or end-grip positions at least 0.045 m apart. A sudden jump above 0.75 m stops further additions until release. Each stroke can retain 256 positions; the work can keep eight pieces and runs. The drawing volume and feedback keep an endpoint from writing into another exhibit. A tube at the point limit needs a separate new stroke. Tight turns and self-intersections are not repaired into a manifold solid. The pink grips and the wall are interactive/collidable; the tube skin is visual geometry. Native automated pickup and input tests are recorded separately from physical headset testing.

### Optional application: patch a sound, wake a machine

Beside the drawing workbench, the existing modular rack now has a focused VCO → VCF → VCA → SPEAKER patch. Close POWER with the physical lever or its matching button. WAVE selects saw, square, triangle or sine (0–3); FREQ and FINE change pitch, AMP changes level, and PAN moves the sound between channels. Turn CUTOFF, then switch the FILTER lever. You should hear the high harmonics change. The sound is generated continuously; adjusting the filter does not restart a recorded note.

Unplug the VCF route and connect VCO OUT directly to VCA IN. The signal bypasses the filter. An incomplete path to SPEAKER is silent. Grab and release plugs close to a compatible socket, or select an output then an input with the museum pointer. A selected occupied socket removes its cord. PATCH EXAMPLE restores the four supplied cords; UNPATCH removes them. Put down a held plug before either operation.

The second route is POWER GATE → MOTOR. Unplugging it stops the coloured bodies without breaking the sound patch. Opening the power lever stops both. Audio and gate sockets accept their own signal kind; a drawn tube crossing a socket cannot silently become an electrical connection. Moving beads show route direction and enabled state at an illustrative speed, not audio frequency or electrical propagation.

The bodies reuse transformed primitives and swept limbs. Their cranks use a shared elapsed phase at three different rates. This is a kinematic study after Jean Tinguely and Niki de Saint Phalle, not a physical motor model or a reconstruction of a particular sculpture. The connected system extends the sweep lesson; synthesizer implementation is supplied. Inspect `commons/audio/cables/live_patch.gd` for the bounded audio graph and `commons/artifacts/spine_studies/patch_and_motion.gd` for its motor receiver. Other rack presets retain their existing sound behavior.

### Optional application: let the line become a ceiling

Look above the drawing bay. The small console on the left controls a canopy made with the same `PipeLayout` and hollow sweep. **RULE** cycles woven crossings, returning U-bends and branching ribs. **DIAMETER** selects 0.36, 0.60 or 0.84 metres; **REPEAT** selects three, five or seven lanes or branch stations. **FINISH** changes pink lacquer to pale enamel and chrome. **RESET** restores the pink five-lane weave without changing the drawing or synth patch.

Keep diameter and repetition fixed. Change only the rule, then look up from the same position. In WEAVE, the two families have opposite heights at every crossing. A cosine raises and lowers each run; the next lane adds half a cycle. In RIBS, repeated branches meet a central run at named anchors. In RETURNS, each lane runs to a semicircular bend and comes back. The same rings and faces make all three; the path rule changes their relation.

`commons/primitives/pipes/pipe_canopy.gd` is the reusable generator. Its `make_layout(mode, count, radius)` returns an ordinary layout dictionary, so another scene can use it with the existing PipeLayout. The museum wrapper adds a frame, hangers, controls, luminaires and a local reflection probe. The inherited museum ceiling presets still handle conventional tiles, vents and fixtures. This installation is an open canopy above the work, leading towards Architecture.

The pipes have real inner surfaces and open mouths. The rib intersections share logical anchors but their surfaces overlap; they are not welded plumbing and carry no simulated flow. The canopy is visual geometry above the reachable drawing volume. Support posts and the console collide. Meshes rebuild only when the layout changes; changing finish reuses them. A local probe captures the surrounding room once, so it is not a live mirror of subsequent drawing or machine movement. Settings last for this hall visit. Physical Quest performance remains untested.

<!-- /tube-making -->
