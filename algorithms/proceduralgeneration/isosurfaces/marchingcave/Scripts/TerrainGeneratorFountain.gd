extends TerrainGeneratorBase
class_name TerrainGeneratorFountain

# --- DNA (stage 2, promoted 2026-08-12) -------------------------------------
# THE PROBLEM. This file was 24 lines with no @export of its own, so the audit called
# the artifact axis-less. It is not. MarchingFountain.glsl builds its density from TWO
# TERMS OF DIFFERENT PROVENANCE and then adds them together in one line:
#
#   WRITTEN   :198  density = (columnRadius - distanceFromAxis) / columnRadius
#                   an analytic tapered cylinder that knows nothing about noise
#   SAMPLED   :169-185  `sum`, four octaves of billow noise
#   THE DEAL  :201  density += sum * 0.5
#
# That literal 0.5 is the entire negotiation between a shape and its weather, and it is
# this wave's theme — where a field comes from — reduced to one multiply. Both axes are
# lifted out of shader literals, exactly as TerrainGeneratorGyroid's were, and reach the
# GPU by the pattern TerrainGeneratorShapes already uses for shapeId: get_params_array()
# calls super and appends trailing floats, and ParamsBuffer gains matching TRAILING
# fields in the SAME ORDER. The shared eleven-field prefix every other Marching*.glsl
# reads is untouched. Order is the contract — a mismatch is not a compile error, it
# silently shifts every float.
#
# admixture — HOW MUCH OF THE FIELD IS SAMPLED RATHER THAN WRITTEN. The multiplier on
#   the noise sum, i.e. the weight of the sampled term against the written one.
#     spray    SHIPPED, 0.5. The literal that has always been compiled in at :201.
#     column   0.0. The sampled term is GONE and what marches out is the clean tapered
#              cylinder alone. Nothing in this sequence has yet shown the written half
#              of a hybrid field by itself, and that frame is the argument: a fountain
#              is a shape plus weather.
#     foam     1.2. The noise sum now exceeds the written term's range, so the column
#              survives as a bias and the skin breaks up.
#     weather  2.5. The noise dominates; the surface breaks into drifting sheets and
#              detached blobs. The first time in this sequence a field's two provenances
#              TRADE PLACES.
#
# taper — THE SHAPE OF THE WRITTEN HALF. Two literals sit at :192 and :194. The base
#   radius is params.scale * 0.4; the flare adds up to another 0.4 * scale below y = 0
#   and is the reason the fountain has a basin at all. This axis multiplies the FLARE
#   COEFFICIENT ONLY and leaves the base 0.4 alone, so it varies the PROFILE with the
#   SIZE held — which is what makes it orthogonal to admixture in the arithmetic
#   (admixture varies what is added with the profile held; taper varies the profile with
#   the addition held).
#     basin    SHIPPED, 1.0.
#     shaft    0.0  — no flare, a straight column.
#     bell     2.5  — a trumpet.
#     waisted  -0.75 — the radius NARROWS downward into an hourglass. The same written
#              field, upended. Bounded on purpose: at the extreme the flare term reaches
#              -0.75 * 0.4 = -0.3 against a base of 0.4, so columnRadius stays strictly
#              positive and the (R - r) / R division can never blow up.
#
# CONDITIONALLY VISIBLE, AND SAID BEFORE THE CAPTURE RATHER THAN AFTER. At
# admixture = weather the noise term is five times the shipped weight and swamps a
# radius difference of a few percent of scale, so all four taper rungs converge there.
# The critic's numbers must be grouped BY VALUE PAIR, not by per-axis mean, or taper
# gets filed WEAK for a reason that is a fact about the other axis. That is the trap
# `join` already paid for once.
#
# WHAT IS DECLINED, by name.
#   flowSpeed and the 5.0 at :164-165 — the fountain's entire animation. It is a RATE
#     and one PNG cannot hold it (law 2). NOT converted to a standing arrangement,
#     because the standing form it would take is a fixed offset of the sample domain,
#     which is `noise_offset` — refused everywhere else in this sequence as a different
#     arbitrary sample of the same field rather than a different field.
#   continuous_update — a rate, and the reason this artifact needs a pose fixture at all.
#   the four-octave loop at :173 — `octaves` is taken twice (mc_cave, mc_inside_cave)
#     and it is the identical question.
#   iso_level — `threshold` is taken by mc_torus_sculpture, AND here it is degenerate:
#     the written term is (R - r) / R, so shifting the threshold by d moves the surface
#     to r = R(1 - d), a proportional radius change — precisely the one thing taper
#     holds fixed. The two axes would measure each other.
#   noise_scale, chunk_scale, center_position — a frequency (the same ratio question as
#     `resolution`) plus a size and a placement, both self-cancelling under an
#     AABB-fitted camera.
#   capture_fade_distance — inherited from TerrainGeneratorBase and irrelevant here.
#     FountainDemo.tscn's material_override is a transparent blue StandardMaterial3D,
#     not TerrainMat.tres, so there is no distance fade to open. Left at 0.0.
#
# NOT DETERMINISTIC AS SHIPPED — see capture_pose_time below. This is the one artifact
# in the wave where a still of the scene as authored is a photograph of a random phase.
# ----------------------------------------------------------------------------

