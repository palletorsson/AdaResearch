# @identity
# essence: twist(t) ∈ [0,1] — Kresling twist maps between flat disc and extended tower
# desire: a disc rolls toward optimal range, twists upward into a sniper tower, fires, collapses, relocates
# critical_parameter: _twist — 0 = tall tower (sniper mode), 1 = flat disc (mobile mode); single DOF controls entire behavior
# triggers: state machine (DISC→RISE→AIM→FIRE→COLLAPSE→RELOCATE) drives twist interpolation
# emerges: the tower seeks optimal_range — it backs away if too close, approaches if too far, creating a standoff distance
# needs: KreslingGeometry solver [has]; fire_bolt projectile [has]; platform aiming [has]
# relationships: contrasts with miura_crawler (vertical tower vs horizontal crawler); contrasts with scissor_stalker (rigid extension vs twist)
# truth: The Kresling fold proves that rotation and translation are coupled — to twist is to rise.

extends CharacterBody3D
class_name KreslingSpire
## Kresling origami sniper tower - twisting cylinder that extends to fire.
## Compact disc form for mobility, tall tower form for sniping.

signal fired_projectile(position: Vector3, direction: Vector3)
signal enemy_destroyed(enemy: Node3D)

enum State { DISC, RISE, AIM, FIRE, COLLAPSE, RELOCATE, DEAD }

const FIRE_BOLT_SCENE: PackedScene = preload("res://commons/hazards/armadillo_droideka/fire_bolt.tscn")

@export_group("Geometry")
@export var radial_segments: int = 6
@export var layers: int = 5
@export var radius: float = 0.28
@export var edge_length: float = 0.22

@export_group("Combat")
@export var max_health: float = 70.0
@export var disc_speed: float = 1.8
@export var detection_radius: float = 14.0
@export var optimal_range: float = 8.0
@export var fire_speed: float = 18.0
@export var fire_damage: float = 22.0
@export var shots_per_burst: int = 2
@export var fire_interval: float = 0.6

@export_group("Timing")
@export var rise_duration: float = 7.0
@export var aim_duration: float = 5.0
@export var collapse_duration: float = 4.0
@export var relocate_time: float = 20.0

@export_group("Appearance")
@export var shell_color: Color = Color(0.35, 0.38, 0.45, 1.0)
@export var crease_color: Color = Color(0.55, 0.58, 0.52, 1.0)
@export var core_color: Color = Color(0.2, 0.22, 0.25, 1.0)
@export var emission_color: Color = Color(1.0, 0.35, 0.1, 1.0)

## AXIS — WARNING: how much the hazard tells you BEFORE it costs you anything.
## Adopted word for word from [[miura_crawler]], [[scissor_stalker]],
## [[kaleidocycle_enemy]] and [[path_block]] — one vocabulary across the hazards,
## so the family measures on one scale instead of five private synonyms.
##
## The spire is the family's SNIPER case. Every other hazard in this vocabulary
## has to reach you; this one never does. It backs off to optimal_range and
## shoots from there, so the only thing that could ever have warned you is what
## it looks like from across the room — and at rest it looks like a hexagonal
## disc on the floor, one twist away from being a tower. The warning is the
## difference between a floor tile and a firing position.
##
##   none    the shell alone, unannounced — THE LEGACY BODY, byte for byte. A
##           low twisted drum with a lit muzzle platform on top.
##   stain   scorch soaked into the ground it has been shooting over: a wide dull
##           patch well past its own footprint, a darker core, and two burn runs
##           bled off one side where the bolts land.
##   cage    a bolted post-and-rail frame the height of the DEPLOYED tower, plus a
##           filed yellow tag. Somebody catalogued the thing and fenced the volume
##           it needs; it still rises and fires on exactly the same schedule.
##   beacon  a lit mast beside it with a lamp head and a shade, plus a glowing
##           outline burnt into the floor around a thing that is otherwise almost
##           flat. The room announces the standoff.
##   shroud  a canvas sleeve standing over the collapsed drum — taller than the
##           disc, shorter than the tower. What it looks like at rest goes under
##           cloth; when it untwists to fire, the platform clears the cover.
##
## APPEARANCE ONLY. fire_damage, fire_speed, shots_per_burst, fire_interval,
## optimal_range, detection_radius, disc_speed, max_health, the twist schedule and
## the collision capsule are byte-identical across all five values. A hazard that
## hides itself is not a gentler hazard.
const WARNING_VALUES: PackedStringArray = ["none", "stain", "cage", "beacon", "shroud"]
@export_enum("none", "stain", "cage", "beacon", "shroud") var warning: String = "none"

