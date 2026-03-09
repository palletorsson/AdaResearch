extends Node3D
## Headless capture scene for grid editor — builds 3D elements from placements.
## Called by capture_with_config.gd via apply_grid_config().

const MeshFactory = preload("res://tools/grid_editor/scripts/glass_mesh_factory.gd")
const UVAC_SCENE = preload("res://commons/audio/UniversalVRAudioController.tscn")

@onready var subset_loader: GridEditorSubsetLoader = $SubsetLoader
var elements_root: Node3D

func _ready() -> void:
	elements_root = Node3D.new()
	elements_root.name = "Elements"
	add_child(elements_root)


func apply_grid_config(config: Dictionary) -> void:
	var subset_id: String = str(config.get("subset", "glass_rack"))
	var placements: Array = config.get("placements", [])
	var grid_dims = config.get("grid_size", [16, 12])

	# Wait for SubsetLoader to finish if needed
	if subset_loader.subsets.is_empty():
		subset_loader.load_all_subsets()
	subset_loader.set_current_subset(subset_id)

	var subset = subset_loader.current_subset
	if subset.is_empty():
		push_error("grid_editor_capture: Subset not found: %s" % subset_id)
		return

	# Preset lookup — resolve preset ID from subset's presets array
	if config.has("preset") and placements.is_empty():
		var preset_id: String = str(config["preset"])
		var found := false
		for p in subset.get("presets", []):
			if str(p.get("id", "")) == preset_id:
				placements = p.get("placements", [])
				grid_dims = p.get("grid_size", grid_dims)
				config["bonds"] = p.get("bonds", [])
				found = true
				break
		if not found:
			push_error("grid_editor_capture: Preset '%s' not found in subset '%s'" % [preset_id, subset_id])
			return

	var gs: float = subset_loader.get_grid_size()
	var orientation = subset_loader.get_orientation()
	var plane: String = orientation.get("plane", "XY")
	var tube_radius: float = subset.get("defaults", {}).get("tube_radius", 0.015)
	var config_bonds: Array = config.get("bonds", [])
	var is_audio: bool = (subset_id == "audio_rack")
	var is_glass: bool = (subset_id == "glass_rack")
	var is_pipes: bool = (subset_id == "big_pipes")
	var is_sticky: bool = (subset_id == "sticky_notes")
	var is_chemical: bool = (subset_id == "chemical_models")
	var is_periodic: bool = (subset_id == "periodic_table")

	print("grid_editor_capture: subset=%s plane=%s gs=%.3f placements=%d" % [subset_id, plane, gs, placements.size()])

	# Audio rack: build a real interactive synth instead of static meshes
	if is_audio:
		# Direct rack_config loading — bypasses preset, loads from commons/audio/rack_configs/
		var rack_config_name: String = str(config.get("rack_config", ""))
		if not rack_config_name.is_empty():
			_build_audio_rack_from_config(rack_config_name, gs, plane)
			return
		_build_audio_rack(subset, placements, grid_dims, gs, plane)
		return

	# Clear previous
	for c in elements_root.get_children():
		c.queue_free()

	# Build elements
	for entry in placements:
		if not entry is Dictionary:
			continue
		var eid: String = str(entry.get("element", ""))
		if eid.is_empty():
			continue
		var element: Dictionary = subset_loader.get_element(eid)
		if element.is_empty():
			push_warning("grid_editor_capture: Unknown element '%s' in subset '%s'" % [eid, subset_id])
			continue

		var pos = entry.get("position", [0, 0])
		if not pos is Array or pos.size() < 2:
			continue
		var rot: int = int(entry.get("rotation", 0))

		# Create 3D node — procedural for glass/pipes/sticky/chemical/periodic, .tscn for others
		var node: Node3D = null
		if is_glass:
			node = MeshFactory.create_glass_segment(element, gs, tube_radius)
		elif is_pipes:
			node = _build_pipe_segment(eid, rot, pos, placements, gs)
		elif is_sticky:
			node = _build_sticky_note(element, gs)
		elif is_chemical:
			node = _build_chemical_element(element, pos, placements, gs, config_bonds)
		elif is_periodic:
			node = _build_periodic_tile(element, gs)
		else:
			var scene_path: String = str(element.get("scene", ""))
			if not scene_path.is_empty() and scene_path != "null" and ResourceLoader.exists(scene_path):
				var scene = load(scene_path)
				if scene:
					node = scene.instantiate()
					node.name = element.get("id", "element")
					# Auto-scale oversized scenes to fit their grid allocation
					_auto_scale_to_footprint(node, element, gs, eid)
			if not node:
				node = MeshFactory.create_placeholder(element, gs)

		if not node:
			continue

		# Position based on plane
		match plane:
			"YZ":
				# Glass generators build in YZ. Rotate PI/2 around Y to display in XY.
				node.rotation.y = PI / 2.0
				node.position = Vector3(float(pos[0]) * gs, float(pos[1]) * gs, 0)
			"XZ":
				if not is_pipes and not is_chemical:
					node.rotation.y = PI / 2.0 - deg_to_rad(rot)
					node.position = Vector3(float(pos[0]) * gs, 0, float(pos[1]) * gs)
				# Pipes/chemical already positioned by their builders
			_:
				# XY default — flip Y so grid row 0 = top of board
				node.position = Vector3(float(pos[0]) * gs, -float(pos[1]) * gs, 0)
				if rot != 0:
					node.rotate_z(deg_to_rad(rot))

		elements_root.add_child(node)

	# Add CaptureCamera
	_add_capture_camera(plane, gs, grid_dims)
	print("grid_editor_capture: Built %d elements" % elements_root.get_child_count())


