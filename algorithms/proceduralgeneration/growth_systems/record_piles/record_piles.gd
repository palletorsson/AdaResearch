extends Node3D
## THE RECORD PILES (floor PG_Branching_Growth; the pass, 2026-11-13)
##
## The hall's desk steps a growth rule on a small apparatus and asks the visitor to compare two numbers on its readout:
## stored records, and distinct positions. They need not agree. With the rule's random terms off, a site that is still
## active chooses the same nearest target again and puts its next child exactly where it put the last one.
##
## This work lays that comparison on the floor. It has NO RULE OF ITS OWN: it reads the records of the lesson's model
## on this floor (the script branching_growth_algorithm.gd, stepped by the desk) and sets every record down as one
## disc at its position, two metres to the study's one: the study's x runs east, its y north, its small depth is left
## out. Records stored at one position lie on each other. So
##   a PLACE is where discs stand on the floor; a RECORD is one disc; a pile's height is what the outline hides.
## Every tenth disc of a pile is pink, to count by; the number stands over the pile. The targets stand as posts, each
## with the ring a site has to stand inside to reach it; a post turns green when the model marks its target reached.
##
## Bench (tools/probes/record_piles_bench.py), the rule alone: the cap of 192 records is spent after eight steps, on
## 14 positions - piles of 40, 30, 30, 20 - with one target of eight reached, 2.9 m of study from the far post. With
## the desk's VARIATION every record gets its own place.
##
## `shows` is the axis, the hall's own comparison: records = every stored record (piles); places = one disc a
## position, which is what a drawing of the tree shows. The plate beside the board changes it.
## `own_steps`: where no lesson stands (a bench, a still) the work steps its own instance of the SAME lesson script,
## set up as the hall's desk sets it up - the eight targets below are the desk's - so there is still one rule.
const Lesson := preload("res://algorithms/proceduralgeneration/growth_systems/branchinggrowthalgorithm/branching_growth_algorithm.gd")
const SCALE := 2.0
const DISC_R := 0.09
const DISC_H := 0.04
const POST := 1.5
const DESK_TARGETS := [Vector3(-2, 1.5, 0), Vector3(-2.5, 2.5, 0.4), Vector3(-3, 3.5, 0), Vector3(1.5, 2.5, 0), Vector3(2, 3.5, -0.5), Vector3(2.5, 4.5, 0), Vector3(0, 5.5, 1), Vector3(0, 6, 0)]      # pg_workshop.gd, _reset_branch
const PALE := Color("d9c9a3")
const DEEP := Color("b89b6a")
const TENTH := Color("f07fa0")
const WAITS := Color(1.0, 0.32, 0.52)      # the lesson's own marks: a target never reached,
const TAKEN := Color(0.25, 0.95, 0.55)      # and one a site has reached
const ROOT := Color(1.0, 0.90, 0.35)

@export_enum("records", "places") var shows := "records"
@export var own_steps := 0

var _model: Object
var _own_model: Object
var _reads := "none"
var _seen := []
var _wait := 0.0
var _tries := 0
var _discs: MultiMeshInstance3D
var _links: MultiMeshInstance3D
var _poles: MultiMeshInstance3D
var _heads: MultiMeshInstance3D
var _rings: MultiMeshInstance3D
var _numbers: Node3D
var _solid: StaticBody3D
var _sign: Label3D
var _plate_words: Label3D
var _on_plate := false
var _counts := {"records": 0, "places": 0, "tallest": 0, "reached": 0, "targets": 0, "discs": 0}


func _ready() -> void:
	var given := {}
	for key in ["shows", "own_steps"]:
		if has_meta("config_" + key): given[key] = get_meta("config_" + key)
	_take(given)
	_furniture()
	_look_for_the_lesson()
	_lay()


func _take(config_data: Dictionary) -> void:
	if config_data.has("shows") and str(config_data["shows"]) in ["records", "places"]: shows = str(config_data["shows"])
	if config_data.has("own_steps"): own_steps = clampi(int(float(str(config_data["own_steps"]))), 0, 60)


func apply_grid_config(config_data: Dictionary) -> void:
	_take(config_data)
	if is_inside_tree() and _discs != null: _lay()


