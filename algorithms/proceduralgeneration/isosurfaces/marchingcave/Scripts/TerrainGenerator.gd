extends TerrainGeneratorBase

# --- DNA (stage 2, promoted 2026-08-12) -------------------------------------
# ONE SCRIPT, THREE SCENES, AND THE TWO THAT MATTER STAND ON OPPOSITE SIDES OF THE SURFACE.
# TerrainGenerator.gd is loaded by marchingcubes_cave.tscn (tokens mc_cave,
# marchingcubes_cave), marchingcubes_inside_cave.tscn (mc_inside_cave,
# marchingcubes_inside_cave) and marchingcubes.tscn (mc_base, marchingcave) — all three by
# the same script uid, c2aji3u2bgmv8. That is a hidden family at SCRIPT level rather than
# at scene level, which is the first one this corpus has found; the five known before it
# (curation_station's booleans, the grab spheres, the pickup cubes, the synth racks, the
# translation cubes) all hide one level lower, at the scene.
#
# The two cave scenes are the same field at two settings:
#
#                                noise_scale  chunk_scale  iso_level  sample step  octave 0
#   marchingcubes_cave.tscn            13.5          300       0.85      4.69 m      ~22 m
#   marchingcubes_inside_cave.tscn      3.8          280       0.88      4.375 m     ~74 m
#
# evaluate() computes samplePos = (worldPos + noise_offset) * noise_scale / chunk_scale, so
# the inside scene samples the noise at 0.01357 per metre against 0.045 and its first
# octave is 3.4x larger. Its voids are chambers a body fits inside rather than fissures a
# body does not — that, plus a Camera3D at (0, 5, 15) INSIDE the field with an OmniLight3D
# torch parented to it and no DirectionalLight3D anywhere in the scene, is the actual
# reason one of these reads as an interior and the other as a block of rock.
#
# THE THIRD SCENE IS NOT PART OF THIS. marchingcubes.tscn sets use_fallback = true, so
# TerrainGeneratorBase._ready returns at its line 65, MarchingCubes.glsl is never loaded,
# and what renders is _create_simple_cave_mesh()'s hand-written 200 m sine tunnel below.
# Both axes are inert there BY CONSTRUCTION, so mc_base and marchingcave must NOT be
# declared: four tiles of that tunnel would be four identical pictures and a 0.00% verdict
# about the wrong artifact.
#
# plumb — WHICH WAY IS DOWN, AND WHETHER THERE IS A DOWN AT ALL. Everything this shader
#   knows about gravity is one term: `density = -(worldPos.y+100)/300 + density`, a linear
#   vertical bias added to an otherwise isotropic ridged-noise sum. plumbScale multiplies
#   that term and nothing else.
#     bedded      SHIPPED, 1.0. The floor you stand on.
#     overturned  -1.0. The bias inverts — rock overhead, the ground opening.
#     weightless   0.0. The term is gone and the sponge is isotropic. The SAME field
#                  mc_cave shows from outside becomes, from inside, a place with no down
#                  and no up; this is the only artifact in the corpus where that
#                  difference is walkable.
#     steep        3.0. The gradient triples, the band in which the field crosses the
#                  threshold compresses, and the chamber presses into a crawl space.
#   The four values are held IDENTICAL to mc_cave's deliberately: it is one const on one
#   script, and holding them identical is what makes the two galleries comparable frame
#   for frame.
#
# octaves — HOW MANY SCALES OF ROCK SURVIVE THE LATTICE. The ridged loop runs a fixed six
#   times. Octave k has features about (octave 0) / 2^k, and the marching grid samples at
#   chunk_scale / 64. Inside: step 4.375 m, so the Nyquist limit of 8.75 m falls between
#   octave 3 (9.2 m, resolvable) and octave 4 (4.6 m, not). On mc_cave: step 4.69 m with
#   octave 0 at ~22 m, so its limit falls between octave 1 (11 m) and octave 2 (5.5 m).
#   Standing inside you can see three or four scales of rock; looking at the block from
#   outside you can see two. Same shader, same rungs, same threshold — the difference is
#   entirely the ratio between the field's own scale and the lattice that samples it,
#   which is this sequence's whole quarrel put as a ratio.
#
#   CONFOUND, STATED RATHER THAN HIDDEN: rung 1 both smooths the walls and removes up to
#   ~0.22 from the ridged sum, which against a 1/300 gradient raises the horizon by up to
#   ~66 m. The two effects are inseparable in a still.
#
# DECLINED. `iso_level` — 0.88 here against 0.85 on the sibling is the one number that
# already separates the two scenes, and it is the most tempting axis in the wave. Refused
# because on a field carrying a vertical gradient a constant threshold offset IS a horizon
# translation, so it would be arguing with plumb for the same pixels. `invert_faces`
# (TerrainGeneratorBase:10) is refused with discomfort rather than cleanly: it is
# documented there as being for "caves viewed from inside vs objects viewed from outside",
# TerrainMat.tres renders cull_back, this scene's camera sits inside the field with a torch
# on it — and the flag is not set on either cave. Two values is below the axis floor and a
# winding order is not a field property, so it is declined as an axis and reported as a
# defect instead. Also refused: the weight-gating literal at MarchingCubes.glsl:174 (it
# conflates connectivity with detail), `noise_offset` (a different arbitrary sample of the
# same field, and already fixed by the .tscn), `chunk_scale` and `center_position` (a size
# and a placement, both self-cancelling under an AABB-fitted camera), `continuous_update`
# (a rate, invisible in a still by law).
#
# BOTH AXES REACH THE GPU the way TerrainGeneratorShapes already reaches it for shapeId:
# get_params_array() calls super and appends trailing floats, and MarchingCubes.glsl's
# ParamsBuffer gains matching trailing fields IN THE SAME ORDER — plumbScale at index 11,
# octaves at index 12. The shared eleven-field prefix every other Marching*.glsl reads is
# untouched. MarchingCubes.glsl is loaded by this script and by nothing else.


