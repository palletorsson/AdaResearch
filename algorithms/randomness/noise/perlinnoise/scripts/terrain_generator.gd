extends Node3D
class_name PerlinTerrainGenerator

# @identity
# essence: mesh_vertex.y = MeshHelper.apply_noise_to_mesh(noise, time_offset) — Perlin noise applied to a subdivided plane mesh, animated by advancing time_offset on a 0.5s timer
# desire: to watch terrain breathe — to see a landscape slowly undulate in real-time and understand that time is just another axis in the noise field
# critical_parameter: readout — what the sampled field is claimed to BE (relief | plate | column); use_fade still softens the terrain edges and use_edges still pins the border, but neither is an argument, only a mask
# triggers: a 0.5s timer fires every cycle, advancing time_offset by 0.5 and regenerating the mesh — the terrain animates in visible 0.5s steps rather than frame-by-frame
# emerges: the periodic timer creates a visible rhythm to the terrain animation — an unintended clock that makes the noise feel like it breathes in beats
# needs: no VR controls [missing]; use_fade and use_edges are editor exports only; animation is automatic [has]; MeshHelper.apply_noise_to_mesh provides the coupling to noise [has]
# relationships: uses the same noise library (NoiseHelper) as other algorithms in the perlinnoise folder; simpler than noiseterrain.gd (no domain warping, no UI); perlin_noise_terrain token in registry points to this script; shares the `readout` axis word for word with [[perlin_noise]] and [[simplex_noise]]
# truth: noise-animated terrain reveals that the landscape and its future are encoded in the same function — slide time_offset and you are not changing the terrain, you are looking at a different cross-section of a 3D noise field

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-02).
#
# Two exports, use_fade and use_edges, and both of them are MASKS: they decide
# which part of the field is allowed to move. Neither asks the question this
# artifact exists to ask, which is the one its own name answers for you before
# you arrive — the thing is called perlin_noise_TERRAIN, and the moment the
# sample became an elevation the argument was over.
#
#   readout   WHAT THE SAMPLED FIELD IS CLAIMED TO BE
#
#     relief   the sample is an ELEVATION. The sheet rises and falls and you are
#              looking at a landscape. THE LEGACY LINEAGE, byte for byte — this
#              is MeshHelper.apply_noise_to_mesh writing vertex.y, untouched.
#     plate    the sample is a VALUE. The sheet lies dead flat and the number
#              survives only as colour across a mosaic of cells: an image of a
#              scalar function. The mountains were never in the noise; they were
#              in the decision to spend the number on height.
#     column   the sample is a MEASURED QUANTITY. Every cell becomes a bar
#              standing off the base plane at its own value, referenced to the
#              field's minimum the way any bar chart is. Noise before it is
#              scenery — four hundred readings on a chart, which is what the
#              generator actually produced.
#
# ONE WORD, THREE ARTIFACTS. `readout` and these three values are adopted
# verbatim from perlin_noise and simplex_noise (promoted 2026-07-29), which ask
# the identical question of a cube field. Same spelling, same order, same
# default, so the noise sequence can be COMPARED across its members instead of
# merely walked past. Where their _shape_cube moves a cube, this moves a vertex;
# the claim is the same claim.
#
# WHAT IS DELIBERATELY NOT THE AXIS. time_offset, the 0.5 s timer, and the whole
# "watch it breathe" behaviour: a rate is invisible to a still and info_board
# already proved what sweeping one buys you (six identical tiles). use_fade and
# use_edges are real and they change the shape, but "which vertices are allowed
# to move" is bookkeeping, not a claim about what the field is.
#
# NOT TOUCHED: the field. Every readout samples the SAME fnoise at the SAME
# coordinates in the same order — get_noise_3d(i*0.1, j*0.1, time_offset), the
# grid MeshHelper walks, with the same edge skip and the same fade. Only what is
# done with the returned number changes.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS — what the sampled field is claimed to be. `relief` is the legacy default.
@export_enum("relief", "plate", "column") var readout: String = "relief"

## The allow-list, same spelling and same order as the @export_enum above. An
## unreadable word keeps the legacy default rather than blanking a field six rooms
## expect to see.
const READOUTS: PackedStringArray = ["relief", "plate", "column"]

@export var use_fade: bool = false  # Toggle fade effect
@export var use_edges: bool = true

## SEED. This one was already pinned — NoiseHelper.setup_noise(1, 0.07) has always
## passed a literal 1 — but it was pinned by accident of a hard-coded argument, not
## by declaration, and nothing stopped the next edit from writing randi() there the
## way NoiseVisualizer.gd:23 does. 1 reproduces every existing placement exactly.
@export var field_seed: int = 1

