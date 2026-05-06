extends Node3D
class_name GlitchBody

## Mesh that refuses stable form — procedural sphere-like shape rebuilt every frame
## with time-varying vertex perturbation. HSV hue cycling colors. A body in continuous
## becoming, resisting fixed categorization. The queer theory artifact.

# --- Configuration ---

@export var body_radius: float = 0.25
@export var lat_segments: int = 20
@export var lon_segments: int = 24
@export var noise_amplitude: float = 0.08
@export var noise_speed: float = 1.5
@export var hue_cycle_speed: float = 0.12
@export var deformation_layers: int = 4

# --- Internal ---

var _time: float = 0.0
var _mesh_instance: MeshInstance3D
var _mesh_mat: StandardMaterial3D
var _title_label: Label3D
var _info_label: Label3D

# Base sphere vertices (unit sphere, computed once)
var _base_verts: PackedVector3Array
var _base_normals: PackedVector3Array
var _tri_indices: PackedInt32Array
var _vert_count: int = 0
var _tri_count: int = 0


func _ready() -> void:
	_compute_base_sphere()
	_create_mesh()
	_create_labels()
	_build_surface()


# --- Base sphere geometry (compute once, deform each frame) ---

func _compute_base_sphere() -> void:
	_base_verts = PackedVector3Array()
	_base_normals = PackedVector3Array()
	_tri_indices = PackedInt32Array()

	# Generate vertices on a unit sphere via spherical coordinates
	for lat in range(lat_segments + 1):
		var theta: float = PI * float(lat) / float(lat_segments)
		var sin_t: float = sin(theta)
		var cos_t: float = cos(theta)

		for lon in range(lon_segments + 1):
			var phi: float = TAU * float(lon) / float(lon_segments)
			var nx: float = sin_t * cos(phi)
			var ny: float = cos_t
			var nz: float = sin_t * sin(phi)

			_base_verts.append(Vector3(nx, ny, nz))
			_base_normals.append(Vector3(nx, ny, nz))

	_vert_count = _base_verts.size()

	# Generate triangle indices
	for lat in range(lat_segments):
		for lon in range(lon_segments):
			var a: int = lat * (lon_segments + 1) + lon
			var b: int = a + 1
			var c: int = a + (lon_segments + 1)
			var d: int = c + 1

			# Two triangles per quad
			_tri_indices.append(a)
			_tri_indices.append(c)
			_tri_indices.append(b)

			_tri_indices.append(b)
			_tri_indices.append(c)
			_tri_indices.append(d)

	_tri_count = _tri_indices.size() / 3


# --- Mesh display ---

func _create_mesh() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "GlitchSurface"
	add_child(_mesh_instance)

	_mesh_mat = StandardMaterial3D.new()
	_mesh_mat.vertex_color_use_as_albedo = true
	_mesh_mat.emission_enabled = true
	_mesh_mat.emission_energy_multiplier = 0.4
	_mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_instance.material_override = _mesh_mat


func _build_surface() -> void:
	var im: ImmediateMesh = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var base_hue: float = fmod(_time * hue_cycle_speed, 1.0)

	for tri in range(_tri_count):
		var i0: int = _tri_indices[tri * 3]
		var i1: int = _tri_indices[tri * 3 + 1]
		var i2: int = _tri_indices[tri * 3 + 2]

		var v0: Vector3 = _deform_vertex(i0)
		var v1: Vector3 = _deform_vertex(i1)
		var v2: Vector3 = _deform_vertex(i2)

		var c0: Color = _vertex_color(i0, base_hue)
		var c1: Color = _vertex_color(i1, base_hue)
		var c2: Color = _vertex_color(i2, base_hue)

		im.surface_set_color(c0)
		im.surface_add_vertex(v0)
		im.surface_set_color(c1)
		im.surface_add_vertex(v1)
		im.surface_set_color(c2)
		im.surface_add_vertex(v2)

	im.surface_end()
	_mesh_instance.mesh = im


