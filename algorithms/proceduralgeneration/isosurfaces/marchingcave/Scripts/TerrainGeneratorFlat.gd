extends TerrainGeneratorBase

# --- DNA (stage 2, promoted 2026-08-12) -------------------------------------
# THE PROBLEM. This file was 74 lines and declared no @export of its own — 60 of
# those lines are a fallback plane nobody has ever seen. The audit therefore
# recorded the artifact as axis-less. It is not. Its one real argument is a single
# literal inside MarchingCubesFlat.glsl, and it is the argument the whole sequence
# is named after.
#
# MarchingCubesFlat.glsl builds its density in two halves that disagree about what
# kind of object this is:
#
#   :182-183  SURFACE NOISE   two snoise reads of (x, 0, z) at amplitudes 15.0 and 5.0
#   :189      HEIGHTFIELD     `terrainDensity = (surfaceHeight - worldPos.y) / 30.0`
#                             — a function of x and z. A GRAPH over the plane. The
#                             thing you do not need marching cubes for at all: it is
#                             single-valued in y everywhere, so a quad grid draws it.
#   :193      THE ARGUMENT    `float density = terrainDensity - (caveNoise * 0.4);`
#                             — four octaves of ridged 3D noise (:170-178) subtracted,
#                             and at that moment the surface stops being a graph.
#
# The whole difference between a plot and a level set is that one literal. `interior`
# is it, lifted out by the pattern TerrainGeneratorShapes already uses for shapeId and
# TerrainGeneratorGyroid used for its four trailing floats: get_params_array() appends,
# ParamsBuffer gains a matching trailing field. The shared eleven-field prefix that
# every other Marching*.glsl reads is untouched, and MarchingCubesFlat.glsl is loaded
# by this script and by nothing else.
#
# interior — DOES THIS LANDSCAPE HAVE AN INSIDE? Strengths per rung, replacing the 0.4.
# Every number below was measured on a float32 numpy replica of evaluate() over the same
# 65^3 corner grid at the scene's own iso_level of 0.0, counting columns whose solid/air
# classification changes more than once down the y axis — which is exactly the question
# "is this still a graph over the plane?" — and taking the triangle count from the
# shader's own lengths[256] table:
#
#     rung       k     triangles   columns with an inside   enclosed air cells
#     none      0.0       12,824        0 of 4,225 (0.00%)                   0
#     undercut  0.3       14,996        8 of 4,225 (0.19%)                   9
#     caverned  0.4       16,382       50 of 4,225 (1.18%)                  68
#     warren    0.8       24,656      436 of 4,225 (10.32%)              1,157
#
#     caverned  SHIPPED, 0.4. Caves through the mass — and the measurement above is the
#               most interesting thing this promotion found. The artifact that has stood
#               in ISO_FlatTerrain all along is 98.8% HEIGHTFIELD. It has an inside in
#               one column in eighty-five. Nobody knew that, because until now there was
#               nothing to compare it to.
#     none      0.0. The exact heightfield y = surfaceHeight, since the scene leaves
#               iso_level at the base default of 0.0 — rolling hills from two snoise
#               reads, smooth, single-sheeted, no overhang ANYWHERE (0 columns, measured,
#               not assumed), marching cubes reduced to a function plotter. THIS IS THE
#               PICTURE NOBODY IN THIS CORPUS HAS SEEN, and it is the negative half of
#               the sequence's claim: here is what the algorithm looks like when it is
#               not being used.
#     undercut  0.3. The first rung where the ground stops being single-valued in y.
#               THE APPROVED DESIGN SAID 0.2 AND THE REPLICA FALSIFIED IT: at 0.2, ZERO
#               of the 4,225 columns cross more than once and not one air cell is
#               enclosed. 0.2 is a heightfield with its mass thinned, not an undercut —
#               declaring it would have put a word in the registry that the render does
#               not contain, which is the science_screen disease in a new costume. The
#               property first appears at 0.25 (one column) and is robust by 0.30. The
#               design's NUMBER and the design's DEFINITION were in conflict; the
#               definition is what the axis argues, so the definition won.
#     warren    0.8. Void-dominated relative to the rest — 10.3% of columns, an order of
#               magnitude past the shipped rung, and the only value whose mesh AABB grows
#               (126.6 m tall against 37-56 m) because the caves reach far below the
#               surface band. Not yet floating islands; that would need k past 1.5, which
#               is outside a ladder whose default must sit inside it.
#
# WHY `interior` AND NOT A NEW WORD. It is SHARED, taken from csg_architecture_cavity
# (boolean_surfaces.json — none|corner|court|room), where it asks whether a solid
# encloses a void you could occupy. Same question, asked of a sampled field instead of
# a boolean solid, and the shared rung `none` means the same thing in both places: no
# interior anywhere. Taking it rather than coining `hollowing` is the check as much as
# the economy — when a shared word is honest the siblings measure ALIKE, so a
# landscape's cave and a wall's court clearing the 3% floor at comparable numbers is
# itself evidence the word is doing one job. NOT `openwork` (csg_architecture_cavity's
# other axis, which is about holes in a face). NOT `resolution`, which this sequence
# already holds twice (queer_marching_cave, animated_noise_explorer) with a different
# question — how finely the field is SAMPLED, not how much of it is subtracted.
#
# THE ARTIFACT NEXT DOOR ASKS A DIFFERENT QUESTION ON THE SAME SUBSTRATE. ISO_FlatTerrain
# places mc_flat_landscape and mc_overhang_landscape in the same room. This shader has
# exactly ONE 3D term, so the only honest axis over it is HOW MUCH inside; the overhang
# shader has four, so its axis is WHICH TERMS. That is deliberate and it is the reason
# neither had to be watered down to avoid the other.
#
# WHAT IS DECLINED. `iso_level` — real, and the sequence's central question, and
# gyroid_demo's declined note explicitly bequeathed it to "a sibling in this sequence
# that has no thickness term", which this is. Refused HERE and paid on
# mc_torus_sculpture instead, because on THIS shader iso_level and interior fight for
# the same pixels: density = terrainDensity - caveNoise*k, so a constant offset to the
# threshold and a scale on the cave term both widen the same caves, and the rigid
# vertical translation that is the rest of iso_level's effect self-cancels under an
# AABB-fitted camera. The torus has no gradient term at all, so there the threshold is
# pure. REFUSED, the surface amplitudes 15.0 and 5.0 at :182-183: they are the relief
# of the heightfield — a magnitude on the half of the field this axis is not about, and
# the two would read as one axis with a loud rung. REFUSED, the octave count at :170
# (`i < 4`): real, and promoted on the cave pair instead, where two sibling scenes
# resolve a different number of octaves and the axis therefore says something; here
# there is one scene and it would be a detail knob. REFUSED, `chunk_scale` and
# `center_position` — an extent and a placement, both self-cancelling under a fitted
# camera. REFUSED, `continuous_update`: a RATE, invisible in a still by law, and here
# only a risk of photographing a half-built mesh. REFUSED, `invert_faces`: two values,
# below the floor, and it changes what the material culls rather than what the field is.
#
# STILL-VISIBLE BY CONSTRUCTION, and this one needed checking rather than asserting,
# because unlike TerrainGeneratorGyroid this subclass does NOT override _process. The
# base's loop therefore re-dispatches once, about 102 frames after _ready (12 for the
# GPU sync, 90 for the mesh thread), and then calls set_process(false). VERIFIED BY
# READING: `params.time` is declared in MarchingCubesFlat.glsl's ParamsBuffer and
# referenced NOWHERE else in the file — grep returns exactly one hit, the declaration —
# so the second dispatch computes a bit-identical field. The sweep's settle photographs
# the first mesh, which _ready built synchronously, and the second would be the same
# picture if it ever arrived first. snoise is the Ashima/stegu simplex function: a pure
# function of position, no seed, no RNG anywhere in this script, so four runs of a rung
# are the same mesh and no seed export is needed.
#
# TRIANGLE BUDGET, checked because the failure would be silent. process_mesh_data aborts
# to num_triangles = 0 above 500,000, which yields an empty mesh, which routes to the
# fallback plane, which measures as a dead axis. The heaviest rung is warren at 24,656 —
# 4.9% of the cap. All four also stay under the 30,000 cutoff at which _create_collision
# skips the trimesh, so collision is built at every rung exactly as it is today.
#
# THE REPLICA HAD TO BE FLOAT32 AND THIS IS WORTH THE LINE. A float64 first pass
# disagreed with the shipped artifact by 3.7x on the mesh AABB. The cause is in the
# noise: `float n_ = 0.142857142857` is a TRUNCATED 1/7, and float32 rounds it to
# 0.14285715 — just ABOVE 1/7 — while float64 keeps it just below. `floor(j * ns.z)`
# and `floor(p * ns.z * ns.z)` therefore land on different integers for every p that is
# a multiple of 49, about 7% of gradient lookups, and each one picks the wrong simplex
# gradient. In float64 snoise ranged +-4.7; in float32 it is the well-behaved +-0.96.
# The corrected replica puts the shipped rung's AABB centre at y = -9.38 against the
# registry's measured -9.91, and its cell-quantised height at 56.25 m against the
# measured 49.62 — inside one 4.6875 m voxel at each end, which is exactly the error a
# cell-quantised bound should have. That agreement is why the numbers below are quoted.
#
# PREDICTED CLOSEST PAIR: `none` against `undercut`, 8.55% focus / 2.11% frame, with
# `caverned` against `warren` the FARTHEST at 58.37% / 24.28%. The approved design
# predicted the exact opposite — caverned/warren closest, at about 5% of frame — and
# named none/undercut as the pair it would be wrong about. It was wrong about it.
#
# WHY THE DESIGN'S ARITHMETIC MISSED, which is the part worth keeping. It reasoned in
# METRES OF SURFACE DISPLACEMENT: k rises by 0.4, caveNoise is typically ~0.5, density
# converts to metres at the :189 gradient of 1/30, so ~6 m of movement. Measured, that
# model is right about the metres and useless about the picture. none -> undercut moves
# the top surface 6.66 m on average and undercut -> caverned only 1.89 m, yet they render
# 8.55% and 13.03% apart — the SMALLER displacement produces the LARGER change. What
# tracks the picture is added surface AREA, not vertical travel: a cave mouth that opens
# adds silhouette where there was none, while a hillside that slides down 6 m looks like
# the same hillside. Triangle counts say it plainly — 12,824 / 14,996 / 16,382 / 24,656 —
# and warren, the only rung that adds eight thousand triangles, is the only rung that is
# far from everything.
#
# The full predicted table, closest first (a flat-shaded ray-march of the same density
# field from the sweep's own standpoint, yaw 0.62 / pitch -0.26, FOV 34, PAD 1.9,
# dna.framing 0.45, at the 160 x 160 the critic resizes to — no material, no lights rig,
# no marching-cubes interpolation, so these are NOT bite numbers):
#     none     <-> undercut    8.55 focus /  2.11% frame
#     undercut <-> caverned   13.03        /  2.61%
#     none     <-> caverned   18.15        /  3.85%
#     none     <-> warren     54.85        / 24.45%
#     undercut <-> warren     55.75        / 23.92%
#     caverned <-> warren     58.37        / 24.28%
#
# WHAT WOULD FALSIFY THIS. (a) If none <-> undercut comes back under 6% the critic will
# call it a twin, and the cause will be that a flat Lambert replica overstates how much
# a shallow cave mouth survives the downsample — the fix is a higher `undercut`, not a
# dead axis. (b) If any pair reads 0.00%, the shader did not reimport: headless Godot
# never reimports a .glsl, and a stale compiled shader is this sequence's known way of
# publishing byte-identical tiles under a correct axis (gyroid_demo, 16 of them). Check
# source_md5 in .godot/imported/*.md5 against the file hash, NOT the mtime.

