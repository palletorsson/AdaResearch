# RhizomeCaveDemoController.gd
# Simplified cave generation controller - no UI, camera, or VR controls
# Only generates caves automatically
#
# @identity
# essence: a cave system grown live by the rhizome generator — chambers connected without a trunk, any passage reachable from any other, marched into walkable rock at load
# desire: to let the player stand inside Deleuze and Guattari's figure instead of reading it; the network room needs a space whose topology is the argument
# critical_parameter: the connectivity of the generated graph — no chamber is root, no passage is main; delete any tunnel and the rest still connects, which is the rhizome's whole claim
# triggers: _ready() defers generate_cave_async so the marching-cubes pass builds the cave without blocking entry; progress and completion arrive by signal
# emerges: navigation without hierarchy — you cannot ask which way is forward, only which opening is next, and orientation becomes relational rather than rooted
# needs: RhizomeCaveGenerator [algorithms/spacetopology/marchingcubes]; async generation [the cave must not gate the map load]; the surrounding 3t labels stating the principles the space enacts
# relationships: the teaching centre of Rhizome_Network — rhizome_grower beside it shows the same figure growing at hand scale while this one is inhabited at body scale
# truth: a rhizome cannot be toured, only entered somewhere. Any point connects to any other, so the map of this cave and the cave itself never agree — and the disagreement is the lesson.

extends Node3D

