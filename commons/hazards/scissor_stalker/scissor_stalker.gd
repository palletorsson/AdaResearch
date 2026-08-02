# @identity
# essence: L(extension) = Σ bar_length · f(θ_i) — Hoberman scissor linkage maps single parameter to reach
# desire: a crouching spider that stalks low, then explosively extends scissor legs to pounce and slam
# critical_parameter: _leg_extension — 0 = compact (hiding), 1 = fully extended (3x reach for pounce)
# triggers: state machine (COMPACT→STALK→POUNCE→ATTACK→RETRACT) with leg extension ramping per state
# emerges: the walk animation arises from phase-offset sine waves on leg tilt — no IK, just linkage geometry
# needs: ScissorLinkage geometry solver [has]; per-leg bar/joint mesh updates [has]; player tracking [has]
# relationships: contrasts with kresling_spire (radial extension vs linear extension); feeds random_game gauntlet
# truth: A scissor linkage is amplification — small angular change becomes dramatic spatial reach.

extends CharacterBody3D
class_name ScissorStalker
## Spider-like enemy with Hoberman scissor linkage legs.
## Legs can extend 3x their compact length for dramatic reach.

signal enemy_destroyed(enemy: Node3D)

enum State { COMPACT, STALK, POUNCE, ATTACK, RETRACT, DEAD }

@export_group("Geometry")
@export var leg_count: int = 6
@export var units_per_leg: int = 3
@export var bar_length: float = 0.12
@export var body_radius: float = 0.2

@export_group("Combat")
@export var max_health: float = 90.0
@export var stalk_speed: float = 1.5
@export var pounce_speed: float = 8.0
@export var detection_radius: float = 10.0
@export var pounce_range: float = 4.0
@export var attack_damage: float = 25.0
@export var attack_radius: float = 1.0

@export_group("Timing")
@export var stalk_extend: float = 0.5  # Leg extension while stalking
@export var pounce_duration: float = 3.5
@export var attack_duration: float = 5.0
@export var retract_duration: float = 4.0

@export_group("Appearance")
@export var body_color: Color = Color(0.25, 0.22, 0.28, 1.0)
@export var leg_color: Color = Color(0.35, 0.32, 0.38, 1.0)
@export var joint_color: Color = Color(0.6, 0.25, 0.2, 1.0)
@export var emission_color: Color = Color(0.9, 0.3, 0.15, 1.0)

## AXIS — WARNING: how much the hazard tells you BEFORE it costs you anything.
## Adopted word for word from [[catalyst_vent]], [[path_block]] and
## [[kaleidocycle_enemy]] — one vocabulary across the hazards. The stalker is the
## member of the family where the question is sharpest, because its reach is not
## visible in its resting pose: a compact scissor linkage is three times shorter than
## the same linkage extended, so what you can SEE of it is a systematic underestimate
## of what it can touch. Whether the room corrects for that is the axis.
##
##   none    the stalker alone, unannounced — THE LEGACY BODY, byte for byte.
##   stain   a dry discolouration soaked into the ground it has been working, and
##           nothing above it: readable only from inside its reach.
##   cage    a bolted bar frame and a filed yellow tag. Somebody catalogued it and
##           fenced it; the pounce carries exactly as far as it always did.
##   beacon  a lit mast standing at its back with a lamp head, plus a glowing outline
##           on the floor at the radius nobody could otherwise guess.
##   shroud  a canvas wrap strapped over the core. The eye goes out, the linkage stops
##           reading as a mechanism, and the reach is unchanged.
##
## APPEARANCE ONLY. attack_damage, attack_radius, pounce_range, pounce_speed,
## detection_radius, max_health, every duration and the collision sphere are
## byte-identical across all five values. A hazard that hides itself is not a gentler
## hazard — a shrouded stalker reaches exactly as far as a caged one.
const WARNING_VALUES: PackedStringArray = ["none", "stain", "cage", "beacon", "shroud"]
@export_enum("none", "stain", "cage", "beacon", "shroud") var warning: String = "none"