## AXIS — POSTURE: which of its two bodies the spire is wearing.
##
## The word is [[armadillo_eggling]]'s, and the question is the same one: a hazard that
## owns two bodies, and a map that gets to say which one it stands in. The VALUES are not
## shared, and should not be — a Kresling drum has no ball and no legs. What is shared is
## the claim underneath. The eggling's `walker` opens the shell and still has no gun,
## which says the deployment was never the weapon; this axis says it from the other side.
##
## _twist is the artifact's own declared critical_parameter, a single DOF running 0 (tall
## tower) to 1 (flat disc), and the shipped spire never holds it still: it rises, fires,
## collapses and rolls. That is the whole argument at rest — to twist IS to rise — and it
## is invisible to any one still, because a still catches one moment of it.
##
##   cycle   THE LEGACY BODY, byte for byte. The state machine owns the fold: it starts
##           deployed and aiming and thereafter runs DISC-RISE-AIM-FIRE-COLLAPSE-RELOCATE
##           on exactly the schedule it always had.
##   disc    the fold pinned flat — the mobile form, permanently. It still tracks, still
##           bursts, still relocates; it simply never gets up. A sniper firing off the
##           floor says the rise was never the weapon.
##   half    pinned mid-fold, caught between the two bodies: a twisted drum that is
##           neither a tile nor a mast. The state a still would otherwise never hold.
##   tower   the fold pinned extended — always a firing position, never a floor plate.
##           The standoff is permanent and legible from across the room.
##
## THE ROUTINE IS UNTOUCHED. The pin is written AFTER the state machine each frame, so
## every state still runs and every combat number — fire_damage, fire_speed,
## shots_per_burst, fire_interval, optimal_range, detection_radius, disc_speed,
## max_health — is identical at all four values. Only the fold is held.
const POSTURES: PackedStringArray = ["cycle", "disc", "half", "tower"]
@export_enum("cycle", "disc", "half", "tower") var posture: String = "cycle"

# State
var _health: float = 0.0
var _state: State = State.DISC
var _state_time: float = 0.0
var _twist: float = 1.0  # 0 = extended (tall), 1 = compressed (disc)
var _shot_timer: float = 0.0
var _shots_fired: int = 0
var _spin_angle: float = 0.0
var _player_node: Node3D = null

# Geometry
var _geometry: KreslingGeometry = null
var _mesh_root: Node3D = null
var _face_meshes: Array[MeshInstance3D] = []
var _platform: Node3D = null
var _muzzle: Marker3D = null

# Materials
var _shell_material: StandardMaterial3D
var _crease_material: StandardMaterial3D
var _platform_material: StandardMaterial3D


func _ready() -> void:
	_health = max_health
	_create_materials()
	_build_collision()
	_geometry = KreslingGeometry.new()
	_rebuild_mesh()
	_find_player()
	add_to_group("enemy")
	add_to_group("kresling_enemy")
	# Start extended for visibility during dev
	_set_state(State.AIM)
	_twist = 0.1
	# POSTURE — a pinned body is shown pinned from the FIRST frame, never caught on its
	# way there. `cycle` returns -1.0 and nothing below runs, so the shipped start pose
	# (AIM at _twist 0.1) is untouched.
	var pin: float = _pin_twist()
	if pin >= 0.0:
		_twist = pin
		_update_mesh()
	print("KreslingSpire: READY at %s" % global_position)
	# WARNING dressing, appended LAST so the collision shape and the mesh root keep
	# their child indices. "none" adds nothing at all — the legacy lineage.
	_build_warning()


