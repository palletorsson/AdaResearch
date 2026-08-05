# sphere_splitting_showcase.gd
# Showcase scene demonstrating all sphere splitting approaches
#
# @identity
# essence: sphere → fragments(method). Five fracture algorithms: planar cut, octree division, orange-peel sectors, CSG boolean, pre-segmented mesh. One sphere, five deaths.
# desire: To compare how the same sphere breaks under five different mathematical decompositions — each one a different answer to "how do you divide a sphere?"
# critical_parameter: The impact point and velocity of the thrown ball. For planar cuts, the impact plane determines the split. For Voronoi, the crack propagates from impact. Geometry meets ballistics.
# triggers: VR grab + throw → ball hits sphere, each sphere type fractures by its algorithm, stats track throws and total splits, per-sphere piece counts update live
# emerges: Planar cuts producing clean halves. Octree producing eight cubic chunks. Sectors peeling like an orange. CSG producing irregular but realistic cuts. Each algorithm's personality visible in its fragments.
# needs: Throwable balls [has], five sphere types [has], per-sphere info labels [has], live piece counters [has]. Missing: slow-motion mode, side-by-side comparison replay.
# relationships: Companion to destructibles_test_scene (cubes + planes vs spheres). Lives in ForcesArena. Showcases computational geometry algorithms through destruction.
# truth: There is no single way to break a sphere. Each fracture method is a decomposition basis — a different answer to what "parts" means.
extends "../shared/vector_scene_base.gd"

@export_group("Scene Configuration")
@export var num_balls: int = 6
@export var ball_spawn_height: float = 1.5
@export var ball_spawn_spacing: float = 0.3

# --- STAGE-2 DNA (promoted 2026-08-05) ---------------------------------------
#
# WHAT WAS WELDED SHUT. Five spheres, five algorithms, one row, always — and the
# row was the only thing this bench could ever say. Its own truth statement says
# "each fracture method is a decomposition basis", which is a claim about how the
# five RELATE, and the exhibit had no way to put any two of them in relation
# except by standing all five in a line and leaving the comparison to the reader.
#
# `comparison` is the bench-wide word for exactly that question — what stands
# beside what — carried here from [[riemann_pump]] and [[launch_arc]], whose
# `single` anchor value is kept character for character. The other three answers
# are this artifact's own, and they are not an arbitrary subsetting: they are the
# one distinction in this material that a STILL can actually carry.
#
#   all        the shipped row, in the shipped order, at the shipped x. Five
#              bases side by side and no claim about which resemble which.
#   computed   planar, octree, CSG — the three whose parts DO NOT EXIST until
#              something hits them. Each is one whole unbroken sphere; the
#              decomposition is a calculation waiting on an event. A bench of
#              three smooth surfaces, and no seam anywhere in the frame.
#   latent     sectored and segmented — the two that are ALREADY in pieces before
#              anything happens, 8 wedges and 48 tiles, and whose "destruction"
#              only removes parts that were always there. A bench of nothing but
#              seams. This is the contrast the row could not make: the same
#              question answered by arithmetic on one side and by mesh topology
#              on the other.
#   single     the planar cut alone. One sphere, one basis, nothing to argue with
#              — the reading you would actually take away.
#
# `all` runs no branch and rebuilds the row term for term (see _slot_x).
const COMPARISONS: PackedStringArray = ["all", "computed", "latent", "single"]
const BENCH_ALL: PackedStringArray = ["planar", "octree", "sectored", "csg", "segmented"]
## Which decomposition bases stand beside each other. all = the shipped five-way row.
@export_enum("all", "computed", "latent", "single") var comparison: String = "all"

# Preloaded scenes
var throw_ball_scene = preload("res://algorithms/vectors/08_vector_throwing/throw_ball.tscn")
var planar_sphere_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/planar_cut_sphere.tscn")
var octree_sphere_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/octree_sphere.tscn")
var sectored_sphere_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/sectored_sphere.tscn")
var csg_sphere_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/csg_cut_sphere.tscn")
var segmented_sphere_scene = preload("res://algorithms/vectors/08_vector_throwing/destructibles/segmented_sphere.tscn")

# Scene references
var throw_balls: Array[Node3D] = []
var spheres_container: Node3D = null
var info_labels: Dictionary = {}  # sphere -> label

