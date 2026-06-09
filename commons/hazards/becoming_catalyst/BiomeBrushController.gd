# BiomeBrushController.gd — biome paint logic for the catalyst's biome_brush stone
#
# The desktop scrubber's brush, driven by a VR controller. The catalyst feeds it
# the controller pose each frame (update); this owns the per-element density
# field, the ground ghost, the live repaint, and the save payload. Mirrors how
# voxel mode delegates to VoxelEditController. See doc/VR_EDITING_SYSTEM.md and
# doc/PAINT_LAYERS.md.

class_name BiomeBrushController
extends Node3D

const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")
const BiomeElementsLib = preload("res://commons/biome_layers/biome_elements.gd")
const ELEMENTS: Array = BiomeElementsLib.NAMES   # single source of truth (BiomeElements)

var grid_w: int = 10
var grid_d: int = 10
var cube: float = 1.0

var _grid: Node = null               # GridSystem (repaint_biome)
var _data: Node = null               # GridDataComponent (existing paint_layers)
var _elem_idx: int = 0
var _radius: int = 2
var _strength: float = 0.6
var _height: float = 1.5             # painted ground/biome rise (BIOME tab HEIGHT slider; was hardcoded 1.5)
var _density: float = 1.0            # scatter density for every painted layer (BIOME tab DEFINE slider; was 1.0)
var _fields: Dictionary = {}         # element -> PackedFloat32Array (grid_w*grid_d)
var _element_artifacts: Dictionary = {}  # element -> Array[name] (the VR picker's lists)
var _stroking: bool = false
var _preview_tick: int = 0

var _ghost: MeshInstance3D = null
var _ghost_mat: StandardMaterial3D = null


## Find GridSystem + GridDataComponent and size to the current map's grid.
func setup() -> void:
	_grid = _find(get_tree().root, "GridSystem")
	_data = _find(get_tree().root, "GridDataComponent")
	if _data and _data.has_method("get_grid_dimensions"):
		var d: Vector3i = _data.get_grid_dimensions()
		grid_w = maxi(1, d.x)
		grid_d = maxi(1, d.z)
	if _grid and "cube_size" in _grid:
		cube = _grid.cube_size
	_build_ghost()


func active_element() -> String:
	return ELEMENTS[_elem_idx]


func cycle_element() -> void:
	_elem_idx = (_elem_idx + 1) % ELEMENTS.size()
	_recolour_ghost()


## Set the active element by name (from the left-hand menu). No-op if unknown.
func set_element(element_name: String) -> void:
	var idx: int = ELEMENTS.find(element_name)
	if idx >= 0:
		_elem_idx = idx
		_recolour_ghost()


## Toggle an artifact in the ACTIVE element's list (from the menu's picker). The
## element's painted layer then carries `artifacts: [...]` so object_scatter places
## those instead of the default morphology. Returns the updated list.
func toggle_artifact(artifact_name: String) -> Array:
	var el: String = active_element()
	var lst: Array = _element_artifacts.get(el, [])
	if artifact_name in lst:
		lst.erase(artifact_name)
	else:
		lst.append(artifact_name)
	_element_artifacts[el] = lst
	return lst


## The active element's artifact list (for the menu to mark selected entries).
func active_artifacts() -> Array:
	return _element_artifacts.get(active_element(), [])


## Set the brush radius in cells (from the menu's size slider).
func set_radius(r: int) -> void:
	_radius = clampi(r, 0, 8)


## Set the brush pressure / strength (from the menu's pressure slider).
func set_strength(s: float) -> void:
	_strength = clampf(s, 0.1, 1.0)


## Set the painted ground/biome rise (from the menu's HEIGHT slider).
func set_height(h: float) -> void:
	_height = clampf(h, 0.5, 4.0)


## Set the scatter density applied to every painted layer (from the menu's DEFINE slider).
func set_density(d: float) -> void:
	_density = clampf(d, 0.1, 1.0)


func has_strokes() -> bool:
	return not _fields.is_empty()


func set_idle() -> void:
	if _ghost:
		_ghost.visible = false


## Called every frame by the catalyst while in biome_brush mode. `paint`/`erase`
## are the trigger/grip held states. Stamps continuously while held; on release,
## rebuilds the biome live with the painted field.
func update(origin: Vector3, forward: Vector3, paint: bool, erase: bool) -> void:
	var cell := _ray_cell(origin, forward)
	if cell.x < 0:
		if _ghost:
			_ghost.visible = false
		if _stroking:
			_stroking = false
			_commit()
		return
	if _ghost:
		_ghost.visible = true
		_ghost.global_position = Vector3((float(cell.x) + 0.5) * cube, 0.05, (float(cell.y) + 0.5) * cube)
	if paint or erase:
		_stamp(cell.x, cell.y, erase)
		_stroking = true
		_live_ground_preview()
	elif _stroking:
		_stroking = false
		_commit()