func _deform_vertex(idx: int) -> Vector3:
	var base: Vector3 = _base_verts[idx]
	var normal: Vector3 = _base_normals[idx]

	# Layer multiple noise frequencies for complex, organic deformation
	var displacement: float = 0.0
	var amp: float = 1.0
	var freq: float = 1.0
	var t: float = _time * noise_speed

	for layer in range(deformation_layers):
		# Use sin-based noise with different spatial/temporal frequencies
		# Each layer uses a different combination of the vertex normal components
		var phase_x: float = base.x * freq * 3.7 + t * (1.0 + layer * 0.3) + layer * 1.37
		var phase_y: float = base.y * freq * 4.1 + t * (0.8 + layer * 0.2) + layer * 2.51
		var phase_z: float = base.z * freq * 3.3 + t * (1.2 + layer * 0.4) + layer * 0.89

		# Cross-coupled noise — each axis feeds back into others
		var nx: float = sin(phase_x + cos(phase_y * 0.7))
		var ny: float = sin(phase_y + cos(phase_z * 0.8))
		var nz: float = sin(phase_z + cos(phase_x * 0.6))

		displacement += (nx + ny + nz) / 3.0 * amp

		amp *= 0.45
		freq *= 2.1

	# Occasional sharp glitch — abrupt deformation spikes
	var glitch_phase: float = sin(_time * 2.3 + base.x * 7.0) * sin(_time * 1.7 + base.z * 5.0)
	if glitch_phase > 0.85:
		displacement += (glitch_phase - 0.85) * 4.0

	# Breathing — slow radial pulsation
	var breath: float = sin(_time * 0.6) * 0.15 + sin(_time * 0.23) * 0.08

	var radius: float = body_radius + displacement * noise_amplitude + breath * noise_amplitude
	# Clamp to prevent collapse or explosion
	radius = clampf(radius, body_radius * 0.3, body_radius * 2.0)

	return normal * radius


func _vertex_color(idx: int, base_hue: float) -> Color:
	var base: Vector3 = _base_verts[idx]

	# Hue varies by vertex position and time — each vertex has its own color journey
	var hue_offset: float = base.x * 0.15 + base.y * 0.2 + base.z * 0.1
	var hue_wave: float = sin(_time * 0.9 + base.y * 3.0) * 0.15
	var hue: float = fmod(base_hue + hue_offset + hue_wave + 1.0, 1.0)

	# Saturation dips where deformation is extreme — whiteout on glitch peaks
	var glitch_factor: float = absf(sin(_time * 2.3 + base.x * 7.0) * sin(_time * 1.7 + base.z * 5.0))
	var saturation: float = lerpf(0.6, 0.15, clampf(glitch_factor - 0.7, 0.0, 0.3) / 0.3)

	# Value modulated by position — darker at base, lighter at tips
	var value: float = lerpf(0.55, 0.95, (base.y + 1.0) * 0.5)
	value += sin(_time * 1.3 + base.x * 4.0) * 0.1

	return Color.from_hsv(hue, saturation, clampf(value, 0.3, 1.0))


# --- Labels ---

func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "GLITCH BODY"
	_title_label.font_size = 24
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, body_radius + 0.12, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.92, 0.92, 0.97)
	_title_label.outline_size = 4
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(_title_label)

	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.font_size = 12
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, body_radius + 0.06, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.7, 0.75, 0.85, 0.9)
	_info_label.outline_size = 2
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_info_label.text = "continuous becoming · %d×%d mesh · %d noise layers" % [
		lat_segments, lon_segments, deformation_layers
	]
	add_child(_info_label)


# --- Per-frame update ---

func _process(delta: float) -> void:
	_time += delta
	_build_surface()


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("noise_amplitude"):
		noise_amplitude = float(config_data["noise_amplitude"])
	if config_data.has("noise_speed"):
		noise_speed = float(config_data["noise_speed"])
	if config_data.has("hue_cycle_speed"):
		hue_cycle_speed = float(config_data["hue_cycle_speed"])
	if config_data.has("body_radius"):
		body_radius = float(config_data["body_radius"])
	if config_data.has("deformation_layers"):
		deformation_layers = clampi(int(config_data["deformation_layers"]), 1, 6)
