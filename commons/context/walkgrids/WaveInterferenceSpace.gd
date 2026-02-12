# WaveInterferenceSpace.gd - Interfering wave fronts as walkable terrain
# Multiple wave sources create constructive/destructive interference patterns.
# Walk through the physics of superposition — where waves meet,
# reality compounds or cancels.
#
# "Two truths meeting don't always add up."

extends TopologySpace
class_name WaveInterferenceSpace

@export var num_sources: int = 5
@export var wave_speed: float = 1.0
@export var base_frequency: float = 2.0
@export var damping: float = 0.02          # How fast waves decay with distance
@export var time_snapshot: float = 0.0     # Frozen moment in wave propagation
@export var seed_value: int = 42

# Wave types
@export var wave_type: WaveType = WaveType.CIRCULAR

enum WaveType {
	CIRCULAR,          # Point sources radiating outward
	PLANE,             # Parallel wave fronts
	MIXED,             # Both circular and plane
	DOUBLE_SLIT,       # Classic double-slit interference
	RIPPLE_TANK,       # Circular waves with reflection
}

# Animation
@export var enable_animation: bool = true
@export var animation_speed: float = 1.0

# Source configuration
var sources: Array[Dictionary] = []  # {position, frequency, amplitude, phase}
var rng: RandomNumberGenerator
var animation_time: float = 0.0

func _ready():
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	_generate_sources()
	super._ready()

func _generate_sources():
	sources.clear()
	match wave_type:
		WaveType.CIRCULAR:
			for _i in range(num_sources):
				sources.append({
					"position": Vector2(
						rng.randf_range(-space_size.x * 0.3, space_size.x * 0.3),
						rng.randf_range(-space_size.y * 0.3, space_size.y * 0.3)
					),
					"frequency": base_frequency * rng.randf_range(0.8, 1.2),
					"amplitude": rng.randf_range(0.5, 1.0),
					"phase": rng.randf_range(0.0, TAU),
					"type": "circular"
				})
		WaveType.PLANE:
			for i in range(num_sources):
				var angle = float(i) / float(num_sources) * PI
				sources.append({
					"direction": Vector2(cos(angle), sin(angle)),
					"frequency": base_frequency * (1.0 + i * 0.1),
					"amplitude": 1.0 / float(num_sources),
					"phase": 0.0,
					"type": "plane"
				})
		WaveType.DOUBLE_SLIT:
			# Two coherent point sources close together
			var slit_gap = space_size.x * 0.1
			sources.append({
				"position": Vector2(-slit_gap / 2.0, -space_size.y * 0.3),
				"frequency": base_frequency,
				"amplitude": 1.0,
				"phase": 0.0,
				"type": "circular"
			})
			sources.append({
				"position": Vector2(slit_gap / 2.0, -space_size.y * 0.3),
				"frequency": base_frequency,
				"amplitude": 1.0,
				"phase": 0.0,
				"type": "circular"
			})
		WaveType.MIXED:
			# Some circular, some plane
			for i in range(num_sources):
				if i % 2 == 0:
					sources.append({
						"position": Vector2(
							rng.randf_range(-space_size.x * 0.3, space_size.x * 0.3),
							rng.randf_range(-space_size.y * 0.3, space_size.y * 0.3)
						),
						"frequency": base_frequency,
						"amplitude": 0.7,
						"phase": rng.randf_range(0.0, TAU),
						"type": "circular"
					})
				else:
					sources.append({
						"direction": Vector2(cos(rng.randf() * PI), sin(rng.randf() * PI)),
						"frequency": base_frequency * 1.5,
						"amplitude": 0.5,
						"phase": 0.0,
						"type": "plane"
					})
		WaveType.RIPPLE_TANK:
			# Single source in center + reflected waves at edges
			sources.append({
				"position": Vector2.ZERO,
				"frequency": base_frequency,
				"amplitude": 1.0,
				"phase": 0.0,
				"type": "circular"
			})
			# Mirror sources (simulate reflection)
			for sign_x in [-1.0, 1.0]:
				for sign_z in [-1.0, 1.0]:
					sources.append({
						"position": Vector2(sign_x * space_size.x, sign_z * space_size.y),
						"frequency": base_frequency,
						"amplitude": 0.5,
						"phase": 0.0,
						"type": "circular"
					})

func generate_space():
	var heights = _compute_wave_field(time_snapshot)

	var mesh = create_mesh_from_heights(heights)
	mesh_instance.mesh = mesh
	create_collision_from_mesh(mesh)
	_setup_material()

func _compute_wave_field(t: float) -> Array:
	var heights: Array = []
	var gs = resolution + 1

	for z in range(gs):
		for x in range(gs):
			var world_x = (x / float(resolution)) * space_size.x - space_size.x / 2.0
			var world_z = (z / float(resolution)) * space_size.y - space_size.y / 2.0
			var pos = Vector2(world_x, world_z)

			var h = 0.0
			for source in sources:
				h += _wave_contribution(pos, source, t)

			heights.append(h * height_scale)

	return heights

func _wave_contribution(pos: Vector2, source: Dictionary, t: float) -> float:
	var src_type: String = source.get("type", "circular")
	var freq: float = source.get("frequency", base_frequency)
	var amp: float = source.get("amplitude", 1.0)
	var phase: float = source.get("phase", 0.0)

	if src_type == "circular":
		var src_pos: Vector2 = source.get("position", Vector2.ZERO)
		var dist = pos.distance_to(src_pos)
		var decay = exp(-dist * damping)
		return amp * decay * sin(freq * dist - wave_speed * t + phase)
	else:
		# Plane wave
		var dir: Vector2 = source.get("direction", Vector2(1, 0))
		var projection = pos.dot(dir)
		return amp * sin(freq * projection - wave_speed * t + phase)

func _setup_material():
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.5, 0.8)  # Water blue
	material.roughness = 0.2
	material.metallic = 0.4
	material.emission_enabled = true
	material.emission = Color(0.2, 0.35, 0.6) * 0.3
	mesh_instance.material_override = material

func _process(delta):
	if not enable_animation:
		return
	animation_time += delta * animation_speed
	var heights = _compute_wave_field(animation_time)
	mesh_instance.mesh = create_mesh_from_heights(heights)
	# Update collision less frequently
	if fmod(animation_time, 0.5) < delta * animation_speed:
		create_collision_from_mesh(mesh_instance.mesh)

# Public API
func set_wave_type(type: WaveType):
	wave_type = type
	_generate_sources()
	generate_space()

func add_source(pos: Vector2, freq: float = -1.0, amp: float = 1.0):
	if freq < 0:
		freq = base_frequency
	sources.append({
		"position": pos,
		"frequency": freq,
		"amplitude": amp,
		"phase": 0.0,
		"type": "circular"
	})
	generate_space()

func regenerate():
	rng.seed = randi()
	_generate_sources()
	generate_space()
