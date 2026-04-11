@tool
extends Node3D
class_name WallCove
## Half-cove slope artifact — curved floor-to-wall transition.
##
## Sits at the base of a wall, curving from the floor plane up into the
## vertical wall surface. Built with SurfaceTool for clean continuous UVs
## so wallpaper_tile (or any spatial shader) tiles seamlessly across the
## curved surface.
##
## Grid config keys:
##   cove_width     – width along the wall (default 1.0 = one grid cell)
##   cove_radius    – radius of the quarter-circle curve (default 0.3)
##   curve_segments – number of segments in the curve (default 24, high-res)
##   wall_extend    – how far up the wall the mesh continues above the curve (default 0.0)
##   shader         – name of .gdshader in commons/resourses/shaders/
##   pattern_seed   – seed for procedural domain texture generation
##   Any other key  → set_shader_parameter()

@export var cove_width: float = 1.0
@export var cove_radius: float = 0.3
@export var curve_segments: int = 24
@export var wall_extend: float = 0.0

var _mesh_instance: MeshInstance3D
var _material: Material
var _shader_path: String = ""

const GEOMETRY_KEYS: Array = [
	"cove_width", "cove_radius", "curve_segments", "wall_extend",
	"shader", "color", "albedo_color", "pattern_seed"
]

# Neon palettes for procedural domain generation
const PALETTES: Array = [
	[Color(0.05, 0.05, 0.07), Color(0.0, 0.95, 0.3), Color(1.0, 0.0, 0.6), Color(0.0, 0.5, 1.0), Color(1.0, 1.0, 0.0)],
	[Color(0.0, 0.0, 0.0), Color(0.95, 0.15, 0.15), Color(1.0, 0.55, 0.0), Color(1.0, 0.85, 0.0), Color(0.6, 0.0, 0.3)],
	[Color(0.9, 0.9, 0.92), Color(0.0, 0.2, 0.8), Color(0.0, 0.7, 0.85), Color(0.5, 0.0, 0.8), Color(0.95, 0.0, 0.5)],
	[Color(0.0, 0.0, 0.0), Color(0.0, 0.9, 0.2), Color(0.3, 1.0, 0.0), Color(0.0, 0.4, 0.15), Color(1.0, 0.0, 1.0)],
	[Color(1.0, 1.0, 1.0), Color(1.0, 0.0, 0.5), Color(0.0, 0.8, 1.0), Color(1.0, 0.7, 0.0), Color(0.5, 0.0, 1.0)],
	[Color(0.06, 0.0, 0.12), Color(1.0, 0.3, 0.7), Color(0.3, 0.8, 1.0), Color(0.6, 0.2, 0.9), Color(0.0, 1.0, 0.7)],
	[Color(0.95, 0.92, 0.85), Color(0.9, 0.15, 0.1), Color(0.0, 0.25, 0.6), Color(1.0, 0.8, 0.0), Color(0.1, 0.1, 0.1)],
	[Color(0.05, 0.0, 0.1), Color(1.0, 0.0, 0.4), Color(0.0, 0.9, 1.0), Color(0.9, 0.0, 0.9), Color(0.0, 0.3, 0.6)],
]

func _ready() -> void:
	if not _mesh_instance:
		_build()

func _build() -> void:
	if _mesh_instance:
		_mesh_instance.queue_free()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _build_cove_mesh()
	add_child(_mesh_instance)
	if _material:
		_mesh_instance.material_override = _material

# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	# ── 1. Geometry ──
	if config_data.has("cove_width"):
		cove_width = clampf(float(config_data["cove_width"]), 0.1, 10.0)
	if config_data.has("cove_radius"):
		cove_radius = clampf(float(config_data["cove_radius"]), 0.05, 1.0)
	if config_data.has("curve_segments"):
		curve_segments = clampi(int(config_data["curve_segments"]), 8, 64)
	if config_data.has("wall_extend"):
		wall_extend = clampf(float(config_data["wall_extend"]), 0.0, 5.0)

	# ── 2. Rebuild mesh ──
	_build()

	# ── 3. Shader or plain material ──
	if config_data.has("shader"):
		_shader_path = str(config_data["shader"])
		var full_path: String = "res://commons/resourses/shaders/%s.gdshader" % _shader_path
		var shader := load(full_path) as Shader
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader

			# Generate domain texture for wallpaper_tile
			if _shader_path == "wallpaper_tile":
				var seed_val: int = 0
				if config_data.has("pattern_seed"):
					seed_val = int(config_data["pattern_seed"])
				else:
					seed_val = hash(str(global_position))
				var dtex: ImageTexture = _generate_domain_texture(seed_val)
				mat.set_shader_parameter("domain_texture", dtex)

			# All non-geometry keys → shader parameters
			for key: String in config_data:
				if key in GEOMETRY_KEYS:
					continue
				_set_shader_param(mat, key, str(config_data[key]))

			_material = mat
			_mesh_instance.material_override = mat

			# Add light so spatial shader is visible
			_add_display_light()
			print("[WallCove] Applied shader: %s" % _shader_path)
		else:
			push_warning("[WallCove] Could not load shader: %s" % full_path)
			_apply_fallback(config_data)
	elif config_data.has("color") or config_data.has("albedo_color"):
		_apply_fallback(config_data)
	else:
		_apply_fallback(config_data)

func _apply_fallback(config_data: Dictionary) -> void:
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

func _set_shader_param(mat: ShaderMaterial, key: String, s: String) -> void:
	# Int first (shader int uniforms need int, not float)
	if s.is_valid_int():
		mat.set_shader_parameter(key, s.to_int())
		return
	if s.is_valid_float():
		mat.set_shader_parameter(key, s.to_float())
		return
	# Try comma-separated as Vector3
	var parts: PackedStringArray = s.split(",")
	if parts.size() == 3 and parts[0].strip_edges().is_valid_float():
		mat.set_shader_parameter(key, Vector3(
			parts[0].strip_edges().to_float(),
			parts[1].strip_edges().to_float(),
			parts[2].strip_edges().to_float()))
		return
	# Boolean
	if s.to_lower() == "true":
		mat.set_shader_parameter(key, true)
		return
	if s.to_lower() == "false":
		mat.set_shader_parameter(key, false)
		return
	# String fallback
	mat.set_shader_parameter(key, s)

func _add_display_light() -> void:
	var light := SpotLight3D.new()
	light.position = Vector3(0, cove_radius + wall_extend + 0.5, cove_radius * 0.6)
	light.rotation_degrees.x = -60
	light.light_energy = 4.0
	light.light_color = Color(0.98, 0.96, 0.92)
	light.spot_range = cove_width * 1.5
	light.spot_angle = 50.0
	light.shadow_enabled = false
	add_child(light)

# ═══════════════════════════════════════════════════════════════════
# MESH — half-cove: floor strip → high-res quarter-circle curve → optional wall strip
#
# UV.x = 0..1 across width
# UV.y = continuous from floor front through curve to wall top
# ═══════════════════════════════════════════════════════════════════

