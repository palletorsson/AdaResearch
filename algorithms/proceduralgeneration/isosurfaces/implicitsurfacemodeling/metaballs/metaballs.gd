extends Node3D

# @identity
# essence: ray-marched metaball field — a fragment shader walks the camera ray through a box volume, sums radial-falloff contributions from N moving spheres, and renders where the field crosses an iso-threshold
# desire: to make the iso-surface visible without ever building a mesh — the surface is computed per-pixel, defined as the level set of a sum, and exists only on the screen
# critical_parameter: blend_factor — at low values metaballs stay distinct, at high values they merge into one organic mass; this is the smoothness of the implicit gluing, reachable from a map as `fusion`
# triggers: animate_strength=true cycles each metaball's strength on its own phase; world_offset shifts the rendering volume in local space while the grid system handles world placement
# emerges: discrete spheres become a single continuous surface as their fields overlap — no mesh stitching, no marching cubes, just a function evaluated everywhere
# needs: ShaderMaterial [resolved], BoxMesh [resolved], DirectionalLight3D [resolved]
# relationships: implicit-surface counterpart to marching cubes — same iso level threshold concept but rendered (raymarching) rather than meshed (marching cubes); contrast with nakama_metaballs which is mesh-based
# truth: a surface does not need vertices to exist — a function plus a threshold is already a shape, and rendering is just asking that function where it equals zero

# Editable parameters
@export var metaball_count: int = 9
@export var min_strength: float = 0.8
@export var max_strength: float = 1.2
@export var blend_factor: float = 0.4
@export var metaball_color: Color = Color(0.2, 0.6, 1.0)
@export var animate_strength: bool = false
@export var base_strength: float = 1.0  # Base strength value for all metaballs
@export var world_offset: Vector3 = Vector3.ZERO  # Local offset (grid system handles world position)

# ─────────────────────────────────────────────────────────────────────
#  STAGE-2 DNA — promoted 2026-08-06 (hand promotion; the runner refused
#  this token for NO TURNABLE KNOBS, which was a fact about the KIND of
#  knob — eight exports, one flag and seven magnitudes — and about
#  apply_grid_config, whose whole body was `pass`, so not one of them was
#  reachable from a map token.)
#
#  fusion          — HOW MUCH OF THE SUM IS VISIBLE. The shader folds the
#                    spheres together with smin(a, b, k), and k is
#                    `blend_factor`, which this artifact's own @identity
#                    already names as its critical_parameter: "at low
#                    values metaballs stay distinct, at high values they
#                    merge into one organic mass". Until now it had one
#                    value and no map could say otherwise.
#
#                    smin only acts where |a - b| < k, so at the shipped
#                    k = 0.4 against gaps of one to three metres it never
#                    engages at all — the picture is nine separate
#                    spheres, and the word for that is `distinct`. The
#                    ladder therefore runs UPWARD only. MEASURED, not
#                    assumed: the shader's map() was re-implemented in
#                    numpy and the silhouette sphere-traced from the
#                    sweep's own camera direction. Against the shipped
#                    k = 0.4, k = 0.02 changes 0.04% of frame — a rung
#                    that exists and cannot be photographed, dropped
#                    before declaring rather than after — while
#                    k = 2.6 / 4.0 / 6.0 change 5.1% / 15.1% / 40.5%.
#
#  metaball_count  — HOW MANY SUMMANDS THE FIELD HAS, which is the whole
#                    argument of an implicit surface: at 1 this is an SDF
#                    sphere and there is no implicit-surface claim to
#                    make; at 9 a sum of nine radial falloffs reads as
#                    one organic body. Numeric axis, sample points
#                    1 / 3 / 5 / 9, measured at 13.5% / 7.9% / 5.1% / 0%
#                    of frame against the shipped 9.
#
#                    NINE IS A CEILING, NOT A DEFAULT. metaball.gdshader
#                    declares `uniform vec4 metaball_positions[9]` and
#                    loops `for (int i = 0; i < 9; i++)`, so the count is
#                    clamped to SHADER_SLOTS and the unused slots are
#                    PARKED a kilometre away at radius 0 and strength 0.
#                    Handing the shader a short array would leave those
#                    slots at zero — a sphere of radius 0 sitting at the
#                    world origin, which smin would then glue the field
#                    to. At the shipped count of 9 the parking loop has
#                    no iterations and the arrays are byte for byte what
#                    they always were.
#
#  metaball_seed and pose_time are the FIXTURE, not axes, for
#  cantor_set's build_mode reason: without them there is no axis to
#  measure, only noise. This artifact is non-deterministic twice over.
#  The radii come from an unseeded randf_range(0.5, 1.0), so five
#  variants are five different objects — the trap the brief names. And
#  _process OVERWRITES every position each frame from
#  Time.get_ticks_msec(), so two tiles captured 1.5 s apart photograph
#  two different poses of the same field. seed 0 and pose_time below zero
#  are the shipped global RNG and the shipped wall clock, exactly.
#
#  DEAD EXPORTS, reported and left alone: `min_strength` and
#  `max_strength` are read by nothing. Every metaball is created at
#  base_strength and its radius comes from a hard-coded
#  randf_range(0.5, 1.0). Wiring them now would change what three live
#  rooms draw, so they stay dead and stay documented.
# ─────────────────────────────────────────────────────────────────────

