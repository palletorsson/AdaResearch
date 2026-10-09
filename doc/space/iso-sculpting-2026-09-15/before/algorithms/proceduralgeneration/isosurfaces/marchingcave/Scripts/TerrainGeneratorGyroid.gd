extends TerrainGeneratorBase
class_name TerrainGeneratorGyroid

# --- DNA (stage 2, promoted 2026-08-12) -------------------------------------
# THE PROBLEM. This file was 24 lines and declared no @export of its own, so the
# audit called the artifact axis-less. It is not: it has eight numbers, and every
# one of them is a literal inside MarchingGyroid.glsl. The shader writes Schoen's
# gyroid in ONE line — `float gyroid = dot(sin(p), cos(p.yzx))` at :185 — and then
# perturbs it three separate times before anything is compared to a threshold:
#
#   :171-181  DOMAIN WARP        three snoise channels at warpScale 0.1, `p += warp * 4.0`
#   :189-190  EROSION            `snoise(p * 2.0)` added at 0.5
#   :194-197  THICKNESS          `snoise(worldPos * 0.05)` added at 1.0 — and because it is
#                                added to the density BEFORE the comparison, it is a
#                                THRESHOLD THAT VARIES THROUGH SPACE
#
# Nobody has ever seen this artifact's own subject. The registry entry promises "gyroid
# minimal surface … triply periodic implicit function" and the pure surface is never
# rendered anywhere in the corpus. Both axes are lifted out of those literals, the way
# csg_compose_workbench's `algebra` was lifted out of a hardcoded three-element array,
# and both are reached by the pattern TerrainGeneratorShapes already uses for shapeId:
# get_params_array() appends trailing floats and ParamsBuffer gains matching trailing
# fields. No shared struct is disturbed and nothing is invented.
#
# intrusion — HOW MUCH NOISE IS ALLOWED TO TOUCH THE FORMULA. The three strengths as a
#   ladder, not as three knobs. Measured on a numpy replica of evaluate() over the same
#   65^3 corner grid at the scene's own iso_level of 1.0, counting connected bodies:
#     melted    SHIPPED. (4.0, 0.5, 1.0). The lattice bent out of true and then shattered:
#               2,859 separate bodies, no period readable anywhere in the box.
#     formula   (0, 0, 0). The pure periodic level set — ONE connected body, 100% of the
#               solid, every unit cell identical. Said precisely, because the difference
#               matters and the registry's own description does not make it: this is the
#               gyroid at THIS ARTIFACT'S threshold, g = iso_level = 1.0, not the balanced
#               minimal surface g = 0. It is the mathematical object the entry claims, at
#               the threshold the scene actually set.
#     eroded    (0, 0.5, 0). Period intact, sheets pitted and ragged: 1,268 bodies, but
#               95.3% of the solid still in one piece. The lattice survives its own wear.
#     drifting  (0, 0.5, 1.0). Erosion plus the space-varying threshold, and nothing else.
#               Sheets thicken in some regions and thin to holes in others because the
#               boundary is no longer a constant — which is this sequence's whole quarrel
#               with the word "the" in "the surface".
#
# period — A TRIPLY-PERIODIC SURFACE HAS NO NATURAL SIZE, so how many cells you see is a
#   framing decision and not a property of the surface. baseScale 0.5 against the tscn's
#   chunk_scale 20 yields ~1.59 periods per axis. The multiplier is applied ONLY to the
#   gyroid term's coordinate, DELIBERATELY not to baseScale, because baseScale also feeds
#   the warp and the erosion and scaling it would confound the two axes. Written this way
#   the pair is strictly orthogonal: intrusion varies what is ADDED to the field with the
#   period held; period varies the period with the additions held.
#     pair     SHIPPED, 1.0 — ~1.6 periods, two half-cells reading as a pair of sheets.
#     sheet    0.5  — ~0.8 periods, less than one full cell. The picture that shows the
#              gyroid is a SURFACE and not a lattice.
#     lattice  2.0  — ~3.2 periods, the repeat unmistakable.
#     weave    4.0  — ~6.4 periods, a fine three-way interpenetrating weave.
#
# WHAT IS DECLINED. `continuous_update` (TerrainGeneratorBase:11) re-runs the dispatch
# every frame — a rate, invisible in a still, and on a static gyroid it changes nothing
# except the risk of photographing a half-built mesh. `noise_offset` walks the field's
# domain, which is not a different surface but a different arbitrary sample of the same
# one. `chunk_scale` and `center_position` are size and placement, and both self-cancel
# under an AABB-fitted camera. `iso_level` is real, and it is the sequence's central
# question — but on THIS artifact the thickness modulation already varies the threshold
# through space, so an axis over the constant would be arguing with intrusion=drifting
# for the same pixels.
#
# STILL-VISIBLE BY CONSTRUCTION: _process is overridden to `pass` (below) and the base
# stops processing after the first mesh, so one PNG is a complete account. This is not a
# subtle rung ladder — it is four objects that share one line of code.

