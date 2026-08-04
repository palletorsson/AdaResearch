extends Node3D

## Assembly Line Puzzle - Data-Driven Version
##
## Ghost forms require multiple shapes (cube + pyramid combinations).
## Place shapes in the correct slots within the ghost projection.
## When all slots filled, product moves down the line.
## Product definitions loaded from products.json

const CUBE_SCENE := preload("res://commons/primitives/cubes/grab_cube.tscn")
const PYRAMID_SCENE := preload("res://commons/primitives/pyramid/grab_pyramid.tscn")
const CYLINDER_SCENE := preload("res://commons/primitives/cylinder/grab_cylinder.tscn")
const DISC_SCENE := preload("res://commons/primitives/cylinder/grab_disc.tscn")
const PRODUCTS_JSON := "res://commons/primitives/assembly/products.json"

signal shape_placed(shape_type: String, slot_index: int)
signal product_completed(product_number: int)
signal all_products_completed()

## Shape type enum for internal use
## CUBE/CUBOID share scene; CUBOID is just CUBE with non-uniform scale.
## PYRAMID/WEDGE share the pyramid scene; visual difference is the slot scale.
## SPHERE swaps the mesh on a grab_cube body (no dedicated grab_sphere yet).
enum ShapeType { CUBE, PYRAMID, CYLINDER, DISC, SPHERE, WEDGE, CUBOID }

## AXIS — WHAT THE LINE DISCLOSES OF ITS ANSWER before you have built one.
## Borrowed character for character from [[chair_assembly_puzzle]],
## [[table_assembly_puzzle]], [[shelf_assembly_puzzle]], [[stool_assembly_puzzle]],
## [[balance_puzzle]] and [[configurable_portal]] — the same four values, the same
## question, and this is the same kind of object as four of them: an assembly
## puzzle whose shipped lineage is the translucent cyan hologram, so `ghost` is
## the default here exactly as it is there. The slot positions, the match
## tolerance, the snap and the conveyors are identical at every value; only what
## stands at the station changes.
##
##   ghost     the legacy lineage — every slot pre-shown as a translucent tinted
##             projection of the target. THE DEFAULT.
##   none      nothing at all: two belts, a bare platform, no stated goal. A line
##             that tells its worker nothing about what it is for.
##   mark      where, not what — a small bright head at each slot point. The
##             positions are given and the form is withheld.
##   exemplar  the answer in solid: the same slot forms rendered opaque in their
##             own colours, one finished product standing on the station already
##             built.
##
## What this argues: a production line is a claim about how much of the plan the
## worker is given, and this one shipped with exactly one answer — the full
## specification, floating, permanently. The other three are the same line under
## a different disclosure regime.
##
## NOT declared, deliberately: what is IN TRANSIT on the belt. spawn_interval,
## input_speed and output_speed are rates, and the pieces they carry are spawned
## by _process on a wall clock — a still catches whatever happened to be between
## the rollers, so a "parts on the belt" axis would photograph as a fact about
## the shutter. The station is the only part of this artifact that holds still.
const TELLS: PackedStringArray = ["ghost", "none", "mark", "exemplar"]
@export_enum("ghost", "none", "mark", "exemplar") var tell: String = "ghost"

## Configuration - loaded from JSON or set via export
@export var category: String = "houses"
@export var product_filter: String = ""  # Empty = build all in category

@export_group("Conveyors")
@export var spawn_interval: float = 2.5
@export var input_speed: float = 0.10
@export var output_speed: float = 0.12
@export var input_start: Vector3 = Vector3(1.0, 0.5, 0)
@export var input_end: Vector3 = Vector3(-0.8, 0.5, 0)
@export var output_start: Vector3 = Vector3(0, 0.5, -0.4)
@export var output_end: Vector3 = Vector3(0, 0.5, -1.4)

@export_group("Production")
@export var station_position: Vector3 = Vector3(0, 0.5, -0.4)
@export var ghost_color: Color = Color(0.3, 0.8, 1.0, 0.4)
@export var slot_match_distance: float = 0.08
@export var snap_duration: float = 0.25
@export var shape_scale: float = 0.07
## When true, snap requires both shape AND color (within tolerance) to match.
## Set false for the legacy houses/lab products which don't carry colors.
@export var require_color_match: bool = false
@export var color_match_tolerance: float = 0.18

@export_group("Sandbox")
## When true: no target ghost, no snap, no completion. The conveyor becomes
## a vocabulary feeder — colored primitives drawn from `palette_source` flow
## down the input belt and the player picks them up and combines them
## however they want. The output belt is unused unless a build platform
## artifact is placed in the world to receive composed stacks.
@export var sandbox_mode: bool = false
## Where to draw shape+color samples from when sandbox_mode is on.
##   "compositions" — all slots from all products in category "compositions"
##   "<category>"   — all slots from a specific category in products.json
##   "rainbow"      — fall back to a built-in saturated palette
@export var palette_source: String = "compositions"

