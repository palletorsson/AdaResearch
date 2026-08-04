# @identity
# essence: body = assemble(available_parts) -- asymmetric creature built from mismatched geometric primitives
# desire: a golem that shatters and rebuilds from whatever is at hand, never the same body twice
# critical_parameter: available parts inventory -- which primitives are nearby determines the next body form
# triggers: damage causes disassembly; reassembly from local parts; each rebuild produces different geometry
# emerges: improvisation as survival -- the bricoleur's method applied to self-construction
# needs: HazardCreatureBase [has]; procedural part assembly [has]; disassembly/reassembly [has]; VR interaction [missing]
# relationships: embodies bricolage sequence philosophy; contrasts with mesh_morpher (fixed topologies vs improvised)
# truth: the bricoleur does not design -- it discovers what available parts want to become.

extends HazardCreatureBase
class_name BricoleurGolem
## Asymmetric body assembled from mismatched primitive parts.
## Each body slot picks a random mesh type and color. On damage,
## parts fly off and new random parts snap back (rebuild).
## After 3 rebuilds, enters EXHAUSTED state (slower, no more rebuilds).

enum BodySlot { HEAD, TORSO, LEFT_ARM, RIGHT_ARM, LEFT_LEG, RIGHT_LEG }

@export_group("Bricolage")
@export var rebuild_time: float = 1.5
@export var rebuild_heal_pct: float = 0.2
@export var max_rebuilds: int = 3
@export var part_scatter_distance: float = 1.5
@export var exhausted_speed_mult: float = 0.4

# --- DNA (promoted 2026-08-04, stage 2) ------------------------------------------------
# The golem shipped with five knobs, and every one of them was a duration or a multiplier:
# how long the rebuild takes, how much it heals, how far the parts fly. None of that is in
# a photograph. The two decisions that actually carry the bricolage argument were written
# as literals — randi_range(0, 3) over four primitive classes, and six slot positions that
# quietly assume a humanoid.
#
# salvage — WHAT IS AT HAND. "mixed" is the shipped pile: box, sphere, cylinder, prism,
#   drawn at random per slot, so the body is visibly scavenged. The single-stock piles
#   (crates / pipes / stones / offcuts) hand the bricoleur a warehouse instead of a junkyard,
#   and the result reads as designed — which is the argument. Bricolage is only legible when
#   the stock is heterogeneous; homogeneous stock produces a product, not an improvisation.
# assembly — WHAT IS DONE WITH IT. "figure" is the shipped six-slot humanoid: found parts
#   forced into a body plan they never had. "lashed" keeps the plan but lets the joints show
#   (canted, gapped). "cairn" abandons anatomy for stacking. "heap" refuses to stand the
#   parts up at all — the pile that has not yet been made into anything.
#
# part_seed exists because the sweep is one still per value: with the shipped global randf()
# every render is a different golem and any measured "bite" is noise. 0 keeps the shipped
# unseeded behaviour; the gallery fixture pins a non-zero seed so the axis is the only
# variable in the frame.
@export_enum("mixed", "crates", "pipes", "stones", "offcuts") var salvage: String = "mixed"
@export_enum("figure", "lashed", "cairn", "heap") var assembly: String = "figure"
@export var part_seed: int = 0  ## 0 = unseeded, exactly the shipped global-RNG behaviour

# ── Slot positions ───────────────────────────────────────────────────────

const SLOT_POSITIONS: Array[Vector3] = [
	Vector3(0, 0.55, 0),       # HEAD
	Vector3(0, 0.3, 0),        # TORSO
	Vector3(-0.2, 0.35, 0),    # LEFT_ARM
	Vector3(0.2, 0.35, 0),     # RIGHT_ARM
	Vector3(-0.08, 0.0, 0),    # LEFT_LEG
	Vector3(0.08, 0.0, 0),     # RIGHT_LEG
]

const SLOT_BASE_SIZES: Array[float] = [
	0.08,  # HEAD
	0.12,  # TORSO
	0.05,  # LEFT_ARM
	0.05,  # RIGHT_ARM
	0.05,  # LEFT_LEG
	0.05,  # RIGHT_LEG
]

