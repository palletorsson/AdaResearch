class_name PearlDropComposer
extends Node3D

## Pearl-drop in Godot — boxes connected by joints, dropped from above
## onto a map's voxel terrain. Uses Godot's built-in physics.
##
## - Each terrain cell with h >= 1 becomes a StaticBody3D + BoxShape3D.
## - Each pearl is a RigidBody3D + BoxShape3D sized to its dressing-room
##   footprint. Rotation locked so footprints stay axis-aligned.
## - Pearls connect with PinJoint3D, positioned mid-air between them so
##   they pivot around the joint and stay at fixed separation
##   (sum-of-half-sizes + string_gap).
## - Drop = re-stage at the canonical "above terrain" pose, run physics.
## - Apply = snap pearl positions to grid cells, write to the map's
##   interactables layer, save.

const ROOMS_DIR := "res://commons/artifacts/dressing_rooms/"
const MAPS_DIR := "res://commons/maps/"

@export var map_name: String = "Point_One"
@export var chain: Array[String] = [
	"lambda_slider", "phi_slider", "qfep_formula_3d",
	"russell_set_box", "pompeii_mosaic_floor",
]
@export var string_gap: float = 0.5            # cells of separation between pearls
@export var gravity: float = 12.0
@export var pearl_thickness: float = 0.5       # Y-axis height of each pearl box
@export var spawn_extra_height: float = 12.0   # cells above terrain to spawn

# ── Scene refs (filled in _ready) ─────────────────────────────────────
@onready var _world: Node3D = $World
@onready var _chain_root: Node3D = $Chain
@onready var _camera_rig: Node3D = $CameraRig
@onready var _camera: Camera3D = $CameraRig/Camera3D
@onready var _info: Label = $UI/Info
@onready var _hint: Label = $UI/Hints

var _map_data: Dictionary = {}
var _rows: int = 0
var _cols: int = 0
var _pearls: Array[RigidBody3D] = []
var _joints: Array[PinJoint3D] = []
var _footprints: Dictionary = {}                 # lookup → {rows, cols, anchor, tiles}
var _running: bool = false

# Camera state.
var _orbit_yaw: float = deg_to_rad(30.0)
var _orbit_pitch: float = deg_to_rad(-22.0)
var _orbit_distance: float = 18.0
var _orbit_focus: Vector3 = Vector3.ZERO
var _is_orbiting: bool = false
var _is_panning: bool = false
var _last_mouse: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Project gravity (so RigidBodies fall) — set globally for the scene.
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space,
		PhysicsServer3D.AREA_PARAM_GRAVITY, gravity)
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space,
		PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR, Vector3.DOWN)

	_load_footprints()
	_load_map(map_name)
	_set_hints()


func _set_hints() -> void:
	if _hint:
		_hint.text = "[Space] drop / pause   [R] reset   [A] apply   drag = orbit   scroll = zoom"


# ──────────────────────────────────────────────────────────────────────
# Loading
# ──────────────────────────────────────────────────────────────────────

func _load_footprints() -> void:
	for lookup in chain:
		var path := ROOMS_DIR + lookup + ".json"
		if not FileAccess.file_exists(path):
			_footprints[lookup] = {"rows": 1, "cols": 1, "anchor": [0, 0], "tiles": [[1]]}
			continue
		var raw := FileAccess.get_file_as_string(path)
		var parsed = JSON.parse_string(raw)
		if not (parsed is Dictionary):
			_footprints[lookup] = {"rows": 1, "cols": 1, "anchor": [0, 0], "tiles": [[1]]}
			continue
		var tiles: Array = parsed.get("footing", {}).get("tiles", [[1]])
		var rows := tiles.size()
		var cols := 0
		for row in tiles:
			if row is Array and row.size() > cols:
				cols = row.size()
		var anchor: Array = parsed.get("footing", {}).get("anchor", [0, 0])
		_footprints[lookup] = {
			"rows": max(1, rows),
			"cols": max(1, cols),
			"anchor": [int(anchor[0]), int(anchor[1])],
			"tiles": tiles,
		}