@export_group("Visuals")
@export var conveyor_color: Color = Color(0.9, 0.9, 0.95)

## Loaded product data
var _products_data: Dictionary = {}
var _product_sequence: Array[Dictionary] = []
var _current_product_index: int = 0

## Ghost and slots
var _ghost_container: Node3D
var _ghost_meshes: Array[MeshInstance3D] = []
var _slot_filled: Array[bool] = []
var _slot_pieces: Array[Node3D] = []

## Conveyor pieces
var _input_pieces: Array[Node3D] = []
var _output_products: Array[Node3D] = []

## Timers and state
var _spawn_timer: float = 0.0
var _products_completed: int = 0


## Sandbox palette: array of {"shape": ShapeType, "color": Color, "scale": Vector3}
var _palette: Array = []


func _ready() -> void:
	_load_products_data()
	_build_product_sequence()
	_create_conveyors()
	_create_production_station()
	_spawn_timer = spawn_interval * 0.5
	if sandbox_mode:
		_build_palette()
	else:
		_setup_current_product_ghost()
	_update_label()


func _process(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		if sandbox_mode:
			_spawn_palette_piece()
		else:
			_spawn_shape_for_current_product()

	_update_input_conveyor(delta)
	_update_output_conveyor(delta)
	if not sandbox_mode:
		_check_slot_matches()


## Build the sandbox palette by aggregating slot data from products.json.
## Sandbox spawns are random draws from this list.
func _build_palette() -> void:
	_palette.clear()
	if palette_source == "rainbow":
		_palette = _rainbow_palette()
		return

	if not _products_data.has("categories"):
		_palette = _rainbow_palette(); return

	var cats = _products_data["categories"]
	var keys: Array = []
	if palette_source == "compositions":
		keys = ["compositions"] if cats.has("compositions") else cats.keys()
	elif cats.has(palette_source):
		keys = [palette_source]
	else:
		keys = cats.keys()

	for cat_key in keys:
		var cat = cats[cat_key]
		var products = cat.get("products", {})
		for prod_key in products.keys():
			for slot in products[prod_key].get("slots", []):
				var shape = _parse_shape_type(slot.get("type", "cube"))
				var col = _slot_color(slot)
				var sc = _array_to_vector3(slot.get("scale", [1, 1, 1]))
				_palette.append({"shape": shape, "color": col, "scale": sc})

	if _palette.is_empty():
		_palette = _rainbow_palette()


func _rainbow_palette() -> Array:
	var shapes := [ShapeType.CUBE, ShapeType.SPHERE, ShapeType.CYLINDER, ShapeType.PYRAMID, ShapeType.WEDGE]
	var colors := [
		Color("#cc1f1f"), Color("#1f4ecc"), Color("#f0c020"),
		Color("#1a8848"), Color("#6a30a0"), Color("#e87018"),
		Color("#1a1a1a"), Color("#f4f2ec"),
	]
	var out: Array = []
	for s in shapes:
		for c in colors:
			out.append({"shape": s, "color": c, "scale": Vector3.ONE})
	return out


## Sandbox: spawn a single random palette draw onto the input belt.
func _spawn_palette_piece() -> void:
	if _palette.is_empty():
		return
	var pick = _palette[randi() % _palette.size()]
	var piece = _create_shape_piece(pick["shape"])
	_apply_piece_color(piece, pick["color"])
	piece.set_meta("piece_color", pick["color"])
	piece.set_meta("piece_origin", "sandbox_palette")

	# Slight scatter along z so consecutive pieces don't pile.
	piece.position = input_start + Vector3(0, 0.08, randf_range(-0.06, 0.06))
	# Honor the slot's per-axis scale on the piece so totem-tall vs cube
	# proportions survive into the spawned object.
	var s: Vector3 = pick.get("scale", Vector3.ONE)
	piece.scale = Vector3(shape_scale * s.x, shape_scale * s.y, shape_scale * s.z)

	if "freeze" in piece:
		piece.freeze = false

	add_child(piece)
	_input_pieces.append(piece)


## Load product definitions from JSON
func _load_products_data() -> void:
	var file = FileAccess.open(PRODUCTS_JSON, FileAccess.READ)
	if not file:
		push_error("AssemblyLine: Could not load %s" % PRODUCTS_JSON)
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("AssemblyLine: JSON parse error: %s" % json.get_error_message())
		return

	_products_data = json.data

	# Apply constants from JSON if present
	if _products_data.has("constants"):
		var c = _products_data["constants"]
		if c.has("shape_scale"): shape_scale = c["shape_scale"]
		if c.has("slot_match_distance"): slot_match_distance = c["slot_match_distance"]
		if c.has("snap_duration"): snap_duration = c["snap_duration"]
		if c.has("spawn_interval"): spawn_interval = c["spawn_interval"]
		if c.has("input_speed"): input_speed = c["input_speed"]
		if c.has("output_speed"): output_speed = c["output_speed"]


## Build the product sequence from JSON data
func _build_product_sequence() -> void:
	_product_sequence.clear()

	if not _products_data.has("categories"):
		push_error("AssemblyLine: No categories in products.json")
		return

	var categories = _products_data["categories"]
	if not categories.has(category):
		push_warning("AssemblyLine: Unknown category '%s', using 'houses'" % category)
		category = "houses"

	var cat_data = categories[category]
	var products = cat_data.get("products", {})

	# If filtering to a single product
	if product_filter != "":
		var filter_lower = product_filter.to_lower()
		if products.has(filter_lower):
			var product = products[filter_lower].duplicate()
			product["key"] = filter_lower
			_product_sequence.append(product)
		else:
			push_warning("AssemblyLine: Product '%s' not found in category '%s'" % [product_filter, category])
	else:
		# Use default sequence or all products
		var sequence = cat_data.get("default_sequence", products.keys())
		for product_key in sequence:
			if products.has(product_key):
				var product = products[product_key].duplicate()
				product["key"] = product_key
				_product_sequence.append(product)


func _get_current_product() -> Dictionary:
	if _current_product_index < _product_sequence.size():
		return _product_sequence[_current_product_index]
	return {}


## Create both conveyors
func _create_conveyors() -> void:
	# Input conveyor
	var input_conv = _create_conveyor_mesh(
		input_start, input_end, true, conveyor_color
	)
	add_child(input_conv)
	_create_rails(input_start, input_end, true)
	_create_arrow(Vector3(input_start.x - 0.3, input_start.y + 0.02, input_start.z), -90)

	# Output conveyor
	var output_conv = _create_conveyor_mesh(
		output_start, output_end, false, conveyor_color.darkened(0.1)
	)
	add_child(output_conv)
	_create_rails(output_start, output_end, false)
	_create_arrow(Vector3(output_start.x, output_start.y + 0.02, output_start.z - 0.15), 180)


func _create_conveyor_mesh(start: Vector3, end: Vector3, horizontal: bool, color: Color) -> MeshInstance3D:
	var conveyor = MeshInstance3D.new()
	var box = BoxMesh.new()

	if horizontal:
		var length = abs(start.x - end.x) + 0.3
		box.size = Vector3(length, 0.02, 0.25)
		conveyor.position = Vector3((start.x + end.x) / 2.0, start.y - 0.05, start.z)
	else:
		var length = abs(start.z - end.z) + 0.2
		box.size = Vector3(0.3, 0.02, length)
		conveyor.position = Vector3(start.x, start.y - 0.05, (start.z + end.z) / 2.0)

	conveyor.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	conveyor.material_override = mat

	return conveyor


func _create_rails(start: Vector3, end: Vector3, horizontal: bool) -> void:
	var length = abs(start.x - end.x) + 0.3 if horizontal else abs(start.z - end.z) + 0.2
	var center = Vector3((start.x + end.x) / 2.0, start.y - 0.01, start.z) if horizontal \
		else Vector3(start.x, start.y - 0.01, (start.z + end.z) / 2.0)
	var offset = 0.14 if horizontal else 0.16

	for side in [-1, 1]:
		var rail = MeshInstance3D.new()
		var box = BoxMesh.new()
		if horizontal:
			box.size = Vector3(length, 0.06, 0.02)
			rail.position = center + Vector3(0, 0, side * offset)
		else:
			box.size = Vector3(0.02, 0.06, length)
			rail.position = center + Vector3(side * offset, 0, 0)
		rail.mesh = box

		var mat = StandardMaterial3D.new()
		mat.albedo_color = conveyor_color.darkened(0.2)
		rail.material_override = mat
		add_child(rail)


func _create_arrow(pos: Vector3, rotation_y: float) -> void:
	var arrow = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(0.08, 0.01, 0.12)
	arrow.mesh = prism
	arrow.rotation_degrees = Vector3(-90, rotation_y, 0)
	arrow.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.7, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.7, 0.3)
	mat.emission_energy_multiplier = 0.5
	arrow.material_override = mat
	add_child(arrow)


