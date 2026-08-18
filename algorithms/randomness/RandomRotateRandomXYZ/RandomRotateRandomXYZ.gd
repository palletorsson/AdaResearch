# @identity
# essence: R(θ_x, θ_y, θ_z) — random rotation in SO(3) applied per instance
# desire: watch a grid of cubes fidget and drift, each chosen by probability field
# critical_parameter: selection_mode — UNIFORM (all equal), CENTER_BELL (Gaussian falloff), NOISE (Perlin probability)
# triggers: _process() picks one instance per frame via rejection sampling, applies random rotation step
# emerges: CENTER_BELL creates a breathing center; NOISE creates wandering regions of agitation
# needs: MultiMeshInstance3D sibling [has]; FastNoiseLite for NOISE mode [has]
# relationships: feeds Random_Rotate_Random_XYZ map; contrasts with random_decay_multimesh (rotation vs dissolution)
# truth: Rotation is the gentlest form of randomness — the object remains itself, only its orientation forgets.

extends Node3D
## RandomRotateRandomXYZ.gd
## Randomly rotates MultiMesh cube instances on X, Y, and Z each frame
## Supports different selection modes for determining which instances rotate.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-06).
#
#   visitation   THE SHAPE OF THE PROBABILITY FIELD — where chance is allowed
#                to call
#
#     even     UNIFORM — every cube equally likely; disorder accumulates as one
#              level scramble across the whole grid, no place favoured.
#     bell     CENTER_BELL — THE SHIPPED LINEAGE (the .tscn sets
#              selection_mode = 1, bell (4,1,4) radius 3): a Gaussian holds
#              court and the grid tumbles hardest near it, going calm with
#              distance. The @identity's "breathing center".
#     weather  NOISE — a Perlin field deals the visits; agitation arrives as
#              patches, regions of jumble beside regions of poise.
#
# This artifact owns NO geometry — it hunts a MultiMeshInstance3D through
# `../GridMultiMesh` (the same class as remove_random and rotate_grid_cubes)
# and rewrites the host grid's transforms, so the bench needs dna.host to build
# the grid it is looking for. And its per-frame step is ±2°, so at the sweep's
# settle the three modes photograph as the same untouched lattice: like
# remove_random's removal_speed 40x, the fixture must DEVELOP the exposure —
# warmup_steps runs the identical per-frame step N times synchronously in
# _ready, so the SHAPE each mode carves is finished when the shutter opens.
# The axis is the spatial distribution of accumulated disorder, not the rate:
# a still can show WHERE chance visited, never how fast.
#
# WHY NOT the sibling's word `selection_mode` (remove_random's axis): that name
# is already this script's int-typed enum export, and the sweep sets axis values
# as STRINGS pre-_ready — a typed int silently rejects "even" and every variant
# would render the default (the science_screen failure, verbatim). Retyping the
# export would orphan the `selection_mode = 1` stored in the .tscn, which is R1.
# So the axis is a String overlay that steers the enum. `chance` (none|hue|
# size|all) is WHAT chance may touch, not where; `field` (cells|orbit|sink|...)
# is flow topology; both rejected as different questions.
#
# SEEDED: the walk drew from an rng.randomize() stream, so five sweeps were
# five artifacts and any bite was noise. rotate_seed = -1 keeps today's
# behaviour exactly; the fixture pins it for capture.
#
# NOT TOUCHED: the shipped path. visitation="bell" with no config leaves the
# scene's own selection_mode untouched, the rng still randomizes, warmup is 0,
# and _process steps exactly as it always has.
# ─────────────────────────────────────────────────────────────────────────────

enum SelectionMode {
	UNIFORM,
	CENTER_BELL,
	NOISE
}

@export_group("Targeting")
@export var multimesh_path: NodePath = "../GridMultiMesh"
@export var selection_mode: SelectionMode = SelectionMode.UNIFORM

@export_group("DNA")
## THE AXIS — the shape of the probability field that deals the visits. `bell`
## is the shipped lineage. A String overlay over selection_mode (see the
## promotion note): it writes the enum only when a value actually arrives, so
## the .tscn's own int stays authoritative on the untouched path.
@export_enum("even", "bell", "weather") var visitation: String = "bell"

## The allow-list, same spelling and order as the @export_enum above.
const VISITATIONS: PackedStringArray = ["even", "bell", "weather"]

## SEED. -1 (the default) is today's behaviour exactly: rng.randomize(), no two
## runs agree. Any value >= 0 seeds the walk so a sweep photographs the axis
## instead of its own noise. The DNA fixture must set it.
@export var rotate_seed: int = -1

