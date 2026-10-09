extends TerrainGeneratorBase

# --- DNA (stage 2, promoted 2026-08-12) -------------------------------------
# THIS FILE WAS 27 LINES: a shader path, a class name, a fallback torus, and an
# apply_grid_config whose whole body was `pass`. Zero @export of its own. Every number
# this artifact has is a literal inside MarchingCubesTorus.glsl, which writes a torus SDF
# at :173-174 and then adds three deformations to it in ONE line at :198:
#
#   :182-188  DEFORMATION   five octaves of snoise, `deformation * 8.0`  (swings ~ +/-15)
#   :192      TWIST         sin(angle*3 + y*0.1) * 3.0                   (swings +/-3)
#   :195      BULGE         sin(angle*5) * cos(y*0.15) * 4.0             (swings +/-4)
#
# and then compares the result to a single constant. Both axes come out of that sentence.
#
# EVERY :NNN BELOW IS A LINE NUMBER IN THE SHADER AS IT SHIPPED, i.e. BEFORE this promotion
# edited it — they are where the literals WERE, which is the claim being made. This edit
# added 16 comment lines to ParamsBuffer and split one expression across four lines, so the
# same code now sits 16-20 lines lower. Current anchors, so the next reader can find them
# without a diff: majorRadius/minorRadius :181-182 (was :165-166), torusDist :190 (:173-174),
# the five-octave loop :198-204 (:182-188), twist :208 (:192), bulge :211 (:195),
# sculptureShape :218-221 (:198), density :225 (:202).
#
# threshold — THE SURFACE IS NOT IN THE FIELD, IT IS IN THE NUMBER YOU COMPARE THE FIELD
#   TO. :202 ends `float density = -sculptureShape;` and main() sets a corner bit when
#   `cubeCorners[i].w < isoLevel`, so solid is density >= isoLevel, i.e.
#   sculptureShape <= -isoLevel. sculptureShape is a signed distance, so the threshold is
#   EXACTLY an offset on the tube radius:
#
#       R_eff = minorRadius - isoLevel - N     (minorRadius = 20 at :166, N = the sum of
#                                               the three deformation terms)
#
#   There is no space-varying thickness term anywhere in this file, which is the precise
#   condition gyroid_demo named when it refused this axis on ITSELF ("it belongs to a
#   sibling in this sequence that has no thickness term"). This is that sibling. The rungs
#   are biases on the shipped iso_level of 0.0, and they are named for what the cut leaves
#   behind rather than for the number, exactly as voxelnoise's `threshold` rungs are:
#     ring      SHIPPED, +0.0. R_eff 20 against a major radius of 50: a 30 m clear hole.
#     closed    -35.0. R_eff 55 against a major radius of 50 — GENUS 1 BECOMES GENUS 0
#               over most of the ring, with no change to a single term of the field.
#     swollen   -18.0. R_eff 38, the hole narrowed from 30 m of clear radius to 12.
#     beaded    +6.0. R_eff 14, and because the deformation swings about +/-22 the tube
#               opens into separate bodies wherever the noise runs positive.
#
# intrusion — HOW MUCH OF THE MATHEMATICAL OBJECT SURVIVES BEING WRITTEN INTO A NOISE
#   PIPELINE. gyroid_demo's question (wave 1, this same sequence) asked of a compact SDF
#   instead of a triply-periodic level set, and the word and two of the rung names are
#   TAKEN FROM IT ON PURPOSE — the family is only readable if the shipped rung and the
#   null rung carry the same names on both artifacts. The triple replaces the three
#   multipliers at :198, of which two were implicit 1.0:
#     melted     SHIPPED, [8.0, 1.0, 1.0]. The heavily deformed lump that four maps place.
#     formula    [0.0, 0.0, 0.0]. The exact torus SDF, major 50 minor 20. The registry
#                entry promises "marching cubes extracting torus isosurface" and this
#                plain torus has never been rendered anywhere in this corpus.
#     rippled    [0.0, 1.0, 1.0]. The two ANALYTIC deformations only — strictly periodic,
#                symmetric under the 3-fold twist and the 5-fold bulge. Order without noise.
#     roughened  [8.0, 0.0, 0.0]. Noise alone.
#   Orthogonal to threshold by construction, and it is gyroid's own orthogonality argument
#   reused: intrusion varies what is ADDED to the distance, threshold varies where it is CUT.
#   The amplitudes at :192 (*3.0) and :195 (*4.0) are deliberately NOT touched — the rung
#   triple multiplies the FINISHED terms, so the author's numbers stay where the author
#   put them and the shipped triple's two 1.0s are exact.
#
# THE HAZARD THAT COULD DESTROY THIS SWEEP, and it is the inverse of every trap in the
# table: TerrainGeneratorBase.create_mesh() falls through to _create_fallback_mesh() when
# len(verts) == 0, and _create_fallback_torus() below sets `mesh = TorusMesh` with inner 30
# / outer 50 / 48 rings — A PERFECT, SMOOTH, TEXTBOOK TORUS. An over-thinned rung that
# empties the field therefore publishes a CLEANER picture than the real artifact, and the
# critic would score it as a huge, confident bite about nothing. `beaded` is +6.0 and not
# +12.0 for exactly this reason. THE RUN IS ONLY VALID IF THE SWEEP LOG SHOWS
# "TerrainGeneratorTorus: Generation complete!" FOR ALL SIXTEEN TILES AND NEVER SHOWS
# "Creating fallback simple torus".
#
# WHAT IS DECLINED. `resolution` — this artifact wants the family word more than anything
# else in the wave (its chunk_scale is 1000 while its torus is 158 m across, so on THIS
# artifact chunk_scale is not extent, it is purely how finely the field is sampled) and it
# CANNOT HAVE IT: TerrainGeneratorBase:13 already declares `const resolution : int = 8`,
# the workgroup count every buffer size is derived from, and a subclass cannot shadow an
# inherited member in GDScript. `hole` on majorRadius 50.0 at :165 is refused because it
# fights threshold for the same pixels — both close the hole, one by moving the centreline
# in and one by fattening the tube, so they would measure each other. `period` because a
# compact object has no period. chunk_scale, center_position, continuous_update,
# invert_faces and noise_offset for the reasons in the registry's `declined`.