func _create_production_station() -> void:
	_ghost_container = Node3D.new()
	_ghost_container.name = "GhostContainer"
	_ghost_container.position = station_position
	add_child(_ghost_container)

	# Platform
	var platform = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.35, 0.02, 0.25)
	platform.mesh = box
	platform.position = Vector3(station_position.x, station_position.y - 0.06, station_position.z)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.85, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 0.6)
	mat.emission_energy_multiplier = 0.3
	platform.material_override = mat
	add_child(platform)

	# Label
	var label = Label3D.new()
	label.name = "ProductLabel"
	label.text = "Built: 0"
	label.font_size = 24
	label.position = Vector3(station_position.x, station_position.y + 0.22, station_position.z)
	label.modulate = Color(1, 1, 1, 0.9)
	add_child(label)


func _setup_current_product_ghost() -> void:
	# Clear old ghosts
	for mesh in _ghost_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()
	_ghost_meshes.clear()
	_slot_filled.clear()
	_slot_pieces.clear()

	var product = _get_current_product()
	if product.is_empty():
		return

	# If product is in "stack mode" (no offsets, just sequence), compute
	# cumulative y offsets from each slot's vertical extent. This lets a
	# primitive_stack composition import directly: shape + color + scale.
	var slots = product.get("slots", [])
	var stack_mode := bool(product.get("stack_mode", false))
	var y_cursor := 0.0
	for i in slots.size():
		var slot = slots[i]
		var slot_type = _parse_shape_type(slot.get("type", "cube"))
		var custom_scale = _array_to_vector3(slot.get("scale", [1, 1, 1]))
		var offset: Vector3
		if stack_mode:
			# Each primitive contributes ~base_size*scale.y to the column.
			var step = shape_scale * 2.0 * custom_scale.y * 1.05
			offset = Vector3(0, y_cursor + step * 0.5, 0)
			y_cursor += step
		else:
			offset = _array_to_vector3(slot.get("offset", [0, 0, 0]))
		var col := _slot_color(slot)
		var ghost = _create_ghost_mesh(slot_type, custom_scale, col)
		ghost.position = offset
		_ghost_container.add_child(ghost)
		_ghost_meshes.append(ghost)
		_slot_filled.append(false)
		_slot_pieces.append(null)

	_update_label()