## BENCH INSTRUMENT, not an axis. 0 (the default) is today: disorder accrues
## one ±2° step per frame, invisible at any settle. A positive count runs that
## same step loop synchronously in _ready — the long exposure that develops the
## visitation pattern — then freezes _process so the plate stops exposing.
## Warmup does not advance _time, so `weather` is photographed as the field
## stands rather than smeared by its own scroll.
@export var warmup_steps: int = 0

@export_subgroup("Bell Curve Settings")
@export var bell_center: Vector3 = Vector3.ZERO
@export var bell_radius: float = 10.0 ## The standard deviation (sigma) of the bell curve

@export_subgroup("Noise Settings")
@export var noise_source: FastNoiseLite
@export var noise_scale: float = 1.0
@export var noise_threshold: float = 0.0 ## Minimum probability cutoff
@export var noise_scroll_speed: Vector3 = Vector3(0.1, 0.1, 0.1)

@export_group("Rotation Settings")
# Initial random rotation range (applied once on _ready)
@export var min_degrees: float = -2.01
@export var max_degrees: float =  2.01

# Per-frame random rotation step range
@export var min_step: float = -2.0
@export var max_step: float =  2.0

var rng := RandomNumberGenerator.new()
var multimesh_instance: MultiMeshInstance3D = null
var multimesh: MultiMesh = null
var _time: float = 0.0

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child and the
	# sweep sets exports pre-add_child, so both are readable here, before the
	# settle frames.
	_read_meta_overrides()
	_apply_visitation()
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	if rotate_seed >= 0:
		rng.seed = rotate_seed
	else:
		rng.randomize()

	if selection_mode == SelectionMode.NOISE and not noise_source:
		# Create default noise if missing
		noise_source = FastNoiseLite.new()
		noise_source.noise_type = FastNoiseLite.TYPE_PERLIN
		noise_source.frequency = 0.1

	# Find the MultiMeshInstance3D
	if not multimesh_path.is_empty():
		multimesh_instance = get_node_or_null(multimesh_path)

	# If path not set or not found, search for it
	if not multimesh_instance:
		multimesh_instance = _find_multimesh_instance(get_parent())

	if multimesh_instance:
		multimesh = multimesh_instance.multimesh
		if multimesh and multimesh.instance_count > 0:
			print("✅ Found MultiMesh with %d instances" % multimesh.instance_count)
			rotate_random_initial()

			# Auto-detect center if bell center is zero (optional UX convenience)
			if selection_mode == SelectionMode.CENTER_BELL and bell_center == Vector3.ZERO:
				var aabb = multimesh.get_aabb()
				bell_center = aabb.get_center()
				print("Centered bell curve at: ", bell_center)

			# The long exposure (bench only — 0 on every shipped path): the same
			# step the live loop takes, run to completion so a still can show the
			# visitation pattern. The plate then stops exposing.
			if warmup_steps > 0:
				for _i in range(warmup_steps):
					_step_once()
				set_process(false)
				print("Warmup applied: %d steps, visitation=%s" % [warmup_steps, visitation])
		else:
			push_warning("MultiMesh found but has no instances")
	else:
		push_warning("Could not find MultiMeshInstance3D - path: %s" % multimesh_path)

func _find_multimesh_instance(node: Node) -> MultiMeshInstance3D:
	if node is MultiMeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_multimesh_instance(child)
		if result:
			return result
	return null

func rotate_random_initial() -> void:
	if not multimesh:
		return

	var count = multimesh.instance_count
	for i in range(count):
		var transform = multimesh.get_instance_transform(i)

		# Apply random initial rotation
		var rand_x = deg_to_rad(rng.randf_range(min_degrees, max_degrees))
		var rand_y = deg_to_rad(rng.randf_range(min_degrees, max_degrees))
		var rand_z = deg_to_rad(rng.randf_range(min_degrees, max_degrees))

		# Create rotation basis and apply to transform
		var rotation_basis = Basis()
		rotation_basis = rotation_basis.rotated(Vector3.RIGHT, rand_x)
		rotation_basis = rotation_basis.rotated(Vector3.UP, rand_y)
		rotation_basis = rotation_basis.rotated(Vector3.BACK, rand_z)

		transform.basis = rotation_basis * transform.basis
		multimesh.set_instance_transform(i, transform)

	print("✅ Applied initial rotation to %d MultiMesh instances" % count)

