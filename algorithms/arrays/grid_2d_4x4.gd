extends Node3D

# @identity
# essence: for x in range(4): for z in range(4): cube.position = Vector3(x, 0, z) with label "[x, z]" — a 4×4 grid of pickup cubes where each cube's position equals its index, paired with a binary table that shows the same data as 1s and 0s
# desire: to navigate a 2D array by walking it — to move from [0,0] to [3,3] and feel that two-dimensional indexing is a spatial act, not a notational one; and when you pick up a cube, to watch its slot turn to 0 in the binary table
# critical_parameter: show_binary_table — when true, a BinaryTableDisplay appears beside the grid showing the same 4×4 structure as a matrix of 0s and 1s; removing cubes live-updates the table, making the array-as-data-structure visible
# triggers: picking up any cube fires tree_exiting → _on_cube_removed(x,z) → grid_data[x][z] = 0 → binary_table.set_cell(x, z, 0) — the physical act of grabbing an object updates the data representation in real time
# emerges: students discover that the grid is not just a physical arrangement but a data structure — removing a cube is setting a value in a 2D array, and the binary table makes the data model visible alongside the spatial model
# needs: pickup cubes with grab physics [has]; Label3D index labels [has]; BinaryTableDisplay [has when show_binary_table=true]; pulsar_visualizer [external, in same map]; gridagent [external, in same map]; no VR slider controls [missing]
# relationships: extends column_3_z to 2 dimensions; precedes grid_3d_4x4x4; binary table connects to pulsar_visualizer (radio signal as 2D array); appears with gridagent in Tutorial_2D_Build
# truth: a 2D array is space folded into coordinates — this artifact makes coordinates walkable positions, proving that the abstract address [x,z] is always a location in space

## STAGE-2 DNA PROMOTION (2026-08-05). This was very nearly declined as a test rig — a 4×4
## of cubes whose only obvious knob is how many of them there are, and grid dimensions are
## the decoration case. What saved it is that the artifact makes a CLAIM it never admitted
## to making. Every cube wears "[x, z]" in the air, which asserts that an address is a tag
## the object carries; pick the cube up and the address leaves with it, while grid_data[x][z]
## quietly becomes 0 and the slot it named stays behind unmarked. That is one answer out of
## several, and shipping only it hid the question.
##
##   notation   by what means the grid declares its addresses
##              label · none · tape · tally · plate
##
## THE SAME WORD AND THE SAME FIVE VALUES, character for character, as column_3_z — which
## this artifact's own @identity names as the thing it extends to two dimensions. A shared
## vocabulary is only honest if the siblings measure alike, and these two are the same
## object at n=1 and n=2: pickup cubes on a floor, an index each, nothing else. Every value
## has a real 2D answer rather than a fudged one; where the second dimension changes the
## answer, it is written out below.
##
##   label   the shipped white billboarded [x, z] over each cube — an address is a TAG the
##           object carries. THE LEGACY LINEAGE, built in the same place in the same loop
##           as before, with the same font size, outline, no_depth_test and colour.
##   none    bare cubes — an address is nothing but POSITION, and you get it by counting
##           in from the corner you started at. The honest null that makes the rest arguable.
##   tape    two rules lying on the floor along the two origin-side margins, minor ticks
##           every quarter interval and a full-width tick at each row and column — an
##           address is a DISTANCE read off a scale, and in two dimensions it is two
##           distances read off two scales. No numerals anywhere: the ticks carry it. This
##           is also the matrix margin, the oldest 2D notation there is.
##   tally   x strokes cut into the face looking back down X, z strokes into the face
##           looking back down Z — an address is a COUNT, and in two dimensions it is two
##           counts, each on the face that points at the origin it counts from. Slot 0 in
##           either direction carries a single bar, because zero is a mark you make rather
##           than a mark you leave off, and the marks go with the cube when the cube is taken.
##   plate   a dark plaque on the floor under each cube with a low card standing on it
##           reading [x, z] — an address belongs to the SLOT. Pick the cube up and the
##           address is still there, which is exactly what grid_data[x][z] = 0 means and
##           what this artifact has always done without ever showing it.
##
## Usage in map_data.json:
##   "grid_2d_4x4#notation:plate"

