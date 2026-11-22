extends Node3D
## A building table where faces go into a fixed frame, one for each trigger.
##
## Palle, 22 November 2026: "Instead of grabbing a building [block] we choose one building block using the hand
## principle, with just one trigger add to a template. Instead of free form we have the template ... when we
## fill all the walls another diamond falls down on the table and ... if we hold it we see the world in wireframe.
## For the cube case ... two different templates. One is the association principle. Each time we couple a cube
## another random cube association object is created. We can remove the button interface."
##
## face_assembly.gd builds this instead of its loose faces and buttons when its config says build = "template".
##  - THE BLOCK is the one face in the glass case. Nothing is carried: the hand points.
##  - A FRAME is the wire outline of a closed form standing over the table. It is one pointer target (a body on
##    the pointables layer with pointer_event, as a push button is), so the VR pointer's trigger and the desktop
##    click both reach it. The wall nearest the pointer's ray shows a gold face; the trigger puts a face there.
##  - A FILLED frame drops its reward on the table and empties, so it can be filled again.
##      triangle table: the diamond, eight faces  -> a diamond; held, the world is drawn in wireframe
##      square table:   the cube, six faces       -> a cube
##                      the cube, six faces       -> a random cube association from commons/modular/terms.json,
##                                                   as a table model no larger than 24 cm
## The second and third readings are mine (Palle answered "yes" to them): his note names the association frame
## and says there are two; the other one is taken to be the plain cube.
const Kit = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Piece = preload("res://commons/artifacts/primitive_encounters/piece.gd")
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const Threshold = preload("res://commons/artifacts/wireframe_threshold/wireframe_threshold.gd")
const Composite = preload("res://commons/modular/composite.tscn")
const TERMS := "res://commons/modular/terms.json"
const TOP := 0.90            # the table top, where a reward lands
const POINTABLE := 1 << 20   # player_rules.gd POINTER_MASK: what a pointer's ray can press
const INK := Color("292530")
const KEPT_REWARDS := 8
const HAND_SIZE := 0.24      # the largest side of an association on the table

## One frame's whole volume, for the pointer. The frame decides which wall is meant.
class Reach extends StaticBody3D:
	var build: Node
	var index := 0
	func pointer_event(event: XRToolsPointerEvent) -> void:
		build.pointed(index, event)

var table: Node3D
var frames: Array[Dictionary] = []
var rewards: Array[Node3D] = []
var ghost: MeshInstance3D
var stock_at := Vector3(1.05, TOP + 0.13, 0.30)
var _holding := {}
var _undressed := false
var _last_term := ""
var _chance := RandomNumberGenerator.new()


func setup(owner_table: Node3D) -> void:
	table = owner_table
	_chance.randomize()
	_build_table()
	if table.sides == 3:
		# where the started form stood: the opera's frame for this row aims here
		_add_frame("DIAMOND", "diamond", Vector3(-0.72, 1.32, 0.38), _octahedron())
	else:
		_add_frame("CUBE", "cube", Vector3(-0.72, 1.22, 0.38), _cube())
		_add_frame("ASSOCIATION(CUBE)", "association", Vector3(0.0, 1.22, 0.38), _cube())
	ghost = MeshInstance3D.new()
	ghost.name = "NextFace"
	ghost.mesh = table._panel_mesh
	var gold := Kit.material(Color(0.96, 0.79, 0.40, 0.55))
	gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gold.cull_mode = BaseMaterial3D.CULL_DISABLED
	ghost.material_override = gold
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ghost.hide()
	add_child(ghost)


func _build_table() -> void:
	var size := Vector3(2.9, 0.06, 0.95)
	var top := Kit.box(self, "TableTop", Vector3(0, TOP - size.y * 0.5, 0.375), size, Color.WHITE)
	top.mesh = Timber.mesh(size)
	top.material_override = Timber.material()
	for x in [-1.36, 1.36]:
		for z in [-0.03, 0.78]:
			Kit.box(self, "Leg", Vector3(x, (TOP - size.y) * 0.5, z), Vector3(0.07, TOP - size.y, 0.07), Color("514653"))
	# the block: one face in a glass case, on the table
	var glass := Kit.material(Color(0.66, 0.85, 0.92, 0.24))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for pane in [[Vector3(-0.26, 0, 0), Vector3(0.012, 0.26, 0.42)], [Vector3(0.26, 0, 0), Vector3(0.012, 0.26, 0.42)],
			[Vector3(0, 0.13, 0), Vector3(0.53, 0.012, 0.42)], [Vector3(0, 0, -0.21), Vector3(0.53, 0.26, 0.012)]]:
		var sheet := Kit.box(self, "CaseGlass", stock_at + pane[0], pane[1], Color.WHITE, false)
		sheet.material_override = glass
		sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var block := MeshInstance3D.new()
	block.name = "Block"
	block.mesh = table._panel_mesh
	block.material_override = table._face_materials[0]
	block.position = stock_at + Vector3(0, -0.06, 0)
	block.rotation = Vector3(deg_to_rad(-18), 0, 0)
	add_child(block)
	var words := Kit.label(self, "POINT AT A FRAME.  ONE TRIGGER ADDS ONE FACE.", Vector3(0.1, TOP + 0.003, 0.80), 15)
	words.rotation.x = -PI / 2


