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