# Stats
var throws_count: int = 0
var total_splits: int = 0
var sphere_stats: Dictionary = {}  # sphere_name -> {splits: int, pieces: int}
var _bench_built: bool = false

func _ready() -> void:
	super._ready()
	_spawn_throw_balls()
	_spawn_spheres()
	_create_main_info_panel()
	_create_instructions()
	_bench_built = true

func _spawn_throw_balls() -> void:
	var balls_container = Node3D.new()
	balls_container.name = "ThrowBalls"
	add_child(balls_container)

	for i in range(num_balls):
		var ball = throw_ball_scene.instantiate()
		ball.name = "ThrowBall_%d" % i
		var x_offset = (i - (num_balls - 1) / 2.0) * ball_spawn_spacing
		ball.position = Vector3(x_offset, ball_spawn_height, 0.5)

		var hue = float(i) / float(num_balls)
		var color = Color.from_hsv(hue, 0.8, 1.0)
		if ball.has_method("set_ball_color"):
			ball.set_ball_color(color)

		ball.dropped.connect(_on_ball_thrown.bind(ball))
		balls_container.add_child(ball)
		throw_balls.append(ball)

func _comparison_value() -> String:
	var c: String = String(comparison).strip_edges().to_lower()
	return c if COMPARISONS.has(c) else "all"


## Which bases stand on the bench, left to right. The fall-through is `all` and returns
## the shipped five in the shipped order.
func _bench() -> PackedStringArray:
	match _comparison_value():
		"computed":
			return PackedStringArray(["planar", "octree", "csg"])
		"latent":
			return PackedStringArray(["sectored", "segmented"])
		"single":
			return PackedStringArray(["planar"])
	return BENCH_ALL


## The x a basis stands at. For the full bench this is the shipped literal term for
## term: slots 0..4 give -1.5, -0.5, +0.5, +1.5, +2.5 times spacing, which is exactly
## the five hard-coded expressions it replaces. A SUBSET is re-centred instead, for the
## reason riemann_pump re-centres its panels: if a lone sphere kept its old x, the
## difference between `single` and `latent` would be dominated by a whole-bench
## translation and the thing being argued — which bases these are — would be the
## smaller signal.
func _slot_x(kind: String, spacing: float) -> float:
	var bench: PackedStringArray = _bench()
	var i: int = bench.find(kind)
	if i < 0:
		return 0.0
	if bench.size() == BENCH_ALL.size():
		return (float(i) - 1.5) * spacing
	return (float(i) - (float(bench.size()) - 1.0) * 0.5) * spacing


