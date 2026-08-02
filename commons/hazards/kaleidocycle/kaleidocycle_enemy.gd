# @identity
# essence: rotation_phase → active_face → attack_mode — topology determines combat behavior
# desire: a tumbling ring of tetrahedra rolls toward you, cycles to reveal fire/ice/spike/shield faces
# critical_parameter: _rotation_phase — continuous rotation selects which of 4 attack modes activates
# triggers: _start_cycle() randomly picks AttackMode, sets target rotation to expose that face, then attacks
# emerges: the shield mode creates damage reduction — the kaleidocycle can randomly become temporarily invincible
# needs: KaleidocycleGeometry solver [has]; fire_bolt projectile [has]; 4 emissive face materials [has]
# relationships: contrasts with origami_droideka (continuous rotation vs binary fold); feeds random_game as final boss-tier enemy
# truth: A kaleidocycle is a closed kinematic chain — every face is always present, only visibility rotates.

extends CharacterBody3D
class_name KaleidocycleEnemy
## Kaleidocycle enemy - tumbling ring of tetrahedra with 4 attack modes.
## Each face type triggers a different attack when it becomes active.

signal fired_projectile(position: Vector3, direction: Vector3)
signal enemy_destroyed(enemy: Node3D)

enum State { ROLL, CYCLE, ATTACK, COOLDOWN, DEAD }
enum AttackMode { FIRE, ICE, SPIKE, SHIELD }

const FIRE_BOLT_SCENE: PackedScene = preload("res://commons/hazards/armadillo_droideka/fire_bolt.tscn")

@export_group("Geometry")
@export var segment_count: int = 6
@export var edge_length: float = 0.18
@export var leg_ratio: float = 1.4

@export_group("Combat")
@export var max_health: float = 100.0
@export var roll_speed: float = 3.0
@export var tumble_speed: float = 0.2
@export var detection_radius: float = 12.0
@export var attack_radius: float = 2.5
@export var base_damage: float = 15.0

@export_group("Timing")
@export var cycle_duration: float = 8.0
@export var attack_duration: float = 6.0
@export var cooldown_duration: float = 4.0

@export_group("Face Colors")
@export var fire_color: Color = Color(1.0, 0.3, 0.1, 1.0)
@export var ice_color: Color = Color(0.2, 0.6, 1.0, 1.0)
@export var spike_color: Color = Color(0.7, 0.2, 0.8, 1.0)
@export var shield_color: Color = Color(1.0, 0.85, 0.2, 1.0)

## AXIS — WARNING: how much the hazard tells you BEFORE it costs you anything.
## Adopted word for word from [[catalyst_vent]] and [[path_block]]: one vocabulary
## across the hazards, because a room cannot coherently cage its vents and leave its
## enemies unannounced. The kaleidocycle is the sharpest case in the family — every
## face is ALWAYS present, only visibility rotates, so nothing it does can be inferred
## from the moment you are looking at. Whether the room admits that in advance is not
## a property of the creature; it is a property of the world around it.
##
##   none    the ring alone, unannounced — THE LEGACY BODY, byte for byte.
##   stain   a burn soaked into the floor where it has been working, and nothing
##           above it. You can only read it standing where it already rolled.
##   cage    a bolted bar frame and a filed yellow tag. Somebody catalogued this
##           and fenced it, and it tumbles through the bars on exactly the same clock.
##   beacon  a lit mast up through the ring's hollow centre with a lamp head, plus a
##           glowing outline on the floor: readable from the doorway.
##   shroud  a canvas wrap strapped over the whole cycle. The four faces are still
##           all there. The world knows and has decided you should not.
##
## APPEARANCE ONLY. max_health, base_damage, roll_speed, detection_radius,
## attack_radius, the collision sphere and every duration are byte-identical across
## all five values. A hazard that hides itself is not a gentler hazard.
const WARNING_VALUES: PackedStringArray = ["none", "stain", "cage", "beacon", "shroud"]
@export_enum("none", "stain", "cage", "beacon", "shroud") var warning: String = "none"

# State
var _health: float = 0.0
var _state: State = State.ROLL
var _state_time: float = 0.0
var _rotation_phase: float = 0.0
var _current_mode: AttackMode = AttackMode.FIRE
var _target_phase: float = 0.0
var _player_node: Node3D = null
var _shield_active: bool = false

# Geometry
var _geometry: KaleidocycleGeometry = null
var _mesh_root: Node3D = null
var _face_meshes: Array[Array] = []  # [tet_idx][face_idx]
var _materials: Array[StandardMaterial3D] = []