## Resolve a slot's color hint (or default ghost_color when not specified).
func _slot_color(slot: Dictionary) -> Color:
	if slot.has("color"):
		var v = slot["color"]
		if v is String:
			return Color(v)
		elif v is Array and v.size() >= 3:
			return Color(float(v[0]), float(v[1]), float(v[2]),
				float(v[3]) if v.size() >= 4 else 1.0)
	return ghost_color


func _create_ghost_mesh(shape_type: ShapeType, custom_scale: Vector3 = Vector3.ONE, tint: Color = Color(0,0,0,0)) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var base_size = shape_scale * 2

	match shape_type:
		ShapeType.CUBE, ShapeType.CUBOID:
			var box = BoxMesh.new()
			box.size = Vector3(base_size * custom_scale.x, base_size * custom_scale.y, base_size * custom_scale.z)
			mesh_instance.mesh = box
		ShapeType.PYRAMID, ShapeType.WEDGE:
			mesh_instance.mesh = _build_pyramid_mesh(base_size * custom_scale.x)
		ShapeType.CYLINDER:
			var cyl = CylinderMesh.new()
			cyl.top_radius = base_size * 0.5 * custom_scale.x
			cyl.bottom_radius = base_size * 0.5 * custom_scale.x
			cyl.height = base_size * custom_scale.y
			mesh_instance.mesh = cyl
		ShapeType.DISC:
			var disc = CylinderMesh.new()
			disc.top_radius = base_size * 0.6 * custom_scale.x
			disc.bottom_radius = base_size * 0.6 * custom_scale.x
			disc.height = base_size * 0.15 * custom_scale.y
			mesh_instance.mesh = disc
		ShapeType.SPHERE:
			var sph = SphereMesh.new()
			sph.radius = base_size * 0.5 * custom_scale.x
			sph.height = base_size * custom_scale.y
			mesh_instance.mesh = sph

	# Ghost is the slot's target color (if given) at low alpha, else the default.
	var col := tint if tint.a > 0.0 else ghost_color
	col.a = 0.45

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.5
	mesh_instance.material_override = mat

	_apply_tell(mesh_instance, col)
	return mesh_instance


## Restyle one slot projection for the `tell` axis. The slot's POSITION is never
## touched — _check_slot_matches() reads _ghost_meshes[i].position for the snap
## target, so the puzzle plays identically at every value; only what the player
## is shown changes. "ghost" returns without doing anything, which is why the
## shipped placements are byte-identical.
func _apply_tell(mesh_instance: MeshInstance3D, col: Color) -> void:
	match tell:
		"none":
			# layers = 0, not visible = false: render layers are per-instance and
			# do not propagate to children, and the mesh and material are left
			# alone. The slot still contributes its AABB, so a sweep frames every
			# value from the same distance.
			mesh_instance.layers = 0
		"mark":
			# Where, not what. One small bright head at the slot point; the form
			# the slot wants is withheld.
			var head := SphereMesh.new()
			head.radius = shape_scale * 0.3
			head.height = shape_scale * 0.6
			mesh_instance.mesh = head
			var mm := StandardMaterial3D.new()
			mm.albedo_color = Color(1.0, 0.82, 0.2)
			mm.emission_enabled = true
			mm.emission = Color(1.0, 0.82, 0.2)
			mm.emission_energy_multiplier = 1.6
			mesh_instance.material_override = mm
		"exemplar":
			# The answer already built: same forms, solid, in their own colours.
			var em := StandardMaterial3D.new()
			em.albedo_color = Color(col.r, col.g, col.b, 1.0)
			em.roughness = 0.55
			em.metallic = 0.05
			mesh_instance.material_override = em
		_:
			pass


