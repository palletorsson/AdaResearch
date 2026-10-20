"""Author the four-file Architecture reconstruction; retain the baseline separately."""
from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Architecture';S.mkdir(parents=True,exist_ok=True)
def write(p,s):p.write_bytes(s.encode('utf-8'))
prior=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Grammars_And_Curves'
rewrite=(prior/'grammar.gd').read_text(encoding='utf-8').split('func rewrite(')[1].split('\nfunc ')[0]
grammar='extends RefCounted\nconst SYMBOL_LIMIT := 4096\n\nfunc rewrite('+rewrite+'''
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
'''
write(S/'grammar.gd',grammar)
source=(R/'commons/artifacts/architecture_lesson/architecture_lesson.gd').read_text(encoding='utf-8')
rectangles='func rectangles('+source.split('func rectangles(')[1].split('\nfunc ')[0]
floor='''extends RefCounted
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

'''+rectangles+'\n'
write(S/'footprint.gd',floor)
room='''extends Node3D
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
	title.text = "%s / width %.1f m / rooms %s\\n%d moves / %d room records" % ["BUILT" if built else "PLAN", WIDTHS[width_index], "ON" if rooms_on else "OFF", records.segments.size(), records.rooms.size()]
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
'''
write(S/'architecture.gd',room)
shutil.copyfile(prior/'point_body.gd',S/'point_body.gd')
M=R/'commons/maps/LSystems_Architecture'
intro='''# A path is not yet a passage

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
'''
def block(name):return '\n<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8')+'```\n'
text=intro+block('grammar.gd')+'''
## Give the records a footprint

`make()` receives the records, width and room choice. Each orthogonal segment gets a rectangle, extended by half the width on both sides and at its ends. Each distinct room address gets a 2.8-metre square. The original room list keeps both Rs. A dictionary keyed by position keeps each address once.

Another dictionary stores occupied grid cells. Adding a cell already present changes nothing: overlapping corridors and rooms form a union. The 0.1-metre pitch represents all three chosen half-widths exactly. Other dimensions would need a declared rounding policy. Grid resolution is a construction decision, not a property of the grammar.

At every occupied cell, inspect four neighbours. If the neighbour is occupied, the edge is internal and gets no wall. This keeps the junction open. Exposed edges get walls, except at the two main ends. A grammar does not choose those doors for us.

The remaining helper groups adjacent cells into rectangles and collinear edges into wall runs. It reduces the number of meshes and colliders without filling holes. Read the first three functions closely; the complete grouping code follows so the example has no missing builder. Wall thickness extends outward from the footprint, preserving the measured clear width.

### footprint.gd
'''+block('footprint.gd')+'''
## Build the same plan twice

PLAN draws without adding collision. BUILD adds floor slabs and wall colliders with the same sizes as their meshes. The museum floor remains underneath both states. Pale centrelines are guides, not walls.

The compact program creates its point and labels. B builds; P returns to plan; W cycles width; O toggles room footprints; R resets. The point’s held trigger also switches BUILD/PLAN, and its local X chooses width. The installed museum retains its six-button desk; rebuilding those button scenes is not part of this example.

Before any change, `people_inside()` checks the prepared player groups in local coordinates. A visitor anywhere inside the fixed brass frame refuses the change, including in PLAN. A refused hand choice is remembered as already attempted: leaving the frame does not apply it later. Move to another mark or press again. This is a bounded local guard for the museum’s declared player groups, not a multiplayer occupancy system.

### architecture.gd
'''+block('architecture.gd')+'''
### point_body.gd — unchanged carried class
'''+block('point_body.gd')+'''
## Make one change of your own

Before editing, leave the frame. Replace only RULE’s production `F[+RF][-RF]F` with `F[+FR][-FR]F`. You moved each R to the other side of its branch’s F.

Predict the four segments first: they should not move. Predict the room addresses next: they should now be (4,-4) and (-4,-4) in the plan’s local x/z coordinates. Run the edited script and enable ROOMS. Two separate squares replace the shared square at the junction. The list still has two records; the number of unique addresses has changed from one to two. Returning to the original rule restores the shared room.

Then compare the 0.4 and 1.4-metre entrances. A test capsule 0.6 metres across should stop at the narrow opening and pass the wider one. The code tests that particular body against actual colliders; your avatar has its own dimensions and movement behavior. A connected line alone is not a passage test. Moving the room markers does not widen the entrance.

## What travels onward

Keep three things separate: the grammatical record, the occupied footprint and the boundary a body meets. This example builds one orthogonal plan; its two door exceptions and fixed guard bounds are specific to that plan. It does not join arbitrary angles, repair any generated building, simulate structural loads or save a design between visits. The miniature and eight companion works remain outside this required reconstruction.

In Competition, a proposed next step will meet a place that is already occupied. We now have a concrete way to ask which part of that decision belongs to a rule and which part belongs to its surroundings.
'''
write(M/'tutorial.md',text)
baseline=R/'doc/book/iterations/2026-10-09-architecture-a-place-to-pass/before/commons/maps/LSystems_Architecture/final.md'
final=baseline.read_text(encoding='utf-8')
final=final.replace('Press BUILD. A low solid base', 'The familiar dark point waits outside the brass frame. Its held trigger switches between the flat plan and the construction; moving it chooses a passage width. The nearby buttons offer the same decisions.\n\nPress BUILD. A low solid base')
final=final.replace("In the dungeon's actual interpreter, R does this:\n\n```gdscript\nrooms.append(pos)\n```\n\nIt records", "R records")
final=final.replace('At each cell edge it asks whether another occupied cell lies beyond it:\n\n```gdscript\nif occupied.has(cell + direction): continue\n```\n\nAn internal edge receives no wall.', 'At each cell edge it asks whether another occupied cell lies beyond it. An internal edge receives no wall.')
final=final.replace('Your body’s collision capsule is forty centimetres across, and so is the gap. The line continues without a break; whether you pass is decided by the disagreement between a capsule and two walls, a few centimetres the plan does not show.', 'The gap is forty centimetres across. A sixty-centimetre test body stops at its entrance. The line continues without a break; whether you pass depends on the meeting between your body’s collision boundary and two walls, dimensions the centreline does not show.')
write(M/'final.md',final)
