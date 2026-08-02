# @identity
# essence: fold(t) = sin(crawl_phase) — Miura-ori corrugation drives inchworm locomotion
# desire: a flat sheet that ripples toward you like a living carpet, compresses to strike, then flattens to disappear
# critical_parameter: _fold_amount — 0 is flat (dormant/invisible), 1 is fully corrugated (attack wind-up)
# triggers: state machine (DORMANT→ALERT→CRAWL→ATTACK→FLATTEN) with fold amount oscillating during crawl phase
# emerges: the inchworm gait arises from sinusoidal fold cycling — no explicit leg animation, just geometry folding
# needs: MiuraGeometry solver [has]; mountain/valley crease visualization [has]; player detection [has]
# relationships: contrasts with kresling_spire (horizontal vs vertical folding); feeds random_game hazard gauntlet
# truth: Miura-ori proves that a single degree of freedom — fold amount — can generate locomotion from flat material.

extends CharacterBody3D
class_name MiuraCrawler
## Miura-ori folding enemy - flat corrugated sheet that crawls like an inchworm.
## Can flatten to squeeze through gaps, pops up to attack.

signal enemy_destroyed(enemy: Node3D)

enum State { DORMANT, ALERT, CRAWL, ATTACK, FLATTEN, DEAD }

@export_group("Geometry")
@export var rows: int = 4
@export var cols: int = 6
@export var panel_width: float = 0.12
@export var panel_height: float = 0.10
@export var skew_angle: float = 65.0

@export_group("Combat")
@export var max_health: float = 60.0
@export var crawl_speed: float = 2.0
@export var detection_radius: float = 8.0
@export var attack_radius: float = 1.5
@export var attack_damage: float = 18.0
@export var attack_cooldown: float = 1.2

@export_group("Timing")
@export var alert_time: float = 4.0
@export var pop_duration: float = 3.0
@export var flatten_duration: float = 2.5

@export_group("Appearance")
@export var surface_color: Color = Color(0.45, 0.52, 0.48, 1.0)
@export var mountain_color: Color = Color(0.7, 0.25, 0.2, 1.0)
@export var valley_color: Color = Color(0.2, 0.35, 0.7, 1.0)
@export var emission_color: Color = Color(0.9, 0.5, 0.2, 1.0)

## AXIS — WARNING: how much the hazard tells you BEFORE it costs you anything.
## Adopted word for word from [[catalyst_vent]], [[path_block]],
## [[kaleidocycle_enemy]] and [[scissor_stalker]] — one vocabulary across the
## hazards. The crawler is the family's limit case: its whole predation strategy is
## to FLATTEN, and with no player in range that is the state it relaxes into within a
## couple of seconds, so the resting pose of this creature is camouflage. What it
## looks like is therefore never the warning. Whatever warning exists has to be
## something the world put around it.
##
##   none    the sheet alone, unannounced — THE LEGACY BODY, byte for byte. Flat, it
##           reads as a panel of floor with a diagram printed on it.
##   stain   a dull discolouration soaked into the ground it has been crossing,
##           spreading past the sheet's own footprint on every side.
##   cage    a bolted bar frame and a filed yellow tag. Somebody catalogued it and
##           fenced it, and it crawls under the bars on exactly the same gait.
##   beacon  a lit mast at the sheet's edge with a lamp head, plus a glowing outline
##           on the floor around a thing that is otherwise almost invisible.
##   shroud  a fitted canvas cover over the sheet. The mountain/valley crease diagram
##           — the only thing that gave it away as a mechanism — goes under cloth.
##
## APPEARANCE ONLY. attack_damage, attack_radius, attack_cooldown, crawl_speed,
## detection_radius, max_health, the fold schedule and the collision box are
## byte-identical across all five values. A hazard that hides itself is not a gentler
## hazard.
const WARNING_VALUES: PackedStringArray = ["none", "stain", "cage", "beacon", "shroud"]
@export_enum("none", "stain", "cage", "beacon", "shroud") var warning: String = "none"

# State
var _health: float = 0.0
var _state: State = State.DORMANT
var _state_time: float = 0.0
var _fold_amount: float = 0.0  # 0 = flat, 1 = corrugated
var _crawl_phase: float = 0.0  # For inchworm locomotion
var _attack_timer: float = 0.0
var _player_node: Node3D = null