func _octahedron() -> Dictionary:
	var r: float = table.EDGE / sqrt(2.0)
	var faces := []
	for i in 4:
		faces.append([0, 2 + i, 2 + (i + 1) % 4])
		faces.append([1, 2 + (i + 1) % 4, 2 + i])
	return {"points": PackedVector3Array([Vector3.UP * r, Vector3.DOWN * r, Vector3.RIGHT * r, Vector3.BACK * r, Vector3.LEFT * r, Vector3.FORWARD * r]), "faces": faces}


func _cube() -> Dictionary:
	var h: float = table.EDGE * 0.5
	var points := PackedVector3Array()
	for y in [-h, h]:
		for corner in [Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h)]:
			points.append(corner + Vector3.UP * y)
	return {"points": points, "faces": [[3, 2, 1, 0], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]}


## Where a panel (flat in XZ, its first edge along +X, its centroid at the origin) lies on one face of the form.
func _wall(points: PackedVector3Array, face: Array) -> Transform3D:
	var first: Vector3 = points[face[0]]
	var second: Vector3 = points[face[1]]
	var x := (second - first).normalized()
	var z: Vector3 = (points[face[2]] - (first + second) * 0.5).normalized() if face.size() == 3 else (points[face[3]] - first).normalized()
	var centre := Vector3.ZERO
	for i in face: centre += points[i]
	return Transform3D(Basis(x, z.cross(x).normalized(), z), centre / float(face.size()))


func _add_frame(title: String, reward: String, centre: Vector3, solid: Dictionary) -> void:
	var points: PackedVector3Array = solid.points
	var root := Node3D.new()
	root.name = "Frame%d" % frames.size()
	root.position = centre
	add_child(root)
	var walls: Array[Transform3D] = []
	var seen := {}
	var reach := 0.0
	var lowest := 0.0
	for point in points:
		reach = maxf(reach, point.length())
		lowest = minf(lowest, point.y)
	var wire := Kit.material(INK)
	wire.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for face: Array in solid.faces:
		walls.append(_wall(points, face))
		for i in face.size():
			var a: int = face[i]
			var b: int = face[(i + 1) % face.size()]
			var key := "%d-%d" % [mini(a, b), maxi(a, b)]
			if seen.has(key): continue
			seen[key] = true
			var bar := MeshInstance3D.new()
			bar.name = "Wire"
			var rod := CylinderMesh.new()
			rod.top_radius = 0.004; rod.bottom_radius = 0.004; rod.radial_segments = 6
			rod.height = points[a].distance_to(points[b])
			bar.mesh = rod
			bar.material_override = wire
			bar.position = (points[a] + points[b]) * 0.5
			bar.quaternion = Quaternion(Vector3.UP, (points[b] - points[a]).normalized())
			root.add_child(bar)
	var stem := centre.y + lowest - TOP
	if stem > 0.01:
		Kit.box(root, "Stem", Vector3(0, lowest - stem * 0.5, 0), Vector3(0.018, stem, 0.018), INK, false)
	var body := Reach.new()
	body.name = "Reach"
	body.build = self
	body.index = frames.size()
	body.collision_layer = POINTABLE
	body.collision_mask = 0
	var ball := SphereShape3D.new()
	ball.radius = reach + 0.06
	var shape := CollisionShape3D.new()
	shape.shape = ball
	body.add_child(shape)
	root.add_child(body)
	var label := Kit.label(self, "", Vector3(centre.x, TOP + 0.003, 0.70), 17)
	label.rotation.x = -PI / 2
	var filled: Array = []
	filled.resize(walls.size())
	frames.append({"root": root, "walls": walls, "filled": filled, "reward": reward, "title": title, "label": label, "busy": false, "centre": centre, "made": 0, "last": ""})
	_count(frames.size() - 1)