## Untyped on purpose: sweep fixtures set this DIRECTLY pre-_ready with the string
## "false", and a typed bool silently rejects that assignment.
##
## true (the default, and what every existing placement gets) = today exactly: the
## 0.5 s timer keeps advancing time_offset, so the terrain is a moving cross-section
## of a 3D noise field. false = the field is sampled once at time_offset 0 and stands
## still. A sweep MUST pin this: the third noise coordinate is the clock, so two
## captures of the SAME readout taken a second apart are two different terrains, and
## the sweep would be measuring the wall clock and reporting it as an axis.
var animate = true

var time_offset = 0.0  # Time-based offset for animation
@onready var noise_plane: MeshInstance3D = $NoisePlane
## Built in _ready from field_seed. It used to be a member initialiser evaluated at
## instantiation; nothing reads it before _ready, so the object it produces is
## identical — it is simply now built from a declared value instead of a literal.
var fnoise: FastNoiseLite = null

## The pink cull-disabled material the scene ships with. `relief` keeps it; the other
## two readouts spend the sample on COLOUR and so need a vertex-colour material, and
## this is what a rebuild back to relief restores.
var _shipped_material: Material = null
## True once _ready has built once — apply_grid_config before that is a value change
## with no geometry to answer it.
var _built: bool = false
## Which readout the mesh currently in noise_plane was built for. "" means the mesh is
## still the one the SCENE shipped, which is the state the relief path must be handed
## on its very first call — restoring a fresh plane there would swap out the scene's own
## QuadMesh resource for an identical-looking copy, and "byte for byte" means the same
## bytes.
var _last_readout: String = ""

# THE SAMPLE GRID, restated because plate and column build their own geometry and must
# land on exactly the samples the relief path lands on.
#
# Godot's PlaneMesh emits subdivide + 2 vertices per side, not subdivide + 1 — its loops
# run `for (i = 0; i <= subdivide_w + 1; i++)` — so subdivide 20 is a 22 x 22 lattice of
# 21 x 21 cells with a spacing of 1/21 m, NOT 21 x 21 at 1/20. Getting this wrong by one
# would have had plate and column sampling a grid the relief sheet never visits, and the
# sweep would then be comparing three different fields and calling the difference a bite.
#
# And MeshHelper samples noise in INDEX space, not in metres:
# get_noise_3d(x_index * 0.1, y_index * 0.1, t), with x_index running 0..21.
const GRID_SUBDIV := 20
const VERTS_PER_SIDE := GRID_SUBDIV + 2     # 22 — what PlaneMesh actually builds
const CELLS_PER_SIDE := VERTS_PER_SIDE - 1  # 21 — quads between them
const SAMPLE_STEP := 0.1
const PLANE_SIZE := 1.0

func _ready() -> void:
	# The grid sets config_* metadata SYNCHRONOUSLY before add_child and calls
	# apply_grid_config call_deferred, i.e. after this — so the meta read happens here,
	# before any geometry exists.
	_read_meta_overrides()
	fnoise = NoiseHelper.setup_noise(field_seed, 0.07)
	TimerHelper.create_timer(self, 0.5, Callable(self, "_on_timer_timeout"))
	noise_plane.mesh.set_orientation(1)
	# Set subdivisions dynamically
	noise_plane.mesh. subdivide_width = GRID_SUBDIV  # Number of subdivisions along X-axis
	noise_plane.mesh.subdivide_depth = GRID_SUBDIV  # Number of subdivisions along Z-axis
	_shipped_material = noise_plane.material_override

	generate_terrain()
	_built = true



func _on_timer_timeout() -> void:
	if not _is_truthy(animate):
		return
	time_offset += 0.5
	generate_terrain()

func generate_terrain() -> void:
	# READOUT dispatch. Appended in front of the legacy call and nowhere else: the
	# default falls straight through to the same two lines it always ran.
	match readout:
		"plate":
			_build_plate()
			return
		"column":
			_build_columns()
			return
		_:
			pass                    # relief — the legacy lineage, below
	if noise_plane.material_override != _shipped_material:
		noise_plane.material_override = _shipped_material
	# A rebuild arriving from plate or column is holding a bar field, not a plane, and
	# apply_noise_to_mesh rewrites the CURRENT mesh's vertex array. First call ever
	# (_last_readout "") falls through untouched.
	if _last_readout != "" and _last_readout != "relief":
		_restore_source_plane()
	var new_mesh = MeshHelper.apply_noise_to_mesh(noise_plane, fnoise, time_offset, use_fade, use_edges)
	if new_mesh:
		noise_plane.mesh = new_mesh
	_last_readout = "relief"