# Geometry
var _geometry: MiuraGeometry = null
var _mesh_root: Node3D = null
var _face_meshes: Array[MeshInstance3D] = []
var _crease_meshes: Array[MeshInstance3D] = []

# Materials
var _surface_material: StandardMaterial3D
var _mountain_material: StandardMaterial3D
var _valley_material: StandardMaterial3D


func _ready() -> void:
	_health = max_health
	_create_materials()
	_build_collision()
	_geometry = MiuraGeometry.new()
	_rebuild_mesh()
	_find_player()
	add_to_group("enemy")
	add_to_group("miura_enemy")
	# Start in CRAWL for visibility during dev
	_set_state(State.CRAWL)
	_fold_amount = 0.7
	print("MiuraCrawler: READY at %s" % global_position)
	# WARNING dressing, appended LAST so the mesh root and every crease keep their
	# child indices. "none" adds nothing at all — the legacy lineage.
	_build_warning()


func _physics_process(delta: float) -> void:
	_state_time += delta
	_attack_timer = max(0.0, _attack_timer - delta)
	
	if not is_instance_valid(_player_node):
		_find_player()
	
	match _state:
		State.DORMANT:
			_process_dormant(delta)
		State.ALERT:
			_process_alert(delta)
		State.CRAWL:
			_process_crawl(delta)
		State.ATTACK:
			_process_attack(delta)
		State.FLATTEN:
			_process_flatten(delta)
		State.DEAD:
			_process_dead(delta)
	
	_update_mesh()
	
	if _state != State.DEAD:
		move_and_slide()


func _process_dormant(delta: float) -> void:
	_fold_amount = move_toward(_fold_amount, 0.05, delta * 2.0)
	velocity = Vector3.ZERO
	
	var dist: float = _get_player_distance()
	if dist <= detection_radius:
		_set_state(State.ALERT)


func _process_alert(delta: float) -> void:
	# Pop up from flat
	var t: float = clamp(_state_time / alert_time, 0.0, 1.0)
	_fold_amount = lerp(0.05, 0.7, ease(t, 0.3))
	velocity = Vector3.ZERO
	
	_face_player(delta * 2.0)
	
	if t >= 1.0:
		_set_state(State.CRAWL)


func _process_crawl(delta: float) -> void:
	var dist: float = _get_player_distance()
	
	# Disengage if player too far
	if dist > detection_radius * 1.5:
		_set_state(State.FLATTEN)
		return
	
	# Attack if close enough
	if dist <= attack_radius and _attack_timer <= 0.0:
		_set_state(State.ATTACK)
		return
	
	# Inchworm locomotion
	_crawl_phase += delta * 0.3
	var phase: float = fmod(_crawl_phase, TAU)
	
	# Fold cycles: bunch up then extend
	var cycle_fold: float = 0.5 + 0.35 * sin(phase)
	_fold_amount = move_toward(_fold_amount, cycle_fold, delta * 4.0)
	
	# Movement: faster during extension phase
	var move_mult: float = 0.5 + 0.5 * max(0.0, cos(phase))
	
	if is_instance_valid(_player_node):
		var to_player: Vector3 = _player_node.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.1:
			var move_dir: Vector3 = to_player.normalized()
			velocity = move_dir * crawl_speed * move_mult
			_face_player(delta * 3.0)
		else:
			velocity = Vector3.ZERO
	else:
		velocity = Vector3.ZERO


func _process_attack(_delta: float) -> void:
	# Lunge attack: pop up high then slam
	var t: float = clamp(_state_time / 0.4, 0.0, 1.0)
	
	if t < 0.3:
		# Wind up - compress
		_fold_amount = lerp(0.7, 1.0, t / 0.3)
	elif t < 0.6:
		# Strike - extend toward player
		_fold_amount = lerp(1.0, 0.3, (t - 0.3) / 0.3)
		
		# Deal damage at peak
		if t > 0.4 and t < 0.5:
			_try_damage_player()
	else:
		# Recovery
		_fold_amount = lerp(0.3, 0.7, (t - 0.6) / 0.4)
	
	velocity = Vector3.ZERO
	
	if t >= 1.0:
		_attack_timer = attack_cooldown
		_set_state(State.CRAWL)