func _process(delta: float) -> void:
	if not multimesh or multimesh.instance_count == 0:
		return

	_time += delta
	_step_once()


## One visit: pick an instance through the probability field, nudge it ±2° on
## each axis. Extracted verbatim from _process so the warmup exposure and the
## live loop are the SAME walk — same draws, same order.
func _step_once() -> void:
	var chosen_index = -1
	var max_attempts = 20 # Try to find a valid instance up to 20 times per frame

	for _attempt in range(max_attempts):
		# Pick a random instance
		var idx = rng.randi_range(0, multimesh.instance_count - 1)
		
		if selection_mode == SelectionMode.UNIFORM:
			chosen_index = idx
			break
		
		var transform = multimesh.get_instance_transform(idx)
		var pos = transform.origin
		var probability = 0.0
		
		if selection_mode == SelectionMode.CENTER_BELL:
			var dist = pos.distance_to(bell_center)
			# Gaussian: e^(-x^2 / 2s^2)
			# Result is 1.0 at center, near 0 at edges
			probability = exp(-(dist * dist) / (2.0 * bell_radius * bell_radius))
			
		elif selection_mode == SelectionMode.NOISE:
			if noise_source:
				var noise_pos = (pos * noise_scale) + (noise_scroll_speed * _time)
				var n = noise_source.get_noise_3dv(noise_pos)
				# Remap -1..1 to 0..1
				probability = (n + 1.0) * 0.5
				if probability < noise_threshold:
					probability = 0.0
		
		# Rejection sampling
		if rng.randf() < probability:
			chosen_index = idx
			break
	
	# If we failed to find a target after max_attempts, we simply skip rotation this frame
	if chosen_index == -1:
		return

	# Perform the rotation on the chosen instance
	var transform = multimesh.get_instance_transform(chosen_index)

	# Generate random rotation steps
	var step_x = deg_to_rad(rng.randf_range(min_step, max_step))
	var step_y = deg_to_rad(rng.randf_range(min_step, max_step))
	var step_z = deg_to_rad(rng.randf_range(min_step, max_step))

	# Apply incremental rotation to the basis
	transform.basis = transform.basis.rotated(Vector3.RIGHT, step_x)
	transform.basis = transform.basis.rotated(Vector3.UP, step_y)
	transform.basis = transform.basis.rotated(Vector3.BACK, step_z)

	# Update the instance transform
	multimesh.set_instance_transform(chosen_index, transform)


# ═════════════════════════════════════════════════════════════════════════════
# DNA plumbing
# ═════════════════════════════════════════════════════════════════════════════

## Map the axis word onto the enum the walk actually branches on. Writes ONLY
## when a value genuinely arrived (config meta, or a non-default export set by
## the sweep) — so on the untouched path the .tscn's own `selection_mode = 1`
## keeps ruling, byte for byte.
func _apply_visitation() -> void:
	if visitation == "bell" and not has_meta("config_visitation"):
		return                       # nothing asked; the scene's enum stands
	match visitation:
		"even":
			selection_mode = SelectionMode.UNIFORM
		"weather":
			selection_mode = SelectionMode.NOISE
		_:
			selection_mode = SelectionMode.CENTER_BELL   # "bell"


func _read_meta_overrides() -> void:
	if has_meta("config_visitation"):
		var v: String = str(get_meta("config_visitation")).strip_edges().to_lower()
		if VISITATIONS.has(v):
			visitation = v
		elif v != "":
			push_warning("Random_Rotate_Random_XYZ: unknown visitation '%s' — keeping '%s'" % [v, visitation])
	if has_meta("config_rotate_seed"):
		rotate_seed = int(str(get_meta("config_rotate_seed")))
	if has_meta("config_warmup_steps"):
		warmup_steps = int(str(get_meta("config_warmup_steps")))
	if has_meta("config_noise_scale"):
		noise_scale = float(str(get_meta("config_noise_scale")))


## Was `pass` — every `#token: value` a map put on a placement was parsed,
## stashed and discarded. Guarded: an unchanged config changes nothing, so
## curation_station's blanket apply_grid_config({"emissive": false}) passes
## through without touching the walk.
func apply_grid_config(config: Dictionary) -> void:
	var before_visitation: String = visitation
	var before_seed: int = rotate_seed
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if visitation != before_visitation:
		_apply_visitation()          # the walk continues under a new law
	if rotate_seed != before_seed and rotate_seed >= 0:
		rng.seed = rotate_seed       # a re-dealt stream, from here on
