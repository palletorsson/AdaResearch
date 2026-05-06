# @identity
# essence: cut(head) -> spawn(2 * head) -- multi-headed hydra with fractal branching to depth 3
# desire: cut one head and two grow back, each smaller, inheriting the parent's attack -- self-similarity
# critical_parameter: fractal depth / head count -- cutting increases heads exponentially until max depth
# triggers: damage to a head triggers split; each new head inherits scaled attack; depth limits growth
# emerges: the punishment for attacking IS more attackers -- self-similarity as defense strategy
# needs: HazardCreatureBase [has]; head/neck mesh generation [has]; fractal splitting [has]; VR interaction [missing]
# relationships: embodies fractals sequence; pairs with recursion_spiral (branching vs spiraling)
# truth: the hydra is the fractal -- damage at any scale reproduces the pattern at smaller scale.

extends HazardCreatureBase
class_name FractalHydra
## Fractals sequence — multi-headed hydra with fractal branching.
## Starts with 2 heads; when damaged, a random head splits into 2 at half
## size (max depth 3, so up to 8 tiny heads from one original). Each head
## bites independently. More heads = faster attacks but less damage each.
## Creature dies when ALL heads reach minimum size and are destroyed.

@export_group("Hydra")
@export var max_depth: int = 3
@export var base_head_size: float = 0.15
@export var neck_length: float = 0.35
@export var bite_range: float = 0.25
@export var bite_speed: float = 3.0
@export var base_bite_damage: float = 12.0

# ── State ──────────────────────────────────────────────────────────────
var _heads: Array[Dictionary] = []
# {mesh: MeshInstance3D, neck: MeshInstance3D, size: float, depth: int,
#  angle: float, bite_timer: float, bite_phase: float, alive: bool}
var _body_mesh: MeshInstance3D = null
var _body_mat: StandardMaterial3D = null
var _head_mats: Array[StandardMaterial3D] = []
var _neck_mat: StandardMaterial3D = null
var _label: Label3D = null
var _total_bite_timer: float = 0.0
var _leg_roots: Array[Node3D] = []
var _walk_phase: float = 0.0


func _on_ready() -> void:
	max_health = 120.0
	_health = max_health
	chase_speed = 2.0
	patrol_speed = 1.2
	contact_damage = 10.0
	detection_radius = 8.0

	# Start with 2 heads
	_add_head(0.0, base_head_size, 0, -0.5)
	_add_head(0.0, base_head_size, 0, 0.5)


func _create_materials() -> void:
	_body_mat = _make_material(Color(0.1, 0.3, 0.1), Color(0.05, 0.15, 0.05))
	_neck_mat = _make_material(Color(0.35, 0.22, 0.1), Color.BLACK)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.35
	col.shape = shape
	col.position.y = 0.4
	add_child(col)


func _build_mesh() -> void:
	_mesh_root.position.y = 0.4

	# Central body
	var body := SphereMesh.new()
	body.radius = 0.2
	body.height = 0.4
	_body_mesh = _add_mesh(body, _body_mat)
	_body_mesh.name = "Body"

	# 2 legs
	for i in range(2):
		var root := Node3D.new()
		root.name = "Leg_%d" % i
		root.position = Vector3((i - 0.5) * 0.15, -0.3, 0)
		_mesh_root.add_child(root)
		_leg_roots.append(root)

		var cyl := CylinderMesh.new()
		cyl.height = 0.2
		cyl.top_radius = 0.025
		cyl.bottom_radius = 0.018
		var leg_mat := _make_material(Color(0.1, 0.25, 0.1), Color.BLACK)
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


func _add_head(base_angle: float, size: float, depth: int, angle_offset: float) -> void:
	var angle: float = base_angle + angle_offset

	# Head material — brighter green at higher depth
	var green_intensity: float = 0.4 + 0.2 * depth
	var head_mat := _make_material(
		Color(0.2, green_intensity, 0.1),
		Color(0.1, green_intensity * 0.8, 0.05)
	)
	_head_mats.append(head_mat)

	# Neck
	var neck_cyl := CylinderMesh.new()
	var neck_len: float = neck_length * (1.0 - depth * 0.15)
	neck_cyl.height = neck_len
	neck_cyl.top_radius = 0.015 * (1.0 - depth * 0.2)
	neck_cyl.bottom_radius = 0.025 * (1.0 - depth * 0.15)
	var neck_mi := MeshInstance3D.new()
	neck_mi.mesh = neck_cyl
	neck_mi.set_surface_override_material(0, _neck_mat)
	_mesh_root.add_child(neck_mi)

	# Head sphere
	var head_sphere := SphereMesh.new()
	head_sphere.radius = size
	head_sphere.height = size * 2.0
	var head_mi := MeshInstance3D.new()
	head_mi.mesh = head_sphere
	head_mi.set_surface_override_material(0, head_mat)
	_mesh_root.add_child(head_mi)

	var entry: Dictionary = {
		"mesh": head_mi,
		"neck": neck_mi,
		"size": size,
		"depth": depth,
		"angle": angle,
		"bite_timer": randf_range(0.5, 2.0),
		"bite_phase": 0.0,
		"alive": true,
	}
	_heads.append(entry)


