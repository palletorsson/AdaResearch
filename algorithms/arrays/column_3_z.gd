extends Node3D

# @identity
# essence: for i in range(4): cube.position = Vector3(0, 0, i × spacing) — four pickup cubes arranged as a linear array in the Z direction, each labeled [i]
# desire: to walk alongside an array — to see [0], [1], [2], [3] as physical objects in space and understand that an index is a distance, that traversal is movement
# critical_parameter: spacing — at 1.0 the cubes are adjacent and the array feels compact; at 2.0 they feel like separate objects; the default 1.0 makes index=position visible
# triggers: picking up a cube removes it from the array visualization, making the gap visible — the array has a hole where the index used to be
# emerges: the pink label color (light pink, Color(1.0, 0.7, 0.8)) subtly codes the array as soft rather than rigid, echoing the project's queer aesthetic
# needs: pickup cubes [has]; Label3D index labels [has]; no interactivity beyond grabbing [missing slider or button]; apply_grid_config supports count/spacing/label overrides [has]
# relationships: simpler than grid_2d_4x4 (one dimension vs two); appears in Tutorial_Row alongside xyz_coordinates; precedes grid_2d_4x4 in the tutorial sequence
# truth: an array is space made countable — column_3_z makes the abstract concept of an index into a physical position you can walk to

# Column of 3 cubes arranged in Z direction
# Each cube is spaced 1 units apart

## AXIS — BY WHAT NOTATION the row declares its own indices. The artifact's truth is that
## "an index is a distance you can walk"; that is one answer out of several, and shipping
## only it hid the question. Each value is a different claim about what an index IS, and
## none of them changes WHAT is taught: the count is four, the origin is zero, the spacing
## is the spacing.
##
##   label   a pink [i] hanging over each cube, billboarded — an index is a TAG the object
##           carries. THE LEGACY LINEAGE, byte for byte, built in the same place in the
##           same loop as before.
##   none    bare cubes, nothing written anywhere — an index is nothing but POSITION, and
##           you get it by counting from the end you started at. The honest null of the set
##           and the one that makes the others arguable.
##   tape    a 3.5 m rule lying under the row, minor ticks every quarter interval and a
##           full-width pink tick at each cube — an index is a DISTANCE read off a scale.
##           No numerals anywhere: the ticks carry it, which is the claim.
##   tally   i strokes cut into the outward face of each cube; slot [0] carries a single
##           horizontal bar, because zero is a mark you make rather than a mark you leave
##           off — an index is a COUNT, and it goes with the cube when the cube is taken.
##   plate   a dark plaque on the floor at each foot with a low card standing on it reading
##           [i] — an index is an ADDRESS belonging to the SLOT. Pick the cube up and the
##           address stays behind, which is the difference between an array with a hole in
##           it and a list that closed the gap.
##
## `tally` is deliberately the same word [[pick_up_cube]] uses for custody=tally — the mark
## the accounting left on the object — because that is exactly where these strokes go.
@export var notation: String = "label"
const NOTATIONS: PackedStringArray = ["label", "none", "tape", "tally", "plate"]


func _ready() -> void:
	create_column()

func create_column() -> void:
	if not NOTATIONS.has(notation):
		notation = "label"
	# Load the pickup cube scene
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	var cubes: Array = []

	# Create 3 cubes in Z direction
	for i in range(4):
		var cube_instance = pickup_cube_scene.instantiate()
		cube_instance.name = "Cube_" + str(i)

		# Position cubes 2 units apart in Z direction
		cube_instance.position = Vector3(0, 0, i * 1.0)

		# Add Index Label
		if notation == "label":
			var label = Label3D.new()
			label.text = "[%d]" % i
			label.font_size = 24
			label.pixel_size = 0.003
			label.outline_size = 0
			label.position = Vector3(0, 1.0, 0)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.modulate = Color(1.0, 0.7, 0.8)  # Light pink
			cube_instance.add_child(label)

		add_child(cube_instance)
		cubes.append(cube_instance)

	# NOTATION dressing, appended LAST so every child index above is untouched on the
	# legacy path. "label" was already built in the loop and adds nothing more here.
	_build_notation(cubes, 4, 1.0, 24, Color(1.0, 0.7, 0.8))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	# Rebuild with new settings
	for child in get_children():
		if not child.owner:
			child.queue_free()
	await get_tree().process_frame

	var count = int(config["count"]) if config.has("count") else 4
	var spacing = float(config["spacing"]) if config.has("spacing") else 1.0
	var label_size = int(config["label_size"]) if config.has("label_size") else 24
	var label_color = Color.from_string(config["label_color"], Color(1.0, 0.7, 0.8)) if config.has("label_color") else Color(1.0, 0.7, 0.8)
	# Notation, read the way station_wall reads upkeep: normalise, and keep the current
	# value on a word the artifact cannot build. An unknown token must never become a
	# silent wildcard — here it would read as `none`, which is a different claim.
	var note: String = str(config.get("notation", notation)).strip_edges().to_lower()
	notation = note if NOTATIONS.has(note) else notation
	if not NOTATIONS.has(notation):
		notation = "label"

	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	var cubes: Array = []
	for i in range(count):
		var cube_instance = pickup_cube_scene.instantiate()
		cube_instance.name = "Cube_" + str(i)
		cube_instance.position = Vector3(0, 0, i * spacing)

		if notation == "label":
			var label = Label3D.new()
			label.text = "[%d]" % i
			label.font_size = label_size
			label.pixel_size = 0.003
			label.outline_size = 0
			label.position = Vector3(0, 1.0, 0)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.modulate = label_color
			cube_instance.add_child(label)

		add_child(cube_instance)
		cubes.append(cube_instance)

	_build_notation(cubes, count, spacing, label_size, label_color)