## --- Procedural pipe builder for big_pipes ---
## Builds cylinders centered in grid cells. Uses neighbor detection for connectivity.

const PIPE_RADIUS := 0.8
const PIPE_COLOR := Color(0.55, 0.55, 0.62)
const CAP_COLOR := Color(0.5, 0.5, 0.58)

func _build_pipe_segment(eid: String, rot: int, pos: Array, placements: Array, gs: float) -> Node3D:
	var node := Node3D.new()
	node.name = eid
	var cx: float = float(pos[0]) * gs + gs * 0.5
	var cz: float = float(pos[1]) * gs + gs * 0.5
	node.position = Vector3(cx, 0, cz)

	# Find adjacent neighbors for connectivity
	var neighbors: Array = _find_all_neighbor_dirs(pos, placements)
	var fwd := _rot_to_dir(rot)

	match eid:
		"straight":
			var axis: Vector3 = Vector3(neighbors[0]) if neighbors.size() >= 1 else fwd
			_add_pipe_cylinder(node, Vector3.ZERO, axis, gs, PIPE_RADIUS)
		"corner_right", "corner_left":
			if neighbors.size() >= 2:
				var d0: Vector3 = Vector3(neighbors[0])
				var d1: Vector3 = Vector3(neighbors[1])
				_add_pipe_cylinder(node, d0 * gs * 0.25, d0, gs * 0.5, PIPE_RADIUS)
				_add_pipe_cylinder(node, d1 * gs * 0.25, d1, gs * 0.5, PIPE_RADIUS)
			else:
				var right := _rot_to_dir(rot + 90)
				var turn_dir := right if eid == "corner_right" else -right
				_add_pipe_cylinder(node, -fwd * gs * 0.25, fwd, gs * 0.5, PIPE_RADIUS)
				_add_pipe_cylinder(node, turn_dir * gs * 0.25, turn_dir, gs * 0.5, PIPE_RADIUS)
			_add_pipe_sphere(node, Vector3.ZERO, PIPE_RADIUS)
		"t_junction":
			if neighbors.size() >= 3:
				var main_dir := Vector3.ZERO
				var branch_dir := Vector3.ZERO
				for i in neighbors.size():
					for j in range(i + 1, neighbors.size()):
						var ni: Vector3 = Vector3(neighbors[i])
						var nj: Vector3 = Vector3(neighbors[j])
						if ni.is_equal_approx(-nj):
							main_dir = ni
							for k in neighbors.size():
								if k != i and k != j:
									branch_dir = Vector3(neighbors[k])
				if not main_dir.is_zero_approx():
					_add_pipe_cylinder(node, Vector3.ZERO, main_dir, gs, PIPE_RADIUS)
					_add_pipe_cylinder(node, branch_dir * gs * 0.25, branch_dir, gs * 0.5, PIPE_RADIUS)
				else:
					for idx in neighbors.size():
						var nd: Vector3 = Vector3(neighbors[idx])
						_add_pipe_cylinder(node, nd * gs * 0.25, nd, gs * 0.5, PIPE_RADIUS)
			else:
				_add_pipe_cylinder(node, Vector3.ZERO, fwd, gs, PIPE_RADIUS)
			_add_pipe_sphere(node, Vector3.ZERO, PIPE_RADIUS)
		"cross":
			if neighbors.size() >= 4:
				var used := {}
				for i in neighbors.size():
					if used.has(i):
						continue
					for j in range(i + 1, neighbors.size()):
						if used.has(j):
							continue
						var ni: Vector3 = Vector3(neighbors[i])
						var nj: Vector3 = Vector3(neighbors[j])
						if ni.is_equal_approx(-nj):
							_add_pipe_cylinder(node, Vector3.ZERO, ni, gs, PIPE_RADIUS)
							used[i] = true
							used[j] = true
			else:
				_add_pipe_cylinder(node, Vector3.ZERO, fwd, gs, PIPE_RADIUS)
				_add_pipe_cylinder(node, Vector3.ZERO, _rot_to_dir(rot + 90), gs, PIPE_RADIUS)
			_add_pipe_sphere(node, Vector3.ZERO, PIPE_RADIUS)
		"end_cap":
			if neighbors.size() >= 1:
				var toward: Vector3 = Vector3(neighbors[0])
				_add_pipe_cylinder(node, toward * gs * 0.25, toward, gs * 0.5, PIPE_RADIUS)
				_add_cap_hemisphere(node, -toward * gs * 0.25, -toward, PIPE_RADIUS)
			else:
				_add_pipe_cylinder(node, fwd * gs * 0.15, fwd, gs * 0.3, PIPE_RADIUS)
				_add_cap_hemisphere(node, -fwd * gs * 0.15, -fwd, PIPE_RADIUS)
		"up", "down":
			var axis: Vector3 = Vector3(neighbors[0]) if neighbors.size() >= 1 else fwd
			_add_pipe_cylinder(node, Vector3.ZERO, axis, gs, PIPE_RADIUS)
			var y_dir := 1.0 if eid == "up" else -1.0
			_add_pipe_cylinder(node, Vector3(0, y_dir * gs * 0.2, 0), Vector3.UP, gs * 0.4, PIPE_RADIUS * 0.9)
			_add_pipe_sphere(node, Vector3.ZERO, PIPE_RADIUS)
		"sbend":
			_add_pipe_cylinder(node, -fwd * gs * 0.25, fwd, gs * 0.5, PIPE_RADIUS)
			var right := _rot_to_dir(rot + 90)
			_add_pipe_cylinder(node, fwd * gs * 0.25 + right * gs * 0.3, fwd, gs * 0.5, PIPE_RADIUS)
			_add_pipe_sphere(node, Vector3.ZERO, PIPE_RADIUS)
			_add_pipe_sphere(node, right * gs * 0.3, PIPE_RADIUS)
		_:
			_add_pipe_cylinder(node, Vector3.ZERO, fwd, gs, PIPE_RADIUS)

	return node


