# BiomePaintVR.gd — VR biome paint brush
#
# The desktop scrubber's brush, ported to a controller. Point at the floor,
# trigger to paint the active element's density, grip to erase. Follows the
# VoxelEditVR idiom — see doc/VR_EDITING_SYSTEM.md and doc/PAINT_LAYERS.md.
#
# Enable from vrStaging.gd:
#   var brush := BiomePaintVR.new()
#   right_controller.add_child(brush)
#   brush.enable()

class_name BiomePaintVR
extends Node3D

const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")
const ELEMENTS: Array = ["tree", "critter", "flower", "mushroom", "large_critter"]

var _controller: XRController3D = null
var _grid: Node = null               # GridSystem (has repaint_biome + cube_size + map_name)
var _data: Node = null               # GridDataComponent (dims + existing paint_layers)
var _active: bool = false

var _ray: MeshInstance3D = null
var _ray_mat: StandardMaterial3D = null
var _ghost: MeshInstance3D = null
var _ghost_mat: StandardMaterial3D = null
var _label: Label3D = null

var _grid_w: int = 10
var _grid_d: int = 10
var _cube: float = 1.0
var _map_name: String = ""

var _elem_idx: int = 0
var _radius: int = 2
var _strength: float = 0.6
var _fields: Dictionary = {}         # element -> PackedFloat32Array (grid_w*grid_d)
var _stroking: bool = false


func _ready() -> void:
	_controller = get_parent() as XRController3D
	if not _controller:
		push_warning("[BiomePaintVR] Must be a child of an XRController3D")
		return
	_build_visuals()
	if _controller.has_signal("button_pressed"):
		_controller.button_pressed.connect(_on_button)


func enable() -> void:
	_grid = _find(get_tree().root, "GridSystem")
	_data = _find(get_tree().root, "GridDataComponent")
	if _data and _data.has_method("get_grid_dimensions"):
		var d: Vector3i = _data.get_grid_dimensions()
		_grid_w = maxi(1, d.x)
		_grid_d = maxi(1, d.z)
	if _grid:
		if "cube_size" in _grid:
			_cube = _grid.cube_size
		if "map_name" in _grid:
			_map_name = str(_grid.map_name)
	_active = true
	if _ray: _ray.visible = true
	if _label: _label.visible = true
	_apply_element_colour()
	_update_label()
	print("[BiomePaintVR] Enabled — %dx%d, map=%s" % [_grid_w, _grid_d, _map_name])


func disable() -> void:
	# Painted biome persists in-session (in-memory, like the bracelet); the
	# runtime override stays until a map reload or an explicit clear.
	_active = false
	_stroking = false
	if _ray: _ray.visible = false
	if _ghost: _ghost.visible = false
	if _label: _label.visible = false


func is_active() -> bool:
	return _active


# ── Input ─────────────────────────────────────────────────────────────
func _on_button(button_name: String) -> void:
	if not _active:
		return
	match button_name:
		"ax_button": _save()
		"by_button": _cycle_element()


func _process(_dt: float) -> void:
	if not _active or not _controller:
		return
	var cell := _ray_cell()
	if cell.x < 0:
		if _ghost: _ghost.visible = false
		# A stroke that wanders off-grid still commits what was painted.
		if _stroking:
			_stroking = false
			_repaint()
		return
	if _ghost:
		_ghost.visible = true
		_ghost.global_position = Vector3((float(cell.x) + 0.5) * _cube, 0.05, (float(cell.y) + 0.5) * _cube)

	var painting: bool = _controller.is_button_pressed("trigger_click")
	var erasing: bool = _controller.is_button_pressed("grip_click")
	if painting or erasing:
		_stamp(cell.x, cell.y, erasing)
		_stroking = true
	elif _stroking:
		# Stroke released → rebuild the biome live with the painted field.
		_stroking = false
		_repaint()


## Cast from the controller onto the ground plane (y=0) → grid cell, or (-1,-1).
func _ray_cell() -> Vector2i:
	var origin: Vector3 = _controller.global_position
	var dir: Vector3 = -_controller.global_transform.basis.z
	if absf(dir.y) < 1e-5:
		return Vector2i(-1, -1)
	var t: float = -origin.y / dir.y
	if t < 0.0:
		return Vector2i(-1, -1)
	var hit: Vector3 = origin + dir * t
	var cx: int = int(floor(hit.x / _cube))
	var cz: int = int(floor(hit.z / _cube))
	if cx < 0 or cx >= _grid_w or cz < 0 or cz >= _grid_d:
		return Vector2i(-1, -1)
	return Vector2i(cx, cz)


func _stamp(cx: int, cz: int, erase: bool) -> void:
	var el: String = ELEMENTS[_elem_idx]
	if not _fields.has(el):
		var nf := PackedFloat32Array()
		nf.resize(_grid_w * _grid_d)
		_fields[el] = nf
	var field: PackedFloat32Array = _fields[el]
	for dz in range(-_radius, _radius + 1):
		for dx in range(-_radius, _radius + 1):
			var x: int = cx + dx
			var z: int = cz + dz
			if x < 0 or x >= _grid_w or z < 0 or z >= _grid_d:
				continue
			var dist: float = sqrt(float(dx * dx + dz * dz))
			if dist > float(_radius) + 0.001:
				continue
			var fall: float = 1.0 - dist / (float(_radius) + 0.0001)
			var i: int = z * _grid_w + x
			if erase:
				field[i] = maxf(0.0, field[i] - _strength * fall)
			else:
				field[i] = minf(1.0, field[i] + _strength * fall)


