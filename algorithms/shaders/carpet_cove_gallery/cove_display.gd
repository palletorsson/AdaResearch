## CoveDisplay — A photography cyclorama/infinity cove mesh for pattern display
##
## Builds a single display unit: flat floor → smooth curved cove → vertical back wall.
## Like a miniature photo studio backdrop. The curve eliminates the hard edge between
## floor and wall so the pattern flows seamlessly.
##
## Uses SurfaceTool for full UV control — UVs map continuously from floor through
## curve to wall so the wallpaper_tile shader tiles without seams.
##
## Usage:
##   var cove := CoveDisplay.new()
##   cove.setup(2.0, 2.0, 1.5)  # width, depth(floor+wall), wall_height
##   cove.apply_shader_material(my_shader_material)
##   add_child(cove)
extends Node3D
class_name CoveDisplay

## Width of the display (X axis)
@export var cove_width: float = 2.0
## Total depth: floor depth + wall height
@export var floor_depth: float = 1.5
## Height of the back wall (Y axis)
@export var wall_height: float = 2.0
## Radius of the curved cove transition
@export var cove_radius: float = 0.4
## Number of segments in the curve (more = smoother)
@export var curve_segments: int = 12

var _mesh_instance: MeshInstance3D

func _ready() -> void:
	if not _mesh_instance:
		setup(cove_width, floor_depth, wall_height)

## Build the cove mesh with proper UVs
func setup(width: float, depth: float, height: float) -> void:
	cove_width = width
	floor_depth = depth
	wall_height = height

	if _mesh_instance:
		_mesh_instance.queue_free()

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _build_cove_mesh()
	add_child(_mesh_instance)

## Apply a ShaderMaterial to the cove surface
func apply_shader_material(mat: ShaderMaterial) -> void:
	if _mesh_instance:
		_mesh_instance.material_override = mat

## Apply a StandardMaterial3D to the cove surface
func apply_standard_material(mat: StandardMaterial3D) -> void:
	if _mesh_instance:
		_mesh_instance.material_override = mat

func get_mesh_instance() -> MeshInstance3D:
	return _mesh_instance

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
# floor front edge through curve to wall top — so the shader
# tiles seamlessly across the whole surface.

func _build_cove_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w: float = cove_width * 0.5

	# Total UV.y length for proportional mapping
	var curve_arc_len: float = cove_radius * PI * 0.5  # Quarter circle
	var total_v: float = floor_depth + curve_arc_len + wall_height

	# We build strips from front to back, each strip is 2 triangles wide.
	# X positions: just 2 columns (left edge, right edge) for a flat panel.
	# For wider coves you could add more X subdivisions.

	var points: Array = []  # Array of {pos: Vector3, uv_v: float, normal: Vector3}

	# ── FLOOR STRIP: z goes from +floor_depth to 0 (front to back) ──
	var floor_steps := 4
	for i in range(floor_steps + 1):
		var t: float = float(i) / float(floor_steps)
		var z: float = floor_depth * (1.0 - t)  # Front to cove start
		var uv_v: float = floor_depth * t
		points.append({
			"pos": Vector3(0, 0, z),
			"uv_v": uv_v,
			"normal": Vector3(0, 1, 0)
		})

	# ── CURVE STRIP: quarter circle from floor (horizontal) to wall (vertical) ──
	# Center of the curve circle is at (0, cove_radius, 0)
	# Curve goes from angle 270° (pointing down = floor) to 180° (pointing back = wall)
	for i in range(1, curve_segments + 1):
		var t: float = float(i) / float(curve_segments)
		var angle: float = (PI * 0.5) * t  # 0 to 90 degrees
		# Parametric: start horizontal, sweep to vertical
		var local_z: float = cove_radius * cos(angle)    # Goes from r to 0
		var local_y: float = cove_radius * (1.0 - sin(angle))  # Goes from 0 to r...
		# Actually: at angle=0 we're at floor level (y=0, z=radius)
		# At angle=90 we're at wall start (y=radius, z=0)
		var pos_z: float = cove_radius * cos(angle)
		var pos_y: float = cove_radius - cove_radius * sin(angle)
		# Wait, let me reconsider. The cove center is above and behind:
		# Center at y=cove_radius, z=0. At angle 0 (start): pos = center + (0, -r, 0) rotated
		# Actually simpler: sweep from pointing +Z (floor) to pointing +Y (wall)
		pos_z = cove_radius * cos(angle)
		pos_y = cove_radius * (1.0 - sin(angle))
		# Hmm, let me just be explicit:
		# At t=0: floor level, z=cove_radius, y=0 (matches last floor point)
		# At t=1: wall base, z=0, y=cove_radius
		pos_z = cove_radius * cos(angle)
		pos_y = cove_radius - cove_radius * sin(angle)
		# Normal points outward from center (y=cove_radius, z=0)
		var nx: float = 0.0
		var ny: float = -sin(angle)
		var nz: float = cos(angle)

		var uv_v: float = floor_depth + curve_arc_len * t
		points.append({
			"pos": Vector3(0, pos_y, pos_z),
			"uv_v": uv_v,
			"normal": Vector3(nx, -ny, nz).normalized()
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

		# 4 corners of this quad strip
		var bl := Vector3(-half_w, p0["pos"].y, p0["pos"].z)  # Bottom-left
		var br := Vector3(half_w, p0["pos"].y, p0["pos"].z)   # Bottom-right
		var tl := Vector3(-half_w, p1["pos"].y, p1["pos"].z)  # Top-left
		var tr := Vector3(half_w, p1["pos"].y, p1["pos"].z)   # Top-right

		var uv_v0: float = p0["uv_v"] / total_v
		var uv_v1: float = p1["uv_v"] / total_v
		var n0: Vector3 = p0["normal"]
		var n1: Vector3 = p1["normal"]

		# Triangle 1: bl, tl, br
		st.set_normal(n0)
		st.set_uv(Vector2(0, uv_v0))
		st.add_vertex(bl)

		st.set_normal(n1)
		st.set_uv(Vector2(0, uv_v1))
		st.add_vertex(tl)

		st.set_normal(n0)
		st.set_uv(Vector2(1, uv_v0))
		st.add_vertex(br)

		# Triangle 2: br, tl, tr
		st.set_normal(n0)
		st.set_uv(Vector2(1, uv_v0))
		st.add_vertex(br)

		st.set_normal(n1)
		st.set_uv(Vector2(0, uv_v1))
		st.add_vertex(tl)

		st.set_normal(n1)
		st.set_uv(Vector2(1, uv_v1))
		st.add_vertex(tr)

	st.generate_tangents()
	return st.commit()

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("cove_width"):
		cove_width = float(config_data["cove_width"])
	if config_data.has("floor_depth"):
		floor_depth = float(config_data["floor_depth"])
	if config_data.has("wall_height"):
		wall_height = float(config_data["wall_height"])
	if config_data.has("cove_radius"):
		cove_radius = float(config_data["cove_radius"])