func _build_pyramid_mesh(size: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half = size * 0.5
	var h = size * 0.8

	var v0 = Vector3(-half, 0, -half)
	var v1 = Vector3(half, 0, -half)
	var v2 = Vector3(half, 0, half)
	var v3 = Vector3(-half, 0, half)
	var apex = Vector3(0, h, 0)

	st.add_vertex(v0); st.add_vertex(v2); st.add_vertex(v1)
	st.add_vertex(v0); st.add_vertex(v3); st.add_vertex(v2)
	st.add_vertex(v0); st.add_vertex(v1); st.add_vertex(apex)
	st.add_vertex(v1); st.add_vertex(v2); st.add_vertex(apex)
	st.add_vertex(v2); st.add_vertex(v3); st.add_vertex(apex)
	st.add_vertex(v3); st.add_vertex(v0); st.add_vertex(apex)

	st.generate_normals()
	return st.commit()


func _spawn_shape_for_current_product() -> void:
	var product = _get_current_product()
	if product.is_empty():
		return

	# Collect (shape, color) needed pairs from unfilled slots.
	var needed: Array = []
	var slots = product.get("slots", [])
	for i in slots.size():
		if not _slot_filled[i]:
			needed.append({
				"shape": _parse_shape_type(slots[i].get("type", "cube")),
				"color": _slot_color(slots[i]),
			})

	if needed.is_empty():
		return

	var shape_type: ShapeType
	var piece_color: Color
	if randf() < 0.75:
		var pick = needed[randi() % needed.size()]
		shape_type = pick["shape"]
		piece_color = pick["color"]
	else:
		# Decoy piece — random shape, random hue from the product's palette.
		var palette: Array = []
		for s in slots:
			palette.append(_slot_color(s))
		shape_type = needed[randi() % needed.size()]["shape"]
		piece_color = palette[randi() % palette.size()] if palette.size() > 0 else Color(0.7, 0.7, 0.75)

	var piece = _create_shape_piece(shape_type)
	_apply_piece_color(piece, piece_color)
	piece.set_meta("piece_color", piece_color)
	piece.position = input_start + Vector3(0, 0.08, randf_range(-0.04, 0.04))
	piece.scale = Vector3.ONE * shape_scale

	if "freeze" in piece:
		piece.freeze = false

	add_child(piece)
	_input_pieces.append(piece)


func _apply_piece_color(piece: Node, col: Color) -> void:
	# Walk children, override the PRIMARY MeshInstance3D's albedo. Skip
	# auxiliary meshes like highlight rings (Torus/non-Box meshes) so the
	# pickup feedback geometry stays its own color.
	var primary_done := false
	for child in _flatten(piece):
		if not (child is MeshInstance3D): continue
		var m: Mesh = child.mesh
		if m == null: continue
		# First Box/Sphere/Cylinder/Pyramid we hit — that's the visual.
		var is_primary := (m is BoxMesh) or (m is SphereMesh) or (m is CylinderMesh) or (m is PrismMesh)
		if is_primary and not primary_done:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = col
			mat.roughness = 0.6
			child.material_override = mat
			primary_done = true


func _flatten(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_flatten(c))
	return out


func _create_shape_piece(shape_type: ShapeType) -> Node3D:
	var piece: Node3D
	match shape_type:
		ShapeType.CUBE, ShapeType.CUBOID:
			piece = CUBE_SCENE.instantiate()
			piece.set_meta("shape_type", "cube" if shape_type == ShapeType.CUBE else "cuboid")
		ShapeType.PYRAMID, ShapeType.WEDGE:
			piece = PYRAMID_SCENE.instantiate()
			piece.set_meta("shape_type", "pyramid" if shape_type == ShapeType.PYRAMID else "wedge")
		ShapeType.CYLINDER:
			piece = CYLINDER_SCENE.instantiate()
			piece.set_meta("shape_type", "cylinder")
		ShapeType.DISC:
			piece = DISC_SCENE.instantiate()
			piece.set_meta("shape_type", "disc")
		ShapeType.SPHERE:
			# No grab_sphere yet — instantiate a cube body and swap ONLY the
			# main visual mesh to a sphere. Skip auxiliary meshes (e.g.
			# highlight_ring's torus) so we don't accidentally render them
			# as giant spheres at the cube's natural size.
			piece = CUBE_SCENE.instantiate()
			piece.set_meta("shape_type", "sphere")
			var swapped := false
			for child in _flatten(piece):
				if swapped: break
				if not (child is MeshInstance3D): continue
				# The grab_cube's main visual is a BoxMesh sized (0.1,0.1,0.1).
				# Only swap that one; leave torus/highlight rings alone.
				if child.mesh is BoxMesh:
					var sph := SphereMesh.new()
					var box_size: Vector3 = (child.mesh as BoxMesh).size
					sph.radius = box_size.x * 0.5
					sph.height = box_size.y
					child.mesh = sph
					swapped = true
	return piece


## Compatibility: shapes that share a base scene also match each other on snap
## (cube↔cuboid, pyramid↔wedge). Color match is enforced separately.
func _shapes_compatible(a: ShapeType, b: ShapeType) -> bool:
	if a == b: return true
	if (a == ShapeType.CUBE and b == ShapeType.CUBOID) or (a == ShapeType.CUBOID and b == ShapeType.CUBE):
		return true
	if (a == ShapeType.PYRAMID and b == ShapeType.WEDGE) or (a == ShapeType.WEDGE and b == ShapeType.PYRAMID):
		return true
	return false


func _colors_close(a: Color, b: Color) -> bool:
	var dr = abs(a.r - b.r)
	var dg = abs(a.g - b.g)
	var db = abs(a.b - b.b)
	return (dr + dg + db) <= color_match_tolerance * 3.0


func _update_input_conveyor(delta: float) -> void:
	var to_remove: Array[Node3D] = []

	for piece in _input_pieces:
		if not is_instance_valid(piece):
			to_remove.append(piece)
			continue

		var is_held = piece.has_method("is_picked_up") and piece.is_picked_up()
		if not is_held:
			piece.position.x -= input_speed * delta
			if piece.position.x < input_end.x:
				to_remove.append(piece)
				piece.queue_free()

	for piece in to_remove:
		_input_pieces.erase(piece)


func _update_output_conveyor(delta: float) -> void:
	var to_remove: Array[Node3D] = []

	for product in _output_products:
		if not is_instance_valid(product):
			to_remove.append(product)
			continue

		product.position.z -= output_speed * delta
		if product.position.z < output_end.z:
			to_remove.append(product)
			_release_artifact_to_world(product)

	for product in to_remove:
		_output_products.erase(product)


func _release_artifact_to_world(artifact: Node3D) -> void:
	var reward_type = artifact.get_meta("reward_type", "unknown")

	var world_pos = artifact.global_position
	var world_rot = artifact.global_rotation
	var local_scale = artifact.scale

	var grid_scene = _find_grid_scene()
	var new_parent = grid_scene if grid_scene else get_parent()

	artifact.get_parent().remove_child(artifact)
	new_parent.add_child(artifact)

	artifact.global_position = world_pos
	artifact.global_rotation = world_rot
	artifact.scale = local_scale

	if artifact is RigidBody3D:
		artifact.freeze = false
		artifact.sleeping = false

	var eq_id = "eq_%s_%d" % [reward_type, Time.get_ticks_msec()]
	if EquipmentRegistry:
		EquipmentRegistry.register(eq_id, artifact, reward_type, {
			"source": "assembly_line",
			"category": category
		})


func _find_grid_scene() -> Node:
	var current = self
	while current:
		if current.name == "GridScene":
			return current
		current = current.get_parent()
	return null


func _check_slot_matches() -> void:
	var product = _get_current_product()
	if product.is_empty():
		return

	var slots = product.get("slots", [])

	for piece in _input_pieces.duplicate():
		if not is_instance_valid(piece):
			continue

		var is_held = piece.has_method("is_picked_up") and piece.is_picked_up()
		if is_held:
			continue

		var piece_type = _parse_shape_type(piece.get_meta("shape_type", "cube"))
		var piece_color: Color = piece.get_meta("piece_color", Color(0,0,0,0))

		for i in slots.size():
			if _slot_filled[i]:
				continue

			var slot = slots[i]
			var slot_type = _parse_shape_type(slot.get("type", "cube"))
			if not _shapes_compatible(slot_type, piece_type):
				continue
			if require_color_match and slot.has("color"):
				if not _colors_close(piece_color, _slot_color(slot)):
					continue

			# Use the ghost mesh's actual position (handles stack_mode autostacking).
			var slot_world_pos: Vector3
			if i < _ghost_meshes.size() and is_instance_valid(_ghost_meshes[i]):
				slot_world_pos = _ghost_meshes[i].global_position
			else:
				slot_world_pos = _ghost_container.global_position + _array_to_vector3(slot.get("offset", [0, 0, 0]))
			var distance = piece.global_position.distance_to(slot_world_pos)

			if distance < slot_match_distance:
				_snap_piece_to_slot(piece, i)
				break


func _snap_piece_to_slot(piece: Node3D, slot_index: int) -> void:
	var product = _get_current_product()
	if product.is_empty():
		return

	var slots = product.get("slots", [])
	if slot_index >= slots.size():
		return

	var slot = slots[slot_index]
	var offset = _array_to_vector3(slot.get("offset", [0, 0, 0]))

	_input_pieces.erase(piece)
	_slot_filled[slot_index] = true
	_slot_pieces[slot_index] = piece

	if piece is RigidBody3D:
		piece.freeze = true

	var target_pos: Vector3
	if slot_index < _ghost_meshes.size() and is_instance_valid(_ghost_meshes[slot_index]):
		target_pos = _ghost_meshes[slot_index].global_position
	else:
		target_pos = _ghost_container.global_position + offset
	var tween = create_tween()
	tween.tween_property(piece, "global_position", target_pos, snap_duration)
	tween.tween_property(piece, "rotation", Vector3.ZERO, snap_duration)

	if slot_index < _ghost_meshes.size() and is_instance_valid(_ghost_meshes[slot_index]):
		_ghost_meshes[slot_index].visible = false

	shape_placed.emit(piece.get_meta("shape_type", "unknown"), slot_index)

	await tween.finished
	_check_product_complete()


func _check_product_complete() -> void:
	for filled in _slot_filled:
		if not filled:
			return

	_products_completed += 1
	product_completed.emit(_products_completed)

	await _move_product_to_output()

	_current_product_index = (_current_product_index + 1) % _product_sequence.size()
	_setup_current_product_ghost()


func _move_product_to_output() -> void:
	var product = _get_current_product()
	if product.is_empty():
		return

	# Delete assembled pieces
	for piece in _slot_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	_slot_pieces.clear()

	# Create artifact
	var artifact = _create_artifact(product)
	if artifact:
		add_child(artifact)
		artifact.global_position = _ghost_container.global_position
		artifact.scale = Vector3.ONE * 0.3
		artifact.set_meta("reward_type", product.get("key", "unknown"))
		artifact.set_meta("equipment_type", product.get("key", "unknown"))

		var tween = create_tween()
		tween.tween_property(artifact, "position", output_start, 0.4)
		await tween.finished

		_output_products.append(artifact)


func _create_artifact(product: Dictionary) -> Node3D:
	# Try loading scene first
	if product.has("reward_scene"):
		var scene = load(product["reward_scene"])
		if scene:
			var artifact = scene.instantiate()
			artifact.name = "Artifact_%s_%d" % [product.get("key", "item"), _products_completed]
			return artifact

	# Fallback to procedural mesh
	return _create_procedural_artifact(product.get("reward_type", "generic"))


func _create_procedural_artifact(reward_type: String) -> Node3D:
	var container = Node3D.new()
	container.name = "Artifact_%s" % reward_type

	match reward_type:
		"house", "tower":
			container.add_child(_create_house_mesh(reward_type == "tower"))
		"health_charger", "security_camera", "specimen_jar":
			container.add_child(_create_lab_mesh())
		_:
			container.add_child(_create_generic_mesh())

	return container


func _create_house_mesh(is_tower: bool = false) -> Node3D:
	var house = Node3D.new()
	var cube_size = 0.06
	var levels = 2 if is_tower else 1

	for i in levels:
		var body = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(cube_size, cube_size, cube_size)
		body.mesh = box
		body.position = Vector3(0, cube_size / 2 + i * cube_size, 0)

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.85, 0.7)
		body.material_override = mat
		house.add_child(body)

	var roof = MeshInstance3D.new()
	roof.mesh = _build_pyramid_mesh(0.07)
	roof.position = Vector3(0, cube_size * levels, 0)

	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.8, 0.3, 0.2)
	roof.material_override = roof_mat
	house.add_child(roof)

	return house