# ── Biome rebuild + save ──────────────────────────────────────────────
## Brush fields (as mode:"brush" layers) + the map's other (non-painted) layers.
func _effective_layers() -> Array:
	var out: Array = []
	var painted: Dictionary = {}
	for el in _fields:
		painted[el] = true
		out.append({"element": el, "mode": "brush", "density": 1.0, "brush": _rows(_fields[el])})
	if _data and _data.has_method("get_paint_layers"):
		for layer in _data.get_paint_layers():
			if layer is Dictionary and not painted.has(str(layer.get("element", ""))):
				out.append(layer)
	return out


func _rows(field: PackedFloat32Array) -> Array:
	var rows: Array = []
	for z in _grid_d:
		var row: Array = []
		for x in _grid_w:
			var i: int = z * _grid_w + x
			row.append(snappedf(field[i] if i < field.size() else 0.0, 0.01))
		rows.append(row)
	return rows


func _repaint() -> void:
	if _grid and _grid.has_method("repaint_biome"):
		_grid.repaint_biome(_effective_layers())


func _save() -> void:
	if _map_name.is_empty():
		_set_label("no map — can't save")
		return
	var path: String = "res://commons/maps/%s/map_data.json" % _map_name
	if not FileAccess.file_exists(path):
		_set_label("map file missing")
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		_set_label("map parse failed")
		return
	# Merge: painted elements replace; other paint_layers preserved.
	var existing: Array = data.get("paint_layers", []) if (data.get("paint_layers") is Array) else []
	var kept: Array = []
	for layer in existing:
		if layer is Dictionary and not _fields.has(str(layer.get("element", ""))):
			kept.append(layer)
	for el in _fields:
		kept.append({"element": el, "mode": "brush", "density": 1.0, "brush": _rows(_fields[el])})
	data["paint_layers"] = kept
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_set_label("SAVE FAILED (read-only?)")
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	_set_label("SAVED %d brush layer(s)" % _fields.size())
	print("[BiomePaintVR] saved paint_layers → %s" % _map_name)


# ── Element + visuals ─────────────────────────────────────────────────
func _cycle_element() -> void:
	_elem_idx = (_elem_idx + 1) % ELEMENTS.size()
	_apply_element_colour()
	_update_label()


func _apply_element_colour() -> void:
	var c := _elem_colour(ELEMENTS[_elem_idx])
	if _ray_mat:
		_ray_mat.albedo_color = Color(c.r, c.g, c.b, 0.4)
	if _ghost_mat:
		_ghost_mat.albedo_color = c


func _elem_colour(el: String) -> Color:
	match el:
		"tree": return Color(0.45, 0.85, 0.50)
		"critter": return Color(1.0, 0.70, 0.36)
		"flower": return Color(1.0, 0.55, 0.76)
		"mushroom": return Color(0.80, 0.55, 0.40)
		"large_critter": return Color(0.95, 0.45, 0.30)
	return Color(0.7, 0.7, 0.7)


func _update_label() -> void:
	_set_label("BIOME BRUSH\n%s  (r%d)\nTrigger paint · Grip erase\nBy element · Ax save" % [
		ELEMENTS[_elem_idx].to_upper(), _radius])


func _set_label(t: String) -> void:
	if _label:
		_label.text = t


func _build_visuals() -> void:
	# Controller ray (forward).
	_ray = MeshInstance3D.new()
	_ray.name = "BrushRay"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.002
	cyl.bottom_radius = 0.002
	cyl.height = 15.0
	_ray.mesh = cyl
	_ray.position = Vector3(0, 0, -7.5)
	_ray.rotation.x = PI * 0.5
	_ray_mat = StandardMaterial3D.new()
	_ray_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ray.material_override = _ray_mat
	_ray.visible = false
	add_child(_ray)

	# Ground ghost — a flat disc at the target cell (top_level → world space).
	_ghost = MeshInstance3D.new()
	_ghost.name = "BrushGhost"
	_ghost.top_level = true
	var disc := CylinderMesh.new()
	disc.top_radius = 0.30
	disc.bottom_radius = 0.30
	disc.height = 0.02
	_ghost.mesh = disc
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_mat.albedo_color = Color(0.45, 0.85, 0.50, 0.5)
	_ghost.material_override = _ghost_mat
	_ghost.visible = false
	add_child(_ghost)

	# HUD label on the controller.
	_label = Label3D.new()
	_label.name = "BrushLabel"
	_label.font_size = 18
	_label.position = Vector3(0, 0.04, -0.08)
	_label.rotation.x = -PI * 0.3
	_label.visible = false
	add_child(_label)


func _find(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find(child, node_name)
		if found:
			return found
	return null