func _ready() -> void:
	_health = max_health
	_create_materials()
	_build_collision()
	_geometry = KaleidocycleGeometry.new()
	_rebuild_mesh()
	_find_player()
	add_to_group("enemy")
	add_to_group("kaleidocycle_enemy")
	print("KaleidocycleEnemy: READY at %s" % global_position)
	# WARNING dressing, appended LAST so every node built above keeps its index.
	# "none" adds nothing at all — the legacy lineage.
	_build_warning()


func _physics_process(delta: float) -> void:
	_state_time += delta
	
	if not is_instance_valid(_player_node):
		_find_player()
	
	match _state:
		State.ROLL:
			_process_roll(delta)
		State.CYCLE:
			_process_cycle(delta)
		State.ATTACK:
			_process_attack(delta)
		State.COOLDOWN:
			_process_cooldown(delta)
		State.DEAD:
			_process_dead(delta)
	
	_update_mesh()
	
	if _state != State.DEAD:
		move_and_slide()


func _process_roll(delta: float) -> void:
	# Continuous tumbling while rolling
	_rotation_phase += delta * tumble_speed
	
	var dist: float = _get_player_distance()
	
	if dist <= detection_radius:
		if dist <= attack_radius:
			# Close enough to attack
			_start_cycle()
		else:
			# Roll toward player
			if is_instance_valid(_player_node):
				var to_player: Vector3 = _player_node.global_position - global_position
				to_player.y = 0.0
				if to_player.length() > 0.1:
					velocity = to_player.normalized() * roll_speed
				else:
					velocity = Vector3.ZERO
			else:
				velocity = Vector3.ZERO
	else:
		velocity = Vector3.ZERO
		_rotation_phase += delta * tumble_speed * 0.3


func _process_cycle(delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, delta * 8.0)
	
	var t: float = clamp(_state_time / cycle_duration, 0.0, 1.0)
	
	# Rotate to target phase
	_rotation_phase = lerp(_rotation_phase, _target_phase, t)
	
	if t >= 1.0:
		_set_state(State.ATTACK)


func _process_attack(_delta: float) -> void:
	velocity = Vector3.ZERO
	
	var t: float = clamp(_state_time / attack_duration, 0.0, 1.0)
	
	# Execute attack based on mode
	if t > 0.2 and t < 0.4:
		match _current_mode:
			AttackMode.FIRE:
				_attack_fire()
			AttackMode.ICE:
				_attack_ice()
			AttackMode.SPIKE:
				_attack_spike()
			AttackMode.SHIELD:
				_attack_shield()
	
	# Slight pulse
	_rotation_phase += sin(t * PI * 0.4) * 0.1
	
	if t >= 1.0:
		_shield_active = false
		_set_state(State.COOLDOWN)


func _process_cooldown(delta: float) -> void:
	_rotation_phase += delta * tumble_speed * 0.5
	velocity = velocity.move_toward(Vector3.ZERO, delta * 4.0)
	
	if _state_time >= cooldown_duration:
		_set_state(State.ROLL)


func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	_rotation_phase += delta * 0.5
	
	if _state_time >= 3.0:
		# Reset instead of destroy for dev observation
		_health = max_health
		_set_state(State.ROLL)


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0


func _start_cycle() -> void:
	# Choose next attack mode (cycle through or random)
	_current_mode = AttackMode.values()[randi() % 4]
	
	# Set target rotation to show that face
	var mode_offset: float = TAU / 4.0 * float(_current_mode)
	_target_phase = _rotation_phase + mode_offset
	
	_set_state(State.CYCLE)


## Attacks

func _attack_fire() -> void:
	# Burst of fire projectiles
	if not FIRE_BOLT_SCENE:
		return
	
	for i in range(3):
		var angle: float = TAU / 3.0 * float(i)
		var dir: Vector3 = Vector3(cos(angle), 0.2, sin(angle)).normalized()
		
		var bolt: Node = FIRE_BOLT_SCENE.instantiate()
		if bolt:
			var scene: Node = get_tree().current_scene
			if scene:
				scene.add_child(bolt)
			if bolt.has_method("launch"):
				bolt.launch(global_position, dir, 12.0, base_damage)
			
			fired_projectile.emit(global_position, dir)


func _attack_ice() -> void:
	# Slow effect on nearby player (conceptual - just damage for now)
	_try_damage_player(base_damage * 0.8)


func _attack_spike() -> void:
	# High damage melee
	_try_damage_player(base_damage * 1.5)


func _attack_shield() -> void:
	# Activate shield - reduce incoming damage temporarily
	_shield_active = true