func _physics_process(delta: float) -> void:
	_state_time += delta
	
	if not is_instance_valid(_player_node):
		_find_player()
	
	match _state:
		State.DISC:
			_process_disc(delta)
		State.RISE:
			_process_rise(delta)
		State.AIM:
			_process_aim(delta)
		State.FIRE:
			_process_fire(delta)
		State.COLLAPSE:
			_process_collapse(delta)
		State.RELOCATE:
			_process_relocate(delta)
		State.DEAD:
			_process_dead(delta)

	# POSTURE - held AFTER the state machine has written, so the routine (positioning,
	# aim, burst, relocate, death) is byte-identical at every value and only the fold is
	# fixed. `cycle` returns -1.0 and writes nothing at all.
	var pin: float = _pin_twist()
	if pin >= 0.0:
		_twist = pin

	_update_mesh()
	
	if _state != State.DEAD:
		move_and_slide()


func _process_disc(delta: float) -> void:
	_twist = move_toward(_twist, 0.95, delta * 3.0)
	
	# Spin while disc
	_spin_angle += delta * 0.4
	if _mesh_root:
		_mesh_root.rotation.y = _spin_angle
	
	# Move toward optimal range
	var dist: float = _get_player_distance()
	
	if dist <= detection_radius:
		if abs(dist - optimal_range) < 1.5:
			# Good position, rise up
			_set_state(State.RISE)
		else:
			# Move to optimal range
			velocity = _get_positioning_velocity()
	else:
		velocity = Vector3.ZERO


func _process_rise(_delta: float) -> void:
	velocity = Vector3.ZERO
	
	var t: float = clamp(_state_time / rise_duration, 0.0, 1.0)
	_twist = lerp(0.95, 0.1, ease(t, 0.4))
	
	# Untwist rotation
	_spin_angle = lerp(_spin_angle, 0.0, t)
	if _mesh_root:
		_mesh_root.rotation.y = _spin_angle
	
	if t >= 1.0:
		_set_state(State.AIM)


func _process_aim(delta: float) -> void:
	velocity = Vector3.ZERO
	_twist = move_toward(_twist, 0.05, delta * 2.0)
	
	_aim_at_player(delta)
	
	if _state_time >= aim_duration:
		_shots_fired = 0
		_shot_timer = 0.0
		_set_state(State.FIRE)


func _process_fire(delta: float) -> void:
	velocity = Vector3.ZERO
	_aim_at_player(delta)
	
	_shot_timer -= delta
	if _shot_timer <= 0.0 and _shots_fired < shots_per_burst:
		_fire_projectile()
		_shots_fired += 1
		_shot_timer = fire_interval
	
	if _shots_fired >= shots_per_burst and _shot_timer <= 0.0:
		# Check if should relocate
		var dist: float = _get_player_distance()
		if dist < optimal_range * 0.5 or dist > detection_radius:
			_set_state(State.COLLAPSE)
		else:
			# Fire again
			_shots_fired = 0
			_set_state(State.AIM)


func _process_collapse(_delta: float) -> void:
	velocity = Vector3.ZERO
	
	var t: float = clamp(_state_time / collapse_duration, 0.0, 1.0)
	_twist = lerp(0.05, 0.95, ease(t, 2.0))
	
	if t >= 1.0:
		_set_state(State.RELOCATE)


func _process_relocate(delta: float) -> void:
	_twist = 0.95
	
	# Spin while moving
	_spin_angle += delta * 0.5
	if _mesh_root:
		_mesh_root.rotation.y = _spin_angle
	
	velocity = _get_positioning_velocity() * 1.5
	
	var dist: float = _get_player_distance()
	if _state_time >= relocate_time or abs(dist - optimal_range) < 2.0:
		_set_state(State.RISE)


func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	_twist = move_toward(_twist, 0.7, delta)
	
	if _state_time >= 3.0:
		# Reset instead of destroy for dev observation
		_health = max_health
		_set_state(State.DISC)


## The fold value POSTURE holds, or -1.0 for "the state machine owns it" — which is the
## default and the shipped behaviour. Kept as one sentinel-returning function so the two
## call sites (first frame, every frame) can never disagree about what `cycle` means.
func _pin_twist() -> float:
	match posture:
		"disc":
			return 0.95
		"half":
			return 0.5
		"tower":
			return 0.05
		_:
			return -1.0


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0


func _get_positioning_velocity() -> Vector3:
	if not is_instance_valid(_player_node):
		return Vector3.ZERO
	
	var to_player: Vector3 = _player_node.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()
	
	if dist < 0.1:
		return Vector3.ZERO
	
	var dir: Vector3 = to_player.normalized()
	
	if dist < optimal_range * 0.6:
		# Too close, back away
		return -dir * disc_speed
	elif dist > optimal_range * 1.3:
		# Too far, approach
		return dir * disc_speed
	else:
		# Good range, strafe
		var side: Vector3 = Vector3(-dir.z, 0.0, dir.x)
		return side * disc_speed * 0.7


