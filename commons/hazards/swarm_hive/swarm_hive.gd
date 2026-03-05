extends Node3D
class_name SwarmHive
## Swarm Intelligence hazard — a stationary hive that spawns boid particles.
## Boids follow separation/alignment/cohesion + player-seeking.
## Teaches emergent collective behavior from simple local rules.

signal enemy_destroyed(enemy: Node3D)

@export_group("Swarm")
@export var max_boids: int = 20
@export var spawn_interval: float = 0.3
@export var boid_speed: float = 3.0
@export var boid_damage: float = 5.0

@export_group("Boid Rules")
@export var separation_radius: float = 0.5
@export var alignment_radius: float = 1.5
@export var cohesion_radius: float = 2.5
@export var separation_weight: float = 2.0
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var player_seek_weight: float = 1.5
@export var detection_radius: float = 8.0

@export_group("Appearance")
@export var hive_color: Color = Color(0.6, 0.45, 0.15)
@export var boid_color: Color = Color(0.9, 0.7, 0.1)
@export var emission_color: Color = Color(1.0, 0.8, 0.2)

# State
var _player_node: Node3D = null
var _boids: Array[Dictionary] = []  # {node, velocity, alive}
var _spawn_timer: float = 0.0
var _hive_health: float = 100.0

# Visual
var _hive_mesh: MeshInstance3D = null
var _hive_mat: StandardMaterial3D
var _boid_mat: StandardMaterial3D
var _boid_mesh: SphereMesh = null


func _ready() -> void:
	_create_materials()
	_build_hive()
	_find_player()
	add_to_group("enemy")

	# Collision for the hive itself
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.6, 0.6, 0.6)
	col.shape = shape
	col.position.y = 0.4
	area.add_child(col)
	area.collision_layer = 4
	area.collision_mask = 0
	add_child(area)

	# Pre-create boid mesh template
	_boid_mesh = SphereMesh.new()
	_boid_mesh.radius = 0.06
	_boid_mesh.height = 0.12
	_boid_mesh.radial_segments = 8
	_boid_mesh.rings = 4


func _process(delta: float) -> void:
	if not is_instance_valid(_player_node):
		_find_player()

	# Spawn boids
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval and _boids.size() < max_boids:
		_spawn_timer = 0.0
		_spawn_boid()

	# Update boids
	_update_boids(delta)


func _create_materials() -> void:
	_hive_mat = StandardMaterial3D.new()
	_hive_mat.albedo_color = hive_color
	_hive_mat.emission_enabled = true
	_hive_mat.emission = emission_color * 0.3
	_hive_mat.emission_energy_multiplier = 1.0

	_boid_mat = StandardMaterial3D.new()
	_boid_mat.albedo_color = boid_color
	_boid_mat.emission_enabled = true
	_boid_mat.emission = emission_color
	_boid_mat.emission_energy_multiplier = 2.0


func _build_hive() -> void:
	# Hexagonal prism hive body
	var body := BoxMesh.new()
	body.size = Vector3(0.5, 0.5, 0.5)
	_hive_mesh = MeshInstance3D.new()
	_hive_mesh.mesh = body
	_hive_mesh.set_surface_override_material(0, _hive_mat)
	_hive_mesh.position.y = 0.4
	add_child(_hive_mesh)

	# Honeycomb accent — smaller boxes on faces
	var accent_mat: StandardMaterial3D = _hive_mat.duplicate()
	accent_mat.albedo_color = hive_color.lightened(0.2)
	var accent := BoxMesh.new()
	accent.size = Vector3(0.12, 0.12, 0.12)
	for i in range(6):
		var a := MeshInstance3D.new()
		a.mesh = accent
		a.set_surface_override_material(0, accent_mat)
		var angle: float = i * TAU / 6.0
		a.position = Vector3(cos(angle) * 0.22, 0.0, sin(angle) * 0.22)
		_hive_mesh.add_child(a)


func _spawn_boid() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _boid_mesh
	mi.set_surface_override_material(0, _boid_mat.duplicate())
	add_child(mi)

	# Random direction outward from hive
	var angle: float = randf() * TAU
	var dir := Vector3(cos(angle), 0.3, sin(angle)).normalized()

	mi.global_position = global_position + Vector3(0.0, 0.4, 0.0) + dir * 0.3

	_boids.append({
		"node": mi,
		"velocity": dir * boid_speed * 0.5,
	})