# ── NOTATION ─────────────────────────────────────────────────────────────────
# Everything below is appended after the cubes are in the tree, so the legacy row is
# built exactly as it always was and only then dressed. Every piece stays inside the
# row's existing envelope in X and Z (x within ±0.26, z within −0.25 .. (n−1)·spacing
# + 0.25) so the sweep frames the same box whichever value it is shooting.

func _build_notation(cubes: Array, count: int, spacing: float, label_size: int,
		label_color: Color) -> void:
	match notation:
		"label":
			pass                                  # the legacy lineage — built in the loop
		"none":
			pass                                  # the bare row: position is the only index
		"tape":
			_notation_tape(count, spacing, label_color)
		"tally":
			_notation_tally(cubes, count, label_color)
		"plate":
			_notation_plate(count, spacing, label_size, label_color)
		_:
			pass                                  # normalised above; here for grammar


## TAPE — index as a DISTANCE. A rule lies under the row, exactly as long as the row: minor
## ticks every quarter interval from one edge, and a full-width tick at each cube. There
## are no numerals on it at all, which is the point — you read the index by counting
## intervals, the way you read a ruler.
func _notation_tape(count: int, spacing: float, tint: Color) -> void:
	var z0: float = -0.25
	var z1: float = float(maxi(count - 1, 0)) * spacing + 0.25
	add_child(_n_box(Vector3(0, 0.010, (z0 + z1) * 0.5),
		Vector3(0.30, 0.006, maxf(z1 - z0, 0.05)), _n_mat(Color(0.86, 0.84, 0.80))))

	var minor := _n_mat(Color(0.30, 0.29, 0.31))
	var q: float = maxf(spacing * 0.25, 0.02)
	var ticks: int = maxi(int((z1 - z0) / q), 1)
	for k in range(ticks + 1):
		add_child(_n_box(Vector3(-0.09, 0.014, z0 + float(k) * q),
			Vector3(0.11, 0.004, 0.014), minor))

	var major := _n_mat(tint)
	for i in range(count):
		add_child(_n_box(Vector3(0, 0.016, float(i) * spacing),
			Vector3(0.30, 0.005, 0.026), major))


## TALLY — index as a COUNT, cut into the cube itself. i strokes on the outward face, so
## the marks travel with the object: take cube [3] and its three strokes go with it, while
## the row keeps no memory of what was there. Slot [0] carries one horizontal bar, because
## zero is a mark you make rather than a mark you leave off.
func _notation_tally(cubes: Array, count: int, tint: Color) -> void:
	var mat := _n_mat(tint)
	for i in range(count):
		if i >= cubes.size():
			break
		var cube = cubes[i]
		if not (cube is Node3D):
			continue
		var host: Node3D = cube
		if i == 0:
			host.add_child(_n_box(Vector3(0.253, 0.50, 0.0),
				Vector3(0.008, 0.034, 0.26), mat))
			continue
		var pitch: float = 0.072
		var span: float = pitch * float(i - 1)
		for k in range(i):
			host.add_child(_n_box(Vector3(0.253, 0.50, -span * 0.5 + pitch * float(k)),
				Vector3(0.008, 0.30, 0.030), mat))


## PLATE — index as an ADDRESS belonging to the slot. A dark plaque on the floor at each
## foot, a bright rim inset in it, and a low card standing on the plaque reading [i]. The
## card is not billboarded: it is a plate on a body, not a tag in the air. Pick the cube up
## and the address is still there — the array has a hole, and the hole is numbered.
func _notation_plate(count: int, spacing: float, label_size: int, tint: Color) -> void:
	var plate := _n_mat(Color(0.16, 0.16, 0.18))
	var rim := _n_mat(Color(0.62, 0.60, 0.57))
	for i in range(count):
		var z: float = float(i) * spacing
		add_child(_n_box(Vector3(0, 0.006, z), Vector3(0.36, 0.012, 0.24), plate))
		add_child(_n_box(Vector3(0, 0.013, z), Vector3(0.32, 0.004, 0.20), rim))
		add_child(_n_box(Vector3(0, 0.075, z + 0.100), Vector3(0.26, 0.13, 0.010), plate))

		var card := Label3D.new()
		card.text = "[%d]" % i
		card.font_size = label_size
		card.pixel_size = 0.003
		card.outline_size = 0
		card.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		card.modulate = tint
		card.position = Vector3(0, 0.075, z + 0.107)
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