# State
var _health: float = 0.0
var _state: State = State.COMPACT
var _state_time: float = 0.0
var _leg_extension: float = 0.0  # 0 = compact, 1 = extended
var _walk_phase: float = 0.0
var _player_node: Node3D = null

# Geometry
var _leg_linkages: Array[ScissorLinkage] = []
var _body_mesh: MeshInstance3D = null
var _leg_roots: Array[Node3D] = []
var _leg_bar_meshes: Array[Array] = []  # [leg_idx][bar_idx] = MeshInstance3D
var _leg_joint_meshes: Array[Array] = []

# Materials
var _body_material: StandardMaterial3D
var _leg_material: StandardMaterial3D
var _joint_material: StandardMaterial3D


func _ready() -> void:
	_health = max_health
	_create_materials()
	_build_collision()
	_build_body()
	_build_legs()
	_find_player()
	add_to_group("enemy")
	add_to_group("scissor_enemy")
	# Start stalking for visibility during dev
	_set_state(State.STALK)
	_leg_extension = 0.5
	print("ScissorStalker: READY at %s" % global_position)
	# WARNING dressing, appended LAST so the body, the eye and every leg root keep
	# their child indices. "none" adds nothing at all — the legacy lineage.
	_build_warning()


func _physics_process(delta: float) -> void:
	_state_time += delta
	
	if not is_instance_valid(_player_node):
		_find_player()
	
	match _state:
		State.COMPACT:
			_process_compact(delta)
		State.STALK:
			_process_stalk(delta)
		State.POUNCE:
			_process_pounce(delta)
		State.ATTACK:
			_process_attack(delta)
		State.RETRACT:
			_process_retract(delta)
		State.DEAD:
			_process_dead(delta)
	
	_update_legs()
	
	if _state != State.DEAD:
		move_and_slide()


func _process_compact(delta: float) -> void:
	_leg_extension = move_toward(_leg_extension, 0.1, delta * 3.0)
	velocity = Vector3.ZERO
	
	# Body hugs ground when compact
	if _body_mesh:
		_body_mesh.position.y = body_radius * 0.4
	
	var dist: float = _get_player_distance()
	if dist <= detection_radius:
		_set_state(State.STALK)


func _process_stalk(delta: float) -> void:
	_leg_extension = move_toward(_leg_extension, stalk_extend, delta * 2.0)
	
	# Raise body
	if _body_mesh:
		_body_mesh.position.y = lerp(body_radius * 0.4, body_radius + _get_leg_height(), _leg_extension)
	
	var dist: float = _get_player_distance()
	
	if dist > detection_radius * 1.3:
		_set_state(State.RETRACT)
		return
	
	if dist <= pounce_range:
		_set_state(State.POUNCE)
		return
	
	# Walk toward player
	_walk_phase += delta * 0.4
	
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.1:
			var move_dir: Vector3 = to_player.normalized()
			velocity = move_dir * stalk_speed
			_face_direction(move_dir, delta * 3.0)
		else:
			velocity = Vector3.ZERO
	else:
		velocity = Vector3.ZERO


func _process_pounce(_delta: float) -> void:
	var t: float = clamp(_state_time / pounce_duration, 0.0, 1.0)
	
	# Rapidly extend legs
	_leg_extension = lerp(stalk_extend, 1.0, ease(t, 0.3))
	
	if _body_mesh:
		_body_mesh.position.y = body_radius + _get_leg_height()
	
	# Lunge toward player
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.1:
			velocity = to_player.normalized() * pounce_speed * (1.0 - t * 0.5)
	
	if t >= 1.0:
		_set_state(State.ATTACK)


