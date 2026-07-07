extends Node3D
class_name TriangleWhiteboard

# @identity
# essence: a lab whiteboard with the SCIENCE of the triangle drawn on it in marker — the diagram, the angle sum, the rigidity note, the GPU fact. Where `pink_triangle` makes the triangle MEAN and `tensegrity_triangle` makes it STAND, this one makes it EXPLAINED: a hand-drawn triangle, the formula "ANGLES = 180°", "ONLY RIGID POLYGON", "3 POINTS -> 1 FACE". It is the plainest object in the salon and the most honest about its job — the board where the concept is taught, not performed.
# desire: it wants to be the flat truth behind the poetry. Every gem in the concept's salon dramatises something the whiteboard states once, cleanly: the 180° that the GPU and the geometry both obey, the rigidity Fuller built on, the fact that the entire rendered world is three-point faces. It wants the player to be able to turn from the felt thing to the stated thing and back — image, structure, symbol, and then the board that says what they all are.
# critical_parameter: diagram + the text lines. diagram selects which concept's sketch is drawn (here "triangle"); the lines carry the formulas. Collapse is a blank board (the lab with no teaching, only objects); the φ-move is the board that names the maths WITHOUT replacing the felt artifacts — explanation as a companion to encounter, not a substitute for it.
# triggers: _ready builds the board, frame, marker tray, the drawn triangle diagram and the marker text; apply_grid_config rebuilds on DNA change. Holds still — a whiteboard does not pulse.
# emerges: hung beside the triangle gems it becomes the answer key — the register that lets a curious player check the feeling against the fact. It is the lab's didactic voice made into an object, the "ten to explore" instinct turned into furniture: here is what the triangle IS, in marker, while the pink triangle and the truss and the GPU-face say what it means, holds, and builds.
# needs: a white surface [board, present]; a frame + tray so it reads as a real whiteboard [present]; a drawn diagram in the concept's own primitive vocabulary [marker lines, present]; the formulas stated plainly [TextMesh, present]
# relationships: the scientific-register companion to every gem in the Triangle salon (`three_points_triangle`, `tensegrity_triangle`, `pink_triangle`); sibling to the lab's generic `whiteboard` (this one is filled, that one is blank); template for `point_whiteboard`, `line_whiteboard` and every concept board downstream — the diagram swaps, the role stays.
# truth: a triangle's interior angles sum to 180° in the plane; it is the only rigid polygon; it is the single face the GPU truly draws. Those three facts are flat, true, and teachable, and the lab owes the player the board that says them — because the salon is not only an experience, it is a curriculum, and a curriculum needs a surface where the answer is written down in marker for anyone who wants to check.

## Triangle whiteboard — the scientific register of the concept.
##
## Built procedurally. Origin at the board centre; front faces +Z (hang
## on a wall). Marker diagram + formulas drawn flat on the surface.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Board")
@export var board_width: float = 1.5
@export var board_height: float = 1.05
@export var board_color: Color = Color(0.94, 0.94, 0.91)
@export var frame_color: Color = Color(0.20, 0.21, 0.24)