# Local debug flag to gate prints (default off)
@export var debug: bool = false
@export var show_binary_table: bool = true

## DNA axis. See the block above. `label` is the shipped lineage.
@export_enum("label", "none", "tape", "tally", "plate") var notation: String = "label"

const NOTATIONS: PackedStringArray = ["label", "none", "tape", "tally", "plate"]

# 4x4 2D grid of cubes arranged in X and Z directions
# Each cube is spaced 1 units apart

# Layout. These were locals inside apply_grid_config with exactly these defaults, and the
# defaults are what _ready hard-coded, so one builder now serves both paths unchanged.
var cols: int = 4
var rows: int = 4
var spacing: float = 1.0
var label_size: int = 32
var label_color: Color = Color.WHITE

# Grid data as 2D array (for binary table display)
var grid_data: Array = []

# Reference to binary table for updates
var _binary_table: Node3D = null

# Track cube references by coordinate
var _cube_refs: Dictionary = {}  # "x_z" -> cube_instance

## True once _ready has built the grid. apply_grid_config must not rebuild before it.
var _built: bool = false

func _ready() -> void:
	create_grid_2d()
	if show_binary_table:
		_create_binary_table()
	_built = true

func create_grid_2d() -> void:
	if not NOTATIONS.has(notation):
		notation = "label"

	# Load the pickup cube scene
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	var cubes: Dictionary = {}

	# Initialize grid data as cols x rows array of 1s
	grid_data = []
	for x in range(cols):
		var row: Array = []
		for z in range(rows):
			row.append(1)
		grid_data.append(row)

	# Create the grid of cubes
	for x in range(cols):
		for z in range(rows):
			var cube_instance = pickup_cube_scene.instantiate()
			cube_instance.name = "Cube_" + str(x) + "_" + str(z)

			# Position cubes in a grid, `spacing` units apart
			cube_instance.position = Vector3(x * spacing, 0, z * spacing)

			# Store coordinate in metadata for tracking
			cube_instance.set_meta("grid_x", x)
			cube_instance.set_meta("grid_z", z)

			# Connect to tree_exiting signal to detect when cube is picked up/removed
			cube_instance.tree_exiting.connect(_on_cube_removed.bind(x, z))

			# Store reference
			_cube_refs["%d_%d" % [x, z]] = cube_instance
			cubes["%d_%d" % [x, z]] = cube_instance

			# Add Index Label - high visibility from all angles
			if notation == "label":
				var label = Label3D.new()
				label.text = "[%d, %d]" % [x, z]
				label.font_size = label_size  # Larger for VR
				label.pixel_size = 0.003
				label.outline_size = 6  # Add outline for visibility
				label.outline_modulate = Color(0, 0, 0, 1)  # Black outline
				label.position = Vector3(0, 1.0, 0)
				label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				label.no_depth_test = true  # Always visible, even through objects
				label.modulate = label_color  # White for maximum contrast
				cube_instance.add_child(label)

			add_child(cube_instance)

	# NOTATION dressing, appended LAST so every child index above is untouched on the
	# legacy path. "label" was already built in the loop and adds nothing more here.
	_build_notation(cubes)

func _create_binary_table() -> void:
	# Load the binary table display scene
	var table_scene = load("res://algorithms/arrays/binary_table/binary_table_display.tscn")
	if not table_scene:
		push_warning("Grid2D4x4: Could not load binary table display scene")
		return

	var table = table_scene.instantiate()
	table.name = "BinaryTableDisplay"

	# Position table to the side of the grid (left side, facing the grid)
	table.position = Vector3(-2.0, 1.8, 1.5)
	table.rotation_degrees = Vector3(0, 90, 0)  # Face toward the grid

	# Configure table - BIGGER for visibility
	table.rows = rows
	table.cols = cols
	table.title = ""  # No title
	table.cell_size = 0.22  # Increased from 0.12
	table.font_size = 56    # Increased from 32
	table.data = grid_data

	add_child(table)

	# Store reference for updates when cubes are removed
	_binary_table = table