const SLOT_NAMES: Array[String] = [
	"HEAD", "TORSO", "LEFT_ARM", "RIGHT_ARM", "LEFT_LEG", "RIGHT_LEG"
]

# Alternative assemblies. Same six parts, same six sizes — only the joinery changes.
const LASHED_POSITIONS: Array[Vector3] = [
	Vector3(0.07, 0.60, -0.05),   # HEAD, sitting off-centre on the torso
	Vector3(0.0, 0.30, 0.0),      # TORSO
	Vector3(-0.29, 0.44, 0.06),   # LEFT_ARM, hung wide with a visible gap
	Vector3(0.27, 0.26, -0.07),   # RIGHT_ARM, lower than the left
	Vector3(-0.14, 0.02, 0.06),   # LEFT_LEG, splayed
	Vector3(0.15, 0.05, -0.05),   # RIGHT_LEG, splayed the other way
]

const CAIRN_POSITIONS: Array[Vector3] = [
	Vector3(0.0, 0.68, 0.0),      # HEAD on top of the stack
	Vector3(0.0, 0.16, 0.0),      # TORSO near the base
	Vector3(0.0, 0.42, 0.0),
	Vector3(0.0, 0.55, 0.0),
	Vector3(0.0, 0.04, 0.0),
	Vector3(0.0, 0.31, 0.0),
]

const HEAP_POSITIONS: Array[Vector3] = [
	Vector3(0.17, 0.05, 0.10),
	Vector3(0.0, 0.07, 0.0),
	Vector3(-0.20, 0.03, 0.05),
	Vector3(0.11, 0.03, -0.18),
	Vector3(-0.11, 0.02, -0.15),
	Vector3(0.21, 0.02, -0.02),
]

# ── State ────────────────────────────────────────────────────────────────

var _rng := RandomNumberGenerator.new()
var _rng_ready: bool = false
var _golem_built: bool = false

var _rebuild_count: int = 0
var _is_rebuilding: bool = false
var _rebuild_timer: float = 0.0
var _is_exhausted: bool = false
var _walk_phase: float = 0.0

# ── Visual refs ──────────────────────────────────────────────────────────

var _part_meshes: Array[MeshInstance3D] = []
var _part_materials: Array[StandardMaterial3D] = []
var _part_original_pos: Array[Vector3] = []
var _scattered_targets: Array[Vector3] = []


func _on_ready() -> void:
	_mesh_root.position.y = 0.15
	max_health = 100.0
	_health = max_health
	chase_speed = 2.8
	patrol_speed = 1.2
	contact_damage = 15.0


## Seed the part RNG once, before the first draw. part_seed = 0 calls randomize(),
## which is what the shipped global randf()/randi_range() already did — every launch
## a different golem. A non-zero seed pins the stream so a still can measure an axis.
func _ensure_rng() -> void:
	if _rng_ready:
		return
	if part_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = part_seed
	_rng_ready = true


func _create_materials() -> void:
	_ensure_rng()
	_part_materials.clear()
	for i in range(6):
		var hue: float = _rng.randf()
		var color := Color.from_hsv(hue, 0.6, 0.7)
		var mat := _make_material(color, color * 0.3)
		_part_materials.append(mat)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.15
	shape.height = 0.6
	col.shape = shape
	col.position.y = 0.45
	add_child(col)


func _build_mesh() -> void:
	_ensure_rng()
	_part_meshes.clear()
	_part_original_pos.clear()
	for i in range(6):
		_build_random_part(i)
	_golem_built = true


## The six slot positions for the current assembly. "figure" returns the shipped
## literals untouched, so a default golem is the pre-promotion golem.
func _slot_positions() -> Array[Vector3]:
	match assembly:
		"lashed":
			return LASHED_POSITIONS
		"cairn":
			return CAIRN_POSITIONS
		"heap":
			return HEAP_POSITIONS
	return SLOT_POSITIONS