## metaball.gdshader's array length. Not a tuning choice — the uniform and
## its loop bound are both literal 9.
const SHADER_SLOTS: int = 9
## Where an unused slot is sent. Far beyond the shader's own t > 20.0 cutoff
## and far beyond any k, so smin's h term is exactly zero for it.
const PARK_DISTANCE: float = 1000.0
## The smin k behind each rung. `distinct` is never read from here — it
## short-circuits to the raw exported blend_factor. See _blend().
const FUSION_K := {"distinct": 0.4, "necked": 2.6, "lobed": 4.0, "single": 6.0}

@export_enum("distinct", "necked", "lobed", "single") var fusion: String = "distinct"
## 0 keeps the shipped global RNG, call for call. Non-zero seeds a local one.
@export var metaball_seed: int = 0
## Below zero keeps the shipped wall clock. Zero or above freezes the pose.
@export var pose_time: float = -1.0

# Internal variables
var cube_mesh: MeshInstance3D
var shader_material: ShaderMaterial
var metaball_positions = []
var metaball_strengths = []
var metaball_radii = []
var _built: bool = false

func _ready() -> void:
	# Create a simple cube mesh for ray marching
	cube_mesh = MeshInstance3D.new()
	cube_mesh.mesh = BoxMesh.new()
	cube_mesh.mesh.size = Vector3(12.0, 12.0, 12.0)
	cube_mesh.position = world_offset
	add_child(cube_mesh)

	# Add light
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(light)

	# Load the shader
	shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://algorithms/proceduralgeneration/isosurfaces/implicitsurfacemodeling/metaballs/metaball.gdshader")

	# Apply to mesh
	cube_mesh.material_override = shader_material

	# Initialize metaballs
	initialize_metaballs()

	# Set shader parameters
	shader_material.set_shader_parameter("blend_factor", _blend())
	shader_material.set_shader_parameter("metaball_color", Vector3(
		metaball_color.r, metaball_color.g, metaball_color.b))

	_built = true
	print("Metaball setup complete with strength: ", base_strength)

## The smin k the shader is handed. `distinct` SHORT-CIRCUITS to the raw
## exported blend_factor rather than to FUSION_K's 0.4, so a scene that
## overrides blend_factor in the inspector is not silently retuned by this
## promotion, and a map naming blend_factor directly still wins.
func _blend() -> float:
	if fusion == "distinct":
		return blend_factor
	return float(FUSION_K.get(fusion, blend_factor))

## How many slots actually carry a metaball. The rest are parked.
func _live_count() -> int:
	return clampi(metaball_count, 1, SHADER_SLOTS)

func initialize_metaballs() -> void:
	# Clear existing arrays
	metaball_positions.clear()
	metaball_strengths.clear()
	metaball_radii.clear()

	# Get the world-space center of the box (available after _ready / add_child)
	var center = cube_mesh.global_position if cube_mesh.is_inside_tree() else world_offset

	# seed 0 is the shipped path: the global RNG, in the same call order.
	var rng: RandomNumberGenerator = null
	if metaball_seed != 0:
		rng = RandomNumberGenerator.new()
		rng.seed = metaball_seed

	var live: int = _live_count()

	# Initialize metaball positions and strengths
	for i in range(live):
		var radius: float = 0.0
		if rng == null:
			radius = randf_range(0.5, 1.0)
		else:
			radius = rng.randf_range(0.5, 1.0)
		metaball_radii.append(radius)

		# Create Vector4 where xyz = world position, w = radius
		var ox: float = 0.0
		var oy: float = 0.0
		var oz: float = 0.0
		if rng == null:
			ox = randf_range(-2.0, 2.0)
			oy = randf_range(-2.0, 2.0)
			oz = randf_range(-2.0, 2.0)
		else:
			ox = rng.randf_range(-2.0, 2.0)
			oy = rng.randf_range(-2.0, 2.0)
			oz = rng.randf_range(-2.0, 2.0)
		var position = Vector4(center.x + ox, center.y + oy, center.z + oz, radius)

		metaball_positions.append(position)
		metaball_strengths.append(base_strength)

	# Park the slots the shader will read but this count does not use. At the
	# shipped count of 9 this loop has no iterations at all.
	for i in range(live, SHADER_SLOTS):
		metaball_radii.append(0.0)
		metaball_positions.append(Vector4(center.x, center.y + PARK_DISTANCE, center.z, 0.0))
		metaball_strengths.append(0.0)

	# Update shader parameters
	update_shader_parameters()