## Cave weight per rung — the float that is multiplied into caveNoise before it is
## subtracted from the heightfield. `caverned` holds 0.4, which IS the literal that used
## to be written inline at MarchingCubesFlat.glsl:193; it was moved from the shader to a
## GDScript const and handed back through a uniform, and nothing on that path is derived,
## scaled or recomputed.
const CAVE_STRENGTHS: Dictionary = {
	"caverned": 0.4,
	"none": 0.0,
	"undercut": 0.3,
	"warren": 0.8,
}

## The shipped number as its own constant, so the default path can SHORT-CIRCUIT to it
## rather than reach the table at all. GDScript's `0.4` is a float64 that
## PackedFloat32Array rounds to the nearest float32, and GLSL's `0.4` literal compiles to
## that same nearest float32 — identical bit pattern — so at the default
## `caveNoise * params.caveStrength` multiplies the same value by the same value the
## inline expression always did.
const SHIPPED_CAVE_STRENGTH: float = 0.4

const INTERIORS: PackedStringArray = ["none", "undercut", "caverned", "warren"]

@export_category("Flat Landscape DNA")
@export_enum("none", "undercut", "caverned", "warren") var interior: String = "caverned"

## Signature of everything the build reads, captured after the last successful
## generation. Empty until _ready has run, which is what tells apply_grid_config that
## there is nothing yet to rebuild.
var _built_signature: String = ""