func _find_all_neighbor_dirs(pos: Array, placements: Array) -> Array:
	## Find unit direction vectors to all adjacent placements (manhattan distance = 1).
	var dirs: Array = []
	var px := int(pos[0])
	var pz := int(pos[1])
	for other in placements:
		if not other is Dictionary:
			continue
		var opos = other.get("position", [0, 0])
		if not opos is Array or opos.size() < 2:
			continue
		var dx := int(opos[0]) - px
		var dz := int(opos[1]) - pz
		if absi(dx) + absi(dz) == 1:
			dirs.append(Vector3(float(dx), 0, float(dz)))
	return dirs


func _rot_to_dir(rot_deg: int) -> Vector3:
	## Convert grid rotation (0=+X, 90=+Z, 180=-X, 270=-Z) to world direction.
	var r := fmod(float(rot_deg), 360.0)
	if r < 0:
		r += 360.0
	match int(r):
		0: return Vector3(1, 0, 0)
		90: return Vector3(0, 0, 1)
		180: return Vector3(-1, 0, 0)
		270: return Vector3(0, 0, -1)
	var angle := deg_to_rad(r)
	return Vector3(cos(angle), 0, sin(angle))


func _add_pipe_cylinder(parent: Node3D, offset: Vector3, direction: Vector3, length: float, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = length
	cm.radial_segments = 16
	mi.mesh = cm
	mi.material_override = _pipe_material(PIPE_COLOR)
	# Rotate cylinder (default Y-axis) to align with direction
	mi.position = offset
	if direction.is_equal_approx(Vector3.UP) or direction.is_equal_approx(Vector3.DOWN):
		pass # Default Y-axis orientation
	elif direction.is_equal_approx(Vector3(1, 0, 0)) or direction.is_equal_approx(Vector3(-1, 0, 0)):
		mi.rotation.z = PI / 2.0
	elif direction.is_equal_approx(Vector3(0, 0, 1)) or direction.is_equal_approx(Vector3(0, 0, -1)):
		mi.rotation.x = PI / 2.0
	parent.add_child(mi)


func _add_pipe_sphere(parent: Node3D, offset: Vector3, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = _pipe_material(PIPE_COLOR)
	mi.position = offset
	parent.add_child(mi)


func _add_cap_hemisphere(parent: Node3D, offset: Vector3, direction: Vector3, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	sm.is_hemisphere = true
	mi.mesh = sm
	mi.material_override = _pipe_material(CAP_COLOR)
	mi.position = offset
	# Point hemisphere outward in the pipe direction
	if direction.is_equal_approx(Vector3(1, 0, 0)):
		mi.rotation.z = -PI / 2.0
	elif direction.is_equal_approx(Vector3(-1, 0, 0)):
		mi.rotation.z = PI / 2.0
	elif direction.is_equal_approx(Vector3(0, 0, 1)):
		mi.rotation.x = PI / 2.0
	elif direction.is_equal_approx(Vector3(0, 0, -1)):
		mi.rotation.x = -PI / 2.0
	elif direction.is_equal_approx(Vector3(0, 1, 0)):
		pass # default orientation
	elif direction.is_equal_approx(Vector3(0, -1, 0)):
		mi.rotation.x = PI
	parent.add_child(mi)


var _pipe_mat_cache: Dictionary = {}

func _pipe_material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if _pipe_mat_cache.has(key):
		return _pipe_mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.6
	mat.roughness = 0.35
	_pipe_mat_cache[key] = mat
	return mat


## --- Sticky Notes builder ---

func _build_sticky_note(element: Dictionary, gs: float) -> Node3D:
	var node := Node3D.new()
	node.name = str(element.get("id", "note"))
	var sz = element.get("size", [1, 1])
	var w: float = float(sz[0]) if sz is Array and sz.size() >= 2 else 1.0
	var h: float = float(sz[1]) if sz is Array and sz.size() >= 2 else 1.0

	var color_hex: String = str(element.get("note_color", "#FDD835"))
	var depth: float = gs * 0.08

	# Main rectangle
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w * gs * 0.9, h * gs * 0.9, depth)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color_hex)
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = Vector3(w * gs * 0.5, h * gs * 0.5, 0)
	node.add_child(mi)

	# Icon label
	var icon_text: String = str(element.get("icon", ""))
	if not icon_text.is_empty():
		var label := Label3D.new()
		label.text = icon_text
		label.position = Vector3(w * gs * 0.5, h * gs * 0.5, depth * 0.6)
		label.pixel_size = 0.003
		label.font_size = 48
		label.modulate = Color(0.2, 0.2, 0.2)
		node.add_child(label)

	return node


## --- Chemical Models builder (ball-and-stick) ---

const BOND_RADIUS := 0.05
const BOND_COLOR := Color(0.75, 0.75, 0.78)

func _build_chemical_element(element: Dictionary, pos: Array, placements: Array, gs: float, explicit_bonds: Array = []) -> Node3D:
	var node := Node3D.new()
	node.name = str(element.get("id", "atom"))
	var cx: float = float(pos[0]) * gs + gs * 0.5
	var cz: float = float(pos[1]) * gs + gs * 0.5
	node.position = Vector3(cx, 0, cz)

	var cpk_hex: String = str(element.get("cpk_color", "#808080"))
	var radius: float = float(element.get("atom_radius", 0.3)) * gs * 0.8

	# Atom sphere — glossy with subtle emission
	var cpk_color := Color(cpk_hex)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 32
	sm.rings = 16
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cpk_color
	mat.metallic = 0.35
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = cpk_color * 0.15
	mat.emission_energy_multiplier = 0.8
	mat.rim_enabled = true
	mat.rim = 0.3
	mat.rim_tint = 0.4
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.5
	mat.clearcoat_roughness = 0.1
	mi.material_override = mat
	mi.position = Vector3(0, radius, 0)
	node.add_child(mi)

	# Symbol label floating above atom
	var symbol: String = str(element.get("icon", "?"))
	var label := Label3D.new()
	label.text = symbol
	label.position = Vector3(0, radius * 2.5, 0)
	label.pixel_size = 0.004
	label.font_size = 44
	label.outline_size = 6
	label.modulate = Color(1, 1, 1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.add_child(label)

	# Bond sticks — use explicit bonds if provided, otherwise auto-detect neighbors
	var eid_str: String = str(element.get("id", ""))
	var bond_dirs: Array
	if explicit_bonds.size() > 0:
		bond_dirs = _get_explicit_bond_dirs(pos, explicit_bonds)
	else:
		bond_dirs = _find_chebyshev_neighbor_dirs(pos, placements, eid_str)
	for idx in bond_dirs.size():
		var nd: Vector3 = Vector3(bond_dirs[idx])
		_add_bond_stick(node, nd, gs, radius)

	return node


func _find_chebyshev_neighbor_dirs(pos: Array, placements: Array, self_id: String = "") -> Array:
	## Find direction vectors to nearby atom placements (chebyshev distance ≤ 1).
	## Skips non-atom elements and H-H bonds to prevent spurious connections.
	var dirs: Array = []
	var px := int(pos[0])
	var pz := int(pos[1])
	for other in placements:
		if not other is Dictionary:
			continue
		var opos = other.get("position", [0, 0])
		if not opos is Array or opos.size() < 2:
			continue
		var oid: String = str(other.get("element", ""))
		# Only bond to atom elements (skip bond_single, lone_pair, etc.)
		if not oid.begins_with("atom_"):
			continue
		# Skip H-H bonds (hydrogen doesn't bond to hydrogen in these models)
		if self_id == "atom_H" and oid == "atom_H":
			continue
		var dx := int(opos[0]) - px
		var dz := int(opos[1]) - pz
		if dx == 0 and dz == 0:
			continue
		if maxi(absi(dx), absi(dz)) <= 1:
			dirs.append(Vector3(float(dx), 0, float(dz)))
	return dirs


func _get_explicit_bond_dirs(pos: Array, bonds: Array) -> Array:
	## Find bond directions for a specific atom position from an explicit bonds list.
	## Each bond is [[col_a, row_a], [col_b, row_b]].
	var dirs: Array = []
	var px := int(pos[0])
	var pz := int(pos[1])
	for bond in bonds:
		if not bond is Array or bond.size() < 2:
			continue
		var a = bond[0]
		var b = bond[1]
		if not a is Array or not b is Array:
			continue
		if a.size() < 2 or b.size() < 2:
			continue
		var dx: int = 0
		var dz: int = 0
		if int(a[0]) == px and int(a[1]) == pz:
			dx = int(b[0]) - px
			dz = int(b[1]) - pz
		elif int(b[0]) == px and int(b[1]) == pz:
			dx = int(a[0]) - px
			dz = int(a[1]) - pz
		else:
			continue
		dirs.append(Vector3(float(dx), 0, float(dz)))
	return dirs


func _add_bond_stick(parent: Node3D, grid_dir: Vector3, gs: float, atom_radius: float) -> void:
	## Half-length bond stick from atom center toward neighbor (each atom draws half).
	## grid_dir is the integer grid offset (e.g. Vector3(1,0,0) or Vector3(1,0,1) for diagonal).
	var dir_norm: Vector3 = grid_dir.normalized()
	var world_dist: float = grid_dir.length() * gs
	var bond_len: float = world_dist * 0.5 - atom_radius * 0.5
	if bond_len <= 0.01:
		return

	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = BOND_RADIUS * gs
	cm.bottom_radius = BOND_RADIUS * gs
	cm.height = bond_len
	cm.radial_segments = 12
	mi.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = BOND_COLOR
	mat.metallic = 0.7
	mat.roughness = 0.15
	mi.material_override = mat
	# Position halfway between atom center and cell edge
	var offset: Vector3 = dir_norm * (atom_radius * 0.5 + bond_len * 0.5)
	offset.y = atom_radius
	mi.position = offset
	# General rotation: align Y-axis cylinder to lie along dir_norm in XZ plane
	var rot_axis: Vector3 = Vector3.UP.cross(dir_norm)
	if rot_axis.length_squared() > 0.001:
		mi.basis = Basis(rot_axis.normalized(), Vector3.UP.angle_to(dir_norm))
	parent.add_child(mi)


## --- Periodic Table tile builder ---

func _build_periodic_tile(element: Dictionary, gs: float) -> Node3D:
	var node := Node3D.new()
	node.name = str(element.get("id", "tile"))

	var color_hex: String = str(element.get("group_color", "#607D8B"))
	var symbol: String = str(element.get("symbol", element.get("icon", "?")))
	var atomic_num = element.get("atomic_number", 0)
	var tile_size: float = gs * 0.9
	var depth: float = gs * 0.15

	# Tile box
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(tile_size, tile_size, depth)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color_hex)
	mat.roughness = 0.7
	mat.metallic = 0.1
	mi.material_override = mat
	mi.position = Vector3(gs * 0.5, gs * 0.5, 0)
	node.add_child(mi)

	# Element symbol (large, centered)
	var sym_label := Label3D.new()
	sym_label.text = symbol
	sym_label.position = Vector3(gs * 0.5, gs * 0.45, depth * 0.55)
	sym_label.pixel_size = 0.002
	sym_label.font_size = 56
	sym_label.modulate = Color(1, 1, 1)
	node.add_child(sym_label)

	# Atomic number (small, top-left)
	if atomic_num > 0:
		var num_label := Label3D.new()
		num_label.text = str(atomic_num)
		num_label.position = Vector3(gs * 0.25, gs * 0.75, depth * 0.55)
		num_label.pixel_size = 0.0015
		num_label.font_size = 28
		num_label.modulate = Color(0.9, 0.9, 0.9, 0.8)
		node.add_child(num_label)

	return node


func _auto_scale_to_footprint(node: Node3D, element: Dictionary, gs: float, eid: String) -> void:
	## Scale scene down if its meshes exceed the element's allocated grid footprint.
	var elem_size = element.get("size", [1, 1])
	if not elem_size is Array or elem_size.size() < 2:
		return
	var footprint: float = max(float(elem_size[0]), float(elem_size[1])) * gs
	var max_extent: float = _compute_max_mesh_extent(node)
	if max_extent > footprint * 1.5:
		var scale_factor: float = footprint / max_extent
		node.scale = Vector3.ONE * scale_factor
		print("grid_editor_capture: Auto-scaled '%s' — extent=%.2f footprint=%.2f scale=%.3f" % [eid, max_extent, footprint, scale_factor])


func _compute_max_mesh_extent(node: Node) -> float:
	## Recursively find the largest mesh extent in a scene tree.
	var max_ext := 0.0
	if node is MeshInstance3D and node.mesh:
		var aabb: AABB = node.mesh.get_aabb()
		max_ext = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	for child in node.get_children():
		max_ext = max(max_ext, _compute_max_mesh_extent(child))
	return max_ext


func _shift_cap_to_neighbor(node: Node3D, pos: Array, placements: Array, gs: float) -> void:
	## Shift end cap toward its nearest adjacent placement to close visual gaps.
	var best_dir := Vector3.ZERO
	var best_dist := 999.0
	for other in placements:
		if not other is Dictionary:
			continue
		var opos = other.get("position", [0, 0])
		if not opos is Array or opos.size() < 2:
			continue
		var dx := float(opos[0]) - float(pos[0])
		var dz := float(opos[1]) - float(pos[1])
		var manhattan := absf(dx) + absf(dz)
		if manhattan < 0.1 or manhattan > 1.5:
			continue
		# Found adjacent cell — shift toward it
		var world_dir := Vector3(dx * gs, 0, dz * gs)
		var dist := world_dir.length()
		if dist < best_dist:
			best_dist = dist
			best_dir = world_dir.normalized()
	if best_dist < 999.0:
		node.position += best_dir * gs * 0.9


func _add_capture_camera(plane: String, gs: float, grid_dims) -> void:
	var cam = Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 40.0

	# Compute content bounds from actual element positions (tighter than full grid)
	var bounds := _compute_content_bounds(plane)

	# Fallback to grid dims if no elements placed
	if bounds.size.is_zero_approx():
		var gw: float = 16.0
		var gh: float = 12.0
		if grid_dims is Array and grid_dims.size() >= 2:
			gw = float(grid_dims[0])
			gh = float(grid_dims[1])
		match plane:
			"XZ":
				bounds = AABB(Vector3.ZERO, Vector3(gw * gs, 0, gh * gs))
			_:
				bounds = AABB(Vector3.ZERO, Vector3(gw * gs, gh * gs, 0))

	# Add padding around content (20% on each side)
	var padded := bounds.grow(max(bounds.size.x, max(bounds.size.y, bounds.size.z)) * 0.2)
	var center: Vector3
	var cam_dist: float
	var span: float

	match plane:
		"YZ":
			center = Vector3(padded.get_center().x, padded.get_center().y, 0)
			span = max(padded.size.x, padded.size.y)
			cam_dist = span * 1.8
			cam.position = center + Vector3(0, 0, cam_dist)
		"XY":
			center = Vector3(padded.get_center().x, padded.get_center().y, 0)
			span = max(padded.size.x, padded.size.y)
			cam_dist = span * 1.4
			cam.position = center + Vector3(0, 0, cam_dist)
		"XZ":
			center = Vector3(padded.get_center().x, 0, padded.get_center().z)
			span = max(padded.size.x, padded.size.z)
			cam_dist = span * 1.8
			cam.position = center + Vector3(0, cam_dist, 0)

	add_child(cam)
	cam.look_at(center, Vector3.UP if plane != "XZ" else Vector3.FORWARD)
	print("grid_editor_capture: Camera at %s looking at %s (span=%.2f dist=%.2f)" % [cam.position, center, span, cam_dist])


func _compute_content_bounds(plane: String) -> AABB:
	## Compute AABB of all element positions in elements_root.
	var result := AABB()
	var first := true
	for child in elements_root.get_children():
		if not child is Node3D:
			continue
		var pos: Vector3 = child.position
		if first:
			result = AABB(pos, Vector3.ZERO)
			first = false
		else:
			result = result.expand(pos)
	return result


## --- Audio Rack bridge: converts grid editor preset → real interactive synth ---

# Type normalization: grid editor control types → UVAC rack config types
const AUDIO_TYPE_MAP := {
	"slider_h": "slh",
	"button": "btn",
}

# Display type normalization: grid editor display types → UVAC display types
const DISPLAY_TYPE_MAP := {
	"waveform": "simple_waveform",
}


func _build_audio_rack_from_config(config_name: String, gs: float, plane: String) -> void:
	## Load a standalone rack config JSON and build UVAC directly.
	var path := "res://commons/audio/rack_configs/%s.json" % config_name
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		push_error("grid_editor_capture: Rack config not found: %s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("grid_editor_capture: Could not open rack config: %s" % path)
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("grid_editor_capture: JSON parse error in %s" % path)
		return

	var rack_config: Dictionary = json.data if json.data is Dictionary else {}
	if rack_config.is_empty():
		push_error("grid_editor_capture: Empty rack config: %s" % path)
		return

	# Clear previous elements
	for c in elements_root.get_children():
		c.queue_free()

	var uvac: Node3D = UVAC_SCENE.instantiate()
	uvac.name = "AudioRack"
	elements_root.add_child(uvac)
	uvac.call_deferred("load_rack_config_from_dict", rack_config)

	# Estimate grid dims from the config's grid array
	var grid_array: Array = rack_config.get("grid", [])
	var rows: int = grid_array.size()
	var cols: int = 0
	for row in grid_array:
		if row is Array and row.size() > cols:
			cols = row.size()
	_add_capture_camera(plane, gs, [cols, rows])
	print("grid_editor_capture: Built audio rack from config '%s' (%d controls)" % [config_name, rack_config.get("control_definitions", {}).size()])


func _build_audio_rack(subset: Dictionary, placements: Array, grid_dims, gs: float, plane: String) -> void:
	## Build a real interactive UniversalVRAudioController from grid editor audio_rack placements.
	# Clear previous elements
	for c in elements_root.get_children():
		c.queue_free()

	var rack_config := _convert_preset_to_rack_config(subset, placements, grid_dims)

	var uvac: Node3D = UVAC_SCENE.instantiate()
	uvac.name = "AudioRack"
	elements_root.add_child(uvac)

	# Load the converted config after the node is in the tree
	uvac.call_deferred("load_rack_config_from_dict", rack_config)

	# Add CaptureCamera
	_add_capture_camera(plane, gs, grid_dims)
	print("grid_editor_capture: Built audio rack with %d controls" % rack_config.get("control_definitions", {}).size())


func _convert_preset_to_rack_config(subset: Dictionary, placements: Array, grid_dims) -> Dictionary:
	## Convert grid editor audio_rack placements into a rack config Dictionary
	## compatible with UniversalVRAudioController.load_rack_config_from_dict().
	var cols: int = int(grid_dims[0]) if grid_dims is Array and grid_dims.size() > 0 else 16
	var rows: int = int(grid_dims[1]) if grid_dims is Array and grid_dims.size() > 1 else 12
	var elements_list: Array = subset.get("elements", [])
	var audio_info: Dictionary = subset.get("audio", {})

	# Build element lookup by ID
	var elem_lookup: Dictionary = {}
	for elem in elements_list:
		elem_lookup[str(elem.get("id", ""))] = elem

	# Initialize empty grid (rows x cols)
	var grid: Array = []
	for r in rows:
		var row: Array = []
		for c in cols:
			row.append("")
		grid.append(row)

	var control_defs: Dictionary = {}
	var sound_type: String = audio_info.get("sound_type", "basic_sine_wave")
	var control_counter: int = 0

	# Track controls per category for section auto-generation
	var category_controls: Dictionary = {}  # category_id -> [ctrl_id, ...]

	for placement in placements:
		if not placement is Dictionary:
			continue
		var eid: String = str(placement.get("element", ""))
		var pos: Array = placement.get("position", [0, 0])
		var col: int = int(pos[0])
		var row: int = int(pos[1])

		var element: Dictionary = elem_lookup.get(eid, {})
		if element.is_empty():
			continue

		# Source elements set sound_type but don't appear as controls
		if element.has("source"):
			var src: Dictionary = element["source"]
			sound_type = src.get("sound_type", sound_type)
			continue

		# Generate unique control ID
		var ctrl_id: String = "%s_%d" % [eid, control_counter]
		control_counter += 1

		# Build control definition
		var ctrl_def: Dictionary = {}
		if element.has("control"):
			var ctrl: Dictionary = element["control"]
			var raw_type: String = str(ctrl.get("type", "slider"))
			ctrl_def["type"] = AUDIO_TYPE_MAP.get(raw_type, raw_type)
			if ctrl.has("parameter"):
				ctrl_def["parameter"] = ctrl["parameter"]
			if ctrl.has("min"):
				ctrl_def["min"] = ctrl["min"]
			if ctrl.has("max"):
				ctrl_def["max"] = ctrl["max"]
			if ctrl.has("default"):
				ctrl_def["default"] = ctrl["default"]
			if ctrl.has("label"):
				ctrl_def["label"] = ctrl["label"]
			if ctrl.has("action"):
				ctrl_def["action"] = ctrl["action"]
			if ctrl.has("color"):
				ctrl_def["color"] = ctrl["color"]
		elif element.has("display"):
			var disp: Dictionary = element["display"]
			var raw_type: String = str(disp.get("type", "monitor"))
			ctrl_def["type"] = DISPLAY_TYPE_MAP.get(raw_type, raw_type)
			if disp.has("source"):
				ctrl_def["source"] = disp["source"]
			if disp.has("label"):
				ctrl_def["label"] = disp["label"]
			if disp.has("freq_param"):
				ctrl_def["freq_param"] = disp["freq_param"]
			if disp.has("amp_param"):
				ctrl_def["amp_param"] = disp["amp_param"]
		else:
			continue

		# Place control ID in the grid
		if row >= 0 and row < rows and col >= 0 and col < cols:
			grid[row][col] = ctrl_id

		control_defs[ctrl_id] = ctrl_def

		# Track category for section auto-generation
		var cat_id: String = str(element.get("category", ""))
		if not cat_id.is_empty() and cat_id != "sources":
			if not category_controls.has(cat_id):
				category_controls[cat_id] = []
			category_controls[cat_id].append(ctrl_id)

	# Build sections from category groups
	var categories_list: Array = subset.get("categories", [])
	var cat_lookup: Dictionary = {}
	for cat in categories_list:
		cat_lookup[str(cat.get("id", ""))] = cat

	var sections: Array = []
	# Section label & color per category
	var section_labels: Dictionary = {
		"controls": "CONTROLS",
		"filters": "FILTER",
		"effects": "EFFECTS",
		"modulators": "ENVELOPE",
		"displays": "MONITORING",
		"buttons": "TRANSPORT"
	}
	for cat_id in category_controls.keys():
		var cat_data: Dictionary = cat_lookup.get(cat_id, {})
		var section := {
			"label": section_labels.get(cat_id, cat_data.get("name", cat_id).to_upper()),
			"color": str(cat_data.get("color", "#4CAF50")),
			"controls": category_controls[cat_id]
		}
		sections.append(section)

	return {
		"rack_info": {
			"name": subset.get("name", "Audio Rack"),
			"sound_type": sound_type
		},
		"layout": {
			"padding_px": 20,
			"gap_px": 15,
			"vr_scale": 1.5,
			"hide_selection": true,
			"hide_buttons": true
		},
		"grid": grid,
		"control_definitions": control_defs,
		"sections": sections
	}
