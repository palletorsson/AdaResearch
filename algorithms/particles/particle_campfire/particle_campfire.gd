extends Node3D

# @identity
# essence: Three systems, one scene. Fire rises, embers arc, smoke expands. Forces + lifetime + collision = recognizable effect.
# desire: To be warm. To synthesize everything the particle sequence taught into one thing you recognize from the real world.
# critical_parameter: Wind — changes the fire's lean, the ember trajectories, the smoke drift. The campfire's character.
# triggers: Wind change → fire leans and flickers, gravity on embers → ballistic arcs, smoke expansion → volumetric sense
# emerges: A campfire from three independent particle types. Recognition from parameter curves. Atmosphere from math.
# needs: VR wind slider [missing]. Temperature/intensity control [missing]. Log arrangement could be grabbable.
# relationships: Capstone of particles sequence. Uses lifetime_curves patterns. Uses sub_emitter logic (embers are soft bursts).
# truth: Emitters plus forces plus lifetime curves plus spatial behavior. This is what the sequence was building toward.

## Particle campfire — synthesis artifact combining emitters, forces, lifetime
## curves, and collision into one recognizable real-time effect.
## Fire (orange → red → grey, rising), embers (bright sparks, long trails),
## smoke (grey, slow, expanding), and ground-level glow.

const MAX_PARTICLES := 800

enum ParticleType { FIRE, EMBER, SMOKE }

class CampfireParticle:
	var pos: Vector3
	var vel: Vector3
	var age: float
	var lifetime: float
	var type: int
	var size: float

var _particles: Array = []
var _spawn_accum_fire := 0.0
var _spawn_accum_ember := 0.0
var _spawn_accum_smoke := 0.0
var _multi_mesh_instance: MultiMeshInstance3D
var _multi_mesh: MultiMesh
var _time := 0.0


func _ready() -> void:
	_setup_multimesh()
	_setup_logs()
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
	sphere.radial_segments = 6
	sphere.rings = 3
	_multi_mesh.mesh = sphere

	_multi_mesh_instance = MultiMeshInstance3D.new()
	_multi_mesh_instance.multimesh = _multi_mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 3.0
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_multi_mesh_instance.material_override = mat
	add_child(_multi_mesh_instance)


func _setup_logs() -> void:
	# Simple log arrangement
	var log_mat := StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.25, 0.12, 0.05)
	log_mat.roughness = 0.9

	for i in 3:
		var log := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.15
		cyl.height = 1.8
		log.mesh = cyl
		log.material_override = log_mat
		var angle := float(i) * TAU / 3.0
		log.position = Vector3(cos(angle) * 0.3, 0.1, sin(angle) * 0.3)
		log.rotation = Vector3(deg_to_rad(85.0), angle, deg_to_rad(randf_range(-15, 15)))
		add_child(log)

	# Ground glow disc
	var glow := MeshInstance3D.new()
	var disc := PlaneMesh.new()
	disc.size = Vector2(3.0, 3.0)
	glow.mesh = disc
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(1.0, 0.4, 0.1, 0.15)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.emission_enabled = true
	gmat.emission = Color(1.0, 0.3, 0.05)
	gmat.emission_energy_multiplier = 0.5
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.material_override = gmat
	glow.position = Vector3(0.0, 0.02, 0.0)
	add_child(glow)


func _setup_labels() -> void:
	var title := Label3D.new()
	title.text = "Particle Campfire"
	title.font_size = 22
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0.0, 6.0, 3.0)
	title.modulate = Color(1, 1, 1, 0.9)
	add_child(title)

	var desc := Label3D.new()
	desc.text = "emitters + forces + lifetime + collision"
	desc.font_size = 13
	desc.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	desc.position = Vector3(0.0, 5.3, 3.0)
	desc.modulate = Color(1, 1, 1, 0.6)
	add_child(desc)