func _on_cube_removed(x: int, z: int) -> void:
	# Called when a cube is picked up or removed from the grid
	if debug:
		print("Grid2D4x4: Cube removed at [%d, %d]" % [x, z])

	# Update grid data
	if x >= 0 and x < grid_data.size():
		if z >= 0 and z < grid_data[x].size():
			grid_data[x][z] = 0

	# Update binary table display
	if _binary_table and _binary_table.has_method("set_cell"):
		_binary_table.set_cell(x, z, 0)

	# Remove from tracking
	var key = "%d_%d" % [x, z]
	if _cube_refs.has(key):
		_cube_refs.erase(key)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## GUARDED. The shipped version tore down every child and rebuilt on ANY non-empty config,
## including one naming nothing it owns — the force_pad fault. Now a value has to actually
## MOVE, and nothing rebuilds before _ready has built once. None of the 14 mentions of this
## token in map_data passes any key this reads, so all of them are untouched.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var changed: bool = false

	if config.has("cols"):
		var c: int = maxi(int(config["cols"]), 1)
		if c != cols:
			cols = c
			changed = true
	if config.has("rows"):
		var r: int = maxi(int(config["rows"]), 1)
		if r != rows:
			rows = r
			changed = true
	if config.has("spacing"):
		var s: float = float(config["spacing"])
		if not is_equal_approx(s, spacing):
			spacing = s
			changed = true
	if config.has("label_size"):
		var ls: int = int(config["label_size"])
		if ls != label_size:
			label_size = ls
			changed = true
	if config.has("label_color"):
		var lc: Color = Color.from_string(str(config["label_color"]), label_color)
		if lc != label_color:
			label_color = lc
			changed = true
	if config.has("show_binary_table"):
		var sb: bool = config["show_binary_table"] is bool and config["show_binary_table"]
		if sb != show_binary_table:
			show_binary_table = sb
			changed = true
	# Notation, read the way column_3_z reads it: normalise, and keep the current value on a
	# word the artifact cannot build. An unknown token must never become a silent wildcard —
	# here it would read as `none`, which is a different claim.
	if config.has("notation"):
		var note: String = str(config["notation"]).strip_edges().to_lower()
		if NOTATIONS.has(note) and note != notation:
			notation = note
			changed = true

	if not _built:
		return
	if not changed:
		return

	# Rebuild with the new settings
	for child in get_children():
		if not child.owner:
			child.queue_free()
	_cube_refs.clear()
	_binary_table = null
	await get_tree().process_frame

	create_grid_2d()
	if show_binary_table:
		_create_binary_table()


# ── NOTATION ─────────────────────────────────────────────────────────────────
# Everything below is appended after the cubes are in the tree, so the legacy grid is built
# exactly as it always was and only then dressed. Every piece stays inside the grid's
# existing envelope in X and Z (−0.25 .. (n−1)·spacing + 0.25, the cubes' own footprint) so
# the sweep frames the same box whichever value it is shooting.

func _build_notation(cubes: Dictionary) -> void:
	match notation:
		"label":
			pass                                  # the legacy lineage — built in the loop
		"none":
			pass                                  # the bare grid: position is the only address
		"tape":
			_notation_tape(label_color)
		"tally":
			_notation_tally(cubes, label_color)
		"plate":
			_notation_plate(label_color)
		_:
			pass                                  # normalised above; here for grammar


## TAPE — address as a DISTANCE, twice. Two rules lie on the floor along the margins nearest
## the origin, each exactly as long as the grid: minor ticks every quarter interval, and a
## full-width tick at each column and each row. There are no numerals on either, which is
## the point — you read [x, z] by counting intervals along two scales, the way you read a
## map reference or a matrix margin.
func _notation_tape(tint: Color) -> void:
	var x0: float = -0.25
	var x1: float = float(maxi(cols - 1, 0)) * spacing + 0.25
	var z0: float = -0.25
	var z1: float = float(maxi(rows - 1, 0)) * spacing + 0.25

	var band := _n_mat(Color(0.86, 0.84, 0.80))
	var minor := _n_mat(Color(0.30, 0.29, 0.31))
	var major := _n_mat(tint)

	# The X rule, laid along the near Z margin, and the Z rule along the near X margin.
	add_child(_n_box(Vector3((x0 + x1) * 0.5, 0.010, z0 + 0.10),
		Vector3(maxf(x1 - x0, 0.05), 0.006, 0.20), band))
	add_child(_n_box(Vector3(x0 + 0.10, 0.010, (z0 + z1) * 0.5),
		Vector3(0.20, 0.006, maxf(z1 - z0, 0.05)), band))

	var q: float = maxf(spacing * 0.25, 0.02)
	var ticks_x: int = maxi(int((x1 - x0) / q), 1)
	for k in range(ticks_x + 1):
		add_child(_n_box(Vector3(x0 + float(k) * q, 0.014, z0 + 0.045),
			Vector3(0.014, 0.004, 0.09), minor))
	var ticks_z: int = maxi(int((z1 - z0) / q), 1)
	for k in range(ticks_z + 1):
		add_child(_n_box(Vector3(x0 + 0.045, 0.014, z0 + float(k) * q),
			Vector3(0.09, 0.004, 0.014), minor))

	for i in range(cols):
		add_child(_n_box(Vector3(float(i) * spacing, 0.016, z0 + 0.10),
			Vector3(0.026, 0.005, 0.20), major))
	for j in range(rows):
		add_child(_n_box(Vector3(x0 + 0.10, 0.016, float(j) * spacing),
			Vector3(0.20, 0.005, 0.026), major))