func _process_flatten(_delta: float) -> void:
	var t: float = clamp(_state_time / flatten_duration, 0.0, 1.0)
	_fold_amount = lerp(0.7, 0.05, ease(t, 2.0))
	velocity = Vector3.ZERO
	
	if t >= 1.0:
		_set_state(State.DORMANT)


func _process_dead(delta: float) -> void:
	velocity = Vector3.ZERO
	_fold_amount = move_toward(_fold_amount, 0.0, delta)
	
	if _state_time >= 3.0:
		# Reset instead of destroy for dev observation
		_health = max_health
		_set_state(State.DORMANT)


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_state_time = 0.0


## Geometry

func _create_materials() -> void:
	_surface_material = StandardMaterial3D.new()
	_surface_material.albedo_color = surface_color
	_surface_material.metallic = 0.1
	_surface_material.roughness = 0.7
	_surface_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	_mountain_material = StandardMaterial3D.new()
	_mountain_material.albedo_color = mountain_color
	_mountain_material.metallic = 0.3
	_mountain_material.roughness = 0.5
	_mountain_material.emission_enabled = true
	_mountain_material.emission = mountain_color * 0.5
	_mountain_material.emission_energy_multiplier = 0.3
	
	_valley_material = StandardMaterial3D.new()
	_valley_material.albedo_color = valley_color
	_valley_material.metallic = 0.3
	_valley_material.roughness = 0.5


func _build_collision() -> void:
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "CollisionShape"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(cols * panel_width, 0.15, rows * panel_height)
	shape.shape = box
	add_child(shape)


func _rebuild_mesh() -> void:
	if _mesh_root and is_instance_valid(_mesh_root):
		_mesh_root.free()
	_face_meshes.clear()
	_crease_meshes.clear()
	
	_geometry.build_pattern(rows, cols, panel_width, panel_height, skew_angle)
	_geometry.solve_fold(_fold_amount)
	
	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)
	
	# Build face meshes
	for i in range(_geometry.faces.size()):
		var mesh_inst: MeshInstance3D = MeshInstance3D.new()
		mesh_inst.name = "Face_%d" % i
		mesh_inst.material_override = _surface_material
		_mesh_root.add_child(mesh_inst)
		_face_meshes.append(mesh_inst)
	
	# Build crease lines
	for edge in _geometry.mountain_creases:
		var line: MeshInstance3D = _create_crease_line(_mountain_material)
		_mesh_root.add_child(line)
		_crease_meshes.append(line)
	
	for edge in _geometry.valley_creases:
		var line: MeshInstance3D = _create_crease_line(_valley_material)
		_mesh_root.add_child(line)
		_crease_meshes.append(line)
	
	_update_mesh()


func _create_crease_line(material: Material) -> MeshInstance3D:
	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.height = 0.1
	cylinder.top_radius = 0.003
	cylinder.bottom_radius = 0.003
	mesh_inst.mesh = cylinder
	mesh_inst.material_override = material
	return mesh_inst


func _update_mesh() -> void:
	if not _geometry:
		return
	
	_geometry.solve_fold(_fold_amount)
	
	# Update face meshes
	for i in range(min(_face_meshes.size(), _geometry.faces.size())):
		if not is_instance_valid(_face_meshes[i]):
			continue
		var face: PackedInt32Array = _geometry.faces[i]
		if face.size() < 4:
			continue

		var v0: Vector3 = _geometry.vertices[face[0]]
		var v1: Vector3 = _geometry.vertices[face[1]]
		var v2: Vector3 = _geometry.vertices[face[2]]
		var v3: Vector3 = _geometry.vertices[face[3]]

		_face_meshes[i].mesh = _create_quad_mesh(v0, v1, v2, v3)
	
	# Update crease lines
	var crease_idx: int = 0
	for edge in _geometry.mountain_creases:
		if crease_idx < _crease_meshes.size() and is_instance_valid(_crease_meshes[crease_idx]):
			_update_crease_line(_crease_meshes[crease_idx], edge)
			crease_idx += 1

	for edge in _geometry.valley_creases:
		if crease_idx < _crease_meshes.size() and is_instance_valid(_crease_meshes[crease_idx]):
			_update_crease_line(_crease_meshes[crease_idx], edge)
			crease_idx += 1


