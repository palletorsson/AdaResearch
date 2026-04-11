# @identity
# essence: self_reference(t) -> contradiction(t) -- creature that contradicts itself, two ghosts swapping
# desire: two ghostly forms alternating reality -- the liar paradox given a body and a lunge
# critical_parameter: _a_is_real -- which ghost is real; swap_timer oscillates; only real ghost can be hit
# triggers: swap_timer alternates real/ghost; lunge_timer drives attacks; wrong ghost is invulnerable
# emerges: self-reference as combat -- the paradox is not a puzzle to solve but a state to survive
# needs: HazardCreatureBase [has]; dual ghost nodes [has]; swap logic [has]; lunge [has]; VR interaction [missing]
# relationships: embodies foundationscrisis; pairs with escher_stairwalker (logical vs geometric paradox)
# truth: the creature that contradicts itself cannot be defeated by consistency -- act in paradox.

extends HazardCreatureBase
class_name ParadoxStalker
## Foundations Crisis hazard — a creature that contradicts itself.
## Two overlapping ghost silhouettes swap which is "real."
## Zeno's paradox: halves the distance but never arrives.
## Teaches paradoxes, Gödel, limits of formalization.

@export_group("Paradox")
@export var ghost_separation: float = 0.6
@export var swap_interval: float = 3.0
@export var zeno_chance: float = 0.15
@export var lunge_speed: float = 5.0
@export var lunge_duration: float = 0.4

@export_group("Appearance")
@export var ghost_a_color: Color = Color(0.8, 0.2, 0.9, 0.5)
@export var ghost_b_color: Color = Color(0.2, 0.8, 0.9, 0.5)
@export var real_emission: Color = Color(1.0, 0.4, 1.0)

# State
var _ghost_a: Node3D = null
var _ghost_b: Node3D = null
var _a_is_real: bool = true
var _swap_timer: float = 0.0
var _lunge_timer: float = 0.0
var _is_lunging: bool = false
var _lunge_dir: Vector3 = Vector3.ZERO
var _mat_a: StandardMaterial3D
var _mat_b: StandardMaterial3D
var _label: Label3D = null
var _ghost_a_offset: Vector3 = Vector3.ZERO
var _ghost_b_offset: Vector3 = Vector3.ZERO


func _on_ready() -> void:
	add_to_group("paradox_enemy")


func _create_materials() -> void:
	_mat_a = _make_material(ghost_a_color, real_emission, ghost_a_color.a)
	_mat_b = _make_material(ghost_b_color, Color.BLACK, ghost_b_color.a)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.4
	add_child(col)


func _build_mesh() -> void:
	# Ghost A
	_ghost_a = Node3D.new()
	_ghost_a.name = "GhostA"
	_mesh_root.add_child(_ghost_a)
	_build_humanoid(_ghost_a, _mat_a)

	# Ghost B (mirror)
	_ghost_b = Node3D.new()
	_ghost_b.name = "GhostB"
	_mesh_root.add_child(_ghost_b)
	_build_humanoid(_ghost_b, _mat_b)

	_ghost_a_offset = Vector3(ghost_separation * 0.5, 0.0, 0.0)
	_ghost_b_offset = Vector3(-ghost_separation * 0.5, 0.0, 0.0)
	_ghost_a.position = _ghost_a_offset
	_ghost_b.position = _ghost_b_offset

	# Label
	_label = Label3D.new()
	_label.text = "REAL: A"
	_label.font_size = 22
	_label.pixel_size = 0.002
	_label.modulate = ghost_a_color
	_label.position = Vector3(0.0, 1.0, 0.05)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mesh_root.add_child(_label)