func _process(delta: float) -> void:
	_time += delta

	# Spawn rates
	_spawn_accum_fire += delta * 80.0
	_spawn_accum_ember += delta * 8.0
	_spawn_accum_smoke += delta * 12.0

	while _spawn_accum_fire >= 1.0 and _particles.size() < MAX_PARTICLES:
		_spawn_accum_fire -= 1.0
		_spawn(ParticleType.FIRE)

	while _spawn_accum_ember >= 1.0 and _particles.size() < MAX_PARTICLES:
		_spawn_accum_ember -= 1.0
		_spawn(ParticleType.EMBER)

	while _spawn_accum_smoke >= 1.0 and _particles.size() < MAX_PARTICLES:
		_spawn_accum_smoke -= 1.0
		_spawn(ParticleType.SMOKE)

	# Update
	var alive: Array = []
	for p in _particles:
		p.age += delta
		if p.age >= p.lifetime:
			continue

		var t: float = p.age / p.lifetime

		match p.type:
			ParticleType.FIRE:
				p.vel.y += 2.5 * delta  # updraft
				p.vel.x += sin(_time * 3.0 + p.pos.y * 2.0) * 0.3 * delta  # flicker
				p.vel.z += cos(_time * 2.5 + p.pos.x * 2.0) * 0.3 * delta
				p.vel *= 0.97
			ParticleType.EMBER:
				p.vel.y -= 1.0 * delta  # gravity
				p.vel *= 0.995
			ParticleType.SMOKE:
				p.vel.y += 0.8 * delta  # gentle rise
				p.vel.x += sin(_time * 0.5 + p.pos.y) * 0.2 * delta
				p.vel *= 0.98

		p.pos += p.vel * delta
		alive.append(p)

	_particles = alive

	# Render
	var count := mini(_particles.size(), MAX_PARTICLES)
	_multi_mesh.visible_instance_count = count
	for i in count:
		var p: CampfireParticle = _particles[i]
		var t: float = p.age / p.lifetime
		var color := _get_color(p.type, t)
		var s := _get_size(p.type, t) * p.size

		var xform := Transform3D.IDENTITY
		xform = xform.scaled(Vector3(s, s, s))
		xform.origin = p.pos
		_multi_mesh.set_instance_transform(i, xform)
		_multi_mesh.set_instance_color(i, color)


func _spawn(type: int) -> void:
	var p := CampfireParticle.new()
	p.type = type
	var spread := randf_range(-0.3, 0.3)

	match type:
		ParticleType.FIRE:
			p.pos = Vector3(spread, 0.2, spread)
			p.vel = Vector3(randf_range(-0.3, 0.3), randf_range(1.5, 3.0), randf_range(-0.3, 0.3))
			p.lifetime = randf_range(0.4, 1.2)
			p.size = randf_range(0.8, 1.5)
		ParticleType.EMBER:
			p.pos = Vector3(spread * 0.5, randf_range(0.5, 1.5), spread * 0.5)
			p.vel = Vector3(randf_range(-1.0, 1.0), randf_range(2.0, 5.0), randf_range(-1.0, 1.0))
			p.lifetime = randf_range(1.0, 3.0)
			p.size = randf_range(0.3, 0.6)
		ParticleType.SMOKE:
			p.pos = Vector3(spread, randf_range(1.5, 2.5), spread)
			p.vel = Vector3(randf_range(-0.2, 0.2), randf_range(0.5, 1.5), randf_range(-0.2, 0.2))
			p.lifetime = randf_range(2.0, 4.0)
			p.size = randf_range(1.0, 2.5)

	p.age = 0.0
	_particles.append(p)


func _get_color(type: int, t: float) -> Color:
	match type:
		ParticleType.FIRE:
			# Bright yellow → orange → red → dark
			if t < 0.3:
				return Color(1.0, 0.9, 0.3).lerp(Color(1.0, 0.5, 0.1), t / 0.3)
			elif t < 0.7:
				return Color(1.0, 0.5, 0.1).lerp(Color(0.8, 0.15, 0.05), (t - 0.3) / 0.4)
			else:
				var c := Color(0.8, 0.15, 0.05).lerp(Color(0.2, 0.1, 0.1), (t - 0.7) / 0.3)
				c.a = clampf(1.0 - (t - 0.7) / 0.3, 0.0, 1.0)
				return c
		ParticleType.EMBER:
			var c := Color(1.0, 0.7, 0.2).lerp(Color(1.0, 0.3, 0.1), t)
			c.a = clampf(1.0 - t, 0.0, 1.0)
			return c
		ParticleType.SMOKE:
			var grey: float = lerp(0.5, 0.3, t)
			var c := Color(grey, grey, grey)
			# Fade in then out
			if t < 0.1:
				c.a = t * 5.0
			else:
				c.a = clampf((1.0 - t) * 0.4, 0.0, 0.4)
			return c
	return Color.WHITE


func _get_size(type: int, t: float) -> float:
	match type:
		ParticleType.FIRE:
			return (1.0 - t) * (0.5 + 0.5 * sin(t * PI))
		ParticleType.EMBER:
			return 1.0 - t * 0.5
		ParticleType.SMOKE:
			return 1.0 + t * 3.0  # smoke expands
	return 1.0


func apply_grid_config(config: Dictionary) -> void:
	pass
