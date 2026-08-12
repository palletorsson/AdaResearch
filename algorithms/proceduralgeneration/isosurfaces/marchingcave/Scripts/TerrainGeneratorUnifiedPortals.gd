extends TerrainGeneratorBase

# --- DNA (stage 2, wave 2, promoted 2026-08-12) ------------------------------
# THE CLAIM THIS ARTIFACT MAKES, and the one line that makes it. The scene's own Label3D
# says "UNIFIED MARCHING CUBES TOPOLOGY / Terrain and portals are ONE seamless mesh!", and
# MarchingCubesPortalTerrain.glsl:240 is where that is argued:
#
#     float density = max(terrainDensity, -portalsDensity);
#
# a CSG union of a heightfield with seven torus SDFs, extracted as one surface. This is the
# only artifact in the wave where the boundary is something you could pass THROUGH, so the
# axes are both about the same question — whether the doors are doors — arriving from two
# directions.
#
# burial — WHERE THE RING SITS RELATIVE TO THE GROUND IT IS MADE OF. Because the operator
#   is a UNION, a buried torus does not merely look half-sunk: its hole is filled by the
#   terrain, so the passage closes. The axis is therefore over the GENUS of the extracted
#   surface, argued by moving one number.
#     straddling  SHIPPED. Returns portal_emergence_height untouched — the .tscn's 0.0.
#                 The rings sit on the surface, the holes half open.
#     sunken      -60.0. Crowns break a surface that itself undulates over +/-20 m: stone
#                 hoops rising out of rock, all one substance, no way through.
#     standing    +60.0. The ring clears the hilltops and the tube still meets the ground at
#                 its feet — one connected mesh, seven doorways.
#     floating    +140.0. The bottom of each ring is ~65 m clear of the highest ground, the
#                 union has EIGHT disconnected components, and the artifact's own claim
#                 about ONE seamless mesh is visibly false. The artifact argues itself
#                 false at one rung, which is what an axis is for.
#
# num_portals — HOW MANY DOORS BEFORE A COLONNADE IS A WALL. The shader at :212 computes
#   angleStep = TAU / numPortals and rings the portals around a fixed circle of radius
#   portal_spacing = 250, so the count does not change the arrangement's SIZE, only its
#   density. 1 is a single arch (the union has two components); 3 is a triangle of doorways
#   you can see between; 7 is shipped; 16 puts them 98 m apart on a 1571 m circumference
#   while each is 110 m wide, so they overlap into a continuous ring wall and the passages
#   close by CROWDING rather than by burial. Same question as burial, other direction, which
#   is why the two are declared together. Shape borrowed from raymarched_metaballs'
#   metaball_count [1, 3, 5, 9] in this same sequence — a count axis over a field built by
#   unioning N primitives. If they measure alike the family is honest.
#
# NO SHADER EDIT, and this is the one artifact in the wave immune to the stale-compiled-
# shader trap. MarchingCubesPortalTerrain.glsl already declares all sixteen ParamsBuffer
# fields (the shared eleven at :107-117 plus numPortals, portalSpacing, portalRadius,
# portalMinorRadius, portalEmergenceHeight at :119-123) and get_params_array() already
# appended those five in that order. Both axes write exports that ALREADY fed this array,
# so field order and count are unchanged on both sides, no .glsl file is touched, and a
# headless run cannot publish a stale-shader verdict on this token.
#
# WHAT IS DECLINED. `portal_radius` (40.0) and `portal_minor_radius` (15.0): real exports,
# already in ParamsBuffer, and refused because the minor radius is ALREADY one sampling
# cell (chunk_scale 1000 / num_voxels_per_axis 64 = 15.6 m), so shrinking it deletes the
# portals into the lattice and growing it is the same fattening burial gets for free. An
# axis whose low rung is indistinguishable from a bug is not an axis. `portal_spacing`
# (250.0): the radius of the arrangement, which is extent, and extent self-cancels under a
# fitted camera — with the twist that here it would also change the union AABB and so the
# framing of every tile. The CSG OPERATOR at :233 and :240 — swapping max for min turns
# union into intersection and would say something enormous about what a field operator is —
# refused because `algebra` is spent on csg_compose_workbench and `fusion` on csg_union_demo,
# implicit_surface_modeling, metaballs and raymarched_metaballs, and because an intersection
# of a heightfield with seven toruses is mostly empty, which routes to the portal-less
# fallback plane below. It belongs to a CSG artifact. iso_level, chunk_scale,
# center_position, continuous_update and invert_faces are refused for the reasons given on
# the other landscapes in this wave.
#
# STILL-VISIBLE: no _process override on this subclass and none needed — evaluate() never
# reads params.time (the field is declared in the shared prefix and never referenced in
# this shader), there is no RNG and no seed, and the snoise is the Ashima/stegu simplex
# function, a pure function of position. Four runs of one rung are the same mesh.