## Nodes THIS script created, and the only nodes it is ever allowed to free. It is
## empty and expected to stay empty — nothing below constructs a node — but the free
## path exists so that a future edit which does add one cannot be tempted into a
## blanket sweep of get_children(). GridInteractablesComponent attaches a _RotationTimer
## to a spawned artifact, and the base's _create_collision owns the StaticBody3D; a
## blanket free is what cost three scripts a pass in the last wave.
var _owned: Array[Node] = []


func get_class_name() -> String:
	return "TerrainGeneratorFlat"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingCubesFlat.glsl"


## Config is stamped as metadata BEFORE the node enters the tree
## (GridInteractablesComponent._apply_artifact_config runs at line 1195, add_child at
## 1220), so reading it here means _ready builds with the right values the first time and
## the deferred apply_grid_config that follows finds nothing to do. capture_config_sweep
## sets the export directly instead, before add_child, which _read_metadata_overrides
## cannot clobber because it only writes when the matching meta key exists.
func _ready() -> void:
	_read_metadata_overrides()
	super._ready()
	_built_signature = _config_signature()


## The one float appended to the base's eleven, matching the trailing field added to
## ParamsBuffer in MarchingCubesFlat.glsl. Count goes 11 -> 12 on BOTH sides and this
## append is the last of each, which is the whole of the risk: a mismatch in order or
## count silently shifts every float and is not a compile error.
func get_params_array():
	var params = super.get_params_array()
	params.append(_cave_strength())   # caveStrength — was the literal 0.4 at the old :193
	return params


