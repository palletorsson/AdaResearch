extends HazardCreatureBase
class_name HullCrusher
## Computational geometry sequence — morphing convex polyhedron creature.
## ~10 orbiting point-nodes define an approximate hull (IcoSphereMesh scales
## to their bounding extent). Points can be fired as projectiles toward
## the player, shrinking the hull. Points respawn after a delay.

@export_group("Hull")
@export var num_points: int = 10
@export var orbit_radius: float = 0.6
@export var fire_interval: float = 2.0
@export var point_respawn_time: float = 4.0
@export var projectile_speed: float = 6.0
@export var projectile_damage: float = 12.0

# ── State ──────────────────────────────────────────────────────────────
var _points: Array[Dictionary] = []  # {node, mat, orbit_a, orbit_b, orbit_phase, active, respawn_timer}
var _hull_mesh: MeshInstance3D = null
var _hull_mat: StandardMaterial3D = null
var _label: Label3D = null
var _fire_timer: float = 0.0
var _projectiles: Array[Dictionary] = []  # {node, velocity, lifetime}
var _leg_roots: Array[Node3D] = []
var _walk_phase: float = 0.0


func _on_ready() -> void:
	max_health = 90.0
	_health = max_health
	chase_speed = 2.8
	patrol_speed = 1.4
	contact_damage = 15.0
	detection_radius = 9.0


func _create_materials() -> void:
	_hull_mat = _make_material(
		Color(0.15, 0.55, 0.5),
		Color(0.1, 0.4, 0.4),
		0.45
	)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.45
	col.shape = shape
	col.position.y = 0.5
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.5

	# Hull body — IcoSphereMesh scaled dynamically
	var ico := SphereMesh.new()
	ico.radius = 0.3
	ico.height = 0.6
	_hull_mesh = _add_mesh(ico, _hull_mat)
	_hull_mesh.name = "HullBody"

	# Create orbiting points
	for i in range(num_points):
		var mat := _make_material(Color(1.0, 0.9, 0.15), Color(0.9, 0.8, 0.1))
		var sphere := SphereMesh.new()
		sphere.radius = 0.04
		sphere.height = 0.08
		var mi := _add_mesh(sphere, mat)
		mi.name = "Point_%d" % i

		var entry: Dictionary = {
			"node": mi,
			"mat": mat,
			"orbit_a": randf_range(0.3, orbit_radius),
			"orbit_b": randf_range(0.2, orbit_radius * 0.8),
			"orbit_phase": randf() * TAU,
			"orbit_speed": randf_range(0.8, 1.5),
			"tilt": randf_range(-0.5, 0.5),
			"active": true,
			"respawn_timer": 0.0,
		}
		_points.append(entry)

	# 2 legs
	for i in range(2):
		_build_leg(i)

	# Label
	_label = Label3D.new()
	_label.text = ""
	_label.font_size = 36
	_label.pixel_size = 0.003
	_label.position = Vector3(0, 0.6, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1, 1, 1, 0.85)
	_mesh_root.add_child(_label)


func _build_leg(index: int) -> void:
	var root := Node3D.new()
	root.name = "Leg_%d" % index
	var x_off: float = (index - 0.5) * 0.2
	root.position = Vector3(x_off, -0.35, 0)
	_mesh_root.add_child(root)
	_leg_roots.append(root)

	var cyl := CylinderMesh.new()
	cyl.height = 0.25
	cyl.top_radius = 0.03
	cyl.bottom_radius = 0.02
	var leg_mat := _make_material(Color(0.2, 0.4, 0.35), Color.BLACK)
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.set_surface_override_material(0, leg_mat)
	mi.position = Vector3(0, -0.125, 0)
	root.add_child(mi)


func _process_visual(delta: float) -> void:
	var active_count: int = 0
	var max_extent: float = 0.15

	# Update point orbits
	for p in _points:
		if not p["active"]:
			p["respawn_timer"] -= delta
			if p["respawn_timer"] <= 0.0:
				p["active"] = true
				p["node"].visible = true
			continue

		active_count += 1
		p["orbit_phase"] += delta * p["orbit_speed"]
		var phase: float = p["orbit_phase"]
		var pos := Vector3(
			cos(phase) * p["orbit_a"],
			sin(phase * 1.3) * p["tilt"],
			sin(phase) * p["orbit_b"]
		)
		p["node"].position = pos
		var ext: float = pos.length()
		if ext > max_extent:
			max_extent = ext

	# Scale hull body to approximate hull size
	var scale_factor: float = max_extent * 1.2
	_hull_mesh.scale = Vector3(scale_factor, scale_factor, scale_factor) / 0.3

	# Approximate volume
	var volume: float = (4.0 / 3.0) * PI * pow(max_extent, 3)

	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 5.0
		for i in range(_leg_roots.size()):
			var phase_offset: float = float(i) * PI
			_leg_roots[i].rotation.x = sin(_walk_phase + phase_offset) * 0.3

	# Update label
	if _label:
		_label.text = "HULL: %d points, V=%.2f" % [active_count, volume]

	# Update projectiles
	var remove_list: Array[int] = []
	for i in range(_projectiles.size()):
		var proj: Dictionary = _projectiles[i]
		proj["lifetime"] -= delta
		if proj["lifetime"] <= 0.0 or not is_instance_valid(proj["node"]):
			remove_list.append(i)
			if is_instance_valid(proj["node"]):
				proj["node"].queue_free()
			continue
		var node: Node3D = proj["node"]
		node.global_position += proj["velocity"] * delta

		# Check if hit player
		if is_instance_valid(_player_node):
			var dist: float = node.global_position.distance_to(_player_node.global_position)
			if dist < 0.3:
				_try_damage_target(_player_node)
				node.queue_free()
				remove_list.append(i)

	for idx in range(remove_list.size() - 1, -1, -1):
		_projectiles.remove_at(remove_list[idx])

	# Fire timer during chase
	if _state == BaseState.CHASE:
		_fire_timer += delta
		if _fire_timer >= fire_interval:
			_fire_timer = 0.0
			_fire_point()


func _fire_point() -> void:
	if not is_instance_valid(_player_node):
		return

	# Find an active point to fire
	var candidates: Array[int] = []
	for i in range(_points.size()):
		if _points[i]["active"]:
			candidates.append(i)

	if candidates.is_empty():
		return

	var idx: int = candidates[randi() % candidates.size()]
	var p: Dictionary = _points[idx]
	p["active"] = false
	p["node"].visible = false
	p["respawn_timer"] = point_respawn_time

	# Create projectile
	var dir: Vector3 = (_player_node.global_position - global_position).normalized()
	var proj_mesh := SphereMesh.new()
	proj_mesh.radius = 0.05
	proj_mesh.height = 0.1
	var proj_mat := _make_material(Color(1.0, 0.8, 0.0), Color(1.0, 0.7, 0.0))
	var mi := MeshInstance3D.new()
	mi.mesh = proj_mesh
	mi.set_surface_override_material(0, proj_mat)
	mi.global_position = global_position + _mesh_root.position
	get_parent().add_child(mi)

	_projectiles.append({
		"node": mi,
		"velocity": dir * projectile_speed,
		"lifetime": 3.0,
	})


func _on_damaged(_amount: float) -> void:
	# Excite all point orbits
	for p in _points:
		p["orbit_speed"] *= 1.5
	_set_state(BaseState.STUNNED)


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.PATROL:
		_fire_timer = 0.0
		for p in _points:
			p["orbit_speed"] = randf_range(0.8, 1.5)