## Emergence height per rung. `straddling` is DELIBERATELY ABSENT: it is handled by the
## short-circuit in _emergence_height(), which hands back the export itself rather than a
## table entry. This is the only scene in the folder that OVERRIDES an export an axis
## touches (marchingcubes_portal_landscape.tscn sets portal_emergence_height = 0.0 against
## a script default of -20.0), so a table whose default entry read -20.0 would have silently
## moved the one placed scene by 20 m and looked correct in every review.
const BURIAL_HEIGHTS: Dictionary = {
	"sunken": -60.0,
	"standing": 60.0,
	"floating": 140.0,
}

const BURIALS: PackedStringArray = ["straddling", "sunken", "standing", "floating"]

## Guard, not an axis bound. numPortals is a loop bound inside evaluate(), which runs
## 262,144 times per dispatch; a map token typing 500 would ask the GPU for 130M torus SDFs
## and hang the capture. 7 and 16 both clamp to themselves, so no declared rung is affected.
const MAX_PORTALS: int = 32

# Portal settings
@export_range(1, 32) var num_portals : int = 7
@export var portal_spacing : float = 250.0
@export var portal_radius : float = 40.0
@export var portal_minor_radius : float = 15.0
@export var portal_emergence_height : float = -20.0

@export_category("Portal DNA")
@export_enum("straddling", "sunken", "standing", "floating") var burial: String = "straddling"

## Signature of everything the build reads, captured after the last successful generation.
## Empty until _ready has run, which is what tells apply_grid_config there is nothing yet
## to rebuild.
var _built_signature: String = ""


func get_class_name() -> String:
	return "TerrainGeneratorUnifiedPortals"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingCubesPortalTerrain.glsl"


## Config is stamped as metadata BEFORE the node enters the tree (GridInteractablesComponent
## ._apply_artifact_config runs at line 1195, add_child at 1220), so reading it here means
## _ready builds with the right values the first time and the deferred apply_grid_config
## that follows finds nothing to do.
func _ready() -> void:
	_read_metadata_overrides()
	super._ready()
	_built_signature = _config_signature()


## The five portal floats appended to the base's eleven. INDEX COMMENTS ARE LOAD-BEARING:
## they name the ParamsBuffer field each float lands in, in MarchingCubesPortalTerrain.glsl.
## A silent offset here shifts every float and is not a compile error.
func get_params_array() -> Array:
	var params = super.get_params_array()
	# Portal params
	params.append(float(_portal_count()))   # 11 numPortals            — export default 7
	params.append(portal_spacing)           # 12 portalSpacing         — 250.0
	params.append(portal_radius)            # 13 portalRadius          — 40.0
	params.append(portal_minor_radius)      # 14 portalMinorRadius     — 15.0
	params.append(_emergence_height())      # 15 portalEmergenceHeight — the export: .tscn 0.0, script -20.0
	return params