# ═════════════════════════════════════════════════════════════════════════════
# THE FIELD — one sampler, shared by all three readouts
# ═════════════════════════════════════════════════════════════════════════════

## The same grid MeshHelper.apply_noise_to_mesh walks, sampled the same way, in the
## same order, with the same edge skip and the same radial fade. Returned as a flat
## Array of (GRID_SUBDIV + 1)^2 floats indexed j * n + i.
##
## Faithfulness matters more than elegance here: if plate and column sampled even
## slightly differently from relief, a sweep of this axis would be comparing three
## different fields and would report the difference between them as a bite.
func _sample_field() -> Array:
	var n: int = VERTS_PER_SIDE
	var out: Array = []
	out.resize(n * n)
	# MeshHelper's centre and max_distance, restated: grid_size = total_vertices - 1,
	# at scale 1, which is 21 — so the centre of the fade is (10.5, 0, 10.5).
	var centre := Vector3(float(CELLS_PER_SIDE) * 0.5, 0.0, float(CELLS_PER_SIDE) * 0.5)
	var max_distance: float = centre.length()
	for j in range(n):
		for i in range(n):
			var idx: int = j * n + i
			# use_edges pins the outer two rings at zero — the vertices MeshHelper
			# `continue`s over, which keeps their shipped y of 0.
			if use_edges and (i < 2 or i >= n - 2 or j < 2 or j >= n - 2):
				out[idx] = 0.0
				continue
			var fade: float = 1.0
			if use_fade:
				var local_pos := Vector3(float(i), 0.0, float(j))
				fade = maxf(1.0 - (local_pos.distance_to(centre) / max_distance), 0.0)
			out[idx] = fnoise.get_noise_3d(
				float(i) * SAMPLE_STEP, float(j) * SAMPLE_STEP, time_offset) * fade
	return out


## The family's height ramp, blue at the low end and amber at the high — the same two
## colours NoiseVisualizer lerps between, so a plate here and a cube field there are
## reading the same number in the same language.
func _ramp(t: float) -> Color:
	return Color(0.2, 0.4, 0.8).lerp(Color(0.8, 0.6, 0.2), clampf(t, 0.0, 1.0))


func _field_span(values: Array) -> Vector2:
	var lo: float = 1e20
	var hi: float = -1e20
	for v in values:
		var f: float = float(v)
		lo = minf(lo, f)
		hi = maxf(hi, f)
	if hi - lo < 0.0001:
		hi = lo + 0.0001
	return Vector2(lo, hi)


## A material that spends the sample on colour instead of on height. cull_mode stays
## DISABLED to match the pink material the scene ships with, so a plate is visible from
## underneath exactly as the relief sheet is.
func _vertex_colour_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(1, 1, 1)
	m.roughness = 0.85
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## PLATE — the field lying flat, every cell painted with its own value. One quad per
## cell of the sampling grid, four hundred of them across a 1 m square, so the mosaic
## is legible at sweep resolution and the sheet's silhouette is a plain rectangle: the
## undulation that made it a landscape is simply gone.
func _build_plate() -> void:
	var values: Array = _sample_field()
	var n: int = VERTS_PER_SIDE
	var span: Vector2 = _field_span(values)
	var step: float = PLANE_SIZE / float(CELLS_PER_SIDE)
	var half: float = PLANE_SIZE * 0.5

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3(0, 1, 0))
	for j in range(CELLS_PER_SIDE):
		for i in range(CELLS_PER_SIDE):
			var t: float = (float(values[j * n + i]) - span.x) / (span.y - span.x)
			var c: Color = _ramp(t)
			var x0: float = -half + float(i) * step
			var z0: float = -half + float(j) * step
			var x1: float = x0 + step
			var z1: float = z0 + step
			var a := Vector3(x0, 0.0, z0)
			var b := Vector3(x1, 0.0, z0)
			var d := Vector3(x1, 0.0, z1)
			var e := Vector3(x0, 0.0, z1)
			for p in [a, b, d, a, d, e]:
				st.set_color(c)
				st.set_uv(Vector2(0, 0))
				st.add_vertex(p as Vector3)
	noise_plane.mesh = st.commit()
	noise_plane.material_override = _vertex_colour_material()
	_last_readout = "plate"