func _try_damage_player(damage: float) -> void:
	if not is_instance_valid(_player_node):
		return
	
	var dist: float = global_position.distance_to(_player_node.global_position)
	if dist > attack_radius * 1.5:
		return
	
	for method in ["take_damage", "apply_damage", "damage"]:
		if _player_node.has_method(method):
			_player_node.call(method, damage)
			return


## Geometry

func _create_materials() -> void:
	_materials.clear()
	
	# One material per attack mode
	for i in range(4):
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.metallic = 0.4
		mat.roughness = 0.5
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 0.6
		
		match i:
			0:  # Fire
				mat.albedo_color = fire_color
				mat.emission = fire_color
			1:  # Ice
				mat.albedo_color = ice_color
				mat.emission = ice_color
			2:  # Spike
				mat.albedo_color = spike_color
				mat.emission = spike_color
			3:  # Shield
				mat.albedo_color = shield_color
				mat.emission = shield_color
		
		_materials.append(mat)


func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = edge_length * segment_count * 0.15
	shape.shape = sphere
	add_child(shape)


func _rebuild_mesh() -> void:
	if _mesh_root:
		_mesh_root.queue_free()
	_face_meshes.clear()
	
	_geometry.build(segment_count, edge_length, leg_ratio)
	_geometry.solve_rotation(_rotation_phase)
	
	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)
	
	# Create face meshes for each tetrahedron
	for tet_idx in range(_geometry.tetrahedra.size()):
		var tet_faces: Array = []
		
		for face_idx in range(4):
			var mesh_inst: MeshInstance3D = MeshInstance3D.new()
			mesh_inst.name = "Tet%d_Face%d" % [tet_idx, face_idx]
			mesh_inst.material_override = _materials[face_idx % _materials.size()]
			_mesh_root.add_child(mesh_inst)
			tet_faces.append(mesh_inst)
		
		_face_meshes.append(tet_faces)
	
	_update_mesh()


func _update_mesh() -> void:
	if not _geometry:
		return
	
	_geometry.solve_rotation(_rotation_phase)
	
	var active_face: int = _geometry.get_active_face()
	
	for tet_idx in range(_geometry.tetrahedra.size()):
		if tet_idx >= _face_meshes.size():
			continue
		
		var verts: PackedVector3Array = _geometry.tetrahedra[tet_idx]
		if verts.size() < 4:
			continue
		
		for face_idx in range(4):
			if face_idx >= _face_meshes[tet_idx].size():
				continue
			if face_idx >= _geometry.face_indices.size():
				continue
			
			var indices: PackedInt32Array = _geometry.face_indices[face_idx]
			if indices.size() < 3:
				continue
			
			var v0: Vector3 = verts[indices[0]]
			var v1: Vector3 = verts[indices[1]]
			var v2: Vector3 = verts[indices[2]]
			
			_face_meshes[tet_idx][face_idx].mesh = _create_triangle_mesh(v0, v1, v2)
			
			# Highlight active face
			var mat: StandardMaterial3D = _materials[face_idx % _materials.size()]
			if face_idx == active_face:
				mat.emission_energy_multiplier = 1.2
			else:
				mat.emission_energy_multiplier = 0.4


func _create_triangle_mesh(v0: Vector3, v1: Vector3, v2: Vector3) -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices: PackedVector3Array = [v0, v1, v2]
	var normal: Vector3 = (v1 - v0).cross(v2 - v0).normalized()
	var normals: PackedVector3Array = [normal, normal, normal]
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Combat

func take_damage(amount: float) -> void:
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	if _state == State.DEAD:
		return
	
	# Shield reduces damage
	if _shield_active:
		amount *= 0.3
	
	_health -= max(0.0, amount)
	
	if _health <= 0.0:
		_set_state(State.DEAD)
		enemy_destroyed.emit(self)
	else:
		# Flash all faces
		for mat in _materials:
			var tween: Tween = create_tween()
			tween.tween_property(mat, "emission_energy_multiplier", 2.0, 0.05)
			tween.tween_property(mat, "emission_energy_multiplier", 0.6, 0.15)


## Utility

func _find_player() -> void:
	var scene: Node = get_tree().current_scene
	if not scene:
		_player_node = null
		return
	
	for candidate in [
		get_tree().get_first_node_in_group("player"),
		scene.find_child("XROrigin3D", true, false),
		scene.find_child("Player", true, false),
	]:
		if candidate is Node3D:
			_player_node = candidate
			return


func _get_player_distance() -> float:
	if not is_instance_valid(_player_node):
		return INF
	return global_position.distance_to(_player_node.global_position)


