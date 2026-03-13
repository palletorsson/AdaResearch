## CoveDisplay — Cyclorama/infinity cove surface for any shader
##
## A reusable display form: flat floor → smooth curved cove → vertical back wall.
## Like a photo studio backdrop. The curve eliminates the hard edge so any shader
## tiles seamlessly across the whole surface.
##
## This is a GENERIC form — it accepts any shader via apply_grid_config():
##   "cove_display#shader:wallpaper_tile#tile_scale:6#wallpaper_group:5"
##   "cove_display#shader:tartanshader#pattern_scale:4"
##   "cove_display#shader:my_custom_shader#my_param:0.5"
##
## The shader path resolves from commons/resourses/shaders/<name>.gdshader
## Any extra config keys become shader parameters via set_shader_parameter().
##
## Grid system artifact — placed by GridInteractablesComponent.
## Uses SurfaceTool for full UV control. UV.x: 0..1 across width.
## UV.y: continuous from floor front edge through curve to wall top.
extends Node3D
class_name CoveDisplay

## Width of the display (X axis) in meters
@export var cove_width: float = 2.0
## Depth of the floor section (Z axis) in meters
@export var floor_depth: float = 1.5
## Height of the back wall (Y axis) in meters
@export var wall_height: float = 2.0
## Radius of the curved cove transition in meters
@export var cove_radius: float = 0.4
## Number of segments in the curve (more = smoother)
@export var curve_segments: int = 12

# Shader configuration
var _shader_path: String = ""
var _shader_params: Dictionary = {}
var _mesh_instance: MeshInstance3D
var _material: Material

# Known geometry keys — everything else is a shader parameter
const GEOMETRY_KEYS: Array = [
	"cove_width", "floor_depth", "wall_height", "cove_radius",
	"curve_segments", "shader", "color", "albedo_color"
]

func _ready() -> void:
	if not _mesh_instance:
		_build()

## Build (or rebuild) the cove mesh and apply material
func _build() -> void:
	if _mesh_instance:
		_mesh_instance.queue_free()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _build_cove_mesh()
	add_child(_mesh_instance)

	# Apply material if configured
	if _material:
		_mesh_instance.material_override = _material

## Apply a ShaderMaterial to the cove surface
func apply_shader_material(mat: ShaderMaterial) -> void:
	_material = mat
	if _mesh_instance:
		_mesh_instance.material_override = mat

## Apply a StandardMaterial3D to the cove surface
func apply_standard_material(mat: StandardMaterial3D) -> void:
	_material = mat
	if _mesh_instance:
		_mesh_instance.material_override = mat

func get_mesh_instance() -> MeshInstance3D:
	return _mesh_instance

# ═══════════════════════════════════════════════════════════════════
# GRID SYSTEM INTEGRATION
# ═══════════════════════════════════════════════════════════════════
#
# Called by GridInteractablesComponent when placed on a map.
# Config syntax in map_data.json interactables layer:
#
#   "cove_display#shader:wallpaper_tile#tile_scale:6#wallpaper_group:10"
#
# Geometry keys (cove_width, floor_depth, etc.) configure the mesh.
# "shader" key loads a .gdshader from commons/resourses/shaders/.
# All other keys become shader parameters via set_shader_parameter().
#
# If no shader is specified, applies a plain white StandardMaterial3D.

func apply_grid_config(config_data: Dictionary) -> void:
	# ── 1. Geometry parameters ──
	if config_data.has("cove_width"):
		cove_width = clampf(float(config_data["cove_width"]), 0.5, 10.0)
	if config_data.has("floor_depth"):
		floor_depth = clampf(float(config_data["floor_depth"]), 0.5, 10.0)
	if config_data.has("wall_height"):
		wall_height = clampf(float(config_data["wall_height"]), 0.5, 10.0)
	if config_data.has("cove_radius"):
		cove_radius = clampf(float(config_data["cove_radius"]), 0.1, 2.0)
	if config_data.has("curve_segments"):
		curve_segments = clampi(int(config_data["curve_segments"]), 4, 32)

	# ── 2. Rebuild mesh with new geometry ──
	_build()

	# ── 3. Shader or plain material ──
	if config_data.has("shader"):
		_shader_path = str(config_data["shader"])
		var full_path: String = "res://commons/resourses/shaders/%s.gdshader" % _shader_path
		var shader := load(full_path) as Shader
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader

			# ── 4. All non-geometry keys become shader parameters ──
			for key: String in config_data:
				if key in GEOMETRY_KEYS:
					continue
				var s: String = str(config_data[key])
				_set_shader_param(mat, key, s)

			_material = mat
			_mesh_instance.material_override = mat
			print("[CoveDisplay] Applied shader: %s with %d params" % [_shader_path, config_data.size() - GEOMETRY_KEYS.size()])
		else:
			push_warning("[CoveDisplay] Could not load shader: %s" % full_path)
			_apply_fallback_material(config_data)
	elif config_data.has("color") or config_data.has("albedo_color"):
		_apply_fallback_material(config_data)
	else:
		# No shader specified — plain white surface
		_apply_fallback_material(config_data)