func _update_boids(delta: float) -> void:
	var player_pos: Vector3 = Vector3.ZERO
	var has_player: bool = false
	if is_instance_valid(_player_node):
		player_pos = _player_node.global_position
		has_player = true

	var positions: Array[Vector3] = []
	var velocities: Array[Vector3] = []

	# Gather positions
	for b in _boids:
		if is_instance_valid(b["node"]):
			positions.append(b["node"].global_position)
			velocities.append(b["velocity"])
		else:
			positions.append(Vector3.ZERO)
			velocities.append(Vector3.ZERO)

	# Update each boid
	var to_remove: Array[int] = []
	for i in range(_boids.size()):
		var boid: Dictionary = _boids[i]
		if not is_instance_valid(boid["node"]):
			to_remove.append(i)
			continue

		var pos: Vector3 = positions[i]
		var vel: Vector3 = velocities[i]

		# Boid rules
		var sep := Vector3.ZERO
		var ali := Vector3.ZERO
		var coh := Vector3.ZERO
		var sep_count: int = 0
		var ali_count: int = 0
		var coh_count: int = 0

		for j in range(_boids.size()):
			if i == j:
				continue
			var diff: Vector3 = pos - positions[j]
			var dist: float = diff.length()

			if dist < separation_radius and dist > 0.01:
				sep += diff.normalized() / dist
				sep_count += 1
			if dist < alignment_radius:
				ali += velocities[j]
				ali_count += 1
			if dist < cohesion_radius:
				coh += positions[j]
				coh_count += 1

		var steering := Vector3.ZERO

		if sep_count > 0:
			steering += (sep / float(sep_count)).normalized() * separation_weight
		if ali_count > 0:
			steering += ((ali / float(ali_count)).normalized() - vel.normalized()) * alignment_weight
		if coh_count > 0:
			var center: Vector3 = coh / float(coh_count)
			steering += (center - pos).normalized() * cohesion_weight

		# Player seeking
		if has_player:
			var to_player: Vector3 = player_pos - pos
			var player_dist: float = to_player.length()
			if player_dist < detection_radius:
				steering += to_player.normalized() * player_seek_weight

				# Contact damage
				if player_dist < 0.3:
					var gm = get_node_or_null("/root/GameManager")
					if gm and gm.has_method("apply_health_damage"):
						gm.apply_health_damage(boid_damage * delta)

		# Hive tethering — don't wander too far
		var to_hive: Vector3 = global_position - pos
		if to_hive.length() > detection_radius * 1.5:
			steering += to_hive.normalized() * 2.0

		# Apply steering
		vel += steering * delta * 5.0
		if vel.length() > boid_speed:
			vel = vel.normalized() * boid_speed

		boid["velocity"] = vel
		boid["node"].global_position += vel * delta

		# Keep above ground
		if boid["node"].global_position.y < 0.1:
			boid["node"].global_position.y = 0.1
			boid["velocity"].y = abs(boid["velocity"].y) * 0.5

	# Clean up dead boids
	for idx in range(to_remove.size() - 1, -1, -1):
		_boids.remove_at(to_remove[idx])


# ── Damage Interface ────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	_hive_health -= max(0.0, amount)
	if _hive_health <= 0.0:
		# Disperse all boids
		for b in _boids:
			if is_instance_valid(b["node"]):
				var tween := get_tree().create_tween()
				tween.tween_property(b["node"], "scale", Vector3.ZERO, 0.5)
				tween.tween_callback(b["node"].queue_free)
		_boids.clear()
		enemy_destroyed.emit(self)
		var die_tween := get_tree().create_tween()
		die_tween.tween_property(_hive_mesh, "scale", Vector3.ZERO, 1.0)
		die_tween.tween_callback(queue_free)


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


func configure(config: Dictionary) -> void:
	if config.has("boids"):
		max_boids = int(config["boids"])
	if config.has("damage"):
		boid_damage = float(config["damage"])

func apply_grid_config(config: Dictionary) -> void:
	configure(config)
