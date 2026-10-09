extends TerrainGeneratorBase

# --- DNA (stage 2, promoted 2026-08-12) -------------------------------------
# THE PROBLEM. This file was 60 lines and declared no @export of its own, so the audit
# called the artifact axis-less. It is not. MarchingCubesOverhangTerrain.glsl is not one
# formula — it is FIVE SCULPTURAL CLAIMS SUMMED, at :234-238 of the pre-promotion file:
#
#     density = baseTerrain - overhangDensity - caveStrength - archStrength
#                                                            + outcropStrength
#
# and each of the four subtracted/added terms carried its own strength LITERAL:
#
#   :171   overhang      elevationFactor * 0.8      gated by smoothstep(-10, 20, height)
#   :198   cave entrance caveNoise * caveMask * 0.6 gated by smoothstep(40, -10, y)
#   :219   arch          archNoise * archMask * 0.4 gated by two smoothsteps
#   :229   rocky outcrop outcropNoise * mask * 0.3  gated by a band above the surface
#
# The scene's own Label3D (marchingcubes_overhang_landscape.tscn:90) advertises that list
# in words — "Featuring: Rocky Overhangs • Cave Entrances / Natural Arches • Vertical
# Outcrops". So the artifact makes a four-item promise IN TEXT, and until now the picture
# was never asked to keep it. `landform` asks.
#
# landform — WHICH LANDFORMS ARE ACTUALLY IN THE FIELD. Not four independent knobs: an
#   ACCUMULATING LADDER, so each rung adds exactly one of the four claims to the one
#   before it and every step is attributable to a single term.
#
#     hillside  [0, 0, 0, 0]              baseTerrain alone. A pure heightfield — one
#                                         value of y per column, the ground as the graph
#                                         of a function. This is the same null that
#                                         mc_flat_landscape argues, and the two artifacts
#                                         STAND IN THE SAME MAP (ISO_FlatTerrain places
#                                         both), which is the first time in this corpus
#                                         two artifacts argue the same null side by side.
#     overhung  [0.8, 0, 0, 0]            the first rung where the ground is not
#                                         single-valued in y. The cliff leans out over
#                                         your head — which is the registry's own
#                                         qfep_connection for this token, made variable.
#     quarried  [0.8, 0.6, 0, 0]          the rung at which the landscape acquires an
#                                         INTERIOR. Cave entrances open. This is the rung
#                                         that answers to the sequence's truth line: the
#                                         boundary between inside and outside becomes
#                                         geometry, and here there starts to be an inside.
#     arched    [0.8, 0.6, 0.4, 0]        pillars with air between them; the ground
#                                         becomes a thing you can pass under.
#     compound  [0.8, 0.6, 0.4, 0.3]      SHIPPED. All five claims, the landscape every
#                                         existing placement has always shown.
#
# WHY `landform` AND NOT A WORD ALREADY IN THE CORPUS. `taxonomy` (combine_capsule,
# facade_grammar_demo, +5) sorts a thing into a kind; this does not sort, it accumulates.
# `formation` (delaunay_triangulation_3d_cell, organic_space, +5) is about how a thing
# came to be arranged and presumes an agent. `relief` is spent on push_relabel_algorithm
# with a graph-theory meaning. `repertoire` is spent on mc_shapes_gallery in this very
# sequence and names a catalogue of separate objects, not terms summed into one field. It
# is emphatically NOT `intrusion` (gyroid_demo, this sequence): that word asks how much
# noise is allowed to touch a formula, and here EVERY term is noise — this asks which of
# five formulas are summed. `landform` is chosen because the shader's own local variables
# are already named for landforms — overhangDensity, caveStrength, archStrength,
# outcroppNoise — so the axis speaks the artifact's own vocabulary, which is the
# `fusion` / `bulge` pattern.
#
# WHAT IS DECLINED, and the first one was the closest call in the wave. THE FOUR MASKS —
# elevationFactor at :170, caveMask at :197, archMask at :216-217, outcropMask at :228 —
# decide WHERE each landform is allowed to appear. They are a zoning ordinance written
# into a density function, and forcing them all to 1.0 would strip the landscape of its
# geography. Refused because it would be a SECOND axis over the same five terms this one
# already varies: at landform=hillside the masks gate nothing, so four of ten cells in the
# crossed sheet would be one picture, and the critic would be grouping by value pair to
# rediscover that. It is the obvious next axis once landform has measured.
# `iso_level`: this shader's baseTerrain is a gradient, so a constant threshold offset is
# a vertical translation plus a widening of exactly the voids landform already opens.
# The surface noise at :148-149, `chunk_scale`, `center_position`: extent and placement,
# and both self-cancel under an AABB-fitted camera. `continuous_update`: a RATE, invisible
# in a still by law. `invert_faces`: two-valued and about winding, not landform.
# The horizontal banding terms — heightMod = sin(y * 0.1) at :174 and horizontalBands =
# sin(y * 0.15) at :206 — are the only strictly periodic things in the file and they do
# produce visible strata, but they are multiplied INTO overhangStrength and archNoise, so
# an axis over them would be an axis over two of landform's four terms wearing a new name.
#
# STILL-VISIBLE BY CONSTRUCTION. This subclass does not override _process, so the base
# ticks and re-dispatches ONCE (frame 0 run_compute, ~frame 12 fetch, ~frame 102
# create_mesh, then set_process(false)). That second pass is BIT-IDENTICAL: `params.time`
# is declared in ParamsBuffer and referenced nowhere in evaluate(), and snoise is the
# Ashima/stegu simplex function — a pure function of position, no seed, no clock. The only
# thing that could move its sample point is noise_offset, which nothing sets. So the mesh
# is finished when _ready returns and a still is a complete account.


