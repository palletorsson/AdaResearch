extends Node3D
class_name RecursionSpiral
## Recursive emergence sequence hazard — a Fibonacci spiral of shrinking sphere nodes.
## Spawns children recursively at golden-angle intervals (137.5 degrees).
## Each child is 0.618x parent size, up to depth 5.
## Destroying a parent destroys all children. Contact damage is proportional to 1/depth.

signal enemy_destroyed(enemy: Node3D)

@export_group("Spiral")
@export var root_radius: float = 0.2
@export var golden_ratio: float = 0.618
@export var golden_angle: float = 137.5  # degrees
@export var max_depth: int = 5
@export var max_nodes: int = 15
@export var spawn_interval: float = 0.8

@export_group("Combat")
@export var base_damage: float = 15.0
@export var contact_radius_multiplier: float = 1.5
@export var damage_cooldown: float = 0.5

@export_group("Appearance")
@export var base_color: Color = Color(0.6, 0.2, 0.9)
@export var emission_color: Color = Color(0.7, 0.3, 1.0)

# State
var _player_node: Node3D = null
var _time: float = 0.0
var _spawn_timer: float = 0.0
var _damage_timer: float = 0.0
var _health: float = 80.0

# Spiral node data
var _spiral_nodes: Array[Dictionary] = []
# Each: { "mesh": MeshInstance3D, "label": Label3D, "depth": int, "radius": float,
#          "angle": float, "parent_idx": int, "children": Array[int] }

# Fibonacci sequence for labels
var _fibonacci: Array[int] = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610]
var _next_fib_idx: int = 0

# Current angle accumulator for spiral placement
var _cumulative_angle: float = 0.0
var _spawn_distance: float = 0.15  # Distance from parent, grows with each spawn


func _ready() -> void:
	_build_root_node()
	_find_player()
	add_to_group("enemy")


func _process(delta: float) -> void:
	_time += delta
	_spawn_timer += delta
	_damage_timer = maxf(0.0, _damage_timer - delta)

	if not is_instance_valid(_player_node):
		_find_player()

	# Spawn new nodes on schedule
	if _spawn_timer >= spawn_interval and _spiral_nodes.size() < max_nodes:
		_spawn_timer = 0.0
		_spawn_next_node()

	# Pulse all nodes
	for i in range(_spiral_nodes.size()):
		var sn: Dictionary = _spiral_nodes[i]
		if not is_instance_valid(sn["mesh"]):
			continue
		var phase: float = _time * 2.0 + float(sn["depth"]) * 0.5
		var pulse: float = 0.7 + 0.3 * sin(phase)
		var mat: StandardMaterial3D = sn["mesh"].get_surface_override_material(0)
		if mat:
			mat.emission_energy_multiplier = pulse * 2.0
		sn["mesh"].scale = Vector3.ONE * sn["radius"] * (0.9 + 0.1 * sin(phase)) / root_radius

	# Contact damage
	if is_instance_valid(_player_node) and _damage_timer <= 0.0:
		var player_pos: Vector3 = _player_node.global_position
		for sn in _spiral_nodes:
			if not is_instance_valid(sn["mesh"]):
				continue
			var dist: float = sn["mesh"].global_position.distance_to(player_pos)
			var hit_radius: float = sn["radius"] * contact_radius_multiplier
			if dist < hit_radius:
				var dmg: float = base_damage / maxf(1.0, float(sn["depth"]))
				var gm = get_node_or_null("/root/GameManager")
				if gm and gm.has_method("apply_health_damage"):
					gm.apply_health_damage(dmg)
					_damage_timer = damage_cooldown
				break