## Brush fields (mode:"brush") + the map's other (non-painted) layers — the
## payload for both live repaint and the B-save POST.
func paint_layers_payload() -> Array:
	var out: Array = []
	var painted: Dictionary = {}
	for el in _fields:
		painted[el] = true
		var layer := {"element": el, "mode": "brush", "density": _density, "brush": _brush_payload(_fields[el])}
		if el == "ground":
			layer["height"] = _height   # painted bumps rise to the HEIGHT slider value
		elif el == "shader":
			var c := _elem_colour(el)
			layer["color"] = [c.r, c.g, c.b]   # the colour painted into the ground texture
		var arts: Array = _element_artifacts.get(el, [])
		if not arts.is_empty():
			layer["artifacts"] = arts.duplicate()   # object_scatter places these here
		out.append(layer)
	# Elements with a picked artifact list but no brush stroke → scatter them by a
	# default distribution so picking alone populates the field (matches desktop).
	for el in _element_artifacts:
		if painted.has(el) or (_element_artifacts[el] as Array).is_empty():
			continue
		painted[el] = true
		out.append({"element": el, "mode": "random", "density": _strength,
			"artifacts": (_element_artifacts[el] as Array).duplicate()})
	if _data and _data.has_method("get_paint_layers"):
		for layer in _data.get_paint_layers():
			if layer is Dictionary and not painted.has(str(layer.get("element", ""))):
				out.append(layer)
	return out


# ── internals ─────────────────────────────────────────────────────────
func _commit() -> void:
	if _grid and _grid.has_method("repaint_biome"):
		_grid.repaint_biome(paint_layers_payload())


## While painting "ground", rebuild just the ground mesh live (throttled) so the
## terrain rises under the brush — the full rebuild (collider) lands on release.
func _live_ground_preview() -> void:
	if ELEMENTS[_elem_idx] != "ground":
		return
	_preview_tick += 1
	if _preview_tick % 3 != 0:
		return
	if _grid and _grid.has_method("preview_ground") and _fields.has("ground"):
		# Use the HEIGHT slider (_height), not a hardcoded 1.5, so the live terrain rises
		# to the same height the committed ground will — taller at HEIGHT=4 than 0.5.
		_grid.preview_ground(_fields["ground"], grid_w, grid_d, _height)


func _ray_cell(origin: Vector3, forward: Vector3) -> Vector2i:
	if absf(forward.y) < 1e-5:
		return Vector2i(-1, -1)
	var t: float = -origin.y / forward.y
	if t < 0.0:
		return Vector2i(-1, -1)
	var hit: Vector3 = origin + forward * t
	var cx: int = int(floor(hit.x / cube))
	var cz: int = int(floor(hit.z / cube))
	if cx < 0 or cx >= grid_w or cz < 0 or cz >= grid_d:
		return Vector2i(-1, -1)
	return Vector2i(cx, cz)


func _stamp(cx: int, cz: int, erase: bool) -> void:
	var el: String = ELEMENTS[_elem_idx]
	if not _fields.has(el):
		var nf := PackedFloat32Array()
		nf.resize(grid_w * grid_d)
		_fields[el] = nf
	var field: PackedFloat32Array = _fields[el]
	for dz in range(-_radius, _radius + 1):
		for dx in range(-_radius, _radius + 1):
			var x: int = cx + dx
			var z: int = cz + dz
			if x < 0 or x >= grid_w or z < 0 or z >= grid_d:
				continue
			var dist: float = sqrt(float(dx * dx + dz * dz))
			if dist > float(_radius) + 0.001:
				continue
			var fall: float = 1.0 - dist / (float(_radius) + 0.0001)
			var i: int = z * grid_w + x
			if erase:
				field[i] = maxf(0.0, field[i] - _strength * fall)
			else:
				field[i] = minf(1.0, field[i] + _strength * fall)


## Brush field → compact sparse {w,d,cells} form for the saved/payload layer
## (only painted cells, not a dense grid of zeros). Distribution._read_brush decodes.
func _brush_payload(field: PackedFloat32Array) -> Dictionary:
	return DistributionField.field_to_sparse(field, grid_w, grid_d)


func _elem_colour(el: String) -> Color:
	return BiomeElementsLib.ui_color(el)


func _build_ghost() -> void:
	if _ghost:
		return
	_ghost = MeshInstance3D.new()
	_ghost.name = "BiomeBrushGhost"
	_ghost.top_level = true
	var disc := CylinderMesh.new()
	disc.top_radius = 0.30
	disc.bottom_radius = 0.30
	disc.height = 0.02
	_ghost.mesh = disc
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost.material_override = _ghost_mat
	add_child(_ghost)
	_recolour_ghost()
	_ghost.visible = false


func _recolour_ghost() -> void:
	if _ghost_mat:
		var c := _elem_colour(ELEMENTS[_elem_idx])
		_ghost_mat.albedo_color = Color(c.r, c.g, c.b, 0.55)


func _find(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find(child, node_name)
		if found:
			return found
	return null