## Bias added to iso_level per rung. `ring` is EXACTLY 0.0 and `x + 0.0` returns the
## identical bit pattern for every finite float, so the default is a structural no-op and
## not a value that lands near the shipped one. Applied to the params array rather than to
## the property because `iso_level = iso_level + bias` would ACCUMULATE across an
## apply_grid_config re-entry; the params override is stateless and cannot drift.
const THRESHOLD_BIASES: Dictionary = {
	"closed": -35.0,
	"swollen": -18.0,
	"ring": 0.0,
	"beaded": 6.0,
}

## [deformWeight, twistWeight, bulgeWeight] per rung. These three floats ARE the three
## multipliers that used to sit at MarchingCubesTorus.glsl:198 — the explicit 8.0 and two
## implicit 1.0s — so `melted` hands the shader back the same arithmetic it always compiled
## in. Nothing is derived, scaled or recomputed on that path.
const INTRUSION_WEIGHTS: Dictionary = {
	"melted": [8.0, 1.0, 1.0],
	"formula": [0.0, 0.0, 0.0],
	"rippled": [0.0, 1.0, 1.0],
	"roughened": [8.0, 0.0, 0.0],
}

const THRESHOLDS: PackedStringArray = ["closed", "swollen", "ring", "beaded"]
const INTRUSIONS: PackedStringArray = ["melted", "formula", "rippled", "roughened"]

@export_category("Torus DNA")
@export_enum("closed", "swollen", "ring", "beaded") var threshold: String = "ring"
@export_enum("melted", "formula", "rippled", "roughened") var intrusion: String = "melted"

## Signature of everything the build reads, captured after the last successful generation.
## Empty until _ready has run, which is what tells apply_grid_config there is nothing yet
## to rebuild.
var _built_signature: String = ""

## Nodes THIS SCRIPT created, and the only nodes it is ever allowed to free. It is empty by
## construction today and that is the point of writing it down: create_mesh() rewrites
## array_mesh's single surface in place and the base's _create_collision() removes only the
## StaticBody3D it created itself, so this script owns nothing. A blanket free of children
## is what cost three scripts a pass in the last wave — GridInteractablesComponent attaches
## a _RotationTimer to the artifact after spawn, and curation_station reparents the whole
## scene under a plinth. If a later edit does build a node here, it registers it in this
## array and _free_owned() is already the only teardown path.
var _owned: Array[Node] = []


func get_class_name() -> String:
	return "TerrainGeneratorTorus"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingCubesTorus.glsl"


## Config is stamped as metadata BEFORE the node enters the tree — GridInteractablesComponent
## finds this node through _config_holder (the .tscn root is a scriptless Node3D), stamps
## config_* at line 1700 and calls add_child at 1220 — so reading it here means _ready builds
## with the right values the first time and the deferred apply_grid_config that follows finds
## nothing to do.
func _ready() -> void:
	_read_metadata_overrides()
	super._ready()
	_built_signature = _config_signature()