func _spawn_spheres() -> void:
	spheres_container = Node3D.new()
	spheres_container.name = "Spheres"
	add_child(spheres_container)

	var spawn_distance = 3.5
	var y_height = 1.2
	var spacing = 1.5
	var bench: PackedStringArray = _bench()

	# Row 1: Planar Cut and Octree
	# Approach 1: Planar Cut
	if bench.has("planar"):
		var planar_sphere = planar_sphere_scene.instantiate()
		planar_sphere.position = Vector3(_slot_x("planar", spacing), y_height, spawn_distance)
		planar_sphere.piece_split.connect(_on_sphere_split.bind("Planar Cut"))
		spheres_container.add_child(planar_sphere)
		sphere_stats["Planar Cut"] = {splits = 0, pieces = 1}
		_add_info_label(planar_sphere, "PLANAR CUT\nSplits in half\nalong plane\n\nPieces: 1\nSplits: 0")

	# Approach 2: Octree
	if bench.has("octree"):
		var octree_sphere = octree_sphere_scene.instantiate()
		octree_sphere.position = Vector3(_slot_x("octree", spacing), y_height, spawn_distance)
		octree_sphere.octant_split.connect(_on_sphere_split.bind("Octree"))
		spheres_container.add_child(octree_sphere)
		sphere_stats["Octree"] = {splits = 0, pieces = 1}
		_add_info_label(octree_sphere, "OCTREE\nDivides into\n8 octants\n\nPieces: 1\nSplits: 0")

	# Approach 3: Sectored (Orange wedges)
	if bench.has("sectored"):
		var sectored_sphere = sectored_sphere_scene.instantiate()
		sectored_sphere.position = Vector3(_slot_x("sectored", spacing), y_height, spawn_distance)
		sectored_sphere.sector_destroyed.connect(_on_sector_destroyed.bind("Sectored"))
		spheres_container.add_child(sectored_sphere)
		sphere_stats["Sectored"] = {splits = 0, pieces = 8}  # Starts with 8 sectors
		_add_info_label(sectored_sphere, "SECTORED\nOrange-like\nwedges\n\nPieces: 8\nSplits: 0")

	# Approach 4: CSG (Realistic cutting)
	if bench.has("csg"):
		var csg_sphere = csg_sphere_scene.instantiate()
		csg_sphere.position = Vector3(_slot_x("csg", spacing), y_height, spawn_distance)
		csg_sphere.piece_split.connect(_on_sphere_split.bind("CSG"))
		spheres_container.add_child(csg_sphere)
		sphere_stats["CSG"] = {splits = 0, pieces = 1}
		_add_info_label(csg_sphere, "CSG CUTTING\nBoolean ops\nfor real cuts\n\nPieces: 1\nSplits: 0")

	# Approach 5: Segmented (Pre-built parts)
	if bench.has("segmented"):
		var segmented_sphere = segmented_sphere_scene.instantiate()
		segmented_sphere.position = Vector3(_slot_x("segmented", spacing), y_height, spawn_distance)
		segmented_sphere.segment_destroyed.connect(_on_segment_destroyed.bind("Segmented"))
		spheres_container.add_child(segmented_sphere)
		var total_segments = 6 * 8  # latitude_segments * longitude_segments
		sphere_stats["Segmented"] = {splits = 0, pieces = total_segments}
		_add_info_label(segmented_sphere, "SEGMENTED\nPre-built\nparts\n\nPieces: %d\nSplits: 0" % total_segments)

func _add_info_label(sphere: Node3D, text: String) -> void:
	"""Add floating info label above sphere"""
	var label = Label3D.new()
	label.text = text
	label.font_size = 18
	label.outline_size = 3
	label.outline_modulate = Color.BLACK
	label.modulate = Color.WHITE
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 0.6, 0)
	sphere.add_child(label)
	info_labels[sphere] = label

func _create_main_info_panel() -> void:
	"""Create main info display"""
	var info_label = Label3D.new()
	info_label.name = "MainInfoLabel"
	info_label.font_size = 36
	info_label.outline_size = 6
	info_label.outline_modulate = Color.BLACK
	info_label.modulate = Color.YELLOW
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.position = Vector3(0, 2.8, 0)
	add_child(info_label)
	_update_main_info(info_label)

func _create_instructions() -> void:
	"""Create instruction panel"""
	var instructions = Label3D.new()
	instructions.font_size = 22
	instructions.outline_size = 4
	instructions.outline_modulate = Color.BLACK
	instructions.modulate = Color(0.8, 0.9, 1.0)
	instructions.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions.position = Vector3(0, 2.3, 0)
	instructions.text = """SPHERE SPLITTING APPROACHES

Throw balls at different spheres to see how they fragment!

1. PLANAR CUT - Splits along impact plane (halves)
2. OCTREE - Divides into 8 cubic octants
3. SECTORED - Orange-like wedge sectors
4. CSG - Realistic boolean cutting operations
5. SEGMENTED - Pre-built from individual parts

Each approach creates real separated geometry!"""
	add_child(instructions)

func _on_ball_thrown(_pickable: Node3D, _ball: Node3D) -> void:
	throws_count += 1

func _on_sphere_split(_parent: Node3D, children: Array, sphere_name: String) -> void:
	"""Handle when a sphere splits"""
	total_splits += 1

	if sphere_name in sphere_stats:
		sphere_stats[sphere_name].splits += 1
		sphere_stats[sphere_name].pieces = children.size()

	_update_sphere_label(sphere_name)
	_update_main_info(get_node_or_null("MainInfoLabel"))

	print("[Showcase] %s split into %d pieces" % [sphere_name, children.size()])

func _on_sector_destroyed(_sector: Node3D, _velocity: Vector3, sphere_name: String) -> void:
	"""Handle when a sector is destroyed"""
	if sphere_name in sphere_stats:
		sphere_stats[sphere_name].splits += 1

	_update_sphere_label(sphere_name)
	_update_main_info(get_node_or_null("MainInfoLabel"))