func _exit_tree() -> void:
	if is_instance_valid(_own_model): (_own_model as Node).free()


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0: return
	_wait = 0.15
	if _reads != "floor" or not is_instance_valid(_model):
		if not is_instance_valid(_model):
			_model = null
			_reads = "none"
		_tries += 1
		if _tries % (7 if _tries < 140 else 34) == 1: _look_for_the_lesson()      # about once a second, later once in five: the floor's lesson is preferred to an own one
	if _signature() != _seen: _lay()


## ---- reading ----

## The lesson's model on this floor: the node that carries the lesson's script, anywhere under the floor this work
## stands on. Where there is none and `own_steps` asks for it, an instance of the same script, kept out of the tree.
func _look_for_the_lesson() -> void:
	var floor_root: Node = get_parent()
	while floor_root != null and not floor_root.has_meta("em_map"): floor_root = floor_root.get_parent()
	if floor_root != null:
		var found := _with_the_script(floor_root)
		if found != null:
			_model = found
			_reads = "floor"
			return
	if own_steps > 0 and not is_instance_valid(_model):
		if not is_instance_valid(_own_model): _step_my_own()
		_model = _own_model
		_reads = "own"


func _with_the_script(node: Node) -> Node:
	if node == self: return null
	var script: Variant = node.get_script()
	if script != null and str((script as Script).resource_path).ends_with("branching_growth_algorithm.gd"): return node
	for child in node.get_children():
		var found := _with_the_script(child)
		if found != null: return found
	return null


func _step_my_own() -> void:
	var own: Node3D = Lesson.new()      # never enters the tree: its _ready does not run; only its records and its step are used
	own.attraction_distance = 8.0
	own.growth_distance = 0.5
	own.min_branch_distance = 0.32
	own.max_branches = 192
	own.jitter = 0.0
	own.pulse_strength = 0.0
	own.add_branch(Vector3.ZERO, Vector3.UP)
	for p in DESK_TARGETS: own.attractors.append(Lesson.Attractor.new(p))
	for i in own_steps:
		if own.branches.size() >= 192: break
		own.time_elapsed += 0.2
		own.pulse_timer += 0.2
		own.grow_step()
	_own_model = own


func _signature() -> Array:
	if not is_instance_valid(_model): return [shows]
	var records: Array = _model.branches
	var targets: Array = _model.attractors
	var reached := 0
	for t in targets:
		if t.is_reached: reached += 1
	return [shows, records.size(), targets.size(), reached, records[records.size() - 1].position if not records.is_empty() else Vector3.ZERO,
		targets[targets.size() - 1].position if not targets.is_empty() else Vector3.ZERO]


## Where a point of the study lies on the floor: x east, y north, two metres to one.
func on_floor(p: Vector3) -> Vector3:
	return Vector3(p.x * SCALE, 0.0, -p.y * SCALE)


## Count the records by position: {"order": positions in order of first appearance, "count": position -> records}.
static func tally(positions: Array) -> Dictionary:
	var count := {}
	var order: Array[Vector3] = []
	for p in positions:
		if not count.has(p):
			count[p] = 0
			order.append(p)
		count[p] += 1
	return {"order": order, "count": count}


## ---- laying it out ----