func _process_attack(delta: float) -> void:
	var t: float = clamp(_state_time / attack_duration, 0.0, 1.0)
	
	velocity = velocity.move_toward(Vector3.ZERO, delta * 15.0)
	
	# Slam down
	_leg_extension = lerp(1.0, 0.3, ease(t, 2.0))
	
	if _body_mesh:
		_body_mesh.position.y = body_radius + _get_leg_height()
	
	# Deal damage at impact
	if t > 0.3 and t < 0.5:
		_try_damage_player()
	
	if t >= 1.0:
		_set_state(State.STALK)


func _process_retract(_delta: float) -> void:
	var t: float = clamp(_state_time / retract_duration, 0.0, 1.0)
	
	_leg_extension = lerp(stalk_extend, 0.1, t)
	velocity = Vector3.ZERO
	
	if _body_mesh:
		_body_mesh.position.y = lerp(body_radius + _get_leg_height(), body_radius * 0.4, t)
	
	if t >= 1.0:
		_set_state(State.COMPACT)


func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	_leg_extension = move_toward(_leg_extension, 0.6, delta)
	
	# Collapse
	if _body_mesh:
		_body_mesh.position.y = move_toward(_body_mesh.position.y, body_radius * 0.3, delta * 0.5)
	
	if _state_time >= 3.0:
		# Reset instead of destroy for dev observation
		_health = max_health
		_set_state(State.COMPACT)


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0


func _get_leg_height() -> float:
	## Get current leg height based on extension.
	if _leg_linkages.is_empty():
		return 0.0
	
	var linkage: ScissorLinkage = _leg_linkages[0]
	linkage.solve_extension(_leg_extension)
	
	# Leg is angled down, so height is portion of length
	var leg_length: float = linkage.get_total_length()
	return leg_length * 0.7  # Approximate vertical component


## Geometry

func _create_materials() -> void:
	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = body_color
	_body_material.metallic = 0.5
	_body_material.roughness = 0.4
	_body_material.emission_enabled = true
	_body_material.emission = emission_color * 0.5
	_body_material.emission_energy_multiplier = 0.6
	
	_leg_material = StandardMaterial3D.new()
	_leg_material.albedo_color = leg_color
	_leg_material.metallic = 0.6
	_leg_material.roughness = 0.35
	
	_joint_material = StandardMaterial3D.new()
	_joint_material.albedo_color = joint_color
	_joint_material.metallic = 0.7
	_joint_material.roughness = 0.3
	_joint_material.emission_enabled = true
	_joint_material.emission = joint_color
	_joint_material.emission_energy_multiplier = 0.4


func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = body_radius * 1.5
	shape.shape = sphere
	add_child(shape)


func _build_body() -> void:
	_body_mesh = MeshInstance3D.new()
	_body_mesh.name = "Body"
	
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = body_radius
	sphere.height = body_radius * 2.0
	_body_mesh.mesh = sphere
	_body_mesh.material_override = _body_material
	_body_mesh.position.y = body_radius * 0.4
	add_child(_body_mesh)
	
	# Eye
	var eye: MeshInstance3D = MeshInstance3D.new()
	var eye_mesh: SphereMesh = SphereMesh.new()
	eye_mesh.radius = body_radius * 0.25
	eye_mesh.height = body_radius * 0.5
	eye.mesh = eye_mesh
	
	var eye_mat: StandardMaterial3D = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.1, 0.1, 0.12)
	eye_mat.emission_enabled = true
	eye_mat.emission = emission_color
	eye_mat.emission_energy_multiplier = 1.5
	eye.material_override = eye_mat
	eye.position = Vector3(0.0, body_radius * 0.3, -body_radius * 0.7)
	_body_mesh.add_child(eye)