## Geometry

func _create_materials() -> void:
	_shell_material = StandardMaterial3D.new()
	_shell_material.albedo_color = shell_color
	_shell_material.metallic = 0.4
	_shell_material.roughness = 0.5
	_shell_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	_crease_material = StandardMaterial3D.new()
	_crease_material.albedo_color = crease_color
	_crease_material.metallic = 0.3
	_crease_material.roughness = 0.6
	
	_platform_material = StandardMaterial3D.new()
	_platform_material.albedo_color = core_color
	_platform_material.metallic = 0.6
	_platform_material.roughness = 0.3
	_platform_material.emission_enabled = true
	_platform_material.emission = emission_color
	_platform_material.emission_energy_multiplier = 0.8


func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape"
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = radius * 1.1
	capsule.height = radius * 4.0
	shape.shape = capsule
	add_child(shape)


func _rebuild_mesh() -> void:
	if _mesh_root and is_instance_valid(_mesh_root):
		_mesh_root.free()
	_face_meshes.clear()
	_platform = null
	_muzzle = null
	
	_geometry.build_pattern(radial_segments, layers, radius, edge_length)
	_geometry.solve_twist(_twist)
	
	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)
	
	# Build face meshes
	for i in range(_geometry.faces.size()):
		var mesh_inst: MeshInstance3D = MeshInstance3D.new()
		mesh_inst.name = "Face_%d" % i
		mesh_inst.material_override = _shell_material
		_mesh_root.add_child(mesh_inst)
		_face_meshes.append(mesh_inst)
	
	# Build top platform
	_platform = Node3D.new()
	_platform.name = "Platform"
	_mesh_root.add_child(_platform)
	
	var platform_mesh: MeshInstance3D = MeshInstance3D.new()
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.height = 0.08
	cylinder.top_radius = radius * 0.7
	cylinder.bottom_radius = radius * 0.8
	platform_mesh.mesh = cylinder
	platform_mesh.material_override = _platform_material
	_platform.add_child(platform_mesh)
	
	# Muzzle
	_muzzle = Marker3D.new()
	_muzzle.name = "Muzzle"
	_muzzle.position = Vector3(0.0, 0.05, -radius * 0.5)
	_platform.add_child(_muzzle)
	
	# Muzzle light
	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = emission_color
	light.light_energy = 1.5
	light.omni_range = 4.0
	_muzzle.add_child(light)
	
	_update_mesh()


func _update_mesh() -> void:
	if not _geometry:
		return
	
	_geometry.solve_twist(_twist)
	
	# Update face meshes
	for i in range(min(_face_meshes.size(), _geometry.faces.size())):
		if not is_instance_valid(_face_meshes[i]):
			continue
		var face: PackedInt32Array = _geometry.faces[i]
		if face.size() < 3:
			continue

		var v0: Vector3 = _geometry.vertices[face[0]]
		var v1: Vector3 = _geometry.vertices[face[1]]
		var v2: Vector3 = _geometry.vertices[face[2]]

		_face_meshes[i].mesh = _create_triangle_mesh(v0, v1, v2)
	
	# Update platform position
	if _platform:
		var top_pos: Vector3 = _geometry.get_top_center()
		top_pos.y = _geometry.get_height()
		_platform.position = top_pos


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

func _fire_projectile() -> void:
	if not FIRE_BOLT_SCENE or not _muzzle:
		return
	
	var bolt: Node = FIRE_BOLT_SCENE.instantiate()
	if not bolt:
		return
	
	var spawn_pos: Vector3 = _muzzle.global_position
	var fire_dir: Vector3 = _get_fire_direction()
	
	var scene: Node = get_tree().current_scene
	if scene:
		scene.add_child(bolt)
	else:
		add_child(bolt)
	
	if bolt.has_method("launch"):
		bolt.launch(spawn_pos, fire_dir, fire_speed, fire_damage)
	
	fired_projectile.emit(spawn_pos, fire_dir)