func _load_map(name: String) -> void:
	var path := MAPS_DIR + name + "/map_data.json"
	var raw := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		_set_info("Could not load map: %s" % name)
		return
	_map_data = parsed
	var struct: Array = _map_data.get("layers", {}).get("structure", [])
	_rows = struct.size()
	_cols = 0
	for row in struct:
		if row is Array and row.size() > _cols:
			_cols = row.size()
	_build_world()
	_build_chain()
	_frame_camera()
	_set_info("Loaded %s  (%dx%d, %d pearls)" % [name, _rows, _cols, _pearls.size()])


# ──────────────────────────────────────────────────────────────────────
# Build static terrain — one StaticBody3D + BoxShape3D per voxel cell.
# Every cell gets at least h=1 so pearls always rest on a cube top.
# ──────────────────────────────────────────────────────────────────────

func _build_world() -> void:
	# Clear prior.
	for c in _world.get_children():
		c.queue_free()

	var struct: Array = _map_data.get("layers", {}).get("structure", [])
	for r in range(_rows):
		var row: Array = struct[r] if r < struct.size() else []
		for c in range(_cols):
			var raw_v = row[c] if c < row.size() else "0"
			var h: int = int(str(raw_v))
			h = max(1, h)
			_make_cube(c + 0.5, h * 0.5, r + 0.5, 1.0, h, 1.0,
				Color(0.55, 0.62, 0.72) if h == 1 else Color(0.65, 0.72, 0.82))

	# Outer fence — 4 walls of height 8 around the grid.
	var fy := 4.0
	_make_cube(-0.5, fy, _rows * 0.5, 1.0, fy * 2.0, _rows + 2.0, Color(0.18, 0.20, 0.24))
	_make_cube(_cols + 0.5, fy, _rows * 0.5, 1.0, fy * 2.0, _rows + 2.0, Color(0.18, 0.20, 0.24))
	_make_cube(_cols * 0.5, fy, -0.5, _cols + 2.0, fy * 2.0, 1.0, Color(0.18, 0.20, 0.24))
	_make_cube(_cols * 0.5, fy, _rows + 0.5, _cols + 2.0, fy * 2.0, 1.0, Color(0.18, 0.20, 0.24))


func _make_cube(x: float, y: float, z: float, sx: float, sy: float, sz: float, color: Color) -> void:
	var sb := StaticBody3D.new()
	sb.position = Vector3(x, y, z)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(sx, sy, sz)
	col.shape = shape
	sb.add_child(col)
	# Visual.
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(sx, sy, sz)
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mi.material_override = mat
	sb.add_child(mi)
	_world.add_child(sb)


# ──────────────────────────────────────────────────────────────────────
# Build the chain — RigidBody3D boxes + PinJoint3D between pearls.
# ──────────────────────────────────────────────────────────────────────

