# @identity
# essence: impulse = m * delta_v -- central body with 5 tethered blocks demonstrating momentum conservation
# desire: blocks crash and bounce on tethers, impulse arrows tracing each collision's physics
# critical_parameter: tether length / block mass -- constrain the collision space; impulse arrows show transfer
# triggers: player proximity triggers block release; physics simulation drives collisions continuously
# emerges: Newton's third law made ambulatory -- every action-reaction pair visible as arrow vectors
# needs: HazardCreatureBase [has]; tethered block physics [has]; impulse visualization [has]; VR interaction [missing]
# relationships: embodies physics simulation sequence; pairs with spring_mass_bouncer (impulse vs elasticity)
# truth: momentum is always conserved -- the impulse arrows prove it whether you believe the math or not.

extends HazardCreatureBase
class_name CollisionCrasher
## Physics simulation sequence — central body with 5 tethered BoxMesh blocks.
## Blocks orbit/bounce around the body with simulated spring-tether physics.
## Elastic collisions between blocks conserve momentum. Impulse arrows
## appear on player collision. During CHASE: tether radius increases.

@export_group("Physics Blocks")
@export var num_blocks: int = 5
@export var block_size: float = 0.08
@export var tether_radius: float = 0.4
@export var tether_k: float = 15.0       # Spring constant for tether
@export var block_damping: float = 0.5
@export var chase_tether_bonus: float = 0.3

@export_group("Combat")
@export var block_damage: float = 10.0

# ── State ──────────────────────────────────────────────────────────────
var _blocks: Array[Dictionary] = []
# {mesh, mat, position, velocity, mass, color}
var _body_mesh: MeshInstance3D = null
var _body_mat: StandardMaterial3D = null
var _impulse_arrows: Array[Dictionary] = []  # {mesh, lifetime}
var _label: Label3D = null
var _total_ke: float = 0.0
var _total_momentum: float = 0.0
var _leg_roots: Array[Node3D] = []
var _walk_phase: float = 0.0

var _block_colors: Array[Color] = [
	Color(0.9, 0.2, 0.15),   # Red
	Color(0.95, 0.55, 0.1),  # Orange
	Color(0.95, 0.85, 0.15), # Yellow
	Color(0.95, 0.45, 0.35), # Coral
	Color(0.95, 0.55, 0.5),  # Salmon
]


func _on_ready() -> void:
	max_health = 85.0
	_health = max_health
	chase_speed = 3.0
	patrol_speed = 1.5
	contact_damage = 10.0
	detection_radius = 8.0


func _create_materials() -> void:
	_body_mat = _make_material(Color(0.3, 0.3, 0.35), Color(0.15, 0.15, 0.2))


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	col.shape = shape
	col.position.y = 0.45
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.45

	# Central body
	var body := SphereMesh.new()
	body.radius = 0.12
	body.height = 0.24
	_body_mesh = _add_mesh(body, _body_mat)
	_body_mesh.name = "CentralBody"

	# Create physics blocks
	for i in range(num_blocks):
		var color: Color = _block_colors[i % _block_colors.size()]
		var mat := _make_material(color, color * 0.5)

		var box := BoxMesh.new()
		box.size = Vector3(block_size, block_size, block_size)
		var mi := MeshInstance3D.new()
		mi.mesh = box
		mi.set_surface_override_material(0, mat)
		mi.name = "Block_%d" % i
		_mesh_root.add_child(mi)

		# Initial position: distribute around the center
		var angle: float = (float(i) / float(num_blocks)) * TAU
		var start_pos := Vector3(
			cos(angle) * tether_radius * 0.5,
			randf_range(-0.1, 0.1),
			sin(angle) * tether_radius * 0.5
		)

		# Initial velocity: tangential
		var tangent := Vector3(-sin(angle), 0, cos(angle))
		var start_vel: Vector3 = tangent * randf_range(0.5, 1.5)

		_blocks.append({
			"mesh": mi,
			"mat": mat,
			"position": start_pos,
			"velocity": start_vel,
			"mass": 1.0 + randf_range(-0.2, 0.2),
			"color": color,
		})

	# 2 legs
	for i in range(2):
		var root := Node3D.new()
		root.name = "Leg_%d" % i
		root.position = Vector3((i - 0.5) * 0.12, -0.35, 0)
		_mesh_root.add_child(root)
		_leg_roots.append(root)

		var cyl := CylinderMesh.new()
		cyl.height = 0.2
		cyl.top_radius = 0.025
		cyl.bottom_radius = 0.018
		var leg_mat := _make_material(Color(0.25, 0.25, 0.3), Color.BLACK)
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.set_surface_override_material(0, leg_mat)
		mi.position = Vector3(0, -0.1, 0)
		root.add_child(mi)

	# Label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 36
	_label.pixel_size = 0.003
	_label.position = Vector3(0, 0.5, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.85)
	_mesh_root.add_child(_label)