## COLUMN — every sample standing up as its own bar, referenced to the field's minimum
## the way a bar chart is referenced to its baseline. Four hundred readings, separated
## by a visible gap, which is what the generator actually handed over before anybody
## decided it was scenery.
##
## The bars grow along LOCAL −Y. The NoisePlane node ships with a 180° flip about Z
## (see the .tscn transform), so local −Y is world UP: a bar chart hanging from the
## ceiling would be a fact about that flip and not about the field. relief is symmetric
## about zero and so is unaffected either way, which is why this only comes up here.
func _build_columns() -> void:
	var values: Array = _sample_field()
	var n: int = VERTS_PER_SIDE
	var span: Vector2 = _field_span(values)
	var step: float = PLANE_SIZE / float(CELLS_PER_SIDE)
	var half: float = PLANE_SIZE * 0.5
	var w: float = step * 0.78          # the gap between bars is the whole point
	var floor_h: float = 0.006

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(CELLS_PER_SIDE):
		for i in range(CELLS_PER_SIDE):
			var value: float = float(values[j * n + i])
			var t: float = (value - span.x) / (span.y - span.x)
			var h: float = floor_h + (value - span.x)
			var cx: float = -half + (float(i) + 0.5) * step
			var cz: float = -half + (float(j) + 0.5) * step
			_add_bar(st, Vector3(cx, -h * 0.5, cz), Vector3(w, h, w), _ramp(t))
	noise_plane.mesh = st.commit()
	noise_plane.material_override = _vertex_colour_material()
	_last_readout = "column"


## One axis-aligned box into an open SurfaceTool. Written out rather than composed from
## BoxMesh instances because four hundred MeshInstance3D children would be four hundred
## nodes the grid's auto-grounding and label framing would then have to walk.
func _add_bar(st: SurfaceTool, centre: Vector3, size: Vector3, c: Color) -> void:
	var h: Vector3 = size * 0.5
	var faces: Array = [
		[Vector3(-1, 0, 0), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z)],
		[Vector3(1, 0, 0), Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z)],
		[Vector3(0, -1, 0), Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z)],
		[Vector3(0, 1, 0), Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z)],
		[Vector3(0, 0, -1), Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z)],
		[Vector3(0, 0, 1), Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)],
	]
	for f in faces:
		st.set_normal(f[0] as Vector3)
		for k in [1, 2, 3, 1, 3, 4]:
			st.set_color(c)
			st.set_uv(Vector2(0, 0))
			st.add_vertex(centre + (f[k] as Vector3))


## Put a fresh subdivided quad back under the relief path. MeshHelper.apply_noise_to_mesh
## reads the CURRENT mesh and rewrites its vertex array, so a rebuild from plate or
## column — where the mesh is a bar field — has to be handed a plane again first.
func _restore_source_plane() -> void:
	var qm := PlaneMesh.new()
	qm.size = Vector2(PLANE_SIZE, PLANE_SIZE)
	qm.set_orientation(1)
	qm.subdivide_width = GRID_SUBDIV
	qm.subdivide_depth = GRID_SUBDIV
	noise_plane.mesh = qm


# ═════════════════════════════════════════════════════════════════════════════
# DNA plumbing
# ═════════════════════════════════════════════════════════════════════════════

## Accepts a real bool, an int, or the strings a map token and a sweep fixture carry.
func _is_truthy(v) -> bool:
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]


func _read_meta_overrides() -> void:
	if has_meta("config_readout"):
		var v: String = str(get_meta("config_readout")).strip_edges().to_lower()
		if READOUTS.has(v):
			readout = v
		elif v != "":
			push_warning("perlin_noise_terrain: unknown readout '%s' — keeping '%s'"
				% [v, readout])
	if has_meta("config_field_seed"):
		field_seed = int(str(get_meta("config_field_seed")))
	if has_meta("config_use_fade"):
		use_fade = _is_truthy(get_meta("config_use_fade"))
	if has_meta("config_use_edges"):
		use_edges = _is_truthy(get_meta("config_use_edges"))
	if has_meta("config_animate"):
		animate = _is_truthy(get_meta("config_animate"))


## LATENT BUG PAID (2026-08-02): this was `pass`. Every `#token: value` a map put on a
## perlin_noise_terrain placement was parsed, logged by GridInteractablesComponent and
## stashed as metadata, then silently dropped, because nothing here ever read it back.
##
## Guarded like prng_crank_machine's: an unchanged readout touches nothing and says
## nothing, so curation_station's blanket apply_grid_config({"emissive": false}) cannot
## trigger a rebuild.
func apply_grid_config(config: Dictionary) -> void:
	var before: String = readout
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return                      # nothing built yet; _ready will use these values
	if readout == before:
		return
	generate_terrain()
	print("[PerlinTerrainGenerator] Config applied — readout=%s" % [readout])