## TALLY — address as a COUNT, cut into the cube itself, once per dimension. x strokes on
## the face looking back down X and z strokes on the face looking back down Z, so each face
## counts toward the origin it measures from. The marks travel with the object: take cube
## [2, 3] and its two and three strokes go with it, while the grid keeps no memory of what
## was there. Slot 0 in a direction carries one horizontal bar, because zero is a mark you
## make rather than a mark you leave off.
func _notation_tally(cubes: Dictionary, tint: Color) -> void:
	var mat := _n_mat(tint)
	var pitch: float = 0.072
	for x in range(cols):
		for z in range(rows):
			var key: String = "%d_%d" % [x, z]
			if not cubes.has(key):
				continue
			var host = cubes[key]
			if not (host is Node3D):
				continue
			var body: Node3D = host

			# X count, on the −X face.
			if x == 0:
				body.add_child(_n_box(Vector3(-0.253, 0.50, 0.0),
					Vector3(0.008, 0.034, 0.26), mat))
			else:
				var span_x: float = pitch * float(x - 1)
				for k in range(x):
					body.add_child(_n_box(Vector3(-0.253, 0.50, -span_x * 0.5 + pitch * float(k)),
						Vector3(0.008, 0.30, 0.030), mat))

			# Z count, on the −Z face.
			if z == 0:
				body.add_child(_n_box(Vector3(0.0, 0.50, -0.253),
					Vector3(0.26, 0.034, 0.008), mat))
			else:
				var span_z: float = pitch * float(z - 1)
				for k in range(z):
					body.add_child(_n_box(Vector3(-span_z * 0.5 + pitch * float(k), 0.50, -0.253),
						Vector3(0.030, 0.30, 0.008), mat))


## PLATE — address as something the SLOT owns. A dark plaque on the floor under each cube, a
## bright rim inset in it, and a low card standing on the near edge reading [x, z]. The card
## is not billboarded: it is a plate on a body, not a tag in the air. Pick the cube up and
## the address is still on the floor — which is precisely the difference this artifact
## already models in data and never showed in space, since grid_data[x][z] goes to 0 and the
## slot does not close up.
func _notation_plate(tint: Color) -> void:
	var plate := _n_mat(Color(0.16, 0.16, 0.18))
	var rim := _n_mat(Color(0.62, 0.60, 0.57))
	for x in range(cols):
		for z in range(rows):
			var px: float = float(x) * spacing
			var pz: float = float(z) * spacing
			add_child(_n_box(Vector3(px, 0.006, pz), Vector3(0.44, 0.012, 0.34), plate))
			add_child(_n_box(Vector3(px, 0.013, pz), Vector3(0.40, 0.004, 0.30), rim))
			add_child(_n_box(Vector3(px, 0.075, pz + 0.160), Vector3(0.40, 0.13, 0.010), plate))

			var card := Label3D.new()
			card.text = "[%d, %d]" % [x, z]
			card.font_size = label_size
			card.pixel_size = 0.0022
			card.outline_size = 0
			card.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			card.modulate = tint
			card.position = Vector3(px, 0.075, pz + 0.167)
			add_child(card)


func _n_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.75
	return m


func _n_box(centre: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = centre
	return mi