func configure(config: Dictionary) -> void:
	if config.has("segments"):
		segment_count = int(config["segments"])
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("damage"):
		base_damage = float(config["damage"])

	if _geometry:
		_rebuild_mesh()

	# WARNING — read last, from the config dict or the config_<key> metadata the
	# grid stamps on the root, and an unknown word keeps the default rather than
	# blanking the dressing.
	var w: String = ""
	if config.has("warning"):
		w = str(config["warning"])
	elif has_meta("config_warning"):
		w = str(get_meta("config_warning"))
	w = w.strip_edges().to_lower()
	if WARNING_VALUES.has(w):
		warning = w
	_build_warning()


func apply_grid_config(config: Dictionary) -> void:
	configure(config)


# ── WARNING ──────────────────────────────────────────────────────────────────
# One axis, five values, the vocabulary shared with [[catalyst_vent]] and
# [[path_block]]. Every builder below adds MeshInstance3D children only — never a
# collider, never a group, never a radius the combat code reads. Deterministic:
# nothing here draws from the random stream, so five variants of the same ring
# differ only in what the world put around it.

const WARN_STAIN_OUTER := Color(0.24, 0.19, 0.13)
const WARN_STAIN_CORE := Color(0.09, 0.075, 0.055)
const WARN_BAR := Color(0.52, 0.50, 0.44)
const WARN_TAG := Color(0.86, 0.72, 0.12)
const WARN_MAST := Color(0.38, 0.38, 0.40)
const WARN_LAMP := Color(1.0, 0.62, 0.12)
const WARN_CLOTH := Color(0.40, 0.38, 0.33)
const WARN_STRAP := Color(0.15, 0.14, 0.13)


func _build_warning() -> void:
	## Rebuildable: a map hands its config to apply_grid_config AFTER _ready, so this
	## runs twice. Drop the previous dressing immediately (remove_child before
	## queue_free — the sweep measures the AABB on the very next frame).
	for child in get_children():
		if child.is_in_group("hazard_warning"):
			remove_child(child)
			child.queue_free()
	var b: AABB = _warn_bounds()
	match warning:
		"stain":
			_warn_stain(b)
		"cage":
			_warn_cage(b)
		"beacon":
			_warn_beacon(b)
		"shroud":
			_warn_shroud(b)
		_:
			pass


## The ring's real extent, read from the solved tetrahedra rather than guessed, so the
## dressing scales with segment_count and edge_length instead of drifting off a
## hardcoded radius. Falls back to a nominal box if the solver has not run yet.
func _warn_bounds() -> AABB:
	if _geometry == null or _geometry.tetrahedra.is_empty():
		var n: float = maxf(edge_length * float(segment_count) * 0.5, 0.2)
		return AABB(Vector3(-n, -n * 0.6, -n), Vector3(n * 2.0, n * 1.2, n * 2.0))
	var lo: Vector3 = Vector3(INF, INF, INF)
	var hi: Vector3 = Vector3(-INF, -INF, -INF)
	for tet in _geometry.tetrahedra:
		for v in tet:
			lo.x = minf(lo.x, v.x)
			lo.y = minf(lo.y, v.y)
			lo.z = minf(lo.z, v.z)
			hi.x = maxf(hi.x, v.x)
			hi.y = maxf(hi.y, v.y)
			hi.z = maxf(hi.z, v.z)
	return AABB(lo, hi - lo)


## STAIN — the notice written on the ground. A dull discolouration soaked where the
## ring has been rolling, with a darker core under it and two runs bled off one side.
func _warn_stain(b: AABB) -> void:
	var r: float = maxf(maxf(b.size.x, b.size.z) * 0.5, 0.05)
	var y: float = b.position.y - 0.006
	_warn_add(Vector3(b.get_center().x, y, b.get_center().z),
		Vector3(r * 3.4, 0.012, r * 3.4), _warn_mat(WARN_STAIN_OUTER, 1.0, 0.0))
	_warn_add(Vector3(b.get_center().x, y + 0.007, b.get_center().z),
		Vector3(r * 2.1, 0.012, r * 2.1), _warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(b.get_center().x + r * 1.5, y + 0.004, b.get_center().z + r * 0.3),
		Vector3(r * 1.1, 0.012, r * 0.30), _warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(b.get_center().x - r * 1.25, y + 0.004, b.get_center().z - r * 0.7),
		Vector3(r * 0.8, 0.012, r * 0.22), _warn_mat(WARN_STAIN_CORE, 1.0, 0.0))