func _build_legs() -> void:
	_leg_linkages.clear()
	_leg_roots.clear()
	_leg_bar_meshes.clear()
	_leg_joint_meshes.clear()
	
	var angle_step: float = TAU / float(leg_count)
	
	for i in range(leg_count):
		# Create linkage
		var linkage: ScissorLinkage = ScissorLinkage.new()
		linkage.build(units_per_leg, bar_length, 0.01)
		_leg_linkages.append(linkage)
		
		# Create leg root
		var root: Node3D = Node3D.new()
		root.name = "Leg_%d" % i
		root.rotation.y = angle_step * float(i)
		root.position = Vector3.ZERO
		add_child(root)
		_leg_roots.append(root)
		
		# Create bar meshes for this leg
		var bars: Array = []
		var joints_arr: Array = []
		
		for u in range(units_per_leg):
			# Two bars per unit
			for b in range(2):
				var bar: MeshInstance3D = MeshInstance3D.new()
				var cylinder: CylinderMesh = CylinderMesh.new()
				cylinder.height = bar_length
				cylinder.top_radius = 0.008
				cylinder.bottom_radius = 0.008
				bar.mesh = cylinder
				bar.material_override = _leg_material
				root.add_child(bar)
				bars.append(bar)
			
			# Joint sphere
			var joint: MeshInstance3D = MeshInstance3D.new()
			var sphere: SphereMesh = SphereMesh.new()
			sphere.radius = 0.015
			sphere.height = 0.03
			joint.mesh = sphere
			joint.material_override = _joint_material
			root.add_child(joint)
			joints_arr.append(joint)
		
		_leg_bar_meshes.append(bars)
		_leg_joint_meshes.append(joints_arr)


func _update_legs() -> void:
	for i in range(leg_count):
		if i >= _leg_linkages.size() or i >= _leg_roots.size():
			continue
		
		var linkage: ScissorLinkage = _leg_linkages[i]
		var root: Node3D = _leg_roots[i]
		
		linkage.solve_extension(_leg_extension)
		
		# Position root at body edge, angled outward and down
		var body_y: float = _body_mesh.position.y if _body_mesh else body_radius
		root.position = Vector3(0.0, body_y - body_radius * 0.3, 0.0)
		
		# Tilt leg outward and down
		var tilt_angle: float = lerp(PI * 0.3, PI * 0.15, _leg_extension)
		root.rotation.x = tilt_angle
		
		# Walk animation
		if _state == State.STALK:
			var phase: float = _walk_phase + float(i) * TAU / float(leg_count)
			root.rotation.x += sin(phase) * 0.15
		
		# Update bar positions
		var bars: Array = _leg_bar_meshes[i]
		var joints_arr: Array = _leg_joint_meshes[i]
		
		for u in range(units_per_leg):
			var bar_idx: int = u * 2
			if bar_idx + 1 >= bars.size():
				continue
			if u * 2 + 1 >= linkage.bar_endpoints.size():
				continue
			
			# Bar 1
			var endpoints1: PackedVector3Array = linkage.bar_endpoints[u * 2]
			if endpoints1.size() >= 2:
				_position_bar(bars[bar_idx], endpoints1[0], endpoints1[1])
			
			# Bar 2
			var endpoints2: PackedVector3Array = linkage.bar_endpoints[u * 2 + 1]
			if endpoints2.size() >= 2:
				_position_bar(bars[bar_idx + 1], endpoints2[0], endpoints2[1])
			
			# Joint
			if u < joints_arr.size() and u < linkage.joints.size():
				# Offset joint to middle of unit (skip first boundary joint)
				var joint_pos: Vector3 = linkage.joints[min(u + 1, linkage.joints.size() - 1)]
				joints_arr[u].position = joint_pos