func _lay() -> void:
	_seen = _signature()
	var records: Array = _model.branches if is_instance_valid(_model) else []
	var targets: Array = _model.attractors if is_instance_valid(_model) else []
	var positions := []
	for b in records: positions.append(b.position)
	var counted := tally(positions)
	var order: Array[Vector3] = counted["order"]
	var count: Dictionary = counted["count"]
	# the discs
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	var tallest := 0
	for p in order:
		var n: int = count[p]
		tallest = maxi(tallest, n)
		var at := on_floor(p)
		for k in (n if shows == "records" else 1):
			transforms.append(Transform3D(Basis(), at + Vector3(0, DISC_H * (float(k) + 0.5), 0)))
			colours.append(TENTH if k % 10 == 9 else (PALE if k % 2 == 0 else DEEP))
	_fill(_discs, transforms, colours)
	# what was stored as parent and child, once a pair of places
	var pairs := {}
	var strips: Array[Transform3D] = []
	for b in records:
		if int(b.parent_index) < 0 or int(b.parent_index) >= records.size(): continue
		var from: Vector3 = on_floor(records[int(b.parent_index)].position)
		var to: Vector3 = on_floor(b.position)
		var key := [from, to]
		if pairs.has(key) or from.distance_to(to) < 0.02: continue
		pairs[key] = true
		var along: Vector3 = (to - from).normalized()
		strips.append(Transform3D(Basis(along * from.distance_to(to), Vector3(0, 0.008, 0), along.cross(Vector3.UP) * 0.03), (from + to) * 0.5 + Vector3(0, 0.005, 0)))
	_fill(_links, strips, [])
	# the posts
	var poles: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	var rings: Array[Transform3D] = []
	var lit: Array[Color] = []
	var reached := 0
	var touch: float = float(_model.min_branch_distance) * SCALE if is_instance_valid(_model) else 0.64
	for t in targets:
		var at := on_floor(t.position)
		poles.append(Transform3D(Basis(), at + Vector3(0, POST * 0.5, 0)))
		heads.append(Transform3D(Basis(), at + Vector3(0, POST, 0)))
		rings.append(Transform3D(Basis().scaled(Vector3(touch, 1.0, touch)), at + Vector3(0, 0.006, 0)))
		lit.append(TAKEN if t.is_reached else WAITS)
		if t.is_reached: reached += 1
	_fill(_poles, poles, lit)
	_fill(_heads, heads, lit)
	_fill(_rings, rings, lit)
	# the numbers over the piles, and something solid where a pile stands
	for old in _numbers.get_children():
		_numbers.remove_child(old)
		old.queue_free()
	for old in _solid.get_children():
		_solid.remove_child(old)
		old.queue_free()
	if shows == "records":
		for p in order:
			var n: int = count[p]
			if n < 2: continue
			var top := on_floor(p) + Vector3(0, DISC_H * float(n), 0)
			var number := Label3D.new()
			number.text = str(n)
			number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			number.pixel_size = 0.0035
			number.font_size = 44
			number.outline_size = 10
			number.outline_modulate = Color(0, 0, 0, 1)
			number.modulate = Color(1, 1, 1)
			number.position = top + Vector3(0, 0.13, 0)
			_numbers.add_child(number)
			if n >= 5:
				var shape := CollisionShape3D.new()
				var column := CylinderShape3D.new()
				column.radius = DISC_R + 0.01
				column.height = DISC_H * float(n)
				shape.shape = column
				shape.position = on_floor(p) + Vector3(0, column.height * 0.5, 0)
				_solid.add_child(shape)
	_counts = {"records": records.size(), "places": order.size(), "tallest": tallest, "reached": reached, "targets": targets.size(), "discs": transforms.size()}
	_write()


func _fill(holder: MultiMeshInstance3D, transforms: Array[Transform3D], colours: Array) -> void:
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.use_colors = not colours.is_empty()
	many.mesh = holder.get_meta("unit")
	many.instance_count = transforms.size()
	for i in transforms.size():
		many.set_instance_transform(i, transforms[i])
		if many.use_colors: many.set_instance_color(i, colours[i])
	holder.multimesh = many
	holder.visible = not transforms.is_empty()


func _write() -> void:
	if _sign == null: return
	var c := _counts
	var lines := PackedStringArray(["EVERY DISC IS ONE STORED RECORD"])
	if _reads == "none":
		lines.append("No lesson stands on this floor: there is nothing to read.")
	else:
		lines.append("The desk steps a rule: every active site answers ONE nearest post. Records stored at one position lie on each other.")
		lines.append("%d records  /  %d places  /  tallest pile %d  /  %d of %d posts reached" % [int(c.records), int(c.places), int(c.tallest), int(c.reached), int(c.targets)])
		if int(c.records) <= 1: lines.append("Which post is nearest the root? Then press STEP at the desk.")
		elif shows == "places": lines.append("Shown now: one disc a place, which is what a drawing of the tree shows.")
	_sign.text = "\n".join(lines)
	if _plate_words != null: _plate_words.text = "SHOWN: %s\nstep here for %s" % ["EVERY RECORD" if shows == "records" else "ONE A PLACE", "one a place" if shows == "records" else "every record"]


## ---- what stands there always ----

func _holder(title: String, unit: Mesh, material: Material) -> MultiMeshInstance3D:
	var holder := MultiMeshInstance3D.new()
	holder.name = title
	holder.set_meta("unit", unit)
	holder.material_override = material
	holder.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(holder)
	return holder