func _count(index: int) -> void:
	var frame: Dictionary = frames[index]
	var filled: Array = frame.filled
	var words := "%s  %d / %d" % [frame.title, filled.size() - filled.count(null), filled.size()]
	if str(frame.last) != "": words += "\n= %s" % str(frame.last).to_upper().replace("_", " ")
	(frame.label as Label3D).text = words


## The pointer's ray picks the empty wall it passes closest to; a nearer wall wins a tie.
func _aim(index: int, event: XRToolsPointerEvent) -> int:
	var frame: Dictionary = frames[index]
	if frame.busy:
		ghost.hide()
		return -1
	var root: Node3D = frame.root
	var from: Vector3 = event.pointer.global_position if is_instance_valid(event.pointer) else event.position
	var along: Vector3 = event.position - from
	if along.length() < 0.001: along = root.global_position - from
	along = along.normalized()
	var best := -1
	var score := INF
	var walls: Array = frame.walls
	var filled: Array = frame.filled
	for i in walls.size():
		if filled[i] != null: continue
		var at: Vector3 = (root.global_transform * (walls[i] as Transform3D)).origin
		var depth := (at - from).dot(along)
		var miss := (at - (from + along * depth)).length() + 0.1 * depth
		if miss < score:
			score = miss
			best = i
	ghost.visible = best >= 0
	if best >= 0: ghost.global_transform = root.global_transform * (walls[best] as Transform3D)
	return best


func pointed(index: int, event: XRToolsPointerEvent) -> void:
	match event.event_type:
		XRToolsPointerEvent.Type.EXITED:
			ghost.hide()
		XRToolsPointerEvent.Type.ENTERED, XRToolsPointerEvent.Type.MOVED:
			_aim(index, event)
		XRToolsPointerEvent.Type.PRESSED:
			var wall := _aim(index, event)
			if wall >= 0: add_face(index, wall)


## One face from the case into one wall. True when it went in.
func add_face(index: int, wall: int) -> bool:
	var frame: Dictionary = frames[index]
	var filled: Array = frame.filled
	if frame.busy or wall < 0 or wall >= filled.size() or filled[wall] != null: return false
	var root: Node3D = frame.root
	var face := MeshInstance3D.new()
	face.name = "Wall%d" % wall
	face.mesh = table._panel_mesh
	face.material_override = table._face_materials[wall % 2]
	root.add_child(face)
	face.global_transform = global_transform * Transform3D(Basis.IDENTITY, stock_at)
	create_tween().tween_property(face, "transform", frame.walls[wall] as Transform3D, 0.22).set_trans(Tween.TRANS_SINE)
	filled[wall] = face
	ghost.hide()
	_count(index)
	if not filled.has(null):
		frame.busy = true
		get_tree().create_timer(0.7).timeout.connect(_complete.bind(index))
	return true


func _complete(index: int) -> void:
	var frame: Dictionary = frames[index]
	var centre: Vector3 = frame.centre
	# three landing places in front of the frame, taken in turn, so a reward does not fall on the one before
	var at := Vector3(centre.x + [0.0, -0.22, 0.22][int(frame.made) % 3], TOP + 0.5, 0.64)
	var reward: Node3D
	if frame.reward == "association":
		reward = _association(at)
		frame.last = _last_term
	else:
		reward = _solid(str(frame.reward), at)
		if frame.reward == "diamond":
			reward.picked_up.connect(func(_who): _hold(reward, true))
			reward.dropped.connect(func(_who): _hold(reward, false))
			reward.tree_exiting.connect(func(): _hold(reward, false))
	frame.made = int(frame.made) + 1
	rewards.append(reward)
	while rewards.size() > KEPT_REWARDS:
		var oldest := rewards[0]
		rewards.remove_at(0)
		if is_instance_valid(oldest) and not _holding.has(oldest.get_instance_id()) and not oldest.held(): oldest.queue_free()
	var filled: Array = frame.filled
	for i in filled.size():
		var face := filled[i] as Node3D
		if is_instance_valid(face):
			var fade := create_tween()
			fade.tween_property(face, "scale", Vector3.ONE * 0.01, 0.3)
			fade.tween_callback(face.queue_free)
		filled[i] = null
	frame.busy = false
	_count(index)