func _position_bar(bar: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var mid: Vector3 = (start + end) * 0.5
	var direction: Vector3 = end - start
	var length: float = direction.length()
	
	bar.position = mid
	
	var cylinder: CylinderMesh = bar.mesh as CylinderMesh
	if cylinder:
		cylinder.height = length
	
	if length > 0.001:
		var up: Vector3 = direction.normalized()
		if abs(up.dot(Vector3.UP)) < 0.99:
			bar.look_at(bar.position + up, Vector3.UP)
			bar.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		else:
			bar.rotation = Vector3(0, 0, PI * 0.5) if up.y < 0 else Vector3.ZERO


## Combat

func _try_damage_player() -> void:
	if not is_instance_valid(_player_node):
		return
	
	var dist: float = global_position.distance_to(_player_node.global_position)
	# Extended reach
	var reach: float = attack_radius + _get_leg_height() * 0.5
	
	if dist > reach:
		return
	
	for method in ["take_damage", "apply_damage", "damage"]:
		if _player_node.has_method(method):
			_player_node.call(method, attack_damage)
			return


func take_damage(amount: float) -> void:
	_apply_damage(amount)

func apply_damage(amount: float) -> void:
	_apply_damage(amount)

func damage(amount: float) -> void:
	_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	if _state == State.DEAD:
		return
	
	_health -= max(0.0, amount)
	
	if _health <= 0.0:
		_set_state(State.DEAD)
		enemy_destroyed.emit(self)
	else:
		var tween: Tween = create_tween()
		tween.tween_property(_body_material, "emission_energy_multiplier", 2.0, 0.05)
		tween.tween_property(_body_material, "emission_energy_multiplier", 0.6, 0.15)


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


func _face_direction(dir: Vector3, speed: float) -> void:
	if dir.length_squared() < 0.001:
		return
	var target_yaw: float = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, speed)


func configure(config: Dictionary) -> void:
	if config.has("legs"):
		leg_count = int(config["legs"])
	if config.has("units"):
		units_per_leg = int(config["units"])
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("damage"):
		attack_damage = float(config["damage"])

	# WARNING — read last, from the config dict or the config_<key> metadata the grid
	# stamps on the root, and an unknown word keeps the default rather than blanking
	# the dressing.
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
# One axis, five values, the vocabulary shared with [[catalyst_vent]],
# [[path_block]] and [[kaleidocycle_enemy]]. Every builder below adds
# MeshInstance3D children only — never a collider, never a group, never a distance
# the combat code reads. Deterministic: nothing here draws from the random stream.

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
	match warning:
		"stain":
			_warn_stain()
		"cage":
			_warn_cage()
		"beacon":
			_warn_beacon()
		"shroud":
			_warn_shroud()
		_:
			pass


## The span the stalker actually occupies once it has relaxed — which is the pose a
## still catches, since with no player in range it retracts to COMPACT within a few
## seconds. Derived from the linkage rather than hardcoded: a scissor chain of
## units_per_leg X-units at the compact pivot angle (0.39·PI half-angle).
func _warn_reach() -> float:
	return maxf(float(units_per_leg) * 2.0 * bar_length * sin(PI * 0.39), body_radius * 2.0)


## The plane it stands on: the body sphere's underside at the compact height.
func _warn_floor() -> float:
	return -body_radius * 0.75


## STAIN — the notice written on the ground. A wide dull discolouration under its
## working radius with a darker core and two runs bled off one side.
func _warn_stain() -> void:
	var r: float = _warn_reach()
	var y: float = _warn_floor()
	_warn_add(Vector3(0, y + 0.006, 0), Vector3(r * 2.6, 0.012, r * 2.6),
		_warn_mat(WARN_STAIN_OUTER, 1.0, 0.0))
	_warn_add(Vector3(0, y + 0.013, 0), Vector3(r * 1.5, 0.012, r * 1.5),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(r * 1.05, y + 0.010, r * 0.24), Vector3(r * 0.78, 0.012, r * 0.20),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(-r * 0.86, y + 0.010, -r * 0.52), Vector3(r * 0.56, 0.012, r * 0.16),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))