## Weight on the noise sum. `spray` is 0.5 and 0.5 is exactly representable, so the
## default is not a value that lands near the literal — it IS the literal that
## MarchingFountain.glsl:201 always compiled in.
const ADMIXTURE_WEIGHTS: Dictionary = {
	"spray": 0.5,     # SHIPPED
	"column": 0.0,    # written term alone
	"foam": 1.2,
	"weather": 2.5,   # sampled term dominates
}

## Multiplier on the FLARE coefficient at :194 only, never on the base radius at :192.
## `basin` is 1.0, and `smoothstep(...) * params.scale * 0.4 * 1.0` returns the identical
## bit pattern for every finite float.
const TAPER_FLARES: Dictionary = {
	"basin": 1.0,     # SHIPPED
	"shaft": 0.0,
	"bell": 2.5,
	"waisted": -0.75,
}

const ADMIXTURES: PackedStringArray = ["spray", "column", "foam", "weather"]
const TAPERS: PackedStringArray = ["basin", "shaft", "bell", "waisted"]

@export_category("Fountain DNA")
@export_enum("spray", "column", "foam", "weather") var admixture: String = "spray"
@export_enum("basin", "shaft", "bell", "waisted") var taper: String = "basin"

## CAPTURE ONLY, and below zero means "keep the shipped wall clock, tick for tick".
##
## params.time is TerrainGeneratorBase.time, incremented in _process every frame, and
## FountainDemo.tscn sets continuous_update = true so the loop never stops. The shader
## scrolls its sample domain by `flowSpeed * params.time * 5.0` at :165, so two tiles
## shot 1.5 s apart photograph two different states of the same field and the bite
## number would be noise dressed as evidence.
##
## Zero or above pins the pose: `time` is assigned ONCE before _ready runs the first
## dispatch, and _process then returns immediately so nothing advances it. Same
## semantics as metaballs.gd's pose_time, and the same capture-only contract
## TerrainGeneratorBase already documents for capture_fade_distance — deliberately NOT
## read by apply_grid_config, so no map token can reach it. It is for dna.fixture, which
## assigns straight onto the typed float export before _ready.
##
## At the shipped -1.0 all three placements animate exactly as they do today.
@export var capture_pose_time: float = -1.0

## Signature of everything the build reads, captured after the last successful
## generation. Empty until _ready has run, which is what tells apply_grid_config that
## there is nothing yet to rebuild.
var _built_signature: String = ""


func get_class_name() -> String:
	return "TerrainGeneratorFountain"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingFountain.glsl"


## Config is stamped as metadata BEFORE the node enters the tree
## (GridInteractablesComponent._apply_artifact_config runs at line 1195, add_child at
## 1220), so reading it here means _ready builds with the right values the first time and
## the deferred apply_grid_config that follows finds nothing to do.
func _ready() -> void:
	_read_metadata_overrides()
	if capture_pose_time >= 0.0:
		# Before super._ready(), because super._ready() runs the first dispatch and the
		# shader reads params.time. Pinning it afterwards would photograph frame zero and
		# call it a pose.
		time = capture_pose_time
	super._ready()
	_built_signature = _config_signature()


