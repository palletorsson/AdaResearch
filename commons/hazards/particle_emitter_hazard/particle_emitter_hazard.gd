# @identity
# essence: emit(pattern, t) = spawn(particle, lifetime, velocity) -- nozzle cycling cone/fountain/spiral
# desire: a particle emitter cycling emission patterns, birth-white to dying-red, lifecycle as ammunition
# critical_parameter: _current_pattern (EmissionPattern) -- cone, fountain, spiral produce different threats
# triggers: emit_timer spawns particles; pattern_timer cycles modes; particles age from white to red
# emerges: particle lifecycle as weapon -- birth, travel, death mapped to color
# needs: manual particle management [has]; 3 emission patterns [has]; color lifecycle [has]; VR interaction [missing]
# relationships: embodies particles sequence; manual particles for educational visibility
# truth: the particle emitter cycles cone, fountain, spiral -- birth-white to dying-red, lifecycle as ammunition.

extends Node3D
class_name ParticleEmitterHazard
## Particles sequence hazard — a nozzle that fires manually-managed projectile particles.
## Particles have lifecycle coloring (white -> yellow -> red -> invisible) and
## physics (velocity + gravity + drag). Emission pattern cycles between CONE,
## FOUNTAIN, and SPIRAL modes. Contact damage via distance check against player.

signal enemy_destroyed(enemy: Node3D)

enum EmissionPattern { CONE, FOUNTAIN, SPIRAL }

@export_group("Emitter")
@export var pool_size: int = 30
@export var particle_radius: float = 0.04
@export var particle_lifetime: float = 3.0
@export var emit_rate: float = 8.0  # Particles per second
@export var pattern_duration: float = 5.0

@export_group("Physics")
@export var initial_speed: float = 4.0
@export var gravity: Vector3 = Vector3(0.0, -9.8, 0.0)
@export var drag: float = 0.3

@export_group("Combat")
@export var contact_damage: float = 8.0
@export var contact_radius: float = 0.15
@export var damage_cooldown: float = 0.3

@export_group("Appearance")
@export var nozzle_color: Color = Color(0.4, 0.4, 0.5)
@export var birth_color: Color = Color(1.0, 1.0, 1.0)
@export var active_color: Color = Color(1.0, 0.9, 0.2)
@export var dying_color: Color = Color(1.0, 0.2, 0.05)

# State
var _player_node: Node3D = null
var _time: float = 0.0
var _emit_timer: float = 0.0
var _pattern_timer: float = 0.0
var _current_pattern: EmissionPattern = EmissionPattern.CONE
var _spiral_angle: float = 0.0
var _damage_timer: float = 0.0

# Particle pool
var _particles: Array[Dictionary] = []
# Each: { "node": MeshInstance3D, "velocity": Vector3, "age": float, "alive": bool }

# Visual
var _nozzle_mesh: MeshInstance3D = null
var _particle_mesh: SphereMesh = null


func _ready() -> void:
	_build_nozzle()
	_build_particle_pool()
	_find_player()
	add_to_group("enemy")


func _process(delta: float) -> void:
	_time += delta
	_emit_timer += delta
	_pattern_timer += delta
	_damage_timer = maxf(0.0, _damage_timer - delta)

	if not is_instance_valid(_player_node):
		_find_player()

	# Cycle emission pattern
	if _pattern_timer >= pattern_duration:
		_pattern_timer = 0.0
		_current_pattern = ((_current_pattern + 1) % 3) as EmissionPattern

	# Emit particles
	var emit_interval: float = 1.0 / emit_rate
	while _emit_timer >= emit_interval:
		_emit_timer -= emit_interval
		_emit_particle()

	# Update all particles
	_update_particles(delta)


func _build_nozzle() -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.1
	cyl.height = 0.25
	cyl.radial_segments = 12

	var mat := StandardMaterial3D.new()
	mat.albedo_color = nozzle_color
	mat.emission_enabled = true
	mat.emission = nozzle_color.lightened(0.3)
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.6
	mat.roughness = 0.3

	_nozzle_mesh = MeshInstance3D.new()
	_nozzle_mesh.mesh = cyl
	_nozzle_mesh.set_surface_override_material(0, mat)
	_nozzle_mesh.position.y = 0.125
	add_child(_nozzle_mesh)


func _build_particle_pool() -> void:
	_particle_mesh = SphereMesh.new()
	_particle_mesh.radius = particle_radius
	_particle_mesh.height = particle_radius * 2.0
	_particle_mesh.radial_segments = 8
	_particle_mesh.rings = 4

	for i in range(pool_size):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = birth_color
		mat.emission_enabled = true
		mat.emission = birth_color
		mat.emission_energy_multiplier = 2.0

		var mi := MeshInstance3D.new()
		mi.mesh = _particle_mesh
		mi.set_surface_override_material(0, mat)
		mi.visible = false
		add_child(mi)

		_particles.append({
			"node": mi,
			"mat": mat,
			"velocity": Vector3.ZERO,
			"age": 0.0,
			"alive": false,
		})