func _process_visual(delta: float) -> void:
	var current_tether: float = tether_radius
	if _state == BaseState.CHASE:
		current_tether += chase_tether_bonus

	_total_ke = 0.0
	var total_p := Vector3.ZERO

	# ── Tether spring forces ──────────────────────────────────────
	for b in _blocks:
		var pos: Vector3 = b["position"]
		var dist: float = pos.length()

		# Spring force toward center if outside tether
		if dist > current_tether:
			var displacement: float = dist - current_tether
			var force: Vector3 = -pos.normalized() * tether_k * displacement
			var acc: Vector3 = force / b["mass"]
			b["velocity"] += acc * delta

		# Gentle centering spring (always)
		b["velocity"] -= pos * 0.5 * delta

		# Damping
		b["velocity"] *= (1.0 - block_damping * delta)

	# ── Elastic collisions between blocks ─────────────────────────
	for i in range(_blocks.size()):
		for j in range(i + 1, _blocks.size()):
			var diff: Vector3 = _blocks[j]["position"] - _blocks[i]["position"]
			var dist: float = diff.length()
			var min_dist: float = block_size * 1.2

			if dist < min_dist and dist > 0.001:
				var normal: Vector3 = diff.normalized()
				var rel_vel: Vector3 = _blocks[i]["velocity"] - _blocks[j]["velocity"]
				var vel_along_normal: float = rel_vel.dot(normal)

				# Only resolve if blocks are approaching
				if vel_along_normal > 0:
					var m1: float = _blocks[i]["mass"]
					var m2: float = _blocks[j]["mass"]
					var impulse: float = (2.0 * vel_along_normal) / (m1 + m2)

					_blocks[i]["velocity"] -= normal * impulse * m2
					_blocks[j]["velocity"] += normal * impulse * m1

				# Separate overlapping blocks
				var overlap: float = min_dist - dist
				_blocks[i]["position"] -= normal * overlap * 0.5
				_blocks[j]["position"] += normal * overlap * 0.5

	# ── Integrate positions ───────────────────────────────────────
	for b in _blocks:
		b["position"] += b["velocity"] * delta
		b["mesh"].position = b["position"]

		var speed: float = b["velocity"].length()
		_total_ke += 0.5 * b["mass"] * speed * speed
		total_p += b["velocity"] * b["mass"]

	_total_momentum = total_p.length()

	# ── Walk animation ────────────────────────────────────────────
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 5.0
		for i in range(_leg_roots.size()):
			_leg_roots[i].rotation.x = sin(_walk_phase + float(i) * PI) * 0.3

	# ── Update impulse arrows ────────────────────────────────────
	var remove_arrows: Array[int] = []
	for i in range(_impulse_arrows.size()):
		_impulse_arrows[i]["lifetime"] -= delta
		if _impulse_arrows[i]["lifetime"] <= 0.0:
			if is_instance_valid(_impulse_arrows[i]["mesh"]):
				_impulse_arrows[i]["mesh"].queue_free()
			remove_arrows.append(i)
		else:
			# Fade out
			var t: float = _impulse_arrows[i]["lifetime"]
			if is_instance_valid(_impulse_arrows[i]["mesh"]):
				var mat: StandardMaterial3D = _impulse_arrows[i]["mesh"].get_surface_override_material(0)
				if mat:
					mat.albedo_color.a = t

	for idx in range(remove_arrows.size() - 1, -1, -1):
		_impulse_arrows.remove_at(remove_arrows[idx])

	# ── Check block proximity to player for impulse visualization ─
	if is_instance_valid(_player_node):
		for b in _blocks:
			var block_world: Vector3 = b["mesh"].global_position
			var to_player: float = block_world.distance_to(_player_node.global_position)
			if to_player < 0.3:
				_spawn_impulse_arrow(b["position"], b["velocity"])

	# ── Label ─────────────────────────────────────────────────────
	if _label:
		_label.text = "KE: %.2f, p: %.2f" % [_total_ke, _total_momentum]


func _spawn_impulse_arrow(pos: Vector3, vel: Vector3) -> void:
	if vel.length() < 0.1:
		return

	var cyl := CylinderMesh.new()
	cyl.height = 0.2
	cyl.top_radius = 0.003
	cyl.bottom_radius = 0.015
	var arrow_mat := _make_material(Color(1, 1, 1), Color(0.8, 0.8, 0.8), 0.8)
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, arrow_mat)
	mi.position = pos
	_mesh_root.add_child(mi)

	# Orient arrow along velocity
	var dir: Vector3 = vel.normalized()
	if dir.length() > 0.01:
		var up := Vector3.UP
		if abs(dir.dot(up)) > 0.95:
			up = Vector3.RIGHT
		mi.look_at_from_position(pos, pos + dir, up)
		mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	_impulse_arrows.append({
		"mesh": mi,
		"lifetime": 1.0,
	})


func _on_damaged(_amount: float) -> void:
	# Blocks scatter outward on damage
	for b in _blocks:
		var outward: Vector3 = b["position"].normalized()
		if outward.length() < 0.01:
			outward = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
		b["velocity"] += outward * 4.0
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.CHASE:
		# Give blocks extra energy when entering chase
		for b in _blocks:
			b["velocity"] *= 1.5