func _get_fire_direction() -> Vector3:
	if _muzzle:
		return -_muzzle.global_transform.basis.z.normalized()
	
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y += 1.2
		return to_player.normalized()
	
	return Vector3.FORWARD


func _aim_at_player(delta: float) -> void:
	if not _platform or not is_instance_valid(_player_node):
		return
	
	var target: Vector3 = _player_node.global_position + Vector3(0, 1.2, 0)
	var to_target: Vector3 = target - _platform.global_position
	
	if to_target.length_squared() < 0.001:
		return
	
	var yaw: float = atan2(to_target.x, to_target.z)
	_platform.rotation.y = lerp_angle(_platform.rotation.y, yaw, delta * 5.0)


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
		# Flash
		var tween: Tween = create_tween()
		tween.tween_property(_platform_material, "emission_energy_multiplier", 3.0, 0.05)
		tween.tween_property(_platform_material, "emission_energy_multiplier", 0.8, 0.15)


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
	var pattern_changed: bool = false
	if config.has("segments"):
		var want_segments: int = int(config["segments"])
		if want_segments != radial_segments:
			radial_segments = want_segments
			pattern_changed = true
	if config.has("layers"):
		var want_layers: int = int(config["layers"])
		if want_layers != layers:
			layers = want_layers
			pattern_changed = true
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("damage"):
		fire_damage = float(config["damage"])

	# GUARDED. This used to read `if _geometry: _rebuild_mesh()`, unconditionally, so ANY
	# config dict — including an empty one, and including one that only names a warning —
	# freed the mesh root and rebuilt every face of every shipped placement. Identical
	# geometry, thrown away and remade, plus a spin angle silently reset to zero. Only a
	# changed PATTERN rebuilds now; nothing else about the body moves.
	if pattern_changed and _geometry:
		_rebuild_mesh()

	# POSTURE — which body it stands in. Only an understood word that DIFFERS is taken, so
	# an absent key, a typo or a repeat of the current value leaves the fold exactly where
	# the state machine had it. The pose is applied immediately rather than waited for,
	# because a map that asks for a disc should not get a tower for one physics frame.
	if config.has("posture"):
		var want_posture: String = str(config["posture"]).strip_edges().to_lower()
		if POSTURES.has(want_posture) and want_posture != posture:
			posture = want_posture
			var pin: float = _pin_twist()
			if pin >= 0.0 and _geometry:
				_twist = pin
				_update_mesh()

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
# One axis, five values, the vocabulary shared with [[miura_crawler]],
# [[scissor_stalker]], [[kaleidocycle_enemy]] and [[path_block]]. Every builder below
# adds MeshInstance3D children only — never a collider, never a group the combat code
# reads, never a distance. Deterministic: nothing here draws from the random stream and
# nothing here is animated, so five variants of the same spire differ only in what
# stands around it.
#
# Sized from the EXPORTS, never from the live twist: _twist is a moving number (the
# tower is a disc at rest and a mast when it fires) and dressing that breathed with it
# would be an animation, not a still.

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


## The drum's half-width. KreslingGeometry centres its ring vertices on the origin at
## every twist, so the footprint is the pattern radius plus a little slack — read from
## the same export the shell is built from, never hardcoded.
func _warn_half() -> float:
	return maxf(radius * 1.15, 0.06)


## The height the spire needs when it is UP. A Kresling layer can never be longer than
## its diagonal edge, so edge_length * layers is the ceiling of the deployed tower —
## the volume a cage has to enclose and a mast has to overlook.
func _warn_top() -> float:
	return maxf(edge_length * float(layers) * 0.92, radius * 2.4)


## STAIN — the notice written on the ground. Scorch spreading well past the drum's own
## footprint, a darker core, and two burn runs bled off one side.
func _warn_stain() -> void:
	var h: float = _warn_half()
	var y: float = -0.028
	_warn_add(Vector3(0, y, 0), Vector3(h * 3.6, 0.012, h * 3.6),
		_warn_mat(WARN_STAIN_OUTER, 1.0, 0.0))
	_warn_add(Vector3(0, y + 0.007, 0), Vector3(h * 2.4, 0.012, h * 2.4),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(h * 1.45, y + 0.004, h * 0.50), Vector3(h * 1.05, 0.012, h * 0.36),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(-h * 1.20, y + 0.004, -h * 1.00), Vector3(h * 0.75, 0.012, h * 0.28),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))