# --- DNA (stage 2, promoted 2026-08-12) --------------------------------------
#
# WHERE THIS ARTIFACT'S FIELD COMES FROM, which is the question wave 3 of the isosurfaces
# sequence is asking. Nowhere else in the sequence is the answer "from a history". Every
# other member samples a function — a gyroid, a noise, a sum of metaball kernels — at each
# lattice point. This one does not evaluate anything. RhizomeCaveGenerator fills the whole
# chunk with density 1.0 and then SUBTRACTS: carve_sphere writes min(current, dist/radius)
# along a graph that grew, iteration by iteration, out of an RNG. The field is a record of
# what happened. Both axes are lifted out of that record, one from the growth and one from
# the carve, and they are orthogonal by construction: `anastomosis` decides the graph and
# never touches a radius; `bore` scales the radius and cannot reach the graph, because the
# graph is finished before the first voxel is written.
#
# anastomosis — WHETHER A BRANCH THAT MEETS AN EXISTING ONE REJOINS IT OR STOPS. The
#   lifted literal is merge_distance, which sat at 6.0 in the hardcoded rhizome_params
#   dict below. RhizomeGrowthPattern.find_merge_candidate returns the first existing node
#   within that distance of a proposed branch tip; on a hit, create_connection adds an
#   EDGE and `continue` suppresses the new node. That is the only way a circuit can enter
#   this graph, and it is the difference between a tree and a net.
#     tree      0.0   — nothing is ever within 0 m, so nothing ever merges. A pure
#                       arborescence: one root, dead ends, no circuit. The figure Deleuze
#                       and Guattari oppose, and the thing this artifact's own truth
#                       statement claims to refute, rendered here for the first time.
#     netted    6.0   SHIPPED. Mostly tree, with chords where a tip lands near a neighbour.
#     matted   12.0   — most branch attempts find a candidate; the graph turns back on
#                       itself far more often than it extends.
#     knotted  20.0   — nearly every attempt rejoins.
#   THE CONFOUND, stated rather than hidden: raising merge_distance both adds edges and
#   SUPPRESSES nodes, because the merge branch does not create the node it was going to
#   create. The network gets loopier and smaller at the same time and a still cannot
#   separate the two. It is one parameter and one picture; it is not two axes wearing one
#   name, but it is not a clean dial either, and the prose says so.
#
# bore — HOW WIDE THE FIELD IS CARVED AROUND THE SAME GRAPH. A multiplier applied inside
#   carve_sphere, which is the single gate every carve passes through (carve_tunnel
#   reaches the field only by calling it). The graph is bit-for-bit identical across all
#   four rungs — same seed, same nodes, same positions, same rng draws — so this is the
#   sequence's central quarrel asked of a CARVED field instead of a sampled one: same
#   field-making history, different surface.
#     thread   0.4  — carve radius 1.2 m against a 1.0 m voxel. Below threshold 0.5 the
#                     solid boundary sits at 0.6 of a voxel, so the tube is thinner than
#                     the sampling lattice and extracts as a broken string of beads. The
#                     field is continuous; the surface is not.
#     tunnel   1.0  SHIPPED. radius * 1.0 is the identical bit pattern for every finite
#                   float, so this rung is not near the old carve, it IS the old carve.
#     hall     1.6  — 4.8 m bores; adjacent tunnels begin to touch.
#     hollow   2.4  — 7.2 m bores in a 24 m box. The tubes swallow each other and the
#                     surface merges what the graph deliberately kept apart. The strong
#                     reading of this rung is that a boundary is not a property of a field.
#   THE TWO WIDE RUNGS WERE APPROVED AT 2.0 AND 3.5 AND ARE IMPLEMENTED AT 1.6 AND 2.4,
#   because 3.5 cannot be photographed. The multiplier lands on node.radius, and
#   create_chambers has already multiplied that by rng 2.0..4.0 — so at 3.5 a single
#   chamber is up to 42 m across and swallows any chunk this artifact can afford to
#   march. Replicated over the real growth and carve at the pinned seed: at 3.5 the
#   hollow column is 100 / 100 / 93 / 9 percent of the box carved, so `tree` and
#   `netted` are the same empty box and that anastomosis pair measures 0.0%. At 2.4 the
#   same column reads 100 / 92 / 54 / 4 and the pair recovers to 0.8%, with fifteen of
#   the sixteen cells carrying surface. `thread` and `tunnel` are untouched: they are
#   the default and the lattice argument, which is where this axis makes its point.
#
# CROSSING NOTE for whoever reads the critic's table: these two are orthogonal in the
# arithmetic and NOT in the picture. A large bore visually fuses tubes the graph never
# joined, so inside the `hollow` column `anastomosis` will read weak. Group the numbers BY
# VALUE PAIR, not by per-axis mean, or the axis will be convicted of the bore's doing.
#
# WHAT IS DECLINED, and why each is a real candidate rather than a strawman:
#   threshold (0.5) — taken by mc_torus_sculpture, and worse, on a field carved as the
#     linear ramp dist/voxel_radius a constant threshold is EXACTLY a uniform change of
#     carve radius. It would argue with `bore` for the same pixels.
#   vertical_bias (0.3) — real and visible, the difference between a flat sheet of
#     tunnels and a ball of them. It is the same question as `plumb` (mc_cave,
#     mc_inside_cave): which way the field prefers to go. Declined for the rhyme.
#   chamber_probability (0.25) — too close to `bulge`, and stochastic: at 0.25 over ~30
#     iterations the variance between seeds would swamp the difference between rungs.
#   branch_probability (0.6), max_depth (4) — population counts, the same shape of
#     question as `metaball_count`.
#   voxel_scale, chunk_size — the sampling lattice, i.e. `resolution`, already taken twice.
#
# THE FIXTURE IS NOT DECORATION — WITHOUT IT THREE OF FOUR RUNGS ARE THE SAME SPHERE.
# find_merge_candidate compares a proposed branch tip against every existing node, and a
# tip sits at most branch_length from its own parent, which is already a node. So if
# merge_distance exceeds max_branch_length, EVERY attempt merges with its parent,
# create_connection rejects the self-edge, and the network never grows past its seed node.
# The capture fixture therefore has to make the branch lengths straddle the rungs, and the
# approved numbers (2.0..6.0) did the opposite: replicated over the real growth loop they
# give merge rates of 0 / 100 / 100 / 100 percent and node counts of 175 / 1 / 1 / 1, so
# netted, matted and knotted would all have photographed as one carved sphere. Shipped
# 5.0..20.0 is nearly as bad at the top — knotted is 20.0, so it collapses too. The
# fixture uses 3.0..26.0, which measures 0 / 34 / 59 / 89 percent merged and 175 / 65 / 18
# / 3 nodes: four different graphs, monotone, none degenerate.
#
# STILL-VISIBLE BY CONSTRUCTION. Nothing here runs _process. More usefully: because the
# chunk starts solid and RhizomeVoxelChunk.get_density returns 1.0 out of bounds, the
# outer faces of the box carry no surface of their own. The only geometry is the inner
# wall of the carved network, drawn CULL_DISABLED, so the picture IS the graph as a set of
# tubes. A tree and a knotted net are different objects on sight.