func _build_cove_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w: float = cove_width * 0.5

	# Arc length of quarter circle
	var arc_len: float = cove_radius * PI * 0.5
	# Small floor lip (10cm) so the cove blends into the grid floor
	var floor_lip: float = 0.1
	var total_v: float = floor_lip + arc_len + wall_extend

	var points: Array = []  # {pos: Vector3, uv_v: float, normal: Vector3}

	# ── FLOOR LIP: small strip on the floor before the curve starts ──
	var lip_steps: int = 2
	for i in range(lip_steps + 1):
		var t: float = float(i) / float(lip_steps)
		var z: float = floor_lip * (1.0 - t)  # z goes from +lip to 0
		points.append({
			"pos": Vector3(0, 0, z),
			"uv_v": floor_lip * t,
			"normal": Vector3(0, 1, 0)
		})

	# ── CURVE: quarter circle, high resolution ──
	for i in range(1, curve_segments + 1):
		var t: float = float(i) / float(curve_segments)
		var angle: float = (PI * 0.5) * t
		var pz: float = cove_radius * cos(angle)
		var py: float = cove_radius - cove_radius * sin(angle)
		# Normal points outward from curve center
		var ny: float = sin(angle)
		var nz: float = cos(angle)

		points.append({
			"pos": Vector3(0, py, pz),
			"uv_v": floor_lip + arc_len * t,
			"normal": Vector3(0, ny, nz).normalized()
		})

	# ── WALL EXTENSION: vertical strip above the curve ──
	if wall_extend > 0.01:
		var wall_steps: int = maxi(2, int(wall_extend * 4))
		for i in range(1, wall_steps + 1):
			var t: float = float(i) / float(wall_steps)
			var y: float = cove_radius + wall_extend * t
			points.append({
				"pos": Vector3(0, y, 0),
				"uv_v": floor_lip + arc_len + wall_extend * t,
				"normal": Vector3(0, 0, 1)
			})

	# ── BUILD TRIANGLES ──
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

		# Triangle 1: bl → tl → br
		st.set_normal(n0); st.set_uv(Vector2(0, uv_v0)); st.add_vertex(bl)
		st.set_normal(n1); st.set_uv(Vector2(0, uv_v1)); st.add_vertex(tl)
		st.set_normal(n0); st.set_uv(Vector2(1, uv_v0)); st.add_vertex(br)

		# Triangle 2: br → tl → tr
		st.set_normal(n0); st.set_uv(Vector2(1, uv_v0)); st.add_vertex(br)
		st.set_normal(n1); st.set_uv(Vector2(0, uv_v1)); st.add_vertex(tl)
		st.set_normal(n1); st.set_uv(Vector2(1, uv_v1)); st.add_vertex(tr)

	st.generate_tangents()
	return st.commit()

# ═══════════════════════════════════════════════════════════════════
# PROCEDURAL DOMAIN TEXTURE
# ═══════════════════════════════════════════════════════════════════

func _generate_domain_texture(seed_val: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 7919 + 31
	var palette: Array = PALETTES[absi(seed_val) % PALETTES.size()]
	var grid: Array = _make_domain_pattern(rng, absi(seed_val) % 6)

	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			var idx: int = grid[y][x]
			var c: Color = palette[idx] if idx < palette.size() else Color.WHITE
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

func _make_domain_pattern(rng: RandomNumberGenerator, pattern_type: int) -> Array:
	var g: Array = _grid8(0)
	match pattern_type:
		0:  # Blocks
			for _i in rng.randi_range(3, 5):
				var x0: int = rng.randi_range(0, 5); var y0: int = rng.randi_range(0, 5)
				var x1: int = rng.randi_range(x0 + 1, 8); var y1: int = rng.randi_range(y0 + 1, 8)
				var c: int = rng.randi_range(1, 4)
				for y in range(y0, y1):
					for x in range(x0, x1):
						g[y][x] = c
		1:  # Stripes
			var horiz: bool = rng.randf() > 0.5; var thick: int = rng.randi_range(1, 3)
			for y in 8:
				for x in 8:
					g[y][x] = ((y if horiz else x) / thick) % 5
		2:  # Diagonal
			var thick: int = rng.randi_range(1, 3)
			for y in 8:
				for x in 8:
					g[y][x] = ((x + y) / thick) % 5
		3:  # Concentric
			for y in 8:
				for x in 8:
					g[y][x] = mini(mini(x, y), mini(7 - x, 7 - y)) % 5
		4:  # Checker
			var b: int = rng.randi_range(1, 3)
			var c1: int = rng.randi_range(0, 2); var c2: int = rng.randi_range(3, 4)
			for y in 8:
				for x in 8:
					g[y][x] = c1 if ((x / b) + (y / b)) % 2 == 0 else c2
		5:  # Cross
			var arm: int = rng.randi_range(1, 3); var c: int = rng.randi_range(2, 4)
			for y in 8:
				for x in 8:
					if absi(x - 4) < arm or absi(y - 4) < arm:
						g[y][x] = c
	return g

func _grid8(fill: int) -> Array:
	var g: Array = []
	for _y in 8:
		var row: Array = []
		for _x in 8:
			row.append(fill)
		g.append(row)
	return g