func _build_humanoid(parent: Node3D, mat: StandardMaterial3D) -> void:
	# Torso
	var torso := BoxMesh.new()
	torso.size = Vector3(0.15, 0.2, 0.08)
	var t := MeshInstance3D.new()
	t.mesh = torso
	t.set_surface_override_material(0, mat)
	t.position = Vector3(0.0, 0.45, 0.0)
	parent.add_child(t)

	# Head
	var head := SphereMesh.new()
	head.radius = 0.06
	head.height = 0.12
	var h := MeshInstance3D.new()
	h.mesh = head
	h.set_surface_override_material(0, mat)
	h.position = Vector3(0.0, 0.62, 0.0)
	parent.add_child(h)

	# Legs
	var leg := CylinderMesh.new()
	leg.top_radius = 0.02
	leg.bottom_radius = 0.025
	leg.height = 0.25
	for side in [-1.0, 1.0]:
		var l := MeshInstance3D.new()
		l.mesh = leg
		l.set_surface_override_material(0, mat)
		l.position = Vector3(side * 0.05, 0.2, 0.0)
		parent.add_child(l)

	# Arms
	var arm := CylinderMesh.new()
	arm.top_radius = 0.015
	arm.bottom_radius = 0.02
	arm.height = 0.2
	for side in [-1.0, 1.0]:
		var a := MeshInstance3D.new()
		a.mesh = arm
		a.set_surface_override_material(0, mat)
		a.position = Vector3(side * 0.12, 0.45, 0.0)
		a.rotation.z = side * 0.3
		parent.add_child(a)


func _process_visual(delta: float) -> void:
	_swap_timer += delta

	# Swap ghosts periodically
	if _swap_timer >= swap_interval:
		_swap_timer = 0.0
		_a_is_real = not _a_is_real

		# Update materials
		_mat_a.emission_enabled = _a_is_real
		_mat_a.albedo_color.a = 0.7 if _a_is_real else 0.3
		_mat_b.emission_enabled = not _a_is_real
		_mat_b.albedo_color.a = 0.7 if not _a_is_real else 0.3

		if _label:
			_label.text = "REAL: %s" % ("A" if _a_is_real else "B")
			_label.modulate = ghost_a_color if _a_is_real else ghost_b_color

		# Zeno chance
		if randf() < zeno_chance and is_instance_valid(_player_node):
			_zeno_halve()

	# Ghost movement: one approaches, other retreats
	if _state == BaseState.CHASE and is_instance_valid(_player_node):
		var dir: Vector3 = _get_player_direction()
		_ghost_a_offset = _ghost_a_offset.lerp(dir * ghost_separation * 0.5, delta * 2.0)
		_ghost_b_offset = _ghost_b_offset.lerp(-dir * ghost_separation * 0.5, delta * 2.0)

	if _ghost_a:
		_ghost_a.position = _ghost_a.position.lerp(_ghost_a_offset, delta * 3.0)
	if _ghost_b:
		_ghost_b.position = _ghost_b.position.lerp(_ghost_b_offset, delta * 3.0)

	# Lunge handling
	if _is_lunging:
		_lunge_timer -= delta
		velocity = _lunge_dir * lunge_speed
		if _lunge_timer <= 0.0:
			_is_lunging = false
			velocity = Vector3.ZERO


func _process_attack(delta: float) -> void:
	if not _is_lunging and _state_time < 0.1:
		_is_lunging = true
		_lunge_timer = lunge_duration
		_lunge_dir = _get_player_direction()
	if _state_time >= lunge_duration + 0.5:
		_set_state(BaseState.CHASE)


func _process_chase(delta: float) -> void:
	super._process_chase(delta)
	# Periodically lunge
	if _state_time > 2.0 and fmod(_state_time, 3.5) < delta:
		_set_state(BaseState.ATTACK)


func _zeno_halve() -> void:
	# Halve the distance to the player (teleport closer)
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		global_position += to_player * 0.5


func _on_damaged(amount: float) -> void:
	# Only take damage if hit matches the "real" ghost
	# (50/50 since we can't determine which side was hit)
	if randf() > 0.5:
		# Missed the real one — restore health
		_health += amount
	_set_state(BaseState.STUNNED)