func _create_lab_mesh() -> Node3D:
	var lab = Node3D.new()

	var body = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.06, 0.08, 0.05)
	body.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.65, 0.7)
	mat.metallic = 0.4
	body.material_override = mat
	lab.add_child(body)

	var screen = MeshInstance3D.new()
	var screen_box = BoxMesh.new()
	screen_box.size = Vector3(0.04, 0.02, 0.01)
	screen.mesh = screen_box
	screen.position = Vector3(0, 0.02, 0.025)

	var screen_mat = StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.2, 0.8, 0.3)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.2, 0.9, 0.3)
	screen_mat.emission_energy_multiplier = 2.0
	screen.material_override = screen_mat
	lab.add_child(screen)

	return lab


func _create_generic_mesh() -> Node3D:
	var container = Node3D.new()

	var body = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.06, 0.08, 0.06)
	body.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.75, 0.8)
	mat.metallic = 0.5
	body.material_override = mat
	container.add_child(body)

	return container


func _update_label() -> void:
	var label = get_node_or_null("ProductLabel")
	if not label:
		return
	if sandbox_mode:
		label.text = "Sandbox · palette: %s" % palette_source
		return
	var product = _get_current_product()
	var product_name = product.get("name", "Product") if not product.is_empty() else "Product"
	label.text = "%s | Built: %d" % [product_name, _products_completed]