func _build_random_part(slot_index: int) -> void:
	# Remove old mesh if it exists
	if slot_index < _part_meshes.size() and is_instance_valid(_part_meshes[slot_index]):
		_part_meshes[slot_index].queue_free()

	var base_size: float = SLOT_BASE_SIZES[slot_index]
	var size_variation: float = base_size * _rng.randf_range(0.8, 1.2)
	var mesh: Mesh = _random_mesh(size_variation)

	# New material with random hue
	var hue: float = _rng.randf()
	var color := Color.from_hsv(hue, 0.6, 0.7)
	var mat := _make_material(color, color * 0.3)

	if slot_index < _part_materials.size():
		_part_materials[slot_index] = mat
	else:
		_part_materials.append(mat)

	var positions: Array[Vector3] = _slot_positions()
	var pos: Vector3 = positions[slot_index]
	var mi := _add_mesh(mesh, mat, pos)
	mi.name = "Part_%s" % SLOT_NAMES[slot_index]

	# Joinery. "figure" leaves every part axis-aligned, exactly as shipped; the other
	# assemblies cant the parts so the improvisation is visible in the silhouette.
	# The three draws happen either way so that the RNG stream — and therefore every
	# part's size and hue — is identical across assembly values under a pinned seed.
	var tilt: float = 0.9 if assembly == "heap" else 0.45
	var cant := Vector3(
		_rng.randf_range(-tilt, tilt),
		_rng.randf_range(-PI, PI),
		_rng.randf_range(-tilt, tilt)
	)
	if assembly != "figure":
		mi.rotation = cant

	if slot_index < _part_meshes.size():
		_part_meshes[slot_index] = mi
	else:
		_part_meshes.append(mi)

	if slot_index < _part_original_pos.size():
		_part_original_pos[slot_index] = pos
	else:
		_part_original_pos.append(pos)


## Which primitive classes the pile holds. "mixed" is the shipped draw over all four.
## The draw is taken whatever the salvage, so a single-stock pile does not shift the
## RNG stream and every variant keeps the same part sizes and hues under a pinned seed.
func _pick_primitive() -> int:
	var drawn: int = _rng.randi_range(0, 3)
	match salvage:
		"crates":
			return 0
		"stones":
			return 1
		"pipes":
			return 2
		"offcuts":
			return 3
	return drawn


func _random_mesh(size: float) -> Mesh:
	var choice: int = _pick_primitive()
	match choice:
		0:
			var m := BoxMesh.new()
			m.size = Vector3(size, size, size)
			return m
		1:
			var m := SphereMesh.new()
			m.radius = size
			m.height = size * 2.0
			return m
		2:
			var m := CylinderMesh.new()
			m.height = size * 2.0
			m.top_radius = size * 0.5
			m.bottom_radius = size * 0.5
			return m
		3:
			var m := PrismMesh.new()
			m.size = Vector3(size, size, size)
			return m
	# Fallback
	var m := BoxMesh.new()
	m.size = Vector3(size, size, size)
	return m


func _process_visual(delta: float) -> void:
	if _is_rebuilding:
		_process_rebuild(delta)
		return

	# Walk animation (swing legs)
	if _state == BaseState.PATROL or _state == BaseState.CHASE:
		_walk_phase += delta * 4.0
		_animate_legs()

	# Exhausted visual: slight droop
	if _is_exhausted:
		_mesh_root.rotation.x = sin(_state_time) * 0.05 + 0.1


func _animate_legs() -> void:
	# LEFT_LEG (index 4) and RIGHT_LEG (index 5)
	var positions: Array[Vector3] = _slot_positions()
	if _part_meshes.size() > 5:
		if is_instance_valid(_part_meshes[4]):
			_part_meshes[4].position.z = positions[4].z + sin(_walk_phase) * 0.06
			_part_meshes[4].position.y = positions[4].y + abs(sin(_walk_phase)) * 0.03
		if is_instance_valid(_part_meshes[5]):
			_part_meshes[5].position.z = positions[5].z + sin(_walk_phase + PI) * 0.06
			_part_meshes[5].position.y = positions[5].y + abs(sin(_walk_phase + PI)) * 0.03