## CAGE — the notice as paperwork. Four posts to the height of the deployed tower, two
## rings of rails, one filed yellow tag. The drum rises inside the bars on the twist it
## always had.
func _warn_cage() -> void:
	var h: float = _warn_half()
	var bot: float = -0.03
	var top: float = _warn_top()
	var p: float = h * 1.30
	var bar: StandardMaterial3D = _warn_mat(WARN_BAR, 0.45, 0.55)
	var thick: float = maxf(radius * 0.30, 0.03)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_warn_add(Vector3(float(sx) * p, (bot + top) * 0.5, float(sz) * p),
				Vector3(thick, top - bot, thick), bar)
	for ry in [top, bot + (top - bot) * 0.45]:
		var y: float = float(ry)
		for s in [-1.0, 1.0]:
			_warn_add(Vector3(0, y, float(s) * p),
				Vector3(p * 2.0 + thick, thick * 0.8, thick * 0.8), bar)
			_warn_add(Vector3(float(s) * p, y, 0),
				Vector3(thick * 0.8, thick * 0.8, p * 2.0 + thick), bar)
	_warn_add(Vector3(p + thick * 0.6, bot + (top - bot) * 0.62, 0),
		Vector3(0.016, top * 0.30, h * 1.55), _warn_mat(WARN_TAG, 0.7, 0.0))


## BEACON — the notice as broadcast. A mast beside the drum with a lamp head under a
## shade, and a lit outline on the floor around a thing that is otherwise almost flat.
func _warn_beacon() -> void:
	var h: float = _warn_half()
	var bot: float = -0.03
	var top: float = _warn_top()
	var mast_h: float = top * 1.15
	var mast: StandardMaterial3D = _warn_mat(WARN_MAST, 0.4, 0.6)
	var lamp: StandardMaterial3D = _warn_emissive(WARN_LAMP, 3.2)
	var thick: float = maxf(radius * 0.30, 0.03)
	var mx: float = -h * 1.30
	_warn_add(Vector3(mx, bot + mast_h * 0.5, 0), Vector3(thick, mast_h, thick), mast)
	_warn_add(Vector3(mx, bot + mast_h + h * 0.30, 0), Vector3(h * 0.72, h * 0.42, h * 0.72), lamp)
	_warn_add(Vector3(mx, bot + mast_h + h * 0.60, 0), Vector3(h * 1.05, thick * 0.7, h * 1.05), mast)
	for s in [-1.0, 1.0]:
		_warn_add(Vector3(0, bot + 0.012, float(s) * h * 1.6),
			Vector3(h * 3.2, 0.02, thick), lamp)
		_warn_add(Vector3(float(s) * h * 1.6, bot + 0.012, 0),
			Vector3(thick, 0.02, h * 3.2), lamp)


## SHROUD — the notice withheld. A canvas sleeve standing over the collapsed drum,
## taller than the disc and shorter than the tower: what the spire looks like at rest
## goes under cloth, and only the firing form clears the cover. The twist, the range
## and the burst are unchanged underneath.
func _warn_shroud() -> void:
	var h: float = _warn_half()
	var cloth: StandardMaterial3D = _warn_mat(WARN_CLOTH, 0.95, 0.0)
	var strap: StandardMaterial3D = _warn_mat(WARN_STRAP, 0.85, 0.1)
	var w: float = h * 2.3
	var lid: float = _warn_top() * 0.62
	_warn_add(Vector3(0, lid, 0), Vector3(w, 0.05, w), cloth)
	for s in [-1.0, 1.0]:
		_warn_add(Vector3(0, lid * 0.5 - 0.015, float(s) * w * 0.5),
			Vector3(w, lid + 0.03, 0.02), cloth)
		_warn_add(Vector3(float(s) * w * 0.5, lid * 0.5 - 0.015, 0),
			Vector3(0.02, lid + 0.03, w), cloth)
	_warn_add(Vector3(0, lid + 0.035, 0), Vector3(w * 0.30, 0.05, w * 0.30), cloth)
	for s in [-1.0, 1.0]:
		_warn_add(Vector3(0, lid * 0.62 + float(s) * lid * 0.24, 0),
			Vector3(w + 0.014, 0.020, w + 0.014), strap)


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