func _process(_delta):
	# Animate around the box's actual world position (works wherever the grid places us)
	var center = cube_mesh.global_position

	# Create new array for updated positions
	var updated_positions = []

	# The shipped clock, unless a fixture pinned the pose.
	var t: float = Time.get_ticks_msec() * 0.001
	if pose_time >= 0.0:
		t = pose_time

	var live: int = _live_count()

	# Animate metaballs
	for i in range(live):
		# Create a new Vector4 for each position (Vector4 is immutable in Godot 4)
		var new_position = Vector4(
			center.x + sin(t * (0.3 + float(i) * 0.1) + i) * 2.0,
			center.y + cos(t * (0.2 + float(i) * 0.1) + i * 0.7) * 2.0,
			center.z + sin(t * (0.4 + float(i) * 0.05) + i * 1.3) * 2.0,
			metaball_radii[i]
		)

		updated_positions.append(new_position)

		# Optionally animate the strength
		if animate_strength:
			metaball_strengths[i] = base_strength + sin(t * 0.5 + i) * 0.3

	# Keep the parked slots parked. No iterations at the shipped count of 9.
	for i in range(live, SHADER_SLOTS):
		updated_positions.append(Vector4(center.x, center.y + PARK_DISTANCE, center.z, 0.0))

	# Replace the array
	metaball_positions = updated_positions

	# Update shader parameters
	update_shader_parameters()

func update_shader_parameters() -> void:
	# Update metaball parameters in the shader
	shader_material.set_shader_parameter("metaball_positions", metaball_positions)
	shader_material.set_shader_parameter("metaball_strengths", metaball_strengths)

	# Update light direction
	shader_material.set_shader_parameter("light_direction", Vector3(1.0, 0.5, 1.0).normalized())

# Public function to update the base strength
func set_strength(new_strength: float) -> void:
	base_strength = new_strength

	# Update all metaball strengths — the live slots only; parked slots stay at 0.
	for i in range(_live_count()):
		metaball_strengths[i] = base_strength

	# Update shader parameters
	update_shader_parameters()

	print("Updated metaball strength to:", base_strength)

# Reset metaballs with current parameters
func reset_metaballs() -> void:
	initialize_metaballs()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Rebuild the field. There is no node teardown to do — the body is one box —
## so this re-draws the sample and re-hands the shader its k.
func _rebuild() -> void:
	initialize_metaballs()
	shader_material.set_shader_parameter("blend_factor", _blend())


## Config from a map token. Guarded twice — a value is taken only when it
## validates AND differs, and _rebuild() fires only after _ready has built once
## — so the three existing placements, which pass no key at all, reach no
## assignment and never rebuild.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	var changed: bool = false

	if config.has("fusion"):
		var f: String = str(config["fusion"]).to_lower()
		if FUSION_K.has(f) and f != fusion:
			fusion = f
			changed = true

	if config.has("metaball_count"):
		var n: int = clampi(int(config["metaball_count"]), 1, SHADER_SLOTS)
		if n != metaball_count:
			metaball_count = n
			changed = true

	if config.has("metaball_seed"):
		var s: int = int(config["metaball_seed"])
		if s != metaball_seed:
			metaball_seed = s
			changed = true

	if config.has("pose_time"):
		var p: float = float(config["pose_time"])
		if not is_equal_approx(p, pose_time):
			pose_time = p
			changed = true

	if not changed:
		return
	# Before the first build there is nothing to redraw — _ready() will pick the
	# new values up when it runs.
	if not _built:
		return
	_rebuild()