## THE DEFAULT IS A SHORT-CIRCUIT, NOT A TABLE LOOKUP. At `straddling` the exported float is
## returned untouched, so the .tscn's override of 0.0 and the script's own default of -20.0
## are BOTH preserved bit for bit and no rung value has to be written that happens to equal
## the shipped one. An unknown string falls back the same way rather than to a table entry.
func _emergence_height() -> float:
	if burial == "straddling":
		return portal_emergence_height
	if BURIAL_HEIGHTS.has(burial):
		return float(BURIAL_HEIGHTS[burial])
	return portal_emergence_height


## num_portals needs no mechanism: the axis IS the export and 7 is the export's default, so
## the sweep simply does not set it at the default rung. clampi(7, 1, 32) is 7.
func _portal_count() -> int:
	return clampi(num_portals, 1, MAX_PORTALS)


## The shader's own input, stringified — if a value reaches the GPU it is in here, so the
## guard cannot drift out of step with what the build actually reads.
##
## INDEX 0 IS SKIPPED, and the reason is a real difference from TerrainGeneratorGyroid,
## which stringifies all eleven. `time` is the first of the base's shared prefix, and this
## subclass does NOT override _process — the base's tick keeps advancing it for ~100 frames
## after spawn, until create_mesh sets _initial_generation_done and calls set_process(false).
## Including it would make the signature a CLOCK and every apply_grid_config call would read
## as a change. It cannot affect the mesh: MarchingCubesPortalTerrain.glsl declares
## `float time;` at :107 as part of the shared prefix and never references params.time
## anywhere in the file.
func _config_signature() -> String:
	var vals: Array = get_params_array()
	var out: String = ""
	for i in range(1, vals.size()):
		out += "%.6f|" % float(vals[i])
	return out


func _read_metadata_overrides() -> void:
	if has_meta("config_burial"):
		var b: String = str(get_meta("config_burial")).strip_edges().to_lower()
		if BURIALS.has(b):
			burial = b
	if has_meta("config_num_portals"):
		var n: int = int(get_meta("config_num_portals"))
		if n > 0:
			num_portals = clampi(n, 1, MAX_PORTALS)


## Guarded. The old body was a bare `pass` — a method that existed only so the grid's
## has_method() check would find it. It now rebuilds when, and only when, a value the shader
## reads has actually changed. NONE of the 3 map placements passes a config key and the
## registry entry declares no default_params, so merged_config is empty, the grid's
## `if not merged_config.is_empty()` gate means _apply_artifact_config is never called at
## all, and zero of three reach the regenerate branch.
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


## Re-run the same three calls _ready runs, in the same order. NOTHING IS FREED BY THIS
## SCRIPT and it owns no nodes: create_mesh() rewrites array_mesh's single surface in place
## and the base's _create_collision() removes only the StaticBody3D it created itself. A
## blanket free of children is what cost three scripts a pass in the last wave —
## GridInteractablesComponent attaches a _RotationTimer to the artifact after spawn, and the
## base's own TerrainCollision body is the only child either script owns.
func _regenerate() -> void:
	if use_fallback or rendering_device == null:
		return
	# A dispatch already in flight: resubmitting under it is the crash release() documents.
	# Reachable here in a way it is not on TerrainGeneratorGyroid, because this subclass
	# keeps the base's _process and so is still cycling for ~100 frames after _ready.
	if waiting_for_compute or waiting_for_meshthread:
		return
	run_compute()
	fetch_and_process_compute_data()
	create_mesh()
	_built_signature = _config_signature()


func _create_fallback_mesh() -> void:
	print("TerrainGeneratorUnifiedPortals: Creating fallback combined mesh (terrain + simple toruses)...")
	# For now, just create terrain - proper fallback would need CSG.
	# NOTE FOR THE SWEEP: this plane has NO PORTALS IN IT. If the capture host cannot build
	# a local rendering device, every tile is this plane and both axes measure zero. The run
	# is only valid if the log shows "Generation complete!" and NOT "Creating fallback".
	_create_simple_terrain()
	print("✅ Fallback mesh created")

func _create_simple_terrain() -> void:
	# Simple flat plane
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