func _build_root_node() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = root_radius
	sphere.height = root_radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8

	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.emission_enabled = true
	mat.emission = emission_color
	mat.emission_energy_multiplier = 2.0

	var mi := MeshInstance3D.new()
	mi.mesh = sphere
	mi.set_surface_override_material(0, mat)
	mi.position = Vector3(0.0, root_radius, 0.0)
	add_child(mi)

	# Fibonacci label
	var label := Label3D.new()
	label.text = str(_get_next_fibonacci())
	label.font_size = 20
	label.pixel_size = 0.002
	label.modulate = Color(1.0, 0.9, 0.5)
	label.position = Vector3(0.0, root_radius * 2.0 + 0.05, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mi.add_child(label)

	_spiral_nodes.append({
		"mesh": mi,
		"label": label,
		"depth": 1,
		"radius": root_radius,
		"angle": 0.0,
		"parent_idx": -1,
		"children": [],
	})


func _spawn_next_node() -> void:
	if _spiral_nodes.is_empty():
		return

	# Find the best parent: prefer shallowest depth that hasn't exceeded depth limit
	var parent_idx: int = -1
	for i in range(_spiral_nodes.size() - 1, -1, -1):
		var sn: Dictionary = _spiral_nodes[i]
		if sn["depth"] < max_depth and is_instance_valid(sn["mesh"]):
			parent_idx = i
			break

	if parent_idx < 0:
		return

	var parent: Dictionary = _spiral_nodes[parent_idx]
	var child_depth: int = parent["depth"] + 1
	var child_radius: float = parent["radius"] * golden_ratio

	# Golden angle placement
	_cumulative_angle += deg_to_rad(golden_angle)
	var distance: float = _spawn_distance * float(_spiral_nodes.size())
	var offset := Vector3(
		cos(_cumulative_angle) * distance,
		0.0,
		sin(_cumulative_angle) * distance
	)

	var sphere := SphereMesh.new()
	sphere.radius = child_radius
	sphere.height = child_radius * 2.0
	sphere.radial_segments = max(8, 16 - child_depth * 2)
	sphere.rings = max(4, 8 - child_depth)

	# Color shifts slightly with depth
	var depth_t: float = float(child_depth) / float(max_depth)
	var node_color: Color = base_color.lerp(Color(1.0, 0.5, 0.2), depth_t * 0.5)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = node_color
	mat.emission_enabled = true
	mat.emission = emission_color.lerp(Color(1.0, 0.6, 0.3), depth_t * 0.4)
	mat.emission_energy_multiplier = 2.0

	var mi := MeshInstance3D.new()
	mi.mesh = sphere
	mi.set_surface_override_material(0, mat)

	# Position relative to parent
	var parent_pos: Vector3 = parent["mesh"].position if is_instance_valid(parent["mesh"]) else Vector3.ZERO
	mi.position = parent_pos + offset
	mi.position.y = child_radius  # Keep on ground plane

	# Parent the mesh to this node so destroying parent destroys children
	add_child(mi)

	# Fibonacci label
	var label := Label3D.new()
	label.text = str(_get_next_fibonacci())
	label.font_size = max(12, 20 - child_depth * 2)
	label.pixel_size = 0.002
	label.modulate = Color(1.0, 0.9, 0.5)
	label.position = Vector3(0.0, child_radius + 0.04, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mi.add_child(label)

	var new_idx: int = _spiral_nodes.size()
	parent["children"].append(new_idx)

	_spiral_nodes.append({
		"mesh": mi,
		"label": label,
		"depth": child_depth,
		"radius": child_radius,
		"angle": _cumulative_angle,
		"parent_idx": parent_idx,
		"children": [],
	})


func _get_next_fibonacci() -> int:
	var val: int = _fibonacci[_next_fib_idx % _fibonacci.size()]
	_next_fib_idx += 1
	return val


func _destroy_node_recursive(idx: int) -> void:
	if idx < 0 or idx >= _spiral_nodes.size():
		return
	var sn: Dictionary = _spiral_nodes[idx]

	# Destroy children first
	var children_copy: Array = sn["children"].duplicate()
	for child_idx in children_copy:
		_destroy_node_recursive(child_idx)

	# Destroy this node's mesh
	if is_instance_valid(sn["mesh"]):
		var tween := get_tree().create_tween()
		tween.tween_property(sn["mesh"], "scale", Vector3.ZERO, 0.3)
		tween.tween_callback(sn["mesh"].queue_free)

	sn["children"].clear()


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
	_health -= maxf(0.0, amount)
	if _health <= 0.0:
		# Destroy entire spiral from root
		for i in range(_spiral_nodes.size()):
			var sn: Dictionary = _spiral_nodes[i]
			if is_instance_valid(sn["mesh"]):
				var tween := get_tree().create_tween()
				tween.tween_property(sn["mesh"], "scale", Vector3.ZERO, 0.4 + float(i) * 0.1)
				tween.tween_callback(sn["mesh"].queue_free)
		enemy_destroyed.emit(self)
		var die_tween := get_tree().create_tween()
		die_tween.tween_interval(2.0)
		die_tween.tween_callback(queue_free)

func configure(config: Dictionary) -> void:
	if config.has("damage"):
		base_damage = float(config["damage"])
	if config.has("health"):
		_health = float(config["health"])
	if config.has("max_depth"):
		max_depth = int(config["max_depth"])

func apply_grid_config(config: Dictionary) -> void:
	configure(config)
