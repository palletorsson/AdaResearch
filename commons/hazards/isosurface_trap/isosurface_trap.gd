extends Area3D
class_name IsosurfaceTrap
## Isosurfaces sequence — blobby metaball zone hazard.
## ~6 charge points define a scalar field (sum of strength/distance).
## Charges drift toward the player, causing the surface to bulge.
## Player takes damage proportional to scalar field value at their position.
## Ring of indicator spheres marks the isosurface boundary.

signal enemy_destroyed(enemy: Node3D)

@export_group("Field")
@export var num_charges: int = 6
@export var field_radius: float = 2.0
@export var base_strength: float = 1.0
@export var threshold: float = 1.5
@export var drift_speed: float = 0.4
@export var charge_spread: float = 1.2

@export_group("Combat")
@export var damage_per_second: float = 12.0

@export_group("Boundary Ring")
@export var ring_samples: int = 24
@export var ring_radius: float = 1.5
@export var indicator_radius: float = 0.02

# ── State ──────────────────────────────────────────────────────────────
var _charges: Array[Dictionary] = []
# {node, mat, position, strength, drift_offset}
var _player_node: Node3D = null
var _player_inside: bool = false
var _damage_accumulator: float = 0.0
var _time: float = 0.0
var _field_at_player: float = 0.0

# Visual
var _ring_meshes: Array[MeshInstance3D] = []
var _ring_mats: Array[StandardMaterial3D] = []
var _label: Label3D = null
var _health: float = 0.0
@export var max_health: float = 100.0


func _ready() -> void:
	_health = max_health

	# Collision area covering the field radius
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = field_radius
	col.shape = shape
	add_child(col)

	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2  # Player layer

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_build_charges()
	_build_boundary_ring()
	_build_label()
	_find_player()
	add_to_group("enemy")


func _process(delta: float) -> void:
	_time += delta

	# ── Drift charges toward player ──────────────────────────────
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		var player_dir: Vector3 = to_player.normalized() if to_player.length() > 0.1 else Vector3.ZERO

		for c in _charges:
			# Drift toward player
			c["position"] += player_dir * drift_speed * delta

			# Also add gentle orbiting motion
			c["drift_offset"] += delta * 0.5
			var orbit := Vector3(
				cos(c["drift_offset"]) * 0.1,
				sin(c["drift_offset"] * 1.3) * 0.05,
				sin(c["drift_offset"]) * 0.1
			)
			c["position"] += orbit * delta

			# Constrain to field radius
			if c["position"].length() > charge_spread:
				c["position"] = c["position"].normalized() * charge_spread

			# Update mesh position and scale based on strength
			c["node"].position = c["position"]
			var s: float = 0.06 + c["strength"] * 0.04
			c["node"].scale = Vector3.ONE * (s / 0.06)

	# ── Compute field at player position ─────────────────────────
	_field_at_player = 0.0
	if is_instance_valid(_player_node):
		var player_local: Vector3 = _player_node.global_position - global_position
		_field_at_player = _compute_field(player_local)

	# ── Damage player based on field ─────────────────────────────
	if _player_inside and _field_at_player > threshold:
		var excess: float = _field_at_player - threshold
		_damage_accumulator += delta * damage_per_second * excess
		if _damage_accumulator >= 1.0:
			var dmg: float = floor(_damage_accumulator)
			_damage_accumulator -= dmg
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("apply_health_damage"):
				gm.apply_health_damage(dmg)

	# ── Update charge colors ─────────────────────────────────────
	for c in _charges:
		# Closer to player = more red
		var local_field: float = _field_at_player
		if local_field > threshold:
			var t: float = clampf((local_field - threshold) / 2.0, 0.0, 1.0)
			c["mat"].albedo_color = Color(0.2 + 0.7 * t, 0.7 * (1.0 - t), 0.8 * (1.0 - t), 0.5)
			c["mat"].emission = Color(0.8 * t, 0.1, 0.1)
			c["mat"].emission_energy_multiplier = 1.0 + t * 3.0
		else:
			c["mat"].albedo_color = Color(0.15, 0.6, 0.8, 0.5)
			c["mat"].emission = Color(0.05, 0.3, 0.5)
			c["mat"].emission_energy_multiplier = 1.0

	# ── Update boundary ring ─────────────────────────────────────
	_update_boundary_ring()

	# ── Label ─────────────────────────────────────────────────────
	if _label:
		_label.text = "FIELD: %.2f at player, THRESHOLD: %.2f" % [_field_at_player, threshold]