func _build_chain() -> void:
	for c in _chain_root.get_children():
		c.queue_free()
	_pearls.clear()
	_joints.clear()
	if chain.is_empty():
		return

	var max_h := 1
	var struct: Array = _map_data.get("layers", {}).get("structure", [])
	for row in struct:
		if not (row is Array): continue
		for v in row:
			var h := int(str(v))
			if h > max_h: max_h = h
	var base_y: float = max(max_h + spawn_extra_height,
		max(_rows, _cols) * 0.6)
	var start_x: float = _cols * 0.5
	var start_z: float = _rows * 0.5

	# Precompute per-pearl size (avg of rows + cols) for chain length.
	var sizes: Array[float] = []
	for lookup in chain:
		var fp = _footprints.get(lookup, {"rows": 1, "cols": 1})
		sizes.append((fp.rows + fp.cols) * 0.5)

	# Spawn Y per pearl: head (i=0) at the bottom of the dangling chain.
	var n := chain.size()
	var ys: Array[float] = []
	ys.resize(n)
	ys[n - 1] = base_y
	for i in range(n - 2, -1, -1):
		var dy: float = sizes[i] * 0.5 + sizes[i + 1] * 0.5 + string_gap
		ys[i] = ys[i + 1] - dy

	# Build the bodies.
	for i in range(n):
		var lookup: String = chain[i]
		var fp = _footprints.get(lookup, {"rows": 1, "cols": 1})
		var w: float = float(fp.cols)
		var d: float = float(fp.rows)
		var pearl := _make_pearl(lookup, i, n,
			Vector3(start_x, ys[i], start_z),
			Vector3(w, pearl_thickness, d))
		_chain_root.add_child(pearl)
		_pearls.append(pearl)

	# Build the joints — placed midway between adjacent pearls so the
	# constraint's anchor on each body sits at the right offset, giving
	# fixed separation = halfA + halfB + string_gap.
	for i in range(n - 1):
		var a := _pearls[i]
		var b := _pearls[i + 1]
		var joint := PinJoint3D.new()
		var midpoint: Vector3 = (a.position + b.position) * 0.5
		joint.position = midpoint
		joint.node_a = a.get_path()
		joint.node_b = b.get_path()
		# A bit of swing; otherwise the joint is too rigid.
		joint.set_param(PinJoint3D.PARAM_BIAS, 0.95)
		joint.set_param(PinJoint3D.PARAM_DAMPING, 1.0)
		joint.set_param(PinJoint3D.PARAM_IMPULSE_CLAMP, 0.0)
		_chain_root.add_child(joint)
		_joints.append(joint)