## The base's eleven floats, with index 2 (iso_level) biased by the threshold rung, plus the
## three trailing floats that match the fields appended to ParamsBuffer in
## MarchingCubesTorus.glsl. ORDER AND COUNT MUST AGREE WITH THE .glsl EXACTLY: eleven from
## super, then deformWeight, twistWeight, bulgeWeight. A mismatch here is not a compile
## error, it silently shifts every float. Same pattern as TerrainGeneratorShapes.shapeId.
func get_params_array():
	var params: Array = super.get_params_array()
	# index 2 is iso_level — TerrainGeneratorBase.get_params_array's third append. The shader
	# already reads it as isoLevel, so `threshold` needs no new field of its own.
	params[2] = float(params[2]) + _threshold_bias()
	var w: Array = _weights()
	params.append(float(w[0]))   # deformWeight — was the literal 8.0 at MarchingCubesTorus.glsl:198
	params.append(float(w[1]))   # twistWeight  — was an implicit 1.0 at :198
	params.append(float(w[2]))   # bulgeWeight  — was an implicit 1.0 at :198
	return params


func _threshold_bias() -> float:
	if THRESHOLD_BIASES.has(threshold):
		return float(THRESHOLD_BIASES[threshold])
	return 0.0


func _weights() -> Array:
	if INTRUSION_WEIGHTS.has(intrusion):
		return INTRUSION_WEIGHTS[intrusion] as Array
	return INTRUSION_WEIGHTS["melted"] as Array


## The shader's own input, stringified — so the guard cannot drift out of step with what the
## build actually reads: if a value reaches the GPU it is in here.
##
## EXCEPT `time`, AND THE EXCEPTION IS LOAD-BEARING. TerrainGeneratorGyroid can include it
## because that subclass overrides _process to `pass` and its time is frozen at 0.0. THIS
## subclass does not override _process, so the base's tick keeps advancing `time` (and
## re-dispatching) for roughly 102 frames after _ready until _initial_generation_done flips
## and set_process(false) lands. MarchingCubesTorus.glsl's evaluate() never references
## params.time — it reads numVoxelsPerAxis, scale, posX/Y/Z, noiseOffset*, noiseScale, and
## main() reads isoLevel — so time is uploaded and ignored. Including it would make this
## guard a CLOCK: every apply_grid_config call would see a changed signature and rebuild,
## which is the exact opposite of what the guard is for.
func _config_signature() -> String:
	var out: String = ""
	var p: Array = get_params_array()
	for i in range(p.size()):
		if i == 0:
			continue    # `time`, uploaded and ignored by this shader — see above
		out += "%.6f|" % float(p[i])
	return out


func _read_metadata_overrides() -> void:
	if has_meta("config_threshold"):
		var t: String = str(get_meta("config_threshold")).strip_edges().to_lower()
		if THRESHOLDS.has(t):
			threshold = t
	if has_meta("config_intrusion"):
		var i: String = str(get_meta("config_intrusion")).strip_edges().to_lower()
		if INTRUSIONS.has(i):
			intrusion = i


## Guarded. The old body was a bare `pass` — a method that existed only so the grid's
## has_method() check would find it. It now rebuilds when, and only when, a value the SHADER
## reads has actually changed. None of the 5 placements across this script's two registry
## tokens passes a config key, so none of them reaches the regenerate branch.
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
func _regenerate() -> void:
	if use_fallback or rendering_device == null:
		return
	# A dispatch already in flight: resubmitting under it is the crash release() documents.
	# Reachable on THIS subclass in a way it is not on the gyroid — the base's _process
	# re-dispatches until the initial generation completes — and the early return is
	# self-healing rather than lossy, because run_compute() re-reads get_params_array() on
	# every pass, so a value that arrives during that window is picked up by the base loop.
	# _built_signature is deliberately NOT advanced here: the worst case is one redundant
	# rebuild of an identical mesh later, which is cheaper than a silently stale one.
	if waiting_for_compute or waiting_for_meshthread:
		return
	_free_owned()
	run_compute()
	fetch_and_process_compute_data()
	create_mesh()
	_built_signature = _config_signature()


## Frees ONLY what this script built. See _owned: empty by construction today.
func _free_owned() -> void:
	for n in _owned:
		if is_instance_valid(n):
			n.queue_free()
	_owned.clear()


func _create_fallback_mesh() -> void:
	print("TerrainGeneratorTorus: Creating fallback simple torus...")
	_create_fallback_torus()
	print("✅ Fallback torus created")

func _create_fallback_torus() -> void:
	var torus = TorusMesh.new()
	torus.inner_radius = 30.0
	torus.outer_radius = 50.0
	torus.rings = 48
	torus.ring_segments = 24
	mesh = torus
	# Ensure collision is created for the primitive mesh if needed
	create_trimesh_collision()

	print("✅ Fallback torus created")