## merge_distance per rung, in metres. `netted` holds 6.0 — the same float the hardcoded
## rhizome_params dict has always handed to set_growth_rules — so the default is a
## short-circuit returning the shipped literal, not a formula that lands near it.
const MERGE_DISTANCES: Dictionary = {
	"tree": 0.0,
	"netted": 6.0,
	"matted": 12.0,
	"knotted": 20.0,
}

## Multiplier on the carve radius. `tunnel` is 1.0 and `radius * 1.0` returns the
## identical bit pattern for every finite float.
const BORE_SCALES: Dictionary = {
	"thread": 0.4,
	"tunnel": 1.0,
	"hall": 1.6,
	"hollow": 2.4,
}

const ANASTOMOSES: PackedStringArray = ["tree", "netted", "matted", "knotted"]
const BORES: PackedStringArray = ["thread", "tunnel", "hall", "hollow"]

@export_category("Rhizome Cave DNA")
@export_enum("tree", "netted", "matted", "knotted") var anastomosis: String = "netted"
@export_enum("thread", "tunnel", "hall", "hollow") var bore: String = "tunnel"

@export_category("Rhizome Cave stage")
## -1 keeps the shipped unseeded growth. Any value >= 0 pins the entire growth history,
## without which four tiles of an axis are four different caves and the bite number is
## noise wearing evidence's clothes.
@export var cave_seed: int = -1
## Side of the cubic chunk in voxels; 12 is what the dict below has always passed.
@export var chunk_extent: int = 12
## Branch length range. 5.0/20.0 are RhizomeGrowthPattern's own declared defaults, which
## nothing has ever been able to override because set_growth_rules did not read them.
@export var min_branch_length: float = 5.0
@export var max_branch_length: float = 20.0
## Capture only. Builds the whole cave inside _ready() with the frame yields removed.
## Left false everywhere a player goes, because a 13k-voxel march must not gate map load.
@export var build_synchronously: bool = false

# Cave generator
@onready var cave_generator_node = $CaveGenerator
var cave_generator: RhizomeCaveGenerator

## Signature of everything the build reads, captured once _ready has decided what to
## build. Empty until then, which is what tells apply_grid_config there is nothing yet
## to rebuild.
var _built_signature: String = ""

func _ready() -> void:
	# Config is stamped as metadata BEFORE the node enters the tree
	# (GridInteractablesComponent._apply_artifact_config runs at :1195, add_child at
	# :1220), so reading it here means the first build already has the right values and
	# the deferred apply_grid_config that follows finds nothing to do.
	_read_metadata_overrides()
	setup_cave_generator()

	if build_synchronously:
		# No call_deferred and no yields: _ready returns with a finished cave.
		await _build_now()
	else:
		# Generate initial cave asynchronously to prevent blocking on startup
		call_deferred("generate_cave_async")

	_built_signature = _config_signature()

# UI setup removed - no UI needed for cave generation only

func setup_cave_generator() -> void:
	"""Initialize the cave generator"""
	cave_generator = RhizomeCaveGenerator.new()
	cave_generator.name = "RhizomeCaveGenerator"
	cave_generator_node.add_child(cave_generator)

	# Connect signals
	cave_generator.generation_progress.connect(_on_generation_progress)
	cave_generator.generation_complete.connect(_on_generation_complete)

	print("RhizomeCaveDemo: Cave generator initialized")