## The four strength weights per rung, in the order the shader reads them:
## [overhang, cave, arch, outcrop]. `compound` holds the four literals that used to be
## written inline at MarchingCubesOverhangTerrain.glsl:171, :198, :219 and :229 — they
## were moved from the shader to this const and are handed back through four uniforms in
## the same order, so each masked noise product is multiplied by the same float32 it
## always compiled in. Nothing on the default path is derived, scaled or recomputed.
const LANDFORM_WEIGHTS: Dictionary = {
	"hillside": [0.0, 0.0, 0.0, 0.0],
	"overhung": [0.8, 0.0, 0.0, 0.0],
	"quarried": [0.8, 0.6, 0.0, 0.0],
	"arched": [0.8, 0.6, 0.4, 0.0],
	"compound": [0.8, 0.6, 0.4, 0.3],
}

const LANDFORMS: PackedStringArray = [
	"hillside", "overhung", "quarried", "arched", "compound"]

@export_category("Overhang Landscape DNA")
## Written in ladder order rather than default-first, because the ladder IS the argument:
## each value adds exactly one of the shader's four terms to the one before it, so the
## registry's declared order reads as the accumulation it is. The default is `compound`,
## the far end, which is what every existing placement has always shown.
##
## ON ONE LINE, DELIBERATELY. check_dna_declarations.has_export matches
## `@export[^\n]*\bvar\s+<axis>\b` — a SINGLE-LINE regex. Split across two lines (the
## annotation above, `var landform` below) this axis is invisible to it and the gate
## reports NO_EXPORT: "declared [...] but there is no `@export var landform`", which reads
## exactly like an axis nobody can set, when the export is right there and works fine in
## the editor and from a map. That is a fact about line breaks wearing the costume of a
## verdict about the registry. TerrainGeneratorGyroid keeps its two on one line each; keep
## this one there too.
@export_enum("hillside", "overhung", "quarried", "arched", "compound") var landform: String = "compound"

## Signature of everything the build reads, captured after the last successful
## generation. Empty until _ready has run, which is what tells apply_grid_config that
## there is nothing yet to rebuild.
var _built_signature: String = ""


func get_class_name() -> String:
	return "TerrainGeneratorOverhang"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingCubesOverhangTerrain.glsl"