## CAGE — the notice as paperwork. Four posts, two rails, one filed yellow tag.
func _warn_cage() -> void:
	var r: float = _warn_reach()
	var bot: float = _warn_floor()
	var top: float = body_radius * 1.5 + r * 0.55
	var hx: float = r * 1.18
	var bar: StandardMaterial3D = _warn_mat(WARN_BAR, 0.45, 0.55)
	var thick: float = maxf(r * 0.075, 0.03)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_warn_add(Vector3(float(sx) * hx, (bot + top) * 0.5, float(sz) * hx),
				Vector3(thick, top - bot, thick), bar)
	for ry in [top, bot + (top - bot) * 0.42]:
		var y: float = float(ry)
		for s in [-1.0, 1.0]:
			var o: float = float(s) * hx
			_warn_add(Vector3(0, y, o), Vector3(hx * 2.0 + thick, thick * 0.8, thick * 0.8), bar)
			_warn_add(Vector3(o, y, 0), Vector3(thick * 0.8, thick * 0.8, hx * 2.0 + thick), bar)
	_warn_add(Vector3(hx + thick * 0.6, bot + (top - bot) * 0.72, 0),
		Vector3(0.016, r * 0.30, r * 0.44), _warn_mat(WARN_TAG, 0.7, 0.0))


## BEACON — the notice as broadcast. A mast at its back with a lamp head on a shade,
## and a lit outline on the floor at the reach you could not otherwise see.
func _warn_beacon() -> void:
	var r: float = _warn_reach()
	var bot: float = _warn_floor()
	var mast_h: float = r * 1.75
	var mast: StandardMaterial3D = _warn_mat(WARN_MAST, 0.4, 0.6)
	var lamp: StandardMaterial3D = _warn_emissive(WARN_LAMP, 3.2)
	var thick: float = maxf(r * 0.075, 0.03)
	var mx: float = -r * 0.88
	_warn_add(Vector3(mx, bot + mast_h * 0.5, 0), Vector3(thick, mast_h, thick), mast)
	_warn_add(Vector3(mx, bot + mast_h + r * 0.16, 0), Vector3(r * 0.38, r * 0.22, r * 0.38), lamp)
	_warn_add(Vector3(mx, bot + mast_h + r * 0.32, 0), Vector3(r * 0.54, thick * 0.7, r * 0.54), mast)
	for s in [-1.0, 1.0]:
		var o: float = float(s) * r * 1.12
		_warn_add(Vector3(0, bot + 0.012, o), Vector3(r * 2.24, 0.02, thick), lamp)
		_warn_add(Vector3(o, bot + 0.012, 0), Vector3(thick, 0.02, r * 2.24), lamp)


## SHROUD — the notice withheld. A canvas wrap strapped over the core: the eye is
## covered, the linkage stops reading as a mechanism, the legs still reach.
func _warn_shroud() -> void:
	# Sized off the BODY, not the reach: the cloth covers the core and the legs go on
	# reaching out from under it, which is the whole claim of this value.
	var bot: float = _warn_floor()
	var cloth: StandardMaterial3D = _warn_mat(WARN_CLOTH, 0.95, 0.0)
	var strap: StandardMaterial3D = _warn_mat(WARN_STRAP, 0.85, 0.1)
	var w: float = body_radius * 3.1
	var top: float = body_radius * 1.55
	var cy: float = (bot + top) * 0.5
	_warn_add(Vector3(0, cy, 0), Vector3(w, top - bot, w), cloth)
	_warn_add(Vector3(0, top + 0.035, 0), Vector3(w * 0.32, 0.07, w * 0.32), cloth)
	_warn_add(Vector3(0, bot + 0.03, 0), Vector3(w + 0.09, 0.06, w + 0.09), cloth)
	for s in [-1.0, 1.0]:
		var o: float = float(s) * w * 0.5
		_warn_add(Vector3(0, cy, o), Vector3(w + 0.012, (top - bot) * 0.22, 0.013), strap)
		_warn_add(Vector3(o, cy, 0), Vector3(0.013, (top - bot) * 0.22, w + 0.012), strap)


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
