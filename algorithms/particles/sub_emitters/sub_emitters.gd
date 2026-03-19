extends Node3D

## Sub-emitters: particles spawning particles on death.
## A mortar launches large projectiles upward. On death, each spawns a burst
## of child particles — the classic firework pattern.

const MAX_PARTICLES := 1200
const LAUNCH_INTERVAL := 2.0
const BURST_COUNT := 40

class Particle:
	var pos: Vector3
	var vel: Vector3
	var age: float
	var lifetime: float
	var is_primary: bool
	var color: Color
	var size: float

var _particles: Array = []
var _launch_timer := 0.0
var _multi_mesh_instance: MultiMeshInstance3D
var _multi_mesh: MultiMesh
var _burst_colors := [
	Color(1.0, 0.4, 0.2),
	Color(0.3, 0.8, 1.0),
	Color(1.0, 0.9, 0.2),
	Color(0.9, 0.3, 0.9),
	Color(0.3, 1.0, 0.5),
]
var _next_color_idx := 0


func _ready() -> void:
	_setup_multimesh()
	_setup_labels()


func _setup_multimesh() -> void:
	_multi_mesh = MultiMesh.new()
	_multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	_multi_mesh.use_colors = true
	_multi_mesh.instance_count = MAX_PARTICLES
	_multi_mesh.visible_instance_count = 0

	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	sphere.radial_segments = 8
	sphere.rings = 4
	_multi_mesh.mesh = sphere

	_multi_mesh_instance = MultiMeshInstance3D.new()
	_multi_mesh_instance.multimesh = _multi_mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 2.0
	_multi_mesh_instance.material_override = mat
	add_child(_multi_mesh_instance)


func _setup_labels() -> void:
	var title := Label3D.new()
	title.text = "Sub-Emitters: Fireworks"
	title.font_size = 24
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0.0, 12.0, 3.0)
	title.modulate = Color(1, 1, 1, 0.9)
	add_child(title)

	var desc := Label3D.new()
	desc.text = "particles spawn particles on death"
	desc.font_size = 14
	desc.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	desc.position = Vector3(0.0, 11.0, 3.0)
	desc.modulate = Color(1, 1, 1, 0.6)
	add_child(desc)


func _process(delta: float) -> void:
	_launch_timer += delta

	# Launch a new mortar
	if _launch_timer >= LAUNCH_INTERVAL and _particles.size() < MAX_PARTICLES - BURST_COUNT - 10:
		_launch_timer -= LAUNCH_INTERVAL
		_launch_mortar()

	# Update particles, collect deaths
	var alive: Array = []
	var deaths: Array = []
	for p in _particles:
		p.age += delta
		if p.age >= p.lifetime:
			if p.is_primary:
				deaths.append(p)
			continue
		# Gravity
		p.vel.y -= 4.0 * delta
		# Drag on children
		if not p.is_primary:
			p.vel *= 0.98
		p.pos += p.vel * delta
		alive.append(p)

	# Spawn bursts from dead primaries
	for dead in deaths:
		_spawn_burst(dead.pos)

	_particles = alive

	# Render
	var count := mini(_particles.size(), MAX_PARTICLES)
	_multi_mesh.visible_instance_count = count
	for i in count:
		var p: Particle = _particles[i]
		var t := p.age / p.lifetime
		var s := p.size
		if not p.is_primary:
			s *= (1.0 - t)  # shrink over life
		var c := p.color
		c.a = clampf(1.0 - t * t, 0.0, 1.0)

		var xform := Transform3D.IDENTITY
		xform = xform.scaled(Vector3(s, s, s))
		xform.origin = p.pos
		_multi_mesh.set_instance_transform(i, xform)
		_multi_mesh.set_instance_color(i, c)


func _launch_mortar() -> void:
	var p := Particle.new()
	p.pos = Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0))
	p.vel = Vector3(randf_range(-0.5, 0.5), randf_range(8.0, 12.0), randf_range(-0.5, 0.5))
	p.age = 0.0
	p.lifetime = randf_range(1.0, 1.8)
	p.is_primary = true
	p.color = Color(1.0, 0.9, 0.6)
	p.size = 2.0
	_particles.append(p)


func _spawn_burst(origin: Vector3) -> void:
	var burst_color: Color = _burst_colors[_next_color_idx % _burst_colors.size()]
	_next_color_idx += 1

	for _i in BURST_COUNT:
		if _particles.size() >= MAX_PARTICLES:
			break
		var p := Particle.new()
		p.pos = origin
		# Spherical spread
		var theta := randf() * TAU
		var phi := randf_range(-PI * 0.5, PI * 0.5)
		var speed := randf_range(2.0, 6.0)
		p.vel = Vector3(
			cos(phi) * cos(theta) * speed,
			cos(phi) * sin(theta) * speed + 1.0,
			sin(phi) * speed
		)
		p.age = 0.0
		p.lifetime = randf_range(0.8, 2.0)
		p.is_primary = false
		p.color = burst_color.lerp(Color.WHITE, randf_range(0.0, 0.3))
		p.size = randf_range(0.8, 1.5)
		_particles.append(p)


func apply_grid_config(config: Dictionary) -> void:
	pass