## The shipped loop, untouched, unless a capture pinned the pose. GDScript does not chain
## built-in virtuals, so `super._process(delta)` here IS the base's body — at the shipped
## capture_pose_time of -1.0 this override is transparent.
func _process(delta: float) -> void:
	if capture_pose_time >= 0.0:
		return
	super._process(delta)


## The two floats appended to the base's eleven, matching the trailing fields added to
## ParamsBuffer in MarchingFountain.glsl. Same pattern as TerrainGeneratorShapes.shapeId
## and TerrainGeneratorGyroid's four. THE ORDER HERE IS THE CONTRACT.
func get_params_array():
	var params = super.get_params_array()
	params.append(_admixture_weight())   # was the literal 0.5 at MarchingFountain.glsl:201
	params.append(_taper_flare())        # was the implicit 1.0 on the flare term at :194
	return params


func _admixture_weight() -> float:
	if ADMIXTURE_WEIGHTS.has(admixture):
		return float(ADMIXTURE_WEIGHTS[admixture])
	return float(ADMIXTURE_WEIGHTS["spray"])


func _taper_flare() -> float:
	if TAPER_FLARES.has(taper):
		return float(TAPER_FLARES[taper])
	return float(TAPER_FLARES["basin"])


## The shader's own input, stringified, MINUS the clock.
##
## Using get_params_array() rather than a hand-listed tuple means the signature cannot
## drift out of step with what the build actually reads — if a value reaches the GPU it
## is in here. Index 0 is `time`, and it is skipped deliberately: on this subclass it is
## a live wall clock, so including it would make every comparison unequal and turn the
## guard into an unconditional rebuild. Nothing else in the array moves on its own.
func _config_signature() -> String:
	var out: String = ""
	var i: int = 0
	for v in get_params_array():
		if i > 0:
			out += "%.6f|" % float(v)
		i += 1
	return out


func _read_metadata_overrides() -> void:
	if has_meta("config_admixture"):
		var a: String = str(get_meta("config_admixture")).strip_edges().to_lower()
		if ADMIXTURES.has(a):
			admixture = a
	if has_meta("config_taper"):
		var t: String = str(get_meta("config_taper")).strip_edges().to_lower()
		if TAPERS.has(t):
			taper = t


## Guarded. The old body was a bare `pass` — a method that existed only so the grid's
## has_method() check would find it. It now rebuilds when, and only when, a value the
## SHADER reads has actually changed.
##
## capture_pose_time is NOT read here, on purpose: it is a capture pin, and no map token
## may reach it. All three placements of this artifact are bare tokens with no config, so
## none of them reaches the regenerate branch at all.
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
## NOTHING IS FREED BY THIS SCRIPT — there is no _owned array because this script owns no
## node. create_mesh() rewrites array_mesh's single surface in place, and the base's
## _create_collision() removes only the StaticBody3D it created itself. A blanket free of
## children is what cost three scripts a pass in the last wave: GridInteractablesComponent
## attaches a _RotationTimer to the artifact after spawn.
func _regenerate() -> void:
	if use_fallback or rendering_device == null:
		return
	if waiting_for_compute or waiting_for_meshthread:
		# A dispatch is already in flight and resubmitting under it is the segfault
		# release() documents. The signature is deliberately NOT recorded here, so this
		# reads as "not built yet" rather than as a success. Unlike the gyroid, this
		# artifact ships with continuous_update = true, so the running loop will pick the
		# new value up on its next dispatch anyway — run_compute() re-reads
		# get_params_array() every time.
		return
	run_compute()
	fetch_and_process_compute_data()
	create_mesh()
	_built_signature = _config_signature()


func _create_fallback_mesh() -> void:
	print("TerrainGeneratorFountain: Creating fallback cylinder...")
	_create_simple_cylinder_mesh()
	print("✅ Fallback cylinder created")

func _create_simple_cylinder_mesh() -> void:
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 20.0
	cylinder.bottom_radius = 20.0
	cylinder.height = 100.0
	mesh = cylinder
	_create_collision()