## Utility functions
func _parse_shape_type(type_str) -> ShapeType:
	if type_str is int:
		return type_str as ShapeType
	match str(type_str).to_lower():
		"cube": return ShapeType.CUBE
		"cuboid": return ShapeType.CUBOID
		"pyramid": return ShapeType.PYRAMID
		"wedge": return ShapeType.WEDGE
		"cylinder": return ShapeType.CYLINDER
		"disc": return ShapeType.DISC
		"sphere": return ShapeType.SPHERE
		_: return ShapeType.CUBE


func _array_to_vector3(arr) -> Vector3:
	if arr is Vector3:
		return arr
	if arr is Array and arr.size() >= 3:
		return Vector3(arr[0], arr[1], arr[2])
	return Vector3.ZERO


## Public API
func get_products_completed() -> int:
	return _products_completed


func reset() -> void:
	_current_product_index = 0
	_products_completed = 0

	for piece in _input_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	_input_pieces.clear()

	for product in _output_products:
		if is_instance_valid(product):
			product.queue_free()
	_output_products.clear()

	_setup_current_product_ghost()
	_update_label()


## Config system for grid artifact
func apply_grid_config(config_data: Dictionary) -> void:
	var needs_rebuild := false

	# Check for category or product specification
	for key in config_data.keys():
		var resolved = _resolve_alias(key)
		if not resolved.is_empty():
			if resolved.has("category") and resolved["category"] != category:
				category = resolved["category"]
				needs_rebuild = true
			if resolved.has("product") and resolved["product"] != product_filter:
				product_filter = resolved["product"]
				needs_rebuild = true
			break

	# Explicit config values
	if config_data.has("category"):
		var new_cat = str(config_data["category"]).to_lower()
		if new_cat != category:
			category = new_cat
			needs_rebuild = true

	if config_data.has("product"):
		var new_product = str(config_data["product"]).to_lower()
		if new_product != product_filter:
			product_filter = new_product
			needs_rebuild = true

	# Legacy puzzle_type support
	if config_data.has("puzzle_type"):
		var resolved = _resolve_alias(str(config_data["puzzle_type"]))
		if not resolved.is_empty():
			if resolved.has("category"):
				category = resolved["category"]
			if resolved.has("product"):
				product_filter = resolved["product"]
			needs_rebuild = true

	# Composition products carry color per slot — enable color-match snap.
	if category == "compositions":
		require_color_match = true

	# Sandbox toggle (truthy: true / "true" / "1" / 1).
	if config_data.has("sandbox") or config_data.has("mode"):
		var raw = config_data.get("sandbox", config_data.get("mode", false))
		var on := false
		if raw is bool: on = raw
		elif raw is int: on = raw != 0
		elif raw is String: on = raw.to_lower() in ["true", "1", "sandbox", "free", "yes"]
		if on != sandbox_mode:
			sandbox_mode = on
			needs_rebuild = true

	# Disclosure axis. Guarded twice — an unknown token is ignored rather than
	# blanking the station, and a value equal to the current one does NOT set
	# needs_rebuild, so the six existing placements (none of which pass `tell`)
	# never reach _rebuild() through this branch.
	if config_data.has("tell"):
		var t := str(config_data["tell"]).to_lower().strip_edges()
		if TELLS.has(t) and t != tell:
			tell = t
			needs_rebuild = true

	if config_data.has("palette") or config_data.has("palette_source"):
		var p = str(config_data.get("palette", config_data.get("palette_source", "")))
		if p != "" and p != palette_source:
			palette_source = p
			needs_rebuild = true

	if needs_rebuild:
		_rebuild()


func _resolve_alias(key: String) -> Dictionary:
	if not _products_data.has("aliases"):
		return {}

	var aliases = _products_data["aliases"]
	var key_lower = key.to_lower().strip_edges()

	if aliases.has(key_lower):
		return aliases[key_lower]
	return {}


func _rebuild() -> void:
	for piece in _input_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	_input_pieces.clear()

	for product in _output_products:
		if is_instance_valid(product):
			product.queue_free()
	_output_products.clear()

	_product_sequence.clear()
	_current_product_index = 0
	_products_completed = 0

	if _ghost_container:
		for child in _ghost_container.get_children():
			child.queue_free()

	if sandbox_mode:
		_build_palette()
	else:
		_build_product_sequence()
		_setup_current_product_ghost()
	_update_label()