func _furniture() -> void:
	var by_colour := StandardMaterial3D.new()
	by_colour.vertex_color_use_as_albedo = true
	by_colour.vertex_color_is_srgb = true
	by_colour.roughness = 0.7
	var glows := StandardMaterial3D.new()
	glows.vertex_color_use_as_albedo = true
	glows.vertex_color_is_srgb = true
	glows.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85
	var disc := CylinderMesh.new()
	disc.top_radius = DISC_R
	disc.bottom_radius = DISC_R
	disc.height = DISC_H
	disc.radial_segments = 20
	disc.rings = 1
	_discs = _holder("Discs", disc, by_colour)
	var strip := BoxMesh.new()
	strip.size = Vector3(1, 1, 1)
	_links = _holder("Links", strip, dark)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.022
	pole.bottom_radius = 0.022
	pole.height = POST
	pole.radial_segments = 8
	_poles = _holder("Poles", pole, glows)
	var head := SphereMesh.new()
	head.radius = 0.12
	head.height = 0.24
	_heads = _holder("Heads", head, glows)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.985
	ring.outer_radius = 1.015
	ring.rings = 48
	ring.ring_segments = 6
	_rings = _holder("Rings", ring, glows)
	_numbers = Node3D.new()
	_numbers.name = "Numbers"
	add_child(_numbers)
	_solid = StaticBody3D.new()
	_solid.name = "Piles"
	add_child(_solid)
	# the root
	var mark := MeshInstance3D.new()
	mark.name = "Root"
	var coin := CylinderMesh.new()
	coin.top_radius = 0.24
	coin.bottom_radius = 0.24
	coin.height = 0.012
	mark.mesh = coin
	var yellow := StandardMaterial3D.new()
	yellow.albedo_color = ROOT
	yellow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark.material_override = yellow
	mark.position = Vector3(0, 0.004, 0)
	add_child(mark)
	# the board: low, east of the root, turned to the arrival
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(3.3, 0, 1.0)
	add_child(stand)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(3.2, 0.9, 0.05)
	panel.mesh = face
	panel.material_override = dark
	panel.position = Vector3(0, 0.62, 0)
	panel.rotation.x = -0.5
	stand.add_child(panel)
	_sign = Label3D.new()
	_sign.pixel_size = 0.0021
	_sign.font_size = 30
	_sign.line_spacing = 2.0
	_sign.modulate = Color(0.88, 0.94, 1.0)
	_sign.outline_size = 4
	_sign.outline_modulate = Color(0, 0, 0, 1)
	_sign.width = 1440
	_sign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sign.position = Vector3(0, 0.035, 0.03)
	panel.add_child(_sign)
	# the plate: at the board's east end, off the way into the field
	var plate := Area3D.new()
	plate.name = "Plate"
	plate.collision_layer = 0
	plate.collision_mask = 0xFFFFFFFF
	plate.position = Vector3(5.6, 0, 1.3)
	var reach := CollisionShape3D.new()
	var room := BoxShape3D.new()
	room.size = Vector3(1.0, 1.2, 1.0)
	reach.shape = room
	reach.position = Vector3(0, 0.6, 0)
	plate.add_child(reach)
	var slab := MeshInstance3D.new()
	var tile := BoxMesh.new()
	tile.size = Vector3(1.0, 0.016, 1.0)
	slab.mesh = tile
	var pink := StandardMaterial3D.new()
	pink.albedo_color = Color("f5a9b8")
	pink.roughness = 0.6
	slab.material_override = pink
	slab.position = Vector3(0, 0.008, 0)
	plate.add_child(slab)
	_plate_words = Label3D.new()
	_plate_words.pixel_size = 0.0024
	_plate_words.font_size = 40
	_plate_words.modulate = Color(0.1, 0.1, 0.12)
	_plate_words.outline_size = 0
	_plate_words.rotation_degrees = Vector3(-90, 0, 0)
	_plate_words.position = Vector3(0, 0.02, 0)
	plate.add_child(_plate_words)
	add_child(plate)
	plate.body_entered.connect(func(b: Node) -> void:
		if not b is CharacterBody3D or _on_plate: return
		_on_plate = true
		shows = "places" if shows == "records" else "records"
		_lay())
	plate.body_exited.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _on_plate = false)


## ---- for a test ----

func state() -> Dictionary:
	var out := _counts.duplicate()
	out["reads"] = _reads
	out["shows"] = shows
	out["solid_piles"] = _solid.get_child_count() if _solid != null else 0
	return out