func _apply_fallback_material(config_data: Dictionary) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	if config_data.has("color"):
		mat.albedo_color = Color.from_string(str(config_data["color"]), Color.WHITE)
	if config_data.has("albedo_color"):
		mat.albedo_color = Color.from_string(str(config_data["albedo_color"]), Color.WHITE)
	mat.roughness = 0.85
	_material = mat
	if _mesh_instance:
		_mesh_instance.material_override = mat

## Parse a string value and set it as a shader parameter with correct type.
func _set_shader_param(mat: ShaderMaterial, key: String, s: String) -> void:
	# Try float first
	if s.is_valid_float():
		mat.set_shader_parameter(key, s.to_float())
		return
	# Try int
	if s.is_valid_int():
		mat.set_shader_parameter(key, s.to_int())
		return
	# Try Vector3 "x,y,z" (for grout_color etc.)
	var parts: PackedStringArray = s.split(",")
	if parts.size() == 3 and parts[0].strip_edges().is_valid_float():
		mat.set_shader_parameter(key, Vector3(
			parts[0].strip_edges().to_float(),
			parts[1].strip_edges().to_float(),
			parts[2].strip_edges().to_float()
		))
		return
	# Fallback: pass as string
	mat.set_shader_parameter(key, s)

# ═══════════════════════════════════════════════════════════════════
# MESH CONSTRUCTION via SurfaceTool
# ═══════════════════════════════════════════════════════════════════
#
# The cove has 3 zones stitched into one continuous mesh:
#
#   WALL (vertical)     ← UV.y goes from curve_end to top
#       |
#       ) CURVE          ← UV.y goes through the cove radius
#       |
#   FLOOR (horizontal)  ← UV.y goes from 0 to floor_depth
#
# UV.x spans 0..1 across the width. UV.y is continuous from
# floor front edge through curve to wall top — so any shader
# tiles seamlessly across the whole surface.

func _build_cove_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w: float = cove_width * 0.5

	# Total UV.y length for proportional mapping
	var curve_arc_len: float = cove_radius * PI * 0.5  # Quarter circle
	var total_v: float = floor_depth + curve_arc_len + wall_height

	var points: Array = []  # Array of {pos: Vector3, uv_v: float, normal: Vector3}

	# ── FLOOR STRIP: z goes from +floor_depth to 0 (front to back) ──
	var floor_steps := 4
	for i in range(floor_steps + 1):
		var t: float = float(i) / float(floor_steps)
		var z: float = floor_depth * (1.0 - t)
		var uv_v: float = floor_depth * t
		points.append({
			"pos": Vector3(0, 0, z),
			"uv_v": uv_v,
			"normal": Vector3(0, 1, 0)
		})

	# ── CURVE STRIP: quarter circle from floor to wall ──
	for i in range(1, curve_segments + 1):
		var t: float = float(i) / float(curve_segments)
		var angle: float = (PI * 0.5) * t
		var pos_z: float = cove_radius * cos(angle)
		var pos_y: float = cove_radius - cove_radius * sin(angle)
		var ny: float = -sin(angle)
		var nz: float = cos(angle)

		var uv_v: float = floor_depth + curve_arc_len * t
		points.append({
			"pos": Vector3(0, pos_y, pos_z),
			"uv_v": uv_v,
			"normal": Vector3(0, -ny, nz).normalized()
		})

	# ── WALL STRIP: y goes from cove_radius up to cove_radius + wall_height ──
	var wall_steps := 4
	for i in range(1, wall_steps + 1):
		var t: float = float(i) / float(wall_steps)
		var y: float = cove_radius + wall_height * t
		var uv_v: float = floor_depth + curve_arc_len + wall_height * t
		points.append({
			"pos": Vector3(0, y, 0),
			"uv_v": uv_v,
			"normal": Vector3(0, 0, 1)
		})

	# ── BUILD TRIANGLES: 2 columns (left, right) × N rows ──
	for i in range(points.size() - 1):
		var p0: Dictionary = points[i]
		var p1: Dictionary = points[i + 1]

		var bl := Vector3(-half_w, p0["pos"].y, p0["pos"].z)
		var br := Vector3(half_w, p0["pos"].y, p0["pos"].z)
		var tl := Vector3(-half_w, p1["pos"].y, p1["pos"].z)
		var tr := Vector3(half_w, p1["pos"].y, p1["pos"].z)

		var uv_v0: float = p0["uv_v"] / total_v
		var uv_v1: float = p1["uv_v"] / total_v
		var n0: Vector3 = p0["normal"]
		var n1: Vector3 = p1["normal"]

		# Triangle 1: bl, tl, br
		st.set_normal(n0); st.set_uv(Vector2(0, uv_v0)); st.add_vertex(bl)
		st.set_normal(n1); st.set_uv(Vector2(0, uv_v1)); st.add_vertex(tl)
		st.set_normal(n0); st.set_uv(Vector2(1, uv_v0)); st.add_vertex(br)

		# Triangle 2: br, tl, tr
		st.set_normal(n0); st.set_uv(Vector2(1, uv_v0)); st.add_vertex(br)
		st.set_normal(n1); st.set_uv(Vector2(0, uv_v1)); st.add_vertex(tl)
		st.set_normal(n1); st.set_uv(Vector2(1, uv_v1)); st.add_vertex(tr)

	st.generate_tangents()
	return st.commit()