func _create_quad_mesh(v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3) -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	# Two triangles for quad
	var vertices: PackedVector3Array = [v0, v1, v2, v0, v2, v3]
	
	var normal1: Vector3 = (v1 - v0).cross(v2 - v0).normalized()
	var normal2: Vector3 = (v2 - v0).cross(v3 - v0).normalized()
	var normals: PackedVector3Array = [normal1, normal1, normal1, normal2, normal2, normal2]
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _update_crease_line(mesh_inst: MeshInstance3D, edge: Vector2i) -> void:
	var v0: Vector3 = _geometry.vertices[edge.x]
	var v1: Vector3 = _geometry.vertices[edge.y]
	var mid: Vector3 = (v0 + v1) * 0.5
	var direction: Vector3 = v1 - v0
	var length: float = direction.length()
	
	if length < 0.001:
		mesh_inst.visible = false
		return
	
	mesh_inst.visible = true
	
	var cylinder: CylinderMesh = mesh_inst.mesh as CylinderMesh
	if cylinder:
		cylinder.height = length
	
	mesh_inst.position = mid
	
	var up: Vector3 = direction.normalized()
	if abs(up.dot(Vector3.UP)) < 0.99:
		mesh_inst.look_at(mesh_inst.position + up, Vector3.UP)
		mesh_inst.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	else:
		mesh_inst.rotation = Vector3.ZERO


## Combat

func _try_damage_player() -> void:
	if not is_instance_valid(_player_node):
		return
	
	var dist: float = global_position.distance_to(_player_node.global_position)
	if dist > attack_radius * 1.5:
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
		# Flash on hit
		var tween: Tween = create_tween()
		tween.tween_property(_surface_material, "emission_energy_multiplier", 2.0, 0.05)
		tween.tween_property(_surface_material, "emission_energy_multiplier", 0.0, 0.15)


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


func _face_player(speed: float) -> void:
	if not is_instance_valid(_player_node):
		return
	
	var to_player: Vector3 = _player_node.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.001:
		return
	
	var target_yaw: float = atan2(to_player.x, to_player.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, speed)


func configure(config: Dictionary) -> void:
	if config.has("rows"):
		rows = int(config["rows"])
	if config.has("cols"):
		cols = int(config["cols"])
	if config.has("health"):
		max_health = float(config["health"])
		_health = max_health
	if config.has("speed"):
		crawl_speed = float(config["speed"])
	if config.has("damage"):
		attack_damage = float(config["damage"])

	if _geometry:
		_rebuild_mesh()

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
# [[path_block]], [[kaleidocycle_enemy]] and [[scissor_stalker]]. Every builder below
# adds MeshInstance3D children only — never a collider, never a group, never a
# distance the combat code reads. Deterministic: nothing here draws from the random
# stream, so five variants of the same sheet differ only in what surrounds it.

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


## The sheet's half-extents. MiuraGeometry recentres its vertices every solve, so the
## pattern sits symmetrically on the origin and these match the collision box the
## crawler already builds — read from the same two exports, never hardcoded.
func _warn_half_x() -> float:
	return maxf(float(cols) * panel_width * 0.5, 0.05)


func _warn_half_z() -> float:
	return maxf(float(rows) * panel_height * 0.5, 0.05)


## STAIN — the notice written on the ground. A dull discolouration spreading past the
## sheet's own footprint, with a darker core and two runs bled off one side.
func _warn_stain() -> void:
	var hx: float = _warn_half_x()
	var hz: float = _warn_half_z()
	var y: float = -0.028
	_warn_add(Vector3(0, y, 0), Vector3(hx * 3.4, 0.012, hz * 3.4),
		_warn_mat(WARN_STAIN_OUTER, 1.0, 0.0))
	_warn_add(Vector3(0, y + 0.007, 0), Vector3(hx * 2.3, 0.012, hz * 2.3),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(hx * 1.35, y + 0.004, hz * 0.45), Vector3(hx * 0.95, 0.012, hz * 0.34),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))
	_warn_add(Vector3(-hx * 1.15, y + 0.004, -hz * 0.95), Vector3(hx * 0.70, 0.012, hz * 0.26),
		_warn_mat(WARN_STAIN_CORE, 1.0, 0.0))