func _process_visual(delta: float) -> void:
	var alive_count: int = 0
	var max_depth_val: int = 0

	for i in range(_heads.size()):
		var h: Dictionary = _heads[i]
		if not h["alive"]:
			h["mesh"].visible = false
			h["neck"].visible = false
			continue

		alive_count += 1
		if h["depth"] > max_depth_val:
			max_depth_val = h["depth"]

		# Position neck and head based on angle
		var ang: float = h["angle"]
		var neck_len: float = neck_length * (1.0 - h["depth"] * 0.15)
		var base_dir := Vector3(sin(ang), 0.5, cos(ang)).normalized()

		# Bite animation — head extends toward player briefly
		var bite_extend: float = 0.0
		if h["bite_phase"] > 0.0:
			h["bite_phase"] -= delta * bite_speed
			bite_extend = sin(h["bite_phase"] * PI) * bite_range
			if h["bite_phase"] <= 0.0:
				h["bite_phase"] = 0.0

		var neck_end: Vector3 = base_dir * (neck_len + bite_extend)
		h["neck"].position = neck_end * 0.5
		# Orient neck cylinder
		if neck_end.length() > 0.01:
			var up := Vector3.UP
			if abs(neck_end.normalized().dot(up)) > 0.95:
				up = Vector3.RIGHT
			h["neck"].look_at_from_position(h["neck"].position, h["neck"].position + neck_end.normalized(), up)
			h["neck"].rotate_object_local(Vector3.RIGHT, PI / 2.0)

		h["mesh"].position = neck_end

		# Bobbing animation
		h["angle"] += delta * 0.3 * (1.0 + h["depth"] * 0.2)

	# Walk animation
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 4.0
		for i in range(_leg_roots.size()):
			var phase_offset: float = float(i) * PI
			_leg_roots[i].rotation.x = sin(_walk_phase + phase_offset) * 0.25

	# Attack logic during chase — heads bite
	if _state == BaseState.CHASE:
		_total_bite_timer += delta
		var bite_interval: float = 2.0 / max(1.0, float(alive_count))
		if _total_bite_timer >= bite_interval and is_instance_valid(_player_node):
			_total_bite_timer = 0.0
			_trigger_bite()

	# Label
	if _label:
		_label.text = "HEADS: %d, DEPTH: %d" % [alive_count, max_depth_val]


func _trigger_bite() -> void:
	# Pick a random alive head to bite
	var alive_indices: Array[int] = []
	for i in range(_heads.size()):
		if _heads[i]["alive"]:
			alive_indices.append(i)

	if alive_indices.is_empty():
		return

	var idx: int = alive_indices[randi() % alive_indices.size()]
	_heads[idx]["bite_phase"] = 1.0

	# Check if player is close enough for damage
	if is_instance_valid(_player_node):
		var dist: float = _get_player_distance()
		var head_reach: float = neck_length + bite_range + 0.3
		if dist < head_reach:
			var alive_count: int = alive_indices.size()
			var dmg: float = base_bite_damage / max(1.0, float(alive_count) * 0.5)
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("apply_health_damage"):
				gm.apply_health_damage(dmg)


func _on_damaged(_amount: float) -> void:
	# Instead of stunned: split a random head
	var alive_heads: Array[int] = []
	for i in range(_heads.size()):
		if _heads[i]["alive"] and _heads[i]["depth"] < max_depth:
			alive_heads.append(i)

	if alive_heads.is_empty():
		# All heads are at max depth — destroy a random one
		var min_heads: Array[int] = []
		for i in range(_heads.size()):
			if _heads[i]["alive"]:
				min_heads.append(i)
		if not min_heads.is_empty():
			var kill_idx: int = min_heads[randi() % min_heads.size()]
			_heads[kill_idx]["alive"] = false
			# Check if all dead
			var any_alive: bool = false
			for h in _heads:
				if h["alive"]:
					any_alive = true
					break
			if not any_alive:
				_health = 0.0
				_set_state(BaseState.DEAD)
				enemy_destroyed.emit(self)
		return

	# Split a random head
	var split_idx: int = alive_heads[randi() % alive_heads.size()]
	var parent_head: Dictionary = _heads[split_idx]
	parent_head["alive"] = false

	var new_size: float = parent_head["size"] * 0.6
	var new_depth: int = parent_head["depth"] + 1
	var base_angle: float = parent_head["angle"]

	_add_head(base_angle, new_size, new_depth, -0.4)
	_add_head(base_angle, new_size, new_depth, 0.4)