## The closed form as one solid that falls: the diamond (two pyramids base to base) or the cube.
func _solid(kind: String, at: Vector3) -> Node3D:
	var reward := _falling("Diamond" if kind == "diamond" else "Cube", at)
	var shape := CollisionShape3D.new()
	if kind == "diamond":
		const TIP := 0.13
		var points := PackedVector3Array([Vector3.UP * TIP, Vector3.DOWN * TIP, Vector3.RIGHT * TIP, Vector3.BACK * TIP, Vector3.LEFT * TIP, Vector3.FORWARD * TIP])
		var triangles := []
		for i in 4:
			triangles.append([0, 2 + i, 2 + (i + 1) % 4])
			triangles.append([1, 2 + (i + 1) % 4, 2 + i])
		Kit.solid(reward, "Diamond", points, triangles, Color("bd85e5"), false)
		var hull := ConvexPolygonShape3D.new()
		hull.points = points
		shape.shape = hull
	else:
		var box := BoxShape3D.new()
		box.size = Vector3.ONE * 0.20
		Kit.box(reward, "Cube", Vector3.ZERO, box.size, Color("8ed6e8"), false)
		shape.shape = box
	reward.add_child(shape)
	table.add_child(reward, true)
	return reward


## A thing the hand can take, that falls and lies on the table until then.
func _falling(title: String, at: Vector3) -> Node3D:
	var body := Piece.new()
	body.name = title
	body.position = at
	body.floats = false
	body.freeze = false
	body.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
	body.collision_layer = (1 << 18) | 4
	body.collision_mask = 1
	return body


## The cube, recognised as a thing: the terms the grammar derives from the cube by association.
func cube_terms() -> Array[String]:
	var out: Array[String] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TERMS))
	if not parsed is Dictionary: return out
	var terms: Dictionary = parsed.get("terms", parsed)
	for key: String in terms:
		if not terms[key] is Dictionary: continue
		var expr := str(terms[key].get("expr", ""))
		if expr.begins_with("association(cube)") or expr.begins_with("association(config(cube))"): out.append(key)
	out.sort()
	return out


func _association(at: Vector3) -> Node3D:
	var names := cube_terms()
	var term := "cardboard_box"
	if not names.is_empty():
		term = names[_chance.randi() % names.size()]
		if term == _last_term and names.size() > 1: term = names[(names.find(term) + 1) % names.size()]
	_last_term = term
	var body := _falling("Association_" + term, at)
	var thing := Composite.instantiate()
	thing.term = term
	body.add_child(thing)
	table.add_child(body, true)
	# The composite brings its own colliders for a thing that stands in a room. Here it is one carried body.
	for inner in thing.find_children("*", "CollisionObject3D", true, false):
		(inner as CollisionObject3D).collision_layer = 0
		(inner as CollisionObject3D).collision_mask = 0
	# A table model: a thing larger than the hand is made at the size of the other rewards (a die stays a die).
	var bounds: AABB = table.mesh_bounds(thing, body)
	var largest := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z)) if bounds.has_surface() else 0.0
	if largest > HAND_SIZE:
		thing.scale = Vector3.ONE * (HAND_SIZE / largest)
		bounds = table.mesh_bounds(thing, body)
	var box := BoxShape3D.new()
	box.size = bounds.size.max(Vector3.ONE * 0.05) if bounds.has_surface() else Vector3.ONE * 0.2
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = bounds.get_center() if bounds.has_surface() else Vector3.ZERO
	body.add_child(shape)
	return body


func _hold(reward: Node, on: bool) -> void:
	if on: _holding[reward.get_instance_id()] = true
	else: _holding.erase(reward.get_instance_id())
	_undress(not _holding.is_empty())


## The room drawn as its triangles while a diamond is in the hand. The counter is the wireframe threshold's, so
## a visitor standing in that ring with a diamond gets the room back only when both are over.
func _undress(on: bool) -> void:
	if on == _undressed: return
	var view := table.get_viewport() if is_instance_valid(table) and table.is_inside_tree() else null
	_undressed = on
	if on:
		if Threshold._held == 0 and view != null: Threshold._restore_to = view.debug_draw
		Threshold._held += 1
		if view != null: view.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	else:
		Threshold._held = maxi(0, Threshold._held - 1)
		if Threshold._held == 0 and view != null: view.debug_draw = Threshold._restore_to


func _exit_tree() -> void:
	_holding.clear()
	_undress(false)
