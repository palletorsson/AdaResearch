# sphere_splitting_showcase.gd
# Showcase scene demonstrating all sphere splitting approaches
extends "../shared/vector_scene_base.gd"

@export_group("Scene Configuration")
@export var num_balls: int = 6
@export var ball_spawn_height: float = 1.5
@export var ball_spawn_spacing: float = 0.3

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

func _ready() -> void:
	super._ready()
	_spawn_throw_balls()
	_spawn_spheres()
	_create_main_info_panel()
	_create_instructions()

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

func _spawn_spheres() -> void:
	spheres_container = Node3D.new()
	spheres_container.name = "Spheres"
	add_child(spheres_container)

	var spawn_distance = 3.5
	var y_height = 1.2
	var spacing = 1.5

	# Row 1: Planar Cut and Octree
	# Approach 1: Planar Cut
	var planar_sphere = planar_sphere_scene.instantiate()
	planar_sphere.position = Vector3(-spacing * 1.5, y_height, spawn_distance)
	planar_sphere.piece_split.connect(_on_sphere_split.bind("Planar Cut"))
	spheres_container.add_child(planar_sphere)
	sphere_stats["Planar Cut"] = {splits = 0, pieces = 1}
	_add_info_label(planar_sphere, "PLANAR CUT\nSplits in half\nalong plane\n\nPieces: 1\nSplits: 0")

	# Approach 2: Octree
	var octree_sphere = octree_sphere_scene.instantiate()
	octree_sphere.position = Vector3(-spacing * 0.5, y_height, spawn_distance)
	octree_sphere.octant_split.connect(_on_sphere_split.bind("Octree"))
	spheres_container.add_child(octree_sphere)
	sphere_stats["Octree"] = {splits = 0, pieces = 1}
	_add_info_label(octree_sphere, "OCTREE\nDivides into\n8 octants\n\nPieces: 1\nSplits: 0")

	# Approach 3: Sectored (Orange wedges)
	var sectored_sphere = sectored_sphere_scene.instantiate()
	sectored_sphere.position = Vector3(spacing * 0.5, y_height, spawn_distance)
	sectored_sphere.sector_destroyed.connect(_on_sector_destroyed.bind("Sectored"))
	spheres_container.add_child(sectored_sphere)
	sphere_stats["Sectored"] = {splits = 0, pieces = 8}  # Starts with 8 sectors
	_add_info_label(sectored_sphere, "SECTORED\nOrange-like\nwedges\n\nPieces: 8\nSplits: 0")

	# Approach 4: CSG (Realistic cutting)
	var csg_sphere = csg_sphere_scene.instantiate()
	csg_sphere.position = Vector3(spacing * 1.5, y_height, spawn_distance)
	csg_sphere.piece_split.connect(_on_sphere_split.bind("CSG"))
	spheres_container.add_child(csg_sphere)
	sphere_stats["CSG"] = {splits = 0, pieces = 1}
	_add_info_label(csg_sphere, "CSG CUTTING\nBoolean ops\nfor real cuts\n\nPieces: 1\nSplits: 0")

	# Approach 5: Segmented (Pre-built parts)
	var segmented_sphere = segmented_sphere_scene.instantiate()
	segmented_sphere.position = Vector3(spacing * 2.5, y_height, spawn_distance)
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