func _on_segment_destroyed(_segment: Node3D, _velocity: Vector3, sphere_name: String) -> void:
	"""Handle when a segment is destroyed"""
	if sphere_name in sphere_stats:
		sphere_stats[sphere_name].splits += 1
		sphere_stats[sphere_name].pieces -= 1  # One less piece

	_update_sphere_label(sphere_name)
	_update_main_info(get_node_or_null("MainInfoLabel"))

func _update_sphere_label(sphere_name: String) -> void:
	"""Update individual sphere's info label"""
	if not sphere_name in sphere_stats:
		return

	var stats = sphere_stats[sphere_name]

	# Find the sphere and its label
	# Clean up any invalid entries first
	var invalid_spheres = []
	for sphere in info_labels.keys():
		if not is_instance_valid(sphere):
			invalid_spheres.append(sphere)

	for sphere in invalid_spheres:
		info_labels.erase(sphere)

	# Now update valid labels
	for sphere in info_labels.keys():
		if not is_instance_valid(sphere):
			continue

		var label: Label3D = info_labels[sphere]
		if not is_instance_valid(label):
			continue

		if label.text.begins_with(sphere_name.to_upper()):
			var lines = label.text.split("\n")
			if lines.size() >= 3:
				# Keep first 3 lines (title and description), update stats
				var title_desc = "\n".join(lines.slice(0, 3))
				label.text = title_desc + "\n\nPieces: %d\nSplits: %d" % [stats.pieces, stats.splits]
			break

func _update_main_info(label: Label3D) -> void:
	"""Update main info panel"""
	if not label:
		return

	label.text = "Throws: %d | Total Splits: %d" % [throws_count, total_splits]

func _process(_delta: float) -> void:
	# Dynamically update piece counts for active splitting spheres
	_update_dynamic_piece_counts()

func _update_dynamic_piece_counts() -> void:
	"""Update piece counts in real-time"""
	# This runs every frame to show real-time piece counts

	# Only update every few frames for performance
	if Engine.get_process_frames() % 30 != 0:
		return

	if spheres_container == null or not is_instance_valid(spheres_container):
		return

	# Find spheres and count their pieces
	for child in spheres_container.get_children():
		var sphere_name = ""

		if "planar" in child.name.to_lower():
			sphere_name = "Planar Cut"
			if child.has_method("get_pieces_count"):
				sphere_stats[sphere_name].pieces = child.get_pieces_count()
		elif "octree" in child.name.to_lower():
			sphere_name = "Octree"
			if child.has_method("get_pieces_count"):
				sphere_stats[sphere_name].pieces = child.get_pieces_count()
		elif "sectored" in child.name.to_lower():
			sphere_name = "Sectored"
			if child.has_method("get_sectors_count"):
				sphere_stats[sphere_name].pieces = child.get_sectors_count()
		elif "csg" in child.name.to_lower():
			sphere_name = "CSG"
			if child.has_method("get_pieces_count"):
				sphere_stats[sphere_name].pieces = child.get_pieces_count()
		elif "segmented" in child.name.to_lower():
			sphere_name = "Segmented"
			if child.has_method("get_segments_remaining"):
				sphere_stats[sphere_name].pieces = child.get_segments_remaining()

		if sphere_name != "":
			_update_sphere_label(sphere_name)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Only `comparison` is honoured, and only when it actually CHANGES. A config that
## names nothing this bench owns reaches no assignment and no rebuild — the body was a
## bare `pass` before this pass and behaves identically for every key but this one. The
## rebuild is confined to the sphere row: the throw balls, the stats panel and the
## instruction wall are never torn down, so nothing the player is holding is destroyed.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("comparison"):
		return
	var want: String = String(config["comparison"]).strip_edges().to_lower()
	if not COMPARISONS.has(want) or want == _comparison_value():
		return
	comparison = want
	if not _bench_built:
		return                                   # _ready has not run; it will build it
	if spheres_container != null and is_instance_valid(spheres_container):
		remove_child(spheres_container)
		spheres_container.queue_free()
	spheres_container = null
	info_labels.clear()
	sphere_stats.clear()
	_spawn_spheres()
	_update_main_info(get_node_or_null("MainInfoLabel"))