## Multiplier on the vertical gradient term. `bedded` is 1.0, and the shader
## SHORT-CIRCUITS on exactly that value rather than multiplying by it, so the shipped path
## executes the same two operations the file always compiled. Nothing on the default path
## is derived, scaled or recomputed.
const PLUMB_SCALES: Dictionary = {
	"bedded": 1.0,
	"overturned": -1.0,
	"weightless": 0.0,
	"steep": 3.0,
}

const PLUMBS: PackedStringArray = ["bedded", "overturned", "weightless", "steep"]

@export_category("Cave DNA")
@export_enum("bedded", "overturned", "weightless", "steep") var plumb: String = "bedded"
## Octaves of the ridged sum. Was the literal 6 in MarchingCubes.glsl's loop bound; 6 is
## still the default and `i < int(6.0)` is the same integer comparison that was there.
@export_range(1, 6) var octaves: int = 6  # 1 | 2 | 3 | 6

## Signature of everything the build reads, captured after the last successful generation.
## Empty until _ready has run, which is what tells apply_grid_config there is nothing yet
## to rebuild.
var _built_signature: String = ""

## Nodes THIS script created and may therefore free. It is empty and stays empty: the
## rebuild path frees nothing of its own, because create_mesh() rewrites array_mesh's
## single surface in place and the base's _create_collision() removes only the
## StaticBody3D it created itself. The array is kept so the invariant is stated rather
## than assumed — a blanket free of children is what cost three scripts a pass in the last
## wave, and it would be worse here, because GridInteractablesComponent attaches a
## _RotationTimer to the artifact after spawn.
var _owned: Array[Node] = []


func get_class_name() -> String:
	return "TerrainGenerator"

func get_compute_shader_path() -> String:
	return "res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Compute/MarchingCubes.glsl"


## Config is stamped as metadata BEFORE the node enters the tree
## (GridInteractablesComponent._apply_artifact_config runs at line 1195, add_child at
## 1220), so reading it here means _ready builds with the right values the first time and
## the deferred apply_grid_config that follows finds nothing to do.
func _ready() -> void:
	_read_metadata_overrides()
	super._ready()
	_built_signature = _config_signature()


## The two floats appended to the base's eleven, matching the trailing fields added to
## ParamsBuffer in MarchingCubes.glsl. ORDER IS THE CONTRACT: plumbScale then octaves, the
## same order the shader declares them. A mismatch here is not a compile error — it
## silently shifts every float.
func get_params_array():
	var params = super.get_params_array()
	params.append(_plumb_scale())                 # plumbScale — was the implicit 1.0 on the
	                                              #   y-gradient at MarchingCubes.glsl:180
	params.append(float(clampi(octaves, 1, 6)))   # octaves    — was the literal 6 at :168
	return params


func _plumb_scale() -> float:
	if PLUMB_SCALES.has(plumb):
		return float(PLUMB_SCALES[plumb])
	return 1.0


## The shader's own input, stringified, MINUS `time`.
##
## Gyroid builds this signature from the whole of get_params_array() and can, because it
## overrides _process to `pass` and its `time` is permanently 0.0. This subclass does NOT
## override _process — the base's tick keeps running for about 102 frames after _ready and
## increments `time` every one of them — so including index 0 would make the guard a clock
## and rebuild the mesh on the first config call for no reason. Dropping it is safe and
## checked, not assumed: MarchingCubes.glsl declares `float time` in ParamsBuffer and
## references it nowhere. Every other value that reaches the GPU is in here, so the guard
## still cannot drift out of step with what the build actually reads.
func _config_signature() -> String:
	var vals: Array = get_params_array()
	var out: String = ""
	for i in range(1, vals.size()):
		out += "%.6f|" % float(vals[i])
	return out