## Config is stamped as metadata BEFORE the node enters the tree
## (GridInteractablesComponent._apply_artifact_config runs at line 1195, add_child at
## 1220), so reading it here means _ready builds with the right value the first time and
## the deferred apply_grid_config that follows finds nothing to do. capture_config_sweep
## takes the other route and assigns the property directly before add_child; that survives
## this call untouched, because with no config_landform metadata present nothing is
## written back over it.
func _ready() -> void:
	_read_metadata_overrides()
	super._ready()
	_built_signature = _config_signature()


## The four floats appended to the base's eleven, matching the trailing fields added to
## ParamsBuffer in MarchingCubesOverhangTerrain.glsl. Order here IS the field order there;
## a mismatch would silently shift every float and is not a compile error. Same pattern as
## TerrainGeneratorShapes.shapeId and TerrainGeneratorGyroid's four.
func get_params_array():
	var params = super.get_params_array()
	var w: Array = _weights()
	params.append(float(w[0]))   # overhangWeight — was the literal 0.8 at :171
	params.append(float(w[1]))   # caveWeight     — was the literal 0.6 at :198
	params.append(float(w[2]))   # archWeight     — was the literal 0.4 at :219
	params.append(float(w[3]))   # outcropWeight  — was the literal 0.3 at :229
	return params


## SHORT-CIRCUIT, not a formula that lands near the shipped numbers: at `compound` this
## returns the const 4-tuple, which is the four literals verbatim.
func _weights() -> Array:
	if LANDFORM_WEIGHTS.has(landform):
		return LANDFORM_WEIGHTS[landform] as Array
	return LANDFORM_WEIGHTS["compound"] as Array


## The shader's own input, stringified — so the guard cannot drift out of step with what
## the build actually reads: if a value reaches the GPU it is in here.
##
## WITH ONE EXCLUSION, AND IT IS LOAD-BEARING. Index 0 is `time`, which this subclass does
## NOT hold at zero: unlike TerrainGeneratorGyroid it leaves the base's _process in place,
## so `time += delta` runs for the ~102 frames of the base's second dispatch cycle.
## Including it would make the signature differ from itself one frame later and turn the
## guard into an unconditional rebuild — the opposite of what it is for. Excluding it is
## safe for exactly one reason, checked in the shader rather than assumed: evaluate() in
## MarchingCubesOverhangTerrain.glsl never references params.time. It is a declared field
## the terrain shaders inherit and this one does not read.
func _config_signature() -> String:
	var vals: Array = get_params_array()
	var out: String = ""
	for i in range(1, vals.size()):
		out += "%.6f|" % float(vals[i])
	return out


func _read_metadata_overrides() -> void:
	if has_meta("config_landform"):
		var v: String = str(get_meta("config_landform")).strip_edges().to_lower()
		if LANDFORMS.has(v):
			landform = v


## Guarded. The old body was a bare `pass` — a method that existed only so the grid's
## has_method() check would find it. It now rebuilds when, and only when, a value the
## shader reads has actually changed.
##
## FIVE PLACEMENTS ON THIS SCENE, reaching it by two paths, and an earlier draft of this
## comment got the second one wrong — it said this method "is never called from any map
## that exists", which is false and would have made the bit-identity claim rest on a
## mechanism that is not the operative one. The truth, traced rather than assumed:
##
##   (1) TWO BARE GRID TOKENS. `mc_overhang_landscape` in ISO_FlatTerrain and
##       `marchingcubes_portal_landscape:0:6` in ISO_PortalLandscape — the `:0:6` is
##       parsed into rotation_y and y_offset, never into config_data. Neither registry
##       entry declares default_params and neither token carries a delegate, so
##       GridInteractablesComponent builds an EMPTY merged_config, its
##       `if not merged_config.is_empty()` gate never opens, _apply_artifact_config is
##       never called, no metadata is stamped, and this method is genuinely not reached.
##
##   (2) THREE curation_station ROSTERS — Corridor_ISO_FlatTerrain and
##       Curation_Bay_isosurfaces_1 under mc_overhang_landscape, Corridor_ISO_PortalLandscape
##       under the crossed sibling. These DO call this method. curation_station.gd stamps
##       identity at :376, add_child at :377 — so _ready has already run and
##       _built_signature is already set — and then unconditionally calls
##       `inst.apply_grid_config({"emissive": false})` at :381-382. So the body below runs
##       with a single key that no build path reads: `emissive` is a valid identifier, so
##       config_emissive is stamped into metadata; _read_metadata_overrides looks only for
##       config_landform and finds none, leaving landform at compound; the recomputed
##       signature equals _built_signature and the method returns at the second guard.
##       Nothing is regenerated, nothing is freed, and the mesh built in _ready stands.
##
## ArtifactIdentity.stamp() is the one route by which a registry could reach the property
## before _ready — it stamps config_<k> for each key of the entry's default_params, at
## :376, BEFORE add_child. Both entries were checked: neither declares default_params, so
## it stamps only artifact_lookup_name and this axis is untouched by it.
##
## So all five come out at landform = compound either way; three of them get there through
## the guard rather than around it, which is exactly what the guard is for.
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


