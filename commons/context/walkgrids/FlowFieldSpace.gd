# FlowFieldSpace.gd - Vector field potential as walkable terrain
# A 2D vector field's potential energy becomes elevation. Curl creates
# hills, divergence creates valleys. Sources push up, sinks pull down.
# Walk the landscape of forces — feel where things want to go.
#
# "The terrain IS the force. Walk uphill and you're fighting the field."

extends TopologySpace
class_name FlowFieldSpace

@export var field_type: FieldType = FieldType.VORTEX_ARRAY
@export var num_elements: int = 6         # Number of sources/vortices
@export var field_strength: float = 1.5
@export var seed_value: int = 42

enum FieldType {
	VORTEX_ARRAY,       # Spinning vortices — potential = curl integral
	SOURCE_SINK,        # Point sources and sinks — potential = log(r)
	DIPOLE_FIELD,       # Magnetic-like dipoles
	GRADIENT_NOISE,     # Curl of noise field (divergence-free)
	SADDLE_POINTS,      # Hyperbolic saddle configurations
	ELECTROMAGNETIC,    # Combined electric + magnetic analogy
}

var elements: Array[Dictionary] = []
var rng: RandomNumberGenerator

func _ready():
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	_generate_elements()
	super._ready()

func _generate_elements():
	elements.clear()
	match field_type:
		FieldType.VORTEX_ARRAY:
			for _i in range(num_elements):
				elements.append({
					"position": Vector2(
						rng.randf_range(-space_size.x * 0.35, space_size.x * 0.35),
						rng.randf_range(-space_size.y * 0.35, space_size.y * 0.35)
					),
					"strength": rng.randf_range(-1.0, 1.0) * field_strength,
					"type": "vortex"
				})
		FieldType.SOURCE_SINK:
			for i in range(num_elements):
				elements.append({
					"position": Vector2(
						rng.randf_range(-space_size.x * 0.35, space_size.x * 0.35),
						rng.randf_range(-space_size.y * 0.35, space_size.y * 0.35)
					),
					# Alternate source/sink
					"strength": (1.0 if i % 2 == 0 else -1.0) * field_strength,
					"type": "source"
				})
		FieldType.DIPOLE_FIELD:
			for _i in range(num_elements / 2):
				var center = Vector2(
					rng.randf_range(-space_size.x * 0.3, space_size.x * 0.3),
					rng.randf_range(-space_size.y * 0.3, space_size.y * 0.3)
				)
				var angle = rng.randf() * TAU
				var offset = Vector2(cos(angle), sin(angle)) * 1.5
				elements.append({
					"position": center + offset,
					"strength": field_strength,
					"type": "source"
				})
				elements.append({
					"position": center - offset,
					"strength": -field_strength,
					"type": "source"
				})
		FieldType.SADDLE_POINTS:
			for _i in range(num_elements):
				elements.append({
					"position": Vector2(
						rng.randf_range(-space_size.x * 0.35, space_size.x * 0.35),
						rng.randf_range(-space_size.y * 0.35, space_size.y * 0.35)
					),
					"strength": rng.randf_range(0.5, 1.5) * field_strength,
					"angle": rng.randf() * PI,
					"type": "saddle"
				})
		_:
			_generate_elements_default()

func _generate_elements_default():
	for _i in range(num_elements):
		elements.append({
			"position": Vector2(
				rng.randf_range(-space_size.x * 0.35, space_size.x * 0.35),
				rng.randf_range(-space_size.y * 0.35, space_size.y * 0.35)
			),
			"strength": rng.randf_range(-1.0, 1.0) * field_strength,
			"type": "source"
		})

func generate_space():
	var heights: Array = []
	var gs = resolution + 1

	for z in range(gs):
		for x in range(gs):
			var wx = (x / float(resolution)) * space_size.x - space_size.x / 2.0
			var wz = (z / float(resolution)) * space_size.y - space_size.y / 2.0
			var pos = Vector2(wx, wz)
			var h = _compute_potential(pos)
			heights.append(h * height_scale)

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _compute_potential(pos: Vector2) -> float:
	match field_type:
		FieldType.VORTEX_ARRAY:
			return _vortex_potential(pos)
		FieldType.SOURCE_SINK:
			return _source_sink_potential(pos)
		FieldType.DIPOLE_FIELD:
			return _source_sink_potential(pos)  # Same math, different arrangement
		FieldType.GRADIENT_NOISE:
			return _noise_curl_potential(pos)
		FieldType.SADDLE_POINTS:
			return _saddle_potential(pos)
		FieldType.ELECTROMAGNETIC:
			return _electromagnetic_potential(pos)
	return 0.0

func _vortex_potential(pos: Vector2) -> float:
	"""Stream function for point vortices: psi = -Gamma/(2pi) * ln(r)"""
	var potential = 0.0
	for el in elements:
		var r = pos.distance_to(el["position"])
		r = maxf(r, 0.3)  # Avoid singularity
		potential += el["strength"] * log(r)
	return potential * 0.3

func _source_sink_potential(pos: Vector2) -> float:
	"""Potential for sources/sinks: phi = Q/(2pi) * ln(r)"""
	var potential = 0.0
	for el in elements:
		var r = pos.distance_to(el["position"])
		r = maxf(r, 0.3)
		potential += el["strength"] * log(r)
	return potential * 0.5

func _noise_curl_potential(pos: Vector2) -> float:
	"""Use noise as a stream function — curl gives divergence-free flow"""
	var noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.05
	noise.fractal_octaves = 4
	return noise.get_noise_2d(pos.x * 3.0, pos.y * 3.0) * field_strength

func _saddle_potential(pos: Vector2) -> float:
	"""Hyperbolic saddle points: phi = x^2 - y^2 (rotated)"""
	var potential = 0.0
	for el in elements:
		var local = pos - el["position"]
		var angle: float = el.get("angle", 0.0)
		# Rotate
		var rx = local.x * cos(angle) - local.y * sin(angle)
		var ry = local.x * sin(angle) + local.y * cos(angle)
		var dist = local.length()
		var falloff = exp(-dist * 0.1)
		potential += (rx * rx - ry * ry) * el["strength"] * falloff * 0.05
	return potential

func _electromagnetic_potential(pos: Vector2) -> float:
	"""Combined electric (radial) + magnetic (tangential) potential"""
	var phi = 0.0
	for el in elements:
		var r = pos.distance_to(el["position"])
		r = maxf(r, 0.3)
		var s = el["strength"]
		# Electric: 1/r
		phi += s / r * 0.5
		# Magnetic: angular component
		var dx = pos.x - el["position"].x
		var dy = pos.y - el["position"].y
		phi += s * atan2(dy, dx) * 0.1
	return phi

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.5, 0.6)  # Cool neutral
	material.roughness = 0.5
	material.metallic = 0.3
	material.emission_enabled = true
	material.emission = Color(0.2, 0.3, 0.4) * 0.25
	mesh_instance.material_override = material

# Public API
func set_field(type: FieldType):
	field_type = type
	_generate_elements()
	generate_space()

func regenerate():
	rng.seed = randi()
	_generate_elements()
	generate_space()