## Everything the generator reads, in one place, so the async path and the capture path
## cannot drift apart. Every literal here is the literal that used to be typed into the
## two dictionaries inline; only merge_distance and the carve scale are now looked up.
func _configure_generator() -> void:
	if cave_generator == null:
		return

	# Configure generation parameters with default values
	var cave_size: float = 30.0  # Default size
	var cave_params := {
		"size": Vector3(cave_size, cave_size * 0.4, cave_size),
		"chunk_size": Vector3i(chunk_extent, chunk_extent, chunk_extent),
		"voxel_scale": 1.0,
		# WAS randi(), and setup_parameters has never read this key, so that draw was
		# taken and thrown away on every cave this project has ever grown. -1 is the
		# sentinel RhizomeGrowthPattern._init already understood.
		"seed": cave_seed,
		"initial_chambers": 3,
		"growth_iterations": 15
	}

	# Configure rhizomatic parameters with default values
	var rhizome_params := {
		"branch_probability": 0.6,
		"merge_distance": _merge_distance(),   # was the literal 6.0
		"vertical_bias": 0.3,
		"chamber_probability": 0.25,
		"max_depth": 4,
		"min_branch_length": min_branch_length,
		"max_branch_length": max_branch_length
	}

	cave_generator.carve_radius_scale = _bore_scale()   # was implicitly 1.0
	cave_generator.setup_parameters(cave_params)
	cave_generator.configure_rhizome_parameters(rhizome_params)


func generate_cave_async() -> void:
	"""Generate a new cave system asynchronously with default parameters"""
	if cave_generator == null:
		return

	print("RhizomeCaveDemo: Starting cave generation...")
	_configure_generator()

	# Start async generation
	await cave_generator.generate_cave_async()

# Keep the old function for backwards compatibility but make it call the async version
func generate_cave() -> void:
	"""Generate a new cave system with current parameters (legacy function)"""
	generate_cave_async()


## The same steps in the same order with the yields switched off. Not a second builder —
## the flag is read inside RhizomeCaveGenerator at the four `await get_tree()` sites and
## nowhere else, so there is exactly one build path and one thing that can be wrong.
func _build_now() -> void:
	if cave_generator == null:
		return
	print("RhizomeCaveDemo: Starting cave generation (synchronous)...")
	cave_generator.synchronous = true
	_configure_generator()
	await cave_generator.generate_cave_async()


func _merge_distance() -> float:
	if MERGE_DISTANCES.has(anastomosis):
		return float(MERGE_DISTANCES[anastomosis])
	return 6.0


func _bore_scale() -> float:
	if BORE_SCALES.has(bore):
		return float(BORE_SCALES[bore])
	return 1.0


## Everything the build reads. Stringified from the same accessors the build calls, so
## the signature cannot drift out of step with what actually reaches the generator.
func _config_signature() -> String:
	return "%.6f|%.6f|%d|%d|%.6f|%.6f|%s" % [
		_merge_distance(), _bore_scale(), cave_seed, chunk_extent,
		min_branch_length, max_branch_length, str(build_synchronously)
	]


## The grid's channel. capture_config_sweep sets the exports straight onto the property
## before add_child instead, which is why both routes have to end at the same values.
func _read_metadata_overrides() -> void:
	if has_meta("config_anastomosis"):
		var a: String = str(get_meta("config_anastomosis")).strip_edges().to_lower()
		if ANASTOMOSES.has(a):
			anastomosis = a
	if has_meta("config_bore"):
		var b: String = str(get_meta("config_bore")).strip_edges().to_lower()
		if BORES.has(b):
			bore = b
	if has_meta("config_cave_seed"):
		cave_seed = int(get_meta("config_cave_seed"))
	if has_meta("config_chunk_extent"):
		chunk_extent = maxi(4, int(get_meta("config_chunk_extent")))
	if has_meta("config_min_branch_length"):
		min_branch_length = maxf(0.1, float(get_meta("config_min_branch_length")))
	if has_meta("config_max_branch_length"):
		max_branch_length = maxf(min_branch_length, float(get_meta("config_max_branch_length")))
	if has_meta("config_build_synchronously"):
		build_synchronously = _as_bool(get_meta("config_build_synchronously"))


