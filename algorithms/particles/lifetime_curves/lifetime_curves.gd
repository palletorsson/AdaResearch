extends Node3D

## Particle lifetime curves — color, size, and opacity mapped over normalized age [0,1].
## Three emitters side by side, each demonstrating a different curve profile:
## quick flash, slow fade, pulsing glow.

const MAX_PARTICLES := 600
const SPAWN_RATE := 40.0  # particles per second per emitter

class Particle:
	var pos: Vector3
	var vel: Vector3
	var age: float
	var lifetime: float
	var emitter_id: int

	func normalized_age() -> float:
		return clampf(age / lifetime, 0.0, 1.0)

var _particles: Array = []
var _spawn_accum := 0.0
var _multi_mesh_instance: MultiMeshInstance3D
var _multi_mesh: MultiMesh
var _time := 0.0

# Curve profiles
var _profiles := [
	{"name": "Quick Flash", "lifetime": 0.6, "offset": Vector3(-4.0, 0.0, 0.0),
	 "color_start": Color(1.0, 0.9, 0.3), "color_end": Color(1.0, 0.2, 0.1)},
	{"name": "Slow Fade", "lifetime": 3.0, "offset": Vector3(0.0, 0.0, 0.0),
	 "color_start": Color(0.3, 0.7, 1.0), "color_end": Color(0.1, 0.2, 0.5)},
	{"name": "Pulse Glow", "lifetime": 2.0, "offset": Vector3(4.0, 0.0, 0.0),
	 "color_start": Color(0.4, 1.0, 0.5), "color_end": Color(0.8, 0.3, 1.0)},
]


func _ready() -> void:
	_setup_multimesh()
	_setup_labels()
	_setup_curve_display()


func _setup_multimesh() -> void:
	_multi_mesh = MultiMesh.new()
	_multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	_multi_mesh.use_colors = true
	_multi_mesh.instance_count = MAX_PARTICLES
	_multi_mesh.visible_instance_count = 0

	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	sphere.radial_segments = 8
	sphere.rings = 4
	_multi_mesh.mesh = sphere

	_multi_mesh_instance = MultiMeshInstance3D.new()
	_multi_mesh_instance.multimesh = _multi_mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 1.5
	_multi_mesh_instance.material_override = mat
	add_child(_multi_mesh_instance)


func _setup_labels() -> void:
	for profile in _profiles:
		var label := Label3D.new()
		label.text = profile["name"]
		label.font_size = 18
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = profile["offset"] + Vector3(0.0, 4.5, 0.0)
		label.modulate = Color(1, 1, 1, 0.85)
		add_child(label)

	var title := Label3D.new()
	title.text = "Particle Lifetime Curves"
	title.font_size = 24
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0.0, 6.0, 3.0)
	title.modulate = Color(1, 1, 1, 0.9)
	add_child(title)


func _setup_curve_display() -> void:
	# Visual curve graphs behind each emitter
	for pi in _profiles.size():
		var profile = _profiles[pi]
		var line := ImmediateMesh.new()
		var inst := MeshInstance3D.new()
		inst.mesh = line
		var mat := StandardMaterial3D.new()
		mat.albedo_color = profile["color_start"]
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		inst.material_override = mat

		# Draw curve as line strip
		line.clear_surfaces()
		line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
		for i in 32:
			var t := float(i) / 31.0
			var size_val := _size_curve(t, pi)
			var x := profile["offset"].x + (t - 0.5) * 2.0
			var y := 5.0 + size_val * 1.5
			line.surface_add_vertex(Vector3(x, y, -1.0))
		line.surface_end()
		add_child(inst)


func _process(delta: float) -> void:
	_time += delta

	# Spawn particles for each emitter
	_spawn_accum += delta * SPAWN_RATE * _profiles.size()
	while _spawn_accum >= 1.0 and _particles.size() < MAX_PARTICLES:
		_spawn_accum -= 1.0
		var emitter_id := randi() % _profiles.size()
		_spawn_particle(emitter_id)

	# Update particles
	var alive: Array = []
	for p in _particles:
		p.age += delta
		if p.age < p.lifetime:
			p.vel += Vector3(0.0, 0.3, 0.0) * delta  # gentle updraft
			p.vel *= 0.995  # drag
			p.pos += p.vel * delta
			alive.append(p)
	_particles = alive

	# Render
	_multi_mesh.visible_instance_count = _particles.size()
	for i in _particles.size():
		var p: Particle = _particles[i]
		var t := p.normalized_age()
		var profile = _profiles[p.emitter_id]

		# Size curve
		var s := _size_curve(t, p.emitter_id)

		# Color curve
		var color: Color = profile["color_start"].lerp(profile["color_end"], t)

		# Opacity curve
		var alpha := _opacity_curve(t, p.emitter_id)
		color.a = alpha

		var xform := Transform3D.IDENTITY
		xform = xform.scaled(Vector3(s, s, s))
		xform.origin = p.pos
		_multi_mesh.set_instance_transform(i, xform)
		_multi_mesh.set_instance_color(i, color)


func _spawn_particle(emitter_id: int) -> void:
	var profile = _profiles[emitter_id]
	var p := Particle.new()
	p.emitter_id = emitter_id
	p.pos = profile["offset"] + Vector3(randf_range(-0.3, 0.3), 0.0, randf_range(-0.3, 0.3))
	p.vel = Vector3(randf_range(-0.5, 0.5), randf_range(1.0, 2.5), randf_range(-0.5, 0.5))
	p.age = 0.0
	p.lifetime = profile["lifetime"] * randf_range(0.8, 1.2)
	_particles.append(p)


func _size_curve(t: float, emitter_id: int) -> float:
	match emitter_id:
		0:  # Quick flash: sharp peak then collapse
			return 1.5 * (1.0 - t) * sin(t * PI)
		1:  # Slow fade: gradual growth then slow shrink
			return 0.5 + 0.8 * sin(t * PI * 0.8)
		2:  # Pulse: oscillating size
			return 0.6 + 0.5 * sin(t * PI * 4.0) * (1.0 - t)
	return 1.0


func _opacity_curve(t: float, emitter_id: int) -> float:
	match emitter_id:
		0:  # Quick flash: instant on, fast fade
			return clampf(1.0 - t * t, 0.0, 1.0)
		1:  # Slow fade: linear fade
			return clampf(1.0 - t, 0.0, 1.0)
		2:  # Pulse: stays visible, drops at end
			if t > 0.8:
				return clampf((1.0 - t) * 5.0, 0.0, 1.0)
			return 0.9
	return 1.0


func apply_grid_config(config: Dictionary) -> void:
	pass