func _read_metadata_overrides() -> void:
	if has_meta("config_plumb"):
		var p: String = str(get_meta("config_plumb")).strip_edges().to_lower()
		if PLUMBS.has(p):
			plumb = p
	if has_meta("config_octaves"):
		# int("bedded") is 0 in GDScript, so a nonsense value fails the range test rather
		# than silently emptying the loop.
		var o: int = int(get_meta("config_octaves"))
		if o >= 1 and o <= 6:
			octaves = o


func _create_fallback_mesh() -> void:
	print("TerrainGenerator: Creating fallback rainbow cave...")
	_create_simple_cave_mesh()
	print("✅ Fallback rainbow cave created")

func _create_simple_cave_mesh() -> void:
	# Create a simple tunnel/cave mesh as fallback
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	# Create a long, winding organic cave tunnel
	var base_radius = 12.0
	var length = 200.0  # Much longer!
	var segments = 40   # More detail
	var rings = 100     # Many more sections

	# Generate vertices for organic tunnel
	for ring in range(rings + 1):
		var progress = float(ring) / rings
		var z = (progress - 0.5) * length

		# Cave path curves and winds through space
		var path_curve_x = sin(progress * PI * 4.0) * 30.0  # S-curves
		var path_curve_y = cos(progress * PI * 6.0) * 20.0  # Vertical waves

		# Radius varies along the tunnel (wider and narrower sections)
		var radius_variation = 0.7 + 0.6 * sin(progress * PI * 8.0)
		var current_radius = base_radius * radius_variation

		for seg in range(segments):
			var angle = float(seg) / segments * TAU
			var base_x = cos(angle) * current_radius
			var base_y = sin(angle) * current_radius

			# Multiple layers of organic noise
			var noise1 = sin(z * 0.02 + angle * 4.0) * 0.3      # Large bumps
			var noise2 = sin(z * 0.08 + angle * 12.0) * 0.15    # Medium details
			var noise3 = sin(z * 0.2 + angle * 8.0) * 0.08      # Fine texture
			var noise4 = cos(z * 0.15 + angle * 6.0 + PI) * 0.12 # Asymmetric variations

			# Combine all noise layers
			var total_noise = 1.0 + noise1 + noise2 + noise3 + noise4

			# Add some chaos for more organic feeling
			var chaos_x = sin(z * 0.03 + angle * 7.0 + progress * 10.0) * 2.0
			var chaos_y = cos(z * 0.04 + angle * 5.0 + progress * 8.0) * 1.5

			# Final position with path curves and noise
			var final_x = (base_x * total_noise) + path_curve_x + chaos_x
			var final_y = (base_y * total_noise) + path_curve_y + chaos_y

			vertices.append(Vector3(final_x, final_y, z))

			# Calculate normal for proper lighting (pointing inward for cave feel)
			var normal_dir = Vector3(final_x - path_curve_x, final_y - path_curve_y, 0).normalized()
			normals.append(-normal_dir)  # Inward-facing normals

			# UV mapping with some distortion for interesting texture flow
			var u = float(seg) / segments
			var v = progress + sin(progress * PI * 4.0) * 0.1  # Flowing UV
			uvs.append(Vector2(u, v))

	# Generate indices for triangles (double-sided)
	for ring in range(rings):
		for seg in range(segments):
			var current = ring * segments + seg
			var next = ring * segments + (seg + 1) % segments
			var next_ring_current = (ring + 1) * segments + seg
			var next_ring_next = (ring + 1) * segments + (seg + 1) % segments

			# Two triangles per quad (front faces)
			indices.append(current)
			indices.append(next_ring_current)
			indices.append(next)

			indices.append(next)
			indices.append(next_ring_current)
			indices.append(next_ring_next)

			# Two triangles per quad (back faces - reversed winding)
			indices.append(current)
			indices.append(next)
			indices.append(next_ring_current)

			indices.append(next)
			indices.append(next_ring_next)
			indices.append(next_ring_next)

	# Create the mesh
	var mesh_arrays = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX] = indices

	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

	print("✅ Created double-sided cave tunnel with ", vertices.size(), " vertices, ", indices.size() / 3, " triangles")
	_create_collision()


## Guarded. The old body was a bare `pass` — a method that existed only so the grid's
## has_method() check would find it. It now rebuilds when, and only when, a value the
## SHADER reads has actually changed. None of the four map placements of these two tokens
## passes a config key at all, and neither registry entry declares default_params, so
## merged_config is empty for every one of them and this method is never reached from a
## map today.
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
	# Reachable on THIS subclass in a way it is not on the gyroid, because _process is not
	# overridden here and the base keeps cycling for ~102 frames after _ready — so the
	# guard is load-bearing rather than defensive.
	if waiting_for_compute or waiting_for_meshthread:
		return
	for n in _owned:
		if is_instance_valid(n):
			n.queue_free()
	_owned.clear()
	run_compute()
	fetch_and_process_compute_data()
	create_mesh()
	_built_signature = _config_signature()