func _emit_particle() -> void:
	# Find a dead particle to reuse
	var p: Dictionary = {}
	var found: bool = false
	for particle in _particles:
		if not particle["alive"]:
			p = particle
			found = true
			break
	if not found:
		return

	p["alive"] = true
	p["age"] = 0.0
	p["node"].visible = true
	p["node"].global_position = global_position + Vector3(0.0, 0.25, 0.0)
	p["node"].scale = Vector3.ONE

	# Compute initial velocity based on current pattern
	var dir := Vector3.ZERO
	match _current_pattern:
		EmissionPattern.CONE:
			var angle: float = randf() * TAU
			var spread: float = randf() * 0.4
			dir = Vector3(sin(angle) * spread, 1.0, cos(angle) * spread).normalized()

		EmissionPattern.FOUNTAIN:
			var angle: float = randf() * TAU
			var spread: float = randf() * 0.15
			dir = Vector3(sin(angle) * spread, 1.0, cos(angle) * spread).normalized()

		EmissionPattern.SPIRAL:
			_spiral_angle += 0.5
			var spread: float = 0.3
			dir = Vector3(sin(_spiral_angle) * spread, 1.0, cos(_spiral_angle) * spread).normalized()

	p["velocity"] = dir * initial_speed

	# Reset material to birth color
	var mat: StandardMaterial3D = p["mat"]
	mat.albedo_color = birth_color
	mat.emission = birth_color
	mat.emission_energy_multiplier = 2.0


func _update_particles(delta: float) -> void:
	var player_pos: Vector3 = Vector3.ZERO
	var has_player: bool = false
	if is_instance_valid(_player_node):
		player_pos = _player_node.global_position
		has_player = true

	for p in _particles:
		if not p["alive"]:
			continue

		p["age"] += delta

		# Kill if expired
		if p["age"] >= particle_lifetime:
			p["alive"] = false
			p["node"].visible = false
			continue

		# Physics: gravity + drag
		var vel: Vector3 = p["velocity"]
		vel += gravity * delta
		vel *= (1.0 - drag * delta)
		p["velocity"] = vel
		p["node"].global_position += vel * delta

		# Kill if below ground
		if p["node"].global_position.y < -0.5:
			p["alive"] = false
			p["node"].visible = false
			continue

		# Lifecycle coloring
		var life_t: float = p["age"] / particle_lifetime  # 0..1
		var mat: StandardMaterial3D = p["mat"]

		if life_t < 0.2:
			# Birth phase: white
			var t: float = life_t / 0.2
			mat.albedo_color = birth_color.lerp(active_color, t)
			mat.emission = birth_color.lerp(active_color, t)
			mat.emission_energy_multiplier = 2.0
		elif life_t < 0.7:
			# Active phase: yellow
			var t: float = (life_t - 0.2) / 0.5
			mat.albedo_color = active_color.lerp(dying_color, t)
			mat.emission = active_color.lerp(dying_color, t)
			mat.emission_energy_multiplier = 1.5
		else:
			# Dying phase: red fading out
			var t: float = (life_t - 0.7) / 0.3
			mat.albedo_color = Color(dying_color.r, dying_color.g, dying_color.b, 1.0 - t)
			mat.emission = dying_color
			mat.emission_energy_multiplier = 1.0 - t
			if mat.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		# Scale down near death
		if life_t > 0.8:
			var shrink: float = 1.0 - (life_t - 0.8) / 0.2
			p["node"].scale = Vector3.ONE * maxf(0.1, shrink)

		# Contact damage
		if has_player and _damage_timer <= 0.0:
			var dist: float = p["node"].global_position.distance_to(player_pos)
			if dist < contact_radius:
				var gm = get_node_or_null("/root/GameManager")
				if gm and gm.has_method("apply_health_damage"):
					gm.apply_health_damage(contact_damage)
					_damage_timer = damage_cooldown


func _find_player() -> void:
	var scene: Node = get_tree().current_scene
	if not scene:
		return
	for candidate in [
		get_tree().get_first_node_in_group("player"),
		scene.find_child("XROrigin3D", true, false),
		scene.find_child("Player", true, false),
	]:
		if candidate is Node3D:
			_player_node = candidate
			return


# ── Damage Interface ────────────────────────────────────────────────────
func take_damage(amount: float) -> void:
	pass  # Spawner — indestructible

func apply_damage(amount: float) -> void:
	pass

func damage(amount: float) -> void:
	pass

func configure(config: Dictionary) -> void:
	if config.has("damage"):
		contact_damage = float(config["damage"])
	if config.has("speed"):
		initial_speed = float(config["speed"])
	if config.has("rate"):
		emit_rate = float(config["rate"])

func apply_grid_config(config: Dictionary) -> void:
	configure(config)