## CAGE — the notice as paperwork. Four posts, two rails, one filed yellow tag. The
## ring tumbles through the bars on exactly the clock it always did.
func _warn_cage(b: AABB) -> void:
	var r: float = maxf(maxf(b.size.x, b.size.z) * 0.5, 0.05)
	var c: Vector3 = b.get_center()
	var bot: float = b.position.y - 0.005
	var top: float = b.position.y + b.size.y + r * 0.55
	var hx: float = r * 1.36
	var bar: StandardMaterial3D = _warn_mat(WARN_BAR, 0.45, 0.55)
	var thick: float = maxf(r * 0.09, 0.025)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_warn_add(Vector3(c.x + float(sx) * hx, (bot + top) * 0.5, c.z + float(sz) * hx),
				Vector3(thick, top - bot, thick), bar)
	for ry in [top, bot + (top - bot) * 0.45]:
		var y: float = float(ry)
		for s in [-1.0, 1.0]:
			var o: float = float(s) * hx
			_warn_add(Vector3(c.x, y, c.z + o), Vector3(hx * 2.0 + thick, thick * 0.8, thick * 0.8), bar)
			_warn_add(Vector3(c.x + o, y, c.z), Vector3(thick * 0.8, thick * 0.8, hx * 2.0 + thick), bar)
	_warn_add(Vector3(c.x + hx + thick * 0.6, bot + (top - bot) * 0.72, c.z),
		Vector3(0.016, r * 0.42, r * 0.62), _warn_mat(WARN_TAG, 0.7, 0.0))


## BEACON — the notice as broadcast. A mast up through the ring's hollow centre with a
## lamp head on a shade, and a lit outline burnt onto the floor around it.
func _warn_beacon(b: AABB) -> void:
	var r: float = maxf(maxf(b.size.x, b.size.z) * 0.5, 0.05)
	var c: Vector3 = b.get_center()
	var crown: float = b.position.y + b.size.y
	var mast_h: float = r * 2.0
	var mast: StandardMaterial3D = _warn_mat(WARN_MAST, 0.4, 0.6)
	var lamp: StandardMaterial3D = _warn_emissive(WARN_LAMP, 3.2)
	var thick: float = maxf(r * 0.10, 0.03)
	_warn_add(Vector3(c.x, crown + mast_h * 0.5, c.z), Vector3(thick, mast_h, thick), mast)
	_warn_add(Vector3(c.x, crown + mast_h + r * 0.20, c.z),
		Vector3(r * 0.52, r * 0.30, r * 0.52), lamp)
	_warn_add(Vector3(c.x, crown + mast_h + r * 0.42, c.z),
		Vector3(r * 0.74, thick * 0.7, r * 0.74), mast)
	var hx: float = r * 1.55
	var y: float = b.position.y - 0.004
	for s in [-1.0, 1.0]:
		var o: float = float(s) * hx
		_warn_add(Vector3(c.x, y, c.z + o), Vector3(hx * 2.0, 0.02, thick), lamp)
		_warn_add(Vector3(c.x + o, y, c.z), Vector3(thick, 0.02, hx * 2.0), lamp)


## SHROUD — the notice withheld. A canvas wrap strapped over the whole cycle: the four
## faces are still all there, and you cannot see which one is up.
func _warn_shroud(b: AABB) -> void:
	var r: float = maxf(maxf(b.size.x, b.size.z) * 0.5, 0.05)
	var c: Vector3 = b.get_center()
	var cloth: StandardMaterial3D = _warn_mat(WARN_CLOTH, 0.95, 0.0)
	var strap: StandardMaterial3D = _warn_mat(WARN_STRAP, 0.85, 0.1)
	var w: float = r * 2.28
	var h: float = b.size.y * 1.20 + 0.03
	_warn_add(Vector3(c.x, c.y, c.z), Vector3(w, h, w), cloth)
	_warn_add(Vector3(c.x, c.y + h * 0.5 + 0.03, c.z), Vector3(w * 0.30, 0.06, w * 0.30), cloth)
	_warn_add(Vector3(c.x, b.position.y - 0.01, c.z), Vector3(w + 0.07, 0.05, w + 0.07), cloth)
	for s in [-1.0, 1.0]:
		var o: float = float(s) * w * 0.5
		_warn_add(Vector3(c.x, c.y, c.z + o), Vector3(w + 0.01, h * 0.22, 0.012), strap)
		_warn_add(Vector3(c.x + o, c.y, c.z), Vector3(0.012, h * 0.22, w + 0.01), strap)


func _warn_add(center: Vector3, box_size: Vector3, mat: Material) -> void:
	var bm: BoxMesh = BoxMesh.new()
	bm.size = box_size
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = mat
	mi.position = center
	mi.add_to_group("hazard_warning")
	add_child(mi)


func _warn_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _warn_emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