## Bring an in-flight dispatch to rest, synchronously, in the same order and with the same
## two calls the base's _process would use. Needed here and not on the gyroid: that
## subclass overrides _process to `pass`, so nothing is ever in flight after _ready. This
## one keeps the base tick, so a config change arriving inside the ~1.7 s second-dispatch
## window would otherwise have to be dropped. rendering_device.sync() inside
## fetch_and_process_compute_data() pairs the outstanding submit(), and create_mesh()
## joins the worker thread — _ready itself calls these two back to back with no frames
## between them, which is what makes the cadence safe outside _process.
func _drain_inflight() -> void:
	if waiting_for_compute:
		fetch_and_process_compute_data()
	if waiting_for_meshthread:
		create_mesh()


## Re-run the same three calls _ready runs, in the same order.
##
## NOTHING IS FREED BY THIS SCRIPT, and it keeps no _owned array because it creates no
## nodes at all: create_mesh() rewrites array_mesh's single surface in place, and the only
## child anything here adds is the StaticBody3D the base's _create_collision() makes and
## removes itself. A blanket free of children is what cost three scripts a pass in the
## last wave — GridInteractablesComponent attaches a _RotationTimer to the artifact after
## spawn, and this scene's Label3Ds, lights and WorldEnvironment are siblings of this node
## rather than children of it.
func _regenerate() -> void:
	if use_fallback or rendering_device == null:
		return
	_drain_inflight()
	# Belt and braces: resubmitting under a dispatch that is still outstanding is the
	# crash release() documents. Unreachable after _drain_inflight, kept as the guard.
	if waiting_for_compute or waiting_for_meshthread:
		return
	run_compute()
	fetch_and_process_compute_data()
	create_mesh()
	_built_signature = _config_signature()


func _create_fallback_mesh() -> void:
	print("TerrainGeneratorOverhang: Creating fallback flat landscape...")
	_create_simple_flat_mesh()
	print("✅ Fallback landscape created")

func _create_simple_flat_mesh() -> void:
	# Simple flat plane with hills (inherited logic from original file)
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var size = chunk_scale * 0.6
	var segments = 60
	var step = size / segments

	for z in range(segments + 1):
		for x in range(segments + 1):
			var px = (x - segments / 2.0) * step
			var pz = (z - segments / 2.0) * step

			var height = sin(px * 0.02) * cos(pz * 0.02) * 10.0

			vertices.append(Vector3(px, height, pz))
			normals.append(Vector3.UP)

	for z in range(segments):
		for x in range(segments):
			var i0 = z * (segments + 1) + x
			var i1 = i0 + 1
			var i2 = (z + 1) * (segments + 1) + x
			var i3 = i2 + 1

			indices.append(i0)
			indices.append(i2)
			indices.append(i1)

			indices.append(i1)
			indices.append(i2)
			indices.append(i3)

	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_INDEX] = indices

	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	_create_collision()