func _compute_field(pos: Vector3) -> float:
	var total: float = 0.0
	for c in _charges:
		var dist: float = pos.distance_to(c["position"])
		if dist < 0.05:
			dist = 0.05  # Prevent division by zero
		total += c["strength"] / dist
	return total


func _build_charges() -> void:
	for i in range(num_charges):
		var angle: float = (float(i) / float(num_charges)) * TAU
		var pos := Vector3(
			cos(angle) * charge_spread * 0.6,
			randf_range(-0.15, 0.15),
			sin(angle) * charge_spread * 0.6
		)
		var strength: float = base_strength + randf_range(-0.2, 0.3)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.6, 0.8, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.05, 0.3, 0.5)
		mat.emission_energy_multiplier = 1.0

		var sphere := SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		var mi := MeshInstance3D.new()
		mi.mesh = sphere
		mi.set_surface_override_material(0, mat)
		mi.position = pos
		mi.name = "Charge_%d" % i
		add_child(mi)

		_charges.append({
			"node": mi,
			"mat": mat,
			"position": pos,
			"strength": strength,
			"drift_offset": randf() * TAU,
		})


func _build_boundary_ring() -> void:
	for i in range(ring_samples):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.8, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(0.1, 0.5, 0.2)
		mat.emission_energy_multiplier = 1.5

		var sphere := SphereMesh.new()
		sphere.radius = indicator_radius
		sphere.height = indicator_radius * 2.0
		var mi := MeshInstance3D.new()
		mi.mesh = sphere
		mi.set_surface_override_material(0, mat)
		mi.name = "RingIndicator_%d" % i
		add_child(mi)

		_ring_meshes.append(mi)
		_ring_mats.append(mat)


func _update_boundary_ring() -> void:
	# Place indicator spheres at approximate isosurface boundary
	for i in range(ring_samples):
		var angle: float = (float(i) / float(ring_samples)) * TAU
		var dir := Vector3(cos(angle), 0, sin(angle))

		# Binary search along this direction for where field == threshold
		var lo: float = 0.1
		var hi: float = field_radius
		var mid: float = ring_radius

		for _step in range(8):
			mid = (lo + hi) * 0.5
			var test_pos: Vector3 = dir * mid
			var field_val: float = _compute_field(test_pos)
			if field_val > threshold:
				lo = mid
			else:
				hi = mid

		_ring_meshes[i].position = dir * mid

		# Color based on field value at this point
		var field_here: float = _compute_field(dir * mid)
		var diff: float = abs(field_here - threshold)
		if diff < 0.3:
			_ring_mats[i].albedo_color = Color(0.2, 0.9, 0.3)
			_ring_mats[i].emission = Color(0.1, 0.6, 0.2)
		else:
			_ring_mats[i].albedo_color = Color(0.5, 0.5, 0.2)
			_ring_mats[i].emission = Color(0.3, 0.3, 0.1)


func _build_label() -> void:
	_label = Label3D.new()
	_label.text = "ISOSURFACE"
	_label.font_size = 36
	_label.pixel_size = 0.003
	_label.modulate = Color(0.8, 0.9, 1.0)
	_label.position = Vector3(0, 1.5, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_player_node = body
		_damage_accumulator = 0.0


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false


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
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	_health -= max(0.0, amount)
	if _health <= 0.0:
		enemy_destroyed.emit(self)
		# Fade out charges and destroy
		for c in _charges:
			if is_instance_valid(c["node"]):
				c["node"].queue_free()
		for mi in _ring_meshes:
			if is_instance_valid(mi):
				mi.queue_free()
		queue_free()
	else:
		# Scatter charges outward on damage
		for c in _charges:
			var outward: Vector3 = c["position"].normalized()
			if outward.length() < 0.01:
				outward = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
			c["position"] += outward * 0.3

func configure(config: Dictionary) -> void:
	if config.has("damage"):
		damage_per_second = float(config["damage"])
	if config.has("threshold"):
		threshold = float(config["threshold"])
	if config.has("drift_speed"):
		drift_speed = float(config["drift_speed"])
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health

func apply_grid_config(config: Dictionary) -> void:
	configure(config)