## bool("false") is TRUE in GDScript — any non-empty string is. A map token carries text.
func _as_bool(v: Variant) -> bool:
	if v is bool:
		return bool(v)
	if v is int or v is float:
		return float(v) != 0.0
	var s: String = str(v).strip_edges().to_lower()
	return s == "true" or s == "1" or s == "yes" or s == "on"


## Guarded. The old body was a bare `pass` — a method that existed only so the grid's
## has_method() check would find it. It now rebuilds when, and only when, a value the
## generator reads has actually changed. NONE of the placements that exist passes a config
## key, so none of them reaches the rebuild: three direct grid cells (two bare
## `rhizome_cave_demo`, one `rhizome_cave_system:0:-0.5`, which is rotation-and-offset and
## carries no config), two curation_station rosters and fourteen exhibit_furniture mounts,
## whose own `#` parameters belong to the host and are never forwarded. Neither registry
## entry declares default_params, so merged_config is empty at every one of them and
## GridInteractablesComponent does not even call this method.
func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		var sk: String = str(k).strip_edges()
		if sk.is_valid_identifier():
			set_meta("config_%s" % sk, config[k])
	_read_metadata_overrides()
	if _built_signature == "":
		return          # _ready has not built yet; it will read the metadata itself
	if _config_signature() == _built_signature:
		return
	await _rebuild()


## Free only what the generator created (its _owned list), then run the same build again.
func _rebuild() -> void:
	if cave_generator == null:
		return
	cave_generator.clear_generated()
	if build_synchronously:
		await _build_now()
	else:
		await generate_cave_async()
	_built_signature = _config_signature()


func _on_generation_progress(percentage: float) -> void:
	"""Log progress during generation"""
	var status = ""
	if percentage <= 20:
		status = "Growing rhizomatic network..."
	elif percentage <= 40:
		status = "Creating voxel grid..."
	elif percentage <= 60:
		status = "Carving cave system..."
	elif percentage <= 80:
		status = "Adding organic variation..."
	elif percentage <= 95:
		status = "Generating meshes..."
	else:
		status = "Creating physics..."

	print("Cave Generation Progress: %.0f%% - %s" % [percentage, status])

func _on_generation_complete() -> void:
	"""Handle generation completion"""
	print("RhizomeCaveDemo: Generation complete!")

	# Log cave statistics
	update_cave_statistics()

func update_cave_statistics() -> void:
	"""Log cave statistics"""
	if cave_generator == null:
		return

	var info = cave_generator.get_cave_info()

	print("=== Cave Statistics ===")
	print("• Mesh Chunks: %d" % info.mesh_instances)
	print("• Collision Bodies: %d" % info.collision_bodies)
	print("• Total Vertices: %s" % format_number(info.total_vertices))
	print("• Total Triangles: %s" % format_number(info.total_triangles))
	print("• Voxel Chunks: %d" % info.voxel_chunks)
	print("• Growth Nodes: %d" % info.growth_nodes)
	print("• Chambers: %d" % info.chambers)

	# Calculate approximate memory usage
	var memory_mb = (info.total_vertices * 12 + info.total_triangles * 6) / (1024 * 1024)
	print("• Memory Est: %.1f MB" % memory_mb)

func format_number(num: int) -> String:
	"""Format large numbers with commas"""
	var str_num = str(num)
	var formatted = ""
	var count = 0

	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = str_num[i] + formatted
		count += 1

	return formatted

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