func _on_damaged(amount: float) -> void:
	if _is_rebuilding:
		return

	if _is_exhausted or _rebuild_count >= max_rebuilds:
		# No more rebuilds, just stun
		_is_exhausted = true
		chase_speed = chase_speed * exhausted_speed_mult
		patrol_speed = patrol_speed * exhausted_speed_mult
		_set_state(BaseState.STUNNED)
		return

	# Start rebuild: scatter parts outward
	_is_rebuilding = true
	_rebuild_timer = 0.0
	_rebuild_count += 1
	velocity = Vector3.ZERO

	_scattered_targets.clear()
	for i in range(_part_meshes.size()):
		var scatter_dir := Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(0.5, 1.5),
			_rng.randf_range(-1.0, 1.0)
		).normalized()
		_scattered_targets.append(_part_original_pos[i] + scatter_dir * part_scatter_distance)


func _process_rebuild(delta: float) -> void:
	_rebuild_timer += delta
	var t: float = _rebuild_timer / rebuild_time

	if t < 0.5:
		# First half: parts fly outward
		var scatter_t: float = t * 2.0
		for i in range(_part_meshes.size()):
			if is_instance_valid(_part_meshes[i]) and i < _scattered_targets.size():
				_part_meshes[i].position = _part_original_pos[i].lerp(_scattered_targets[i], scatter_t)
	elif t < 0.6:
		# Brief pause at scattered positions — regenerate part types
		pass
	else:
		# Second half: new parts snap back
		if t >= 0.6 and _rebuild_timer - delta < rebuild_time * 0.6:
			# Regenerate parts at the transition point
			for i in range(6):
				_build_random_part(i)
				if i < _scattered_targets.size():
					_part_meshes[i].position = _scattered_targets[i]

		var snap_t: float = (t - 0.6) / 0.4
		snap_t = clamp(snap_t, 0.0, 1.0)
		for i in range(_part_meshes.size()):
			if is_instance_valid(_part_meshes[i]) and i < _scattered_targets.size():
				_part_meshes[i].position = _scattered_targets[i].lerp(_part_original_pos[i], snap_t)

	if t >= 1.0:
		_is_rebuilding = false
		# Heal partially
		_health = min(max_health, _health + max_health * rebuild_heal_pct)
		# Snap all parts to final positions
		for i in range(_part_meshes.size()):
			if is_instance_valid(_part_meshes[i]) and i < _part_original_pos.size():
				_part_meshes[i].position = _part_original_pos[i]
		_set_state(BaseState.PATROL)


func _process_chase(delta: float) -> void:
	if _is_rebuilding:
		velocity = Vector3.ZERO
		return

	var dist := _get_player_distance()
	if dist > disengage_radius:
		_set_state(BaseState.PATROL)
		return

	var spd: float = chase_speed
	if _is_exhausted:
		spd *= exhausted_speed_mult

	if is_instance_valid(_player_node):
		var dir := _get_player_direction()
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
		velocity.y = 0.0
		_face_direction(dir, delta * 5.0)
	else:
		velocity = Vector3.ZERO


func _on_state_changed(new_state: BaseState) -> void:
	if new_state == BaseState.DEAD:
		_is_rebuilding = false


# ── Grid configuration ───────────────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	# The base handles the numeric keys (health, speed, damage, detection).
	super.apply_grid_config(config_data)
	if config_data.is_empty():
		return

	var changed: bool = false

	if config_data.has("salvage"):
		var want_salvage: String = str(config_data["salvage"]).strip_edges().to_lower()
		if want_salvage in ["mixed", "crates", "pipes", "stones", "offcuts"] and want_salvage != salvage:
			salvage = want_salvage
			changed = true

	if config_data.has("assembly"):
		var want_assembly: String = str(config_data["assembly"]).strip_edges().to_lower()
		if want_assembly in ["figure", "lashed", "cairn", "heap"] and want_assembly != assembly:
			assembly = want_assembly
			changed = true

	if config_data.has("part_seed"):
		var seed_text: String = str(config_data["part_seed"]).strip_edges()
		if seed_text.is_valid_int():
			var want_seed: int = int(seed_text)
			if want_seed != part_seed:
				part_seed = want_seed
				_rng_ready = false
				changed = true

	# Guarded: never rebuild unless a declared value actually changed, the first
	# build has already happened, and the golem is not mid-scatter. A map that
	# passes none of these keys touches nothing.
	if not changed or not _golem_built or _is_rebuilding:
		return
	_ensure_rng()
	for i in range(6):
		_build_random_part(i)