@export_group("Content")
## Which concept diagram to draw. "triangle" implemented; the field is
## here so point_whiteboard / line_whiteboard can reuse this script.
@export var diagram: String = "triangle"
@export var title: String = "THE TRIANGLE"
@export var line1: String = "ANGLES = 180°"
@export var line2: String = "ONLY RIGID POLYGON"
@export var line3: String = "3 POINTS -> 1 FACE"
@export var marker_color: Color = Color(0.12, 0.13, 0.17)
@export var accent_marker: Color = Color(0.16, 0.42, 0.92)

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _front_z: float = 0.0


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_board_width"):
		board_width = float(str(get_meta("config_board_width")))
	if has_meta("config_board_height"):
		board_height = float(str(get_meta("config_board_height")))
	if has_meta("config_diagram"):
		diagram = str(get_meta("config_diagram"))
	if has_meta("config_title"):
		title = str(get_meta("config_title"))
	if has_meta("config_line1"):
		line1 = str(get_meta("config_line1"))
	if has_meta("config_line2"):
		line2 = str(get_meta("config_line2"))
	if has_meta("config_line3"):
		line3 = str(get_meta("config_line3"))


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	var depth := 0.04
	_front_z = depth * 0.5

	# White board surface.
	var board := MeshInstance3D.new()
	board.name = "Board"
	var bm := BoxMesh.new()
	bm.size = Vector3(board_width, board_height, depth)
	board.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = board_color
	bmat.roughness = 0.6
	bmat.metallic = 0.0
	board.material_override = bmat
	add_child(board)

	# Frame — four thin bars around the edge.
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = frame_color
	fmat.roughness = 0.4
	fmat.metallic = 0.6
	var ft := 0.05
	var hw := board_width * 0.5
	var hh := board_height * 0.5
	_add_box("FrameTop", Vector3(0, hh + ft * 0.5, 0), Vector3(board_width + ft * 2, ft, depth + 0.01), fmat)
	_add_box("FrameBot", Vector3(0, -hh - ft * 0.5, 0), Vector3(board_width + ft * 2, ft, depth + 0.01), fmat)
	_add_box("FrameL", Vector3(-hw - ft * 0.5, 0, 0), Vector3(ft, board_height, depth + 0.01), fmat)
	_add_box("FrameR", Vector3(hw + ft * 0.5, 0, 0), Vector3(ft, board_height, depth + 0.01), fmat)
	# Marker tray along the bottom.
	_add_box("Tray", Vector3(0, -hh - ft * 0.3, depth * 0.5 + 0.04), Vector3(board_width * 0.6, 0.03, 0.08), fmat)

	# Text sizing: TextMesh world glyph height ≈ font_size * pixel_size.
	# font_size is fixed at 80 (see _add_text), so a 0.10 m title needs
	# pixel_size ≈ 0.00125, body ≈ 0.0008. All centred.
	# Title — top of the board.
	_add_text(title, Vector3(0, hh - 0.14, _front_z + 0.006), 0.00135, accent_marker, HORIZONTAL_ALIGNMENT_CENTER)

	# Diagram — centred, upper-middle.
	if diagram == "triangle":
		_draw_triangle_diagram()

	# Formula lines — centred column, lower portion, well-spaced so they
	# never overlap (glyph height ~0.06 m, line pitch ~0.13 m).
	_add_text(line1, Vector3(0, -0.10, _front_z + 0.006), 0.00100, marker_color, HORIZONTAL_ALIGNMENT_CENTER)
	_add_text(line2, Vector3(0, -0.24, _front_z + 0.006), 0.00075, marker_color, HORIZONTAL_ALIGNMENT_CENTER)
	_add_text(line3, Vector3(0, -0.37, _front_z + 0.006), 0.00075, marker_color, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_triangle_diagram() -> void:
	# A marker triangle centred in the upper-middle of the board, between
	# the title and the formula lines. Drawn flat in board-local XY.
	var cx := 0.0
	var cy := board_height * 0.13
	var s := minf(board_width, board_height) * 0.16
	var top := Vector2(cx, cy + s * 0.7)
	var bl := Vector2(cx - s * 0.85, cy - s * 0.55)
	var br := Vector2(cx + s * 0.85, cy - s * 0.55)
	_marker_line(top, bl)
	_marker_line(bl, br)
	_marker_line(br, top)
	# Corner dots (the three points).
	for p in [top, bl, br]:
		_add_dot(p, accent_marker)


func _marker_line(a: Vector2, b: Vector2) -> void:
	var mid := (a + b) * 0.5
	var d := b - a
	var length := d.length()
	if length < 0.001:
		return
	var ang := atan2(d.y, d.x)
	var m := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = Vector3(length, 0.014, 0.008)
	m.mesh = bx
	var mat := StandardMaterial3D.new()
	mat.albedo_color = marker_color
	mat.roughness = 0.7
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.position = Vector3(mid.x, mid.y, _front_z + 0.004)
	m.rotation = Vector3(0, 0, ang)
	add_child(m)


func _add_dot(p: Vector2, col: Color) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.018
	sm.height = 0.036
	m.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 1.2
	m.material_override = mat
	m.position = Vector3(p.x, p.y, _front_z + 0.008)
	add_child(m)


func _add_box(n: String, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var b := MeshInstance3D.new()
	b.name = n
	var bm := BoxMesh.new()
	bm.size = size
	b.mesh = bm
	b.material_override = mat
	b.position = pos
	add_child(b)


func _add_text(txt: String, pos: Vector3, scale: float, col: Color, align: int) -> void:
	if txt.strip_edges() == "":
		return
	var label := MeshInstance3D.new()
	var tm := TextMesh.new()
	tm.text = txt
	tm.font_size = 80
	tm.pixel_size = scale
	tm.depth = 0.0
	tm.horizontal_alignment = align
	label.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.7
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	label.material_override = mat
	label.position = pos
	add_child(label)