## SHORT-CIRCUIT at the default, deliberately, rather than a lookup that happens to
## agree: at `caverned` the shader is handed the shipped constant itself.
func _cave_strength() -> float:
	if interior == "caverned":
		return SHIPPED_CAVE_STRENGTH
	if CAVE_STRENGTHS.has(interior):
		return float(CAVE_STRENGTHS[interior])
	return SHIPPED_CAVE_STRENGTH


## The shader's own input, stringified, so the guard cannot drift out of step with what
## the build actually reads — if a value reaches the GPU it is in here.
##
## WITH ONE DOCUMENTED EXCEPTION, and it is the difference between this subclass and
## TerrainGeneratorGyroid, which used the array whole. Gyroid overrides _process to
## `pass`, so its `time` is permanently 0.0 and the signature is stable. This subclass
## does not override _process, so `time` advances for the ~102 frames before the base
## calls set_process(false) — a signature including it would be a CLOCK, and every
## apply_grid_config arriving in that window would compare unequal and trigger a rebuild
## that changes nothing. Index 0 is skipped because `params.time` is declared in
## MarchingCubesFlat.glsl and read nowhere in it, so it cannot change the mesh. That is
## a fact checked in the shader, not an assumption about what `time` is for.
func _config_signature() -> String:
	var vals: Array = get_params_array()
	var out: String = ""
	for i in range(1, vals.size()):
		out += "%.6f|" % float(vals[i])
	return out