## CAGE — the notice as paperwork. Four posts, two rails, one filed yellow tag. The
## sheet crawls under the bars on the gait it always had.
func _warn_cage() -> void:
	var hx: float = _warn_half_x()
	var hz: float = _warn_half_z()
	var r: float = maxf(hx, hz)
	var bot: float = -0.03
	var top: float = r * 0.95
	var px: float = hx * 1.30
	var pz: float = hz * 1.55
	var bar: StandardMaterial3D = _warn_mat(WARN_BAR, 0.45, 0.55)
	var thick: float = maxf(r * 0.09, 0.028)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_warn_add(Vector3(float(sx) * px, (bot + top) * 0.5, float(sz) * pz),
				Vector3(thick, top - bot, thick), bar)
	for ry in [top, bot + (top - bot) * 0.45]:
		var y: float = float(ry)
		for s in [-1.0, 1.0]:
			_warn_add(Vector3(0, y, float(s) * pz),
				Vector3(px * 2.0 + thick, thick * 0.8, thick * 0.8), bar)
			_warn_add(Vector3(float(s) * px, y, 0),
				Vector3(thick * 0.8, thick * 0.8, pz * 2.0 + thick), bar)
	_warn_add(Vector3(px + thick * 0.6, bot + (top - bot) * 0.72, 0),
		Vector3(0.016, r * 0.34, r * 0.50), _warn_mat(WARN_TAG, 0.7, 0.0))


## BEACON — the notice as broadcast. A mast at the sheet's edge with a lamp head on a
## shade, and a lit outline on the floor around a thing that is otherwise flat.
func _warn_beacon() -> void:
	var hx: float = _warn_half_x()
	var hz: float = _warn_half_z()
	var r: float = maxf(hx, hz)
	var bot: float = -0.03
	var mast_h: float = r * 2.1
	var mast: StandardMaterial3D = _warn_mat(WARN_MAST, 0.4, 0.6)
	var lamp: StandardMaterial3D = _warn_emissive(WARN_LAMP, 3.2)
	var thick: float = maxf(r * 0.09, 0.028)
	var mx: float = -hx * 1.05
	_warn_add(Vector3(mx, bot + mast_h * 0.5, 0), Vector3(thick, mast_h, thick), mast)
	_warn_add(Vector3(mx, bot + mast_h + r * 0.18, 0), Vector3(r * 0.42, r * 0.24, r * 0.42), lamp)
	_warn_add(Vector3(mx, bot + mast_h + r * 0.36, 0), Vector3(r * 0.60, thick * 0.7, r * 0.60), mast)
	for s in [-1.0, 1.0]:
		_warn_add(Vector3(0, bot + 0.012, float(s) * hz * 1.5),
			Vector3(hx * 2.5, 0.02, thick), lamp)
		_warn_add(Vector3(float(s) * hx * 1.25, bot + 0.012, 0),
			Vector3(thick, 0.02, hz * 3.0), lamp)


## SHROUD — the notice withheld. A fitted canvas cover with short skirts down to the
## floor: the mountain/valley crease diagram, the only thing that read as a mechanism,
## goes under cloth. The sheet folds and crawls exactly as before.
func _warn_shroud() -> void:
	var hx: float = _warn_half_x()
	var hz: float = _warn_half_z()
	var cloth: StandardMaterial3D = _warn_mat(WARN_CLOTH, 0.95, 0.0)
	var strap: StandardMaterial3D = _warn_mat(WARN_STRAP, 0.85, 0.1)
	var w: float = hx * 2.0 + 0.10
	var d: float = hz * 2.0 + 0.10
	var lid: float = 0.075
	_warn_add(Vector3(0, lid, 0), Vector3(w, 0.05, d), cloth)
	for s in [-1.0, 1.0]:
		_warn_add(Vector3(0, lid * 0.5 - 0.015, float(s) * d * 0.5), Vector3(w, lid + 0.03, 0.02), cloth)
		_warn_add(Vector3(float(s) * w * 0.5, lid * 0.5 - 0.015, 0), Vector3(0.02, lid + 0.03, d), cloth)
	_warn_add(Vector3(0, lid + 0.035, 0), Vector3(w * 0.26, 0.05, d * 0.26), cloth)
	for s in [-1.0, 1.0]:
		_warn_add(Vector3(0, lid + 0.026, float(s) * d * 0.28), Vector3(w + 0.012, 0.016, 0.05), strap)


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