## Warp, erosion and thickness strength per rung. These three triples ARE the three
## literals that used to sit at MarchingGyroid.glsl:181, :190 and :197; `melted` holds
## them, so the default hands the shader back the same three floats it always compiled
## in. Nothing is derived, scaled or recomputed on that path.
const INTRUSION_STRENGTHS: Dictionary = {
	"melted": [4.0, 0.5, 1.0],
	"formula": [0.0, 0.0, 0.0],
	"eroded": [0.0, 0.5, 0.0],
	"drifting": [0.0, 0.5, 1.0],
}

## Multiplier on the gyroid term's coordinate only. `pair` is 1.0 and `p * 1.0` returns
## the identical bit pattern for every finite float, so the default is an exact no-op
## rather than a value that happens to be close.
const PERIOD_SCALES: Dictionary = {
	"pair": 1.0,
	"sheet": 0.5,
	"lattice": 2.0,
	"weave": 4.0,
}

const INTRUSIONS: PackedStringArray = ["melted", "formula", "eroded", "drifting"]
const PERIODS: PackedStringArray = ["pair", "sheet", "lattice", "weave"]

@export_category("Gyroid DNA")
@export_enum("melted", "formula", "eroded", "drifting") var intrusion: String = "melted"
@export_enum("pair", "sheet", "lattice", "weave") var period: String = "pair"

## Signature of everything the build reads, captured after the last successful
## generation. Empty until _ready has run, which is what tells apply_grid_config
## that there is nothing yet to rebuild.
var _built_signature: String = ""


func get_class_name() -> String:
	return "TerrainGeneratorGyroid"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingGyroid.glsl"

func _process(_delta):
	# Disable per-frame updates for optimal static mesh generation
	pass


## Config is stamped as metadata BEFORE the node enters the tree
## (GridInteractablesComponent._apply_artifact_config runs at line 1195, add_child at
## 1220), so reading it here means _ready builds with the right values the first time
## and the deferred apply_grid_config that follows finds nothing to do.
func _ready() -> void:
	_read_metadata_overrides()
	super._ready()
	_built_signature = _config_signature()


## The four floats appended to the base's eleven, matching the trailing fields added to
## ParamsBuffer in MarchingGyroid.glsl. Same pattern as TerrainGeneratorShapes.shapeId.
func get_params_array():
	var params = super.get_params_array()
	var s: Array = _strengths()
	params.append(float(s[0]))   # warpStrength      — was the literal 4.0
	params.append(float(s[1]))   # erosionStrength   — was the literal 0.5
	params.append(float(s[2]))   # thicknessStrength — was the literal 1.0
	params.append(_period_scale())
	return params


func _strengths() -> Array:
	if INTRUSION_STRENGTHS.has(intrusion):
		return INTRUSION_STRENGTHS[intrusion] as Array
	return INTRUSION_STRENGTHS["melted"] as Array


func _period_scale() -> float:
	if PERIOD_SCALES.has(period):
		return float(PERIOD_SCALES[period])
	return 1.0


## The shader's own input, stringified. Using get_params_array() rather than a
## hand-listed tuple means the signature cannot drift out of step with what the build
## actually reads — if a value reaches the GPU it is in here. `time` is one of the
## eleven and is permanently 0.0 on this subclass, because _process is `pass`.
func _config_signature() -> String:
	var out: String = ""
	for v in get_params_array():
		out += "%.6f|" % float(v)
	return out


func _read_metadata_overrides() -> void:
	if has_meta("config_intrusion"):
		var i: String = str(get_meta("config_intrusion")).strip_edges().to_lower()
		if INTRUSIONS.has(i):
			intrusion = i
	if has_meta("config_period"):
		var p: String = str(get_meta("config_period")).strip_edges().to_lower()
		if PERIODS.has(p):
			period = p


## Guarded. The old body was a bare `pass` — a method that existed only so the grid's
## has_method() check would find it. It now rebuilds when, and only when, a value the
## shader reads has actually changed. None of the 13 map files that place this scene
## passes a config key at all, so none of them reaches the regenerate branch.
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


## Re-run the same three calls _ready runs, in the same order. Nothing is freed by this
## script: create_mesh() rewrites array_mesh's single surface in place and the base's
## _create_collision() removes only the StaticBody3D it created itself. A blanket free of
## children is what cost three scripts a pass in the last wave — GridInteractablesComponent
## attaches a _RotationTimer to the artifact after spawn, and this node's own StaticBody3D
## is the only child either script owns.
func _regenerate() -> void:
	if use_fallback or rendering_device == null:
		return
	# A dispatch already in flight: resubmitting under it is the crash release() documents.
	# Unreachable in practice, because _ready completes the whole cycle synchronously and
	# this subclass's _process never starts another.
	if waiting_for_compute or waiting_for_meshthread:
		return
	run_compute()
	fetch_and_process_compute_data()
	create_mesh()
	_built_signature = _config_signature()


func _create_fallback_mesh() -> void:
	print("TerrainGeneratorGyroid: Creating fallback sphere...")
	# Just a Sphere for fallback
	var sphere = SphereMesh.new()
	sphere.radius = 20.0
	sphere.height = 40.0
	mesh = sphere
	_create_collision()