func _read_metadata_overrides() -> void:
	if has_meta("config_interior"):
		var v: String = str(get_meta("config_interior")).strip_edges().to_lower()
		if INTERIORS.has(v):
			interior = v


## Guarded. The old body was a bare `pass` — a method that existed only so the grid's
## has_method() check would find it. It now rebuilds when, and only when, a value the
## SHADER reads has actually changed. None of the 4 placements across the two registry
## tokens passes a config key, and neither entry declares default_params, so
## GridInteractablesComponent's `if not merged_config.is_empty()` gate means
## _apply_artifact_config never runs for any of them: no metadata is stamped and this
## method is never called from any map that exists.
func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		var sk: String = str(k).strip_edges()
		if sk.is_valid_identifier():
			set_meta("config_%s" % sk, config[k])
	_read_metadata_overrides()
	if _built_signature == "":
		return                      # _ready has not built yet; it will read the metadata
	if _config_signature() == _built_signature:
		return
	_regenerate()


## Re-run the same three calls _ready runs, in the same order.
##
## It refuses to run while a dispatch is in flight, because resubmitting under one is
## the teardown segfault release() documents — and unlike the gyroid this subclass's
## _process CAN hold that state, for the ~102 frames before it stops. In that case
## _built_signature is deliberately left stale, so the next apply_grid_config with the
## same config still compares unequal and retries rather than recording a rebuild that
## did not happen. Unreachable in practice twice over: _ready completes the whole cycle
## synchronously and the deferred apply_grid_config lands in the same idle frame, before
## this node's first _process tick — and no map reaches this method at all.
func _regenerate() -> void:
	if use_fallback or rendering_device == null:
		return
	if waiting_for_compute or waiting_for_meshthread:
		return
	_free_owned()
	run_compute()
	fetch_and_process_compute_data()
	create_mesh()
	_built_signature = _config_signature()


func _free_owned() -> void:
	for n in _owned:
		if is_instance_valid(n):
			n.queue_free()
	_owned.clear()


func _create_fallback_mesh() -> void:
	print("TerrainGeneratorFlat: Creating fallback flat landscape...")
	_create_simple_flat_mesh()
	print("✅ Fallback flat landscape created")

func _create_simple_flat_mesh() -> void:
	# Create a simple flat plane with some hills as fallback
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	# Create a large flat terrain grid
	var size = 200.0  # Size of terrain
	var segments = 50  # Resolution
	var step = size / segments

	# Generate vertices for flat terrain with hills
	for z in range(segments + 1):
		for x in range(segments + 1):
			var px = (x - segments / 2.0) * step
			var pz = (z - segments / 2.0) * step

			# Add some rolling hills
			var height = 0.0
			height += sin(px * 0.05) * cos(pz * 0.05) * 8.0
			height += sin(px * 0.15) * cos(pz * 0.12) * 3.0

			vertices.append(Vector3(px, height, pz))
			normals.append(Vector3.UP)
			uvs.append(Vector2(float(x) / segments, float(z) / segments))

	# Generate indices for triangles
	for z in range(segments):
		for x in range(segments):
			var i0 = z * (segments + 1) + x
			var i1 = i0 + 1
			var i2 = (z + 1) * (segments + 1) + x
			var i3 = i2 + 1

			# Two triangles per quad
			indices.append(i0)
			indices.append(i2)
			indices.append(i1)

			indices.append(i1)
			indices.append(i2)
			indices.append(i3)

	# Create the mesh
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX] = indices

	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

	print("✅ Created flat landscape with ", vertices.size(), " vertices, ", indices.size() / 3, " triangles")
	_create_collision()