func _make_pearl(lookup: String, i: int, n: int,
		pos: Vector3, size: Vector3) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.name = "Pearl_%d_%s" % [i, lookup]
	rb.position = pos
	rb.mass = 1.0
	# Lock rotation so footprints stay axis-aligned with the grid.
	rb.lock_rotation = true
	# Damping so they settle smoothly.
	rb.linear_damp = 0.6
	rb.angular_damp = 0.95
	# Don't simulate until "drop" pressed.
	rb.freeze = true
	rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	rb.add_child(col)

	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	if i == 0:
		mat.albedo_color = Color(0.13, 0.77, 0.37)        # green head
	elif i == n - 1:
		mat.albedo_color = Color(0.96, 0.62, 0.04)        # amber tail
	else:
		mat.albedo_color = Color(0.38, 0.65, 0.98)        # blue body
	mat.roughness = 0.4
	mat.metallic = 0.05
	mi.material_override = mat
	rb.add_child(mi)

	# Index label so chain order is readable in the 3D view.
	var label := Label3D.new()
	label.text = str(i)
	label.font_size = 64
	label.position = Vector3(0, size.y * 0.5 + 0.3, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	rb.add_child(label)

	rb.set_meta("lookup", lookup)
	rb.set_meta("chain_index", i)
	rb.set_meta("fp_rows", int((_footprints.get(lookup, {"rows":1}) as Dictionary).rows))
	rb.set_meta("fp_cols", int((_footprints.get(lookup, {"cols":1}) as Dictionary).cols))
	rb.set_meta("anchor", _footprints.get(lookup, {"anchor":[0, 0]}).anchor)
	rb.set_meta("tiles", _footprints.get(lookup, {"tiles":[[1]]}).tiles)
	return rb


# ──────────────────────────────────────────────────────────────────────
# Run / pause / reset / apply
# ──────────────────────────────────────────────────────────────────────

func drop() -> void:
	# Always re-stage from above each press, so it's a true drop.
	_reset_positions()
	for p in _pearls:
		p.freeze = false
	_running = true
	_set_info("dropping…")


func pause_drop() -> void:
	for p in _pearls:
		p.freeze = true
	_running = false
	_set_info("paused")


func reset_drop() -> void:
	_reset_positions()
	for p in _pearls:
		p.freeze = true
	_running = false
	_set_info("reset")


func _reset_positions() -> void:
	if _pearls.is_empty(): return
	var max_h := 1
	var struct: Array = _map_data.get("layers", {}).get("structure", [])
	for row in struct:
		if not (row is Array): continue
		for v in row:
			var h := int(str(v))
			if h > max_h: max_h = h
	var base_y: float = max(max_h + spawn_extra_height,
		max(_rows, _cols) * 0.6)
	var start_x: float = _cols * 0.5
	var start_z: float = _rows * 0.5
	var sizes: Array[float] = []
	for lookup in chain:
		var fp = _footprints.get(lookup, {"rows": 1, "cols": 1})
		sizes.append((fp.rows + fp.cols) * 0.5)
	var n := _pearls.size()
	var ys: Array[float] = []
	ys.resize(n)
	ys[n - 1] = base_y
	for i in range(n - 2, -1, -1):
		var dy: float = sizes[i] * 0.5 + sizes[i + 1] * 0.5 + string_gap
		ys[i] = ys[i + 1] - dy
	for i in range(n):
		var p := _pearls[i]
		p.linear_velocity = Vector3.ZERO
		p.angular_velocity = Vector3.ZERO
		p.position = Vector3(start_x, ys[i], start_z)
		p.rotation = Vector3.ZERO


func apply_to_map() -> void:
	if _map_data.is_empty(): return
	# Snap each pearl to a grid cell with collision-aware spiral search.
	var occupied: Dictionary = {}
	var placements: Array = []
	for p in _pearls:
		var pr: Vector3 = p.position
		var col: int = clampi(int(round(pr.x - 0.5)), 0, _cols - 1)
		var row: int = clampi(int(round(pr.z - 0.5)), 0, _rows - 1)
		var key := "%d,%d" % [row, col]
		if occupied.has(key):
			# Spiral outward.
			var found := false
			var radius := 1
			while radius <= _rows + _cols and not found:
				for dr in range(-radius, radius + 1):
					for dc in range(-radius, radius + 1):
						if max(absi(dr), absi(dc)) != radius: continue
						var nr: int = row + dr
						var nc: int = col + dc
						if nr < 0 or nr >= _rows or nc < 0 or nc >= _cols: continue
						var nk := "%d,%d" % [nr, nc]
						if occupied.has(nk): continue
						row = nr; col = nc
						found = true
						break
					if found: break
				radius += 1
		occupied["%d,%d" % [row, col]] = true
		placements.append({"lookup": p.get_meta("lookup"), "row": row, "col": col})

	# Carve corridor cells (Bresenham between consecutive anchors) — set
	# any void cells along the way to floor.
	var struct: Array = _map_data.get("layers", {}).get("structure", []).duplicate(true)
	var carved := 0
	for i in range(placements.size() - 1):
		var a = placements[i]
		var b = placements[i + 1]
		var line := _bresenham(a.row, a.col, b.row, b.col)
		for cell in line:
			var rr: int = cell[0]
			var cc: int = cell[1]
			if rr < 0 or rr >= _rows or cc < 0 or cc >= _cols: continue
			while struct.size() <= rr:
				struct.append([])
			var row: Array = struct[rr]
			while row.size() <= cc:
				row.append("0")
			if int(str(row[cc])) == 0:
				row[cc] = "1"
				carved += 1
			struct[rr] = row

	# Stamp artifacts into interactables layer.
	var inter: Array = _map_data.get("layers", {}).get("interactables", []).duplicate(true)
	while inter.size() < _rows:
		inter.append([])
	for p_data in placements:
		var rr: int = p_data.row
		var cc: int = p_data.col
		while inter.size() <= rr: inter.append([])
		var row: Array = inter[rr]
		while row.size() <= cc: row.append(" ")
		row[cc] = "%s:0:0" % p_data.lookup
		inter[rr] = row
		# Make sure the cell is walkable.
		while struct.size() <= rr: struct.append([])
		var srow: Array = struct[rr]
		while srow.size() <= cc: srow.append("0")
		if int(str(srow[cc])) == 0:
			srow[cc] = "1"
		struct[rr] = srow

	# Spawn at first pearl, teleporter just past last (on first free neighbour).
	var utils: Array = _map_data.get("layers", {}).get("utilities", []).duplicate(true)
	while utils.size() < _rows: utils.append([])
	if not placements.is_empty():
		var first = placements[0]
		while utils.size() <= first.row: utils.append([])
		var u_row: Array = utils[first.row]
		while u_row.size() <= first.col: u_row.append(" ")
		u_row[first.col] = "s"
		utils[first.row] = u_row

	_map_data["layers"]["structure"] = struct
	_map_data["layers"]["utilities"] = utils
	_map_data["layers"]["interactables"] = inter
	_map_data["map_info"]["metadata"] = _map_data.get("map_info", {}).get("metadata", {})
	_map_data["map_info"]["metadata"]["composed_from_dressing_rooms"] = true
	_map_data["map_info"]["metadata"]["compose_mode"] = "pearl_drop_godot"
	_map_data["map_info"]["metadata"]["anchors"] = placements

	# Save under <map>_PearlDrop so we don't clobber the original.
	var out_name: String = "%s_PearlDrop" % map_name
	var out_dir: String = MAPS_DIR + out_name + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var out_path: String = out_dir + "map_data.json"
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		_set_info("apply: cannot write %s" % out_path)
		return
	f.store_string(JSON.stringify(_map_data, "\t"))
	f.close()
	_set_info("✓ wrote %s  (%d pearls, %d corridor cells carved)" % [
		out_name, placements.size(), carved])


func _bresenham(r0: int, c0: int, r1: int, c1: int) -> Array:
	var out: Array = []
	var dr: int = absi(r1 - r0)
	var dc: int = absi(c1 - c0)
	var sr: int = 1 if r0 < r1 else -1
	var sc: int = 1 if c0 < c1 else -1
	var err: int = dc - dr
	var r: int = r0
	var c: int = c0
	while true:
		out.append([r, c])
		if r == r1 and c == c1: break
		var e2: int = 2 * err
		if e2 > -dr:
			err -= dr
			c += sc
		if e2 < dc:
			err += dc
			r += sr
	return out


# ──────────────────────────────────────────────────────────────────────
# Camera + input
# ──────────────────────────────────────────────────────────────────────

func _frame_camera() -> void:
	_orbit_focus = Vector3(_cols * 0.5, 1.5, _rows * 0.5)
	_orbit_distance = max(_rows, _cols) * 1.4 + 6.0
	_update_camera()


func _update_camera() -> void:
	var x: float = _orbit_distance * cos(_orbit_pitch) * sin(_orbit_yaw)
	var y: float = _orbit_distance * sin(_orbit_pitch)
	var z: float = _orbit_distance * cos(_orbit_pitch) * cos(_orbit_yaw)
	_camera_rig.global_position = _orbit_focus + Vector3(x, y, z)
	_camera_rig.look_at(_orbit_focus, Vector3.UP)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_is_orbiting = mb.pressed
			_last_mouse = mb.position
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = mb.pressed
			_last_mouse = mb.position
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_orbit_distance = max(2.0, _orbit_distance - 1.5)
			_update_camera()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_orbit_distance = min(60.0, _orbit_distance + 1.5)
			_update_camera()
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if _is_orbiting:
			var d: Vector2 = mm.position - _last_mouse
			_last_mouse = mm.position
			_orbit_yaw -= d.x * 0.006
			_orbit_pitch = clamp(_orbit_pitch + d.y * 0.006,
				deg_to_rad(-80), deg_to_rad(80))
			_update_camera()
		elif _is_panning:
			var d2: Vector2 = mm.position - _last_mouse
			_last_mouse = mm.position
			var bx: Vector3 = -_camera_rig.global_transform.basis.x
			var by: Vector3 = _camera_rig.global_transform.basis.y
			_orbit_focus += bx * d2.x * 0.02 * (_orbit_distance / 12.0)
			_orbit_focus += by * d2.y * 0.02 * (_orbit_distance / 12.0)
			_update_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				if _running: pause_drop()
				else: drop()
			KEY_R:
				reset_drop()
			KEY_A:
				apply_to_map()
			KEY_F:
				_frame_camera()


func _set_info(text: String) -> void:
	if _info: _info.text = text
