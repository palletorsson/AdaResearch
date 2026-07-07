# rd_artifact.gd
# Placeable wrapper around RDSim (Gray-Scott reaction-diffusion). Simulates
# the 2D field per the config and renders it as a colored heightmap mesh.
# Mirrors dna_workstation._build_rd.

extends Node3D
class_name RDArtifact

const RDSim = preload("res://commons/rd_grammar/rd_sim.gd")

@export var config_path: String = ""
@export var world_size: float = 1.0     # half-size of the heightmap mesh
@export var height_amp_override: float = -1.0  # -1 = use config value

## VR-preview cap: 96×96 × 3000 iterations ≈ 3-5s per artifact. Cap at 32×32 × 800
## ≈ 200ms. Set false to use full fidelity (only when bake-time, not at-load-time).
@export var vr_preview: bool = true

var _current: MeshInstance3D = null


func _ready() -> void:
	if config_path.strip_edges().is_empty(): return
	_build()


func apply_grid_config(cfg: Dictionary) -> void:
	if cfg.has("config_path"): config_path = str(cfg["config_path"])
	if cfg.has("world_size"):  world_size = float(cfg["world_size"])
	if cfg.has("height_amp"):  height_amp_override = float(cfg["height_amp"])
	_clear()
	_build()


func _clear() -> void:
	if _current:
		_current.queue_free()
		_current = null
	for c in get_children():
		c.queue_free()


func _build() -> void:
	if config_path.is_empty(): return
	var txt := FileAccess.get_file_as_string(config_path)
	if txt.is_empty(): return
	var j := JSON.new()
	if j.parse(txt) != OK or not (j.data is Dictionary): return
	var cfg: Dictionary = j.data

	if vr_preview:
		cfg["grid_size"] = mini(int(cfg.get("grid_size", 96)), 32)
		cfg["iterations"] = mini(int(cfg.get("iterations", 3000)), 800)

	var N: int = int(cfg.get("grid_size", 96))
	var field: PackedFloat32Array = RDSim.simulate(cfg)
	if field.size() != N * N: return
	var color_lo := _color_or(cfg.get("color_lo", null), Color(0.15, 0.2, 0.3))
	var color_hi := _color_or(cfg.get("color_hi", null), Color(0.9, 0.8, 0.5))
	var height_amp: float = (height_amp_override
		if height_amp_override > 0.0
		else float(cfg.get("height_amp", 0.4)))

	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var cell: float = world_size * 2.0 / float(max(N - 1, 1))
	for iy in N:
		for ix in N:
			var x: float = -world_size + float(ix) * cell
			var z: float = -world_size + float(iy) * cell
			var h: float = field[iy * N + ix] * height_amp
			verts.append(Vector3(x, h, z))
			var t: float = clampf(field[iy * N + ix] * 2.0, 0.0, 1.0)
			colors.append(color_lo.lerp(color_hi, t))
	for iy in N - 1:
		for ix in N - 1:
			var i0: int = iy * N + ix
			var i1: int = iy * N + ix + 1
			var i2: int = (iy + 1) * N + ix + 1
			var i3: int = (iy + 1) * N + ix
			indices.append_array([i0, i1, i2, i0, i2, i3])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.55
	mi.material_override = mat
	mi.position = Vector3(0, 0.5, 0)
	add_child(mi)
	_current = mi


func _color_or(v, fallback: Color) -> Color:
	if v is Array and (v as Array).size() >= 3:
		var a: Array = v
		return Color(float(a[0]), float(a[1]), float(a[2]),
		             float(a[3]) if a.size() >= 4 else 1.0)
	return fallback
