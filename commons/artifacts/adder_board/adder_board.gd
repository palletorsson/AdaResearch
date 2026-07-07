# adder_board.gd
# "The Adder's Drafting Board" — vector ADDITION made tactile on a tilted
# navigator's chart table. Drag two glowing tip-pucks across an etched grid and
# watch a+b draw tip-to-tail AND as a parallelogram, with the arithmetic penned
# live in a floating two-column formula plate. Part of "The Vector Bench".
#
# @identity
# essence: a + b = (a.x+b.x, a.y+b.y). Place b's tail at a's tip; the resultant
#   reaches from origin straight to b's new tip. The tip-to-tail chain and the
#   parallelogram are the SAME truth, drawn two ways.
# desire: To compose. To drag two heading-arrows end to end and see the diagonal
#   you'd actually travel light up in gold the instant it lands on a grid line.
# critical_parameter: The two grabbable tip-pucks (a's tip, b's tip). Everything
#   else — the resultant, every number, the parallelogram ghosts — snaps to the
#   math the same frame. Inputs you move; results you never touch.
# triggers: drag a tip → a stretches, b's tail rides a's tip, the resultant
#   swings, all components recompute; toggle button flips chain-glow vs
#   parallelogram-glow; sliders set |a|,|b| to clean integers.
# emerges: The triangle inequality, discoverable while dragging: |a+b| <= |a|+|b|,
#   with a brass needle that pegs to equality only when a and b go parallel.
# truth: Addition is not about arrows. It is the fact that two displacements taken
#   in sequence equal one displacement — and that the detour is never shorter.
extends "res://algorithms/vectors/shared/vector_scene_base.gd"

class_name AdderBoard

# ── The Vector Bench colour language (fixed across the whole collection) ───────
const COLOR_A: Color = Color(1.0, 0.72, 0.22)        # input vector A = warm amber
const COLOR_B: Color = Color(1.0, 0.5, 0.15)         # input vector B = cooler orange
const COLOR_RESULT: Color = Color(0.55, 0.7, 1.0)    # derived/resultant = cyan-violet
const COLOR_DEGENERATE: Color = Color(1.0, 0.3, 0.25)# degenerate/parallel flips to red
const COLOR_BRASS: Color = Color(0.78, 0.62, 0.28)   # pedestal rim + inequality needle
const COLOR_SLATE: Color = Color(0.08, 0.09, 0.11)   # dark slate pedestal + slab
const COLOR_GRID: Color = Color(0.62, 0.68, 0.78, 0.55) # etched integer lattice

# ── Board geometry (logical, pre-scale) ───────────────────────────────────────
# The board is a tilted plane. We work in BOARD-LOCAL coordinates where +X runs
# right across the slab and +Y runs up the slab face; the origin pin sits at the
# lower-left. The whole board_root is tilted toward the player so the surface
# reads at a comfortable drafting angle.
const BOARD_TILT_DEG: float = 20.0
const BOARD_WIDTH: float = 1.4      # logical board width  (X span)
const BOARD_HEIGHT: float = 1.05    # logical board height (Y span)
const GRID_CELLS_X: int = 7         # integer lattice columns (10 cm cells at presentation)
const GRID_CELLS_Y: int = 5         # integer lattice rows
const ARROW_THICKNESS: float = 0.018

# How far up-and-right the origin pin sits from the slab's lower-left corner.
const ORIGIN_MARGIN_X: float = 0.18
const ORIGIN_MARGIN_Y: float = 0.16

# Preloaded interactable (toggle button); the slider scene comes from the base.
const BUTTON_SCENE := preload("res://commons/interactables/push_button.tscn")
const ControlPanelScript = preload("res://commons/ui/control_panel.gd")

# ── Tunable DNA (overridable via apply_grid_config) ───────────────────────────
var a_start: Vector2 = Vector2(3.0, 2.0)   # initial a in grid cells
var b_start: Vector2 = Vector2(1.0, 3.0)   # initial b in grid cells
var snap_to_grid: bool = true               # pucks soft-snap to integer cells
var pedestal_height: float = 0.9            # logical pedestal height

# ── Runtime node references ───────────────────────────────────────────────────
var _board_root: Node3D = null              # tilted plane that holds all 2D geometry
var _origin_node: Node3D = null             # the lower-left origin pin (board-local origin)

var _vector_a: Node3D = null                # grabbable: a from origin
var _vector_b: Node3D = null                # grabbable: b, drawn tip-to-tail off a's tip

var _arrow_a: Node3D = null                 # derived visual: a from origin (amber), under the puck
var _arrow_result: Node3D = null            # derived: a+b (NEVER grabbable)
var _arrow_b_chain: Node3D = null           # derived: b redrawn tip-to-tail (visual only)
var _ghost_a: Node3D = null                 # parallelogram ghost of a (off b's tip)
var _ghost_b: Node3D = null                 # parallelogram ghost of b (off a's tip)

var _label_a: Label3D = null
var _label_b: Label3D = null
var _label_result: Label3D = null
var _inequality_needle: Node3D = null       # brass needle: pegs at |a+b| == |a|+|b|

var _info_label: Label = null             # left column, live numbers
var _readout_label: Label3D = null          # billboarded headline above the action
var _inequality_label: Label3D = null       # billboarded |a+b| <= |a|+|b| readout

var _slider_a: Node3D = null
var _slider_b: Node3D = null
var _toggle_button: Node3D = null

# Cached endpoint nodes for fast per-frame reads.
var _a_start_node: Node3D = null
var _a_end_node: Node3D = null
var _b_start_node: Node3D = null
var _b_end_node: Node3D = null

# Emphasis state: false = tip-to-tail CHAIN glows; true = PARALLELOGRAM glows.
var _parallelogram_emphasis: bool = false

# Slider magnitude ranges (in grid cells).
const SLIDER_MIN_MAG: float = 0.5
const SLIDER_MAX_MAG: float = 6.0

# Throttle for text updates (matches VectorAddition.gd pattern).
var _time_since_text: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1

# Material cache local to this artifact (board chrome, distinct from base cache).
var _mat_cache: Dictionary = {}


# ═════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	super._ready()


func build_scene() -> void:
	# Scaled exhibition presentation. base_scale() == 0.5 * scale_multiplier.
	scale = base_scale()

	_build_pedestal()
	_build_board_root()
	_build_slab_and_grid()
	_build_origin_pin()
	_build_input_vectors()
	_build_derived_arrows()
	_build_parallelogram_ghosts()
	_build_board_labels()
	_build_inequality_needle()
	_build_info_panel()
	_build_readouts()
	_build_controls()

	_refresh_all()


func _process(delta: float) -> void:
	var a: Vector2 = _read_a()
	var b: Vector2 = _read_b()

	# If snapping is on, write the snapped values straight back into the input
	# endpoints so the pucks click to whole cells (release is handled by grip in
	# the grab layer; here we keep the math legible by snapping the read values).
	if snap_to_grid:
		var a_snap: Vector2 = Vector2(round(a.x), round(a.y))
		var b_snap: Vector2 = Vector2(round(b.x), round(b.y))
		# Only rewrite if the puck is not actively being dragged far from a cell;
		# we soft-snap by nudging toward the nearest integer each frame.
		a = a.lerp(a_snap, 0.35)
		b = b.lerp(b_snap, 0.35)
		_write_a(a)
		_write_b(b)

	_update_geometry(a, b)

	_time_since_text += delta
	if _time_since_text >= TEXT_UPDATE_INTERVAL:
		_time_since_text = 0.0
		_update_text(a, b)


# ═════════════════════════════════════════════════════════════════════════
# PEDESTAL + BOARD STRUCTURE
# ═════════════════════════════════════════════════════════════════════════

## Dark slate pedestal with a brass rim — the shared Vector Bench plinth.
func _build_pedestal() -> void:
	var ped_root: Node3D = Node3D.new()
	ped_root.name = "Pedestal"
	environment_root.add_child(ped_root)

	var slate_mat: StandardMaterial3D = _local_material(COLOR_SLATE, 0.0, 0.7, 0.25)
	var brass_mat: StandardMaterial3D = _local_material(COLOR_BRASS, 0.35, 0.35, 0.85)

	# Column.
	var column: MeshInstance3D = MeshInstance3D.new()
	var col_box: BoxMesh = BoxMesh.new()
	col_box.size = Vector3(0.5, pedestal_height, 0.4)
	column.mesh = col_box
	column.material_override = slate_mat
	column.position = Vector3(0.0, pedestal_height * 0.5, 0.0)
	ped_root.add_child(column)

	# Brass rim cap at the top of the column.
	var rim: MeshInstance3D = MeshInstance3D.new()
	var rim_box: BoxMesh = BoxMesh.new()
	rim_box.size = Vector3(0.58, 0.05, 0.48)
	rim.mesh = rim_box
	rim.material_override = brass_mat
	rim.position = Vector3(0.0, pedestal_height + 0.02, 0.0)
	ped_root.add_child(rim)

	# Base foot.
	var foot: MeshInstance3D = MeshInstance3D.new()
	var foot_box: BoxMesh = BoxMesh.new()
	foot_box.size = Vector3(0.62, 0.06, 0.52)
	foot.mesh = foot_box
	foot.material_override = slate_mat
	foot.position = Vector3(0.0, 0.03, 0.0)
	ped_root.add_child(foot)


## The tilted plane that all 2D board geometry lives in. Sits on the pedestal,
## tilted toward the player (-X rotation lifts the far edge so the face angles up
## toward the viewer standing in front, looking along -Z toward the board).
func _build_board_root() -> void:
	_board_root = Node3D.new()
	_board_root.name = "BoardRoot"
	# Place the board's lower edge at pedestal top, sitting slightly forward.
	_board_root.position = Vector3(0.0, pedestal_height + 0.07, 0.0)
	# Tilt the slab back so its face angles up toward the player.
	_board_root.rotation = Vector3(deg_to_rad(-(90.0 - BOARD_TILT_DEG)), 0.0, 0.0)
	add_child(_board_root)


## Maps board-local 2D grid coordinates (cells) to a 3D point in board_root local
## space. The slab plane is the board_root's local XY plane (z = small offset for
## arrows to sit just above the etched surface). Origin pin offsets are applied so
## the lattice starts up-and-right of the lower-left corner.
func _board_point(cell: Vector2, z_lift: float = 0.0) -> Vector3:
	var cell_w: float = BOARD_WIDTH / float(GRID_CELLS_X)
	var cell_h: float = BOARD_HEIGHT / float(GRID_CELLS_Y)
	var px: float = -BOARD_WIDTH * 0.5 + ORIGIN_MARGIN_X + cell.x * cell_w
	var py: float = -BOARD_HEIGHT * 0.5 + ORIGIN_MARGIN_Y + cell.y * cell_h
	return Vector3(px, py, z_lift)


## Inverse of _board_point for the X/Y axes: convert a board_root-local point back
## to grid cells (ignoring the small z lift).
func _point_to_cell(local_point: Vector3) -> Vector2:
	var cell_w: float = BOARD_WIDTH / float(GRID_CELLS_X)
	var cell_h: float = BOARD_HEIGHT / float(GRID_CELLS_Y)
	var cx: float = (local_point.x - (-BOARD_WIDTH * 0.5 + ORIGIN_MARGIN_X)) / cell_w
	var cy: float = (local_point.y - (-BOARD_HEIGHT * 0.5 + ORIGIN_MARGIN_Y)) / cell_h
	return Vector2(cx, cy)


## The black drafting slab plus an etched integer lattice (faint grid lines).
func _build_slab_and_grid() -> void:
	# Slab.
	var slab: MeshInstance3D = MeshInstance3D.new()
	slab.name = "Slab"
	var slab_box: BoxMesh = BoxMesh.new()
	slab_box.size = Vector3(BOARD_WIDTH + 0.12, BOARD_HEIGHT + 0.12, 0.03)
	slab.mesh = slab_box
	slab.material_override = _local_material(Color(0.05, 0.06, 0.08), 0.0, 0.55, 0.1)
	slab.position = Vector3(0.0, 0.0, -0.02)
	_board_root.add_child(slab)

	# Brass frame edge around the slab.
	var frame_mat: StandardMaterial3D = _local_material(COLOR_BRASS, 0.25, 0.4, 0.8)
	var fw: float = BOARD_WIDTH + 0.12
	var fh: float = BOARD_HEIGHT + 0.12
	var ft: float = 0.025
	for y_sign in [-1.0, 1.0]:
		var edge_h: MeshInstance3D = MeshInstance3D.new()
		var eh_box: BoxMesh = BoxMesh.new()
		eh_box.size = Vector3(fw + ft, ft, 0.035)
		edge_h.mesh = eh_box
		edge_h.material_override = frame_mat
		edge_h.position = Vector3(0.0, (fh * 0.5) * y_sign, -0.01)
		_board_root.add_child(edge_h)
	for x_sign in [-1.0, 1.0]:
		var edge_v: MeshInstance3D = MeshInstance3D.new()
		var ev_box: BoxMesh = BoxMesh.new()
		ev_box.size = Vector3(ft, fh, 0.035)
		edge_v.mesh = ev_box
		edge_v.material_override = frame_mat
		edge_v.position = Vector3((fw * 0.5) * x_sign, 0.0, -0.01)
		_board_root.add_child(edge_v)

	# Etched lattice: thin emissive lines on grid cell boundaries.
	var grid_mat: StandardMaterial3D = StandardMaterial3D.new()
	grid_mat.albedo_color = COLOR_GRID
	grid_mat.emission_enabled = true
	grid_mat.emission = Color(COLOR_GRID.r, COLOR_GRID.g, COLOR_GRID.b)
	grid_mat.emission_energy_multiplier = 0.4
	grid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var line_thick: float = 0.004
	var z_grid: float = 0.001
	# Vertical lines (constant cell.x).
	for ix in range(GRID_CELLS_X + 1):
		var v_line: MeshInstance3D = MeshInstance3D.new()
		var v_box: BoxMesh = BoxMesh.new()
		v_box.size = Vector3(line_thick, BOARD_HEIGHT, 0.001)
		v_line.mesh = v_box
		v_line.material_override = grid_mat
		var p0: Vector3 = _board_point(Vector2(float(ix), 0.0), z_grid)
		v_line.position = Vector3(p0.x, _board_point(Vector2(0, GRID_CELLS_Y * 0.5), 0).y, z_grid)
		_board_root.add_child(v_line)
	# Horizontal lines (constant cell.y).
	for iy in range(GRID_CELLS_Y + 1):
		var h_line: MeshInstance3D = MeshInstance3D.new()
		var h_box: BoxMesh = BoxMesh.new()
		h_box.size = Vector3(BOARD_WIDTH, line_thick, 0.001)
		h_line.mesh = h_box
		h_line.material_override = grid_mat
		var q0: Vector3 = _board_point(Vector2(0.0, float(iy)), z_grid)
		h_line.position = Vector3(_board_point(Vector2(GRID_CELLS_X * 0.5, 0), 0).x, q0.y, z_grid)
		_board_root.add_child(h_line)


## A glowing origin pin at the lower-left lattice corner (board-local origin).
func _build_origin_pin() -> void:
	_origin_node = Node3D.new()
	_origin_node.name = "OriginPin"
	_origin_node.position = _board_point(Vector2.ZERO, 0.01)
	_board_root.add_child(_origin_node)

	var pin: MeshInstance3D = MeshInstance3D.new()
	var pin_sphere: SphereMesh = SphereMesh.new()
	pin_sphere.radius = 0.022
	pin_sphere.height = 0.044
	pin.mesh = pin_sphere
	var pin_mat: StandardMaterial3D = StandardMaterial3D.new()
	pin_mat.albedo_color = Color.WHITE
	pin_mat.emission_enabled = true
	pin_mat.emission = Color.WHITE
	pin_mat.emission_energy_multiplier = 0.8
	pin.material_override = pin_mat
	_origin_node.add_child(pin)


# ═════════════════════════════════════════════════════════════════════════
# INPUT VECTORS (grabbable) + DERIVED ARROWS (never grabbable)
# ═════════════════════════════════════════════════════════════════════════

## Spawn the two grabbable input vectors and reparent them under the tilted board
## so their grab-puck endpoints rest on the slab surface. We do NOT use the base
## arrows for drawing the a/b lines (those use the line.tscn look); instead we
## keep the grab spheres as the draggable tip-pucks and draw our own emissive
## catapult-style arrows over the top via _update_geometry().
func _build_input_vectors() -> void:
	# spawn_vector adds the arrow as a child of self at origin*SCENE_SCALE; we then
	# reparent under the board root and place it at the origin pin so its local
	# endpoints live in board space.
	_vector_a = spawn_vector(Vector3.ZERO, Vector3(a_start.x, a_start.y, 0.0), COLOR_A, "vec_a", true)
	_vector_b = spawn_vector(Vector3.ZERO, Vector3(b_start.x, b_start.y, 0.0), COLOR_B, "vec_b", true)

	_reparent_to_board(_vector_a)
	_reparent_to_board(_vector_b)

	# Cache endpoint nodes for fast reads.
	_a_start_node = _vector_a.get_node_or_null("lineContainer/GrabSphere")
	_a_end_node = _vector_a.get_node_or_null("lineContainer/GrabSphere2")
	_b_start_node = _vector_b.get_node_or_null("lineContainer/GrabSphere")
	_b_end_node = _vector_b.get_node_or_null("lineContainer/GrabSphere2")

	# Pin both tails to the origin and seat the tips at their initial cells. The
	# endpoint positions are board-root local (the arrow root sits at origin pin).
	if _a_start_node:
		_a_start_node.position = Vector3.ZERO
	if _b_start_node:
		_b_start_node.position = Vector3.ZERO
	_write_a(a_start)
	_write_b(b_start)

	# Hide the default line.tscn visual mesh for b's tail-pinned line; we redraw
	# b tip-to-tail ourselves. We KEEP a's grab sphere visible (it is the puck),
	# but the underlying drawn line for both is replaced by our emissive arrows.
	# Leaving the line.tscn line visible would double-draw; dim it instead by
	# hiding its container mesh if present.
	_dim_default_line(_vector_a)
	_dim_default_line(_vector_b)


## Reparent a spawned arrow under the tilted board root, keeping it at the origin
## pin so its local endpoint coordinates are board-plane coordinates.
func _reparent_to_board(arrow: Node3D) -> void:
	if arrow == null or _board_root == null:
		return
	if arrow.get_parent():
		arrow.get_parent().remove_child(arrow)
	_board_root.add_child(arrow)
	arrow.position = _board_point(Vector2.ZERO, 0.012)
	arrow.rotation = Vector3.ZERO
	arrow.scale = Vector3.ONE


## Hide the line.tscn drawn segment + its "Length:" billboard so only our emissive
## board arrows show, while keeping the GrabSphere pucks interactive and visible.
## line.gd re-creates and re-positions its connection mesh every _process frame, so
## hiding the mesh once is not enough — we stop its processing entirely (the grab
## pucks stay interactive: grabbing lives on the snap_point bodies, not line.gd's
## per-frame loop) and we refresh our own math via _refresh_line() on writes.
func _dim_default_line(arrow: Node3D) -> void:
	if arrow == null:
		return
	var line_container: Node3D = arrow.get_node_or_null("lineContainer")
	if line_container == null:
		return
	# Stop line.gd from redrawing its metallic segment + glitch behaviour each frame.
	line_container.set_process(false)
	line_container.set_physics_process(false)
	# Free / hide the connection mesh and the "Length:" billboard it spawned.
	for child in line_container.get_children():
		if child is MeshInstance3D:
			child.visible = false
		elif child is Label3D:
			child.visible = false


## Derived arrows: the amber a (origin->a tip, sitting under a's grab puck), the
## resultant a+b, and the tip-to-tail copy of b. Built with the catapult arrow
## helper so they redraw flat on the board each frame. NEVER grabbable.
func _build_derived_arrows() -> void:
	# Amber a, drawn from the origin to a's tip. The grab puck rides at a's tip.
	_arrow_a = _create_arrow("AArrow", COLOR_A)
	_board_root.add_child(_arrow_a)

	_arrow_result = _create_arrow("ResultArrow", COLOR_RESULT)
	_board_root.add_child(_arrow_result)

	_arrow_b_chain = _create_arrow("BChainArrow", COLOR_B)
	_board_root.add_child(_arrow_b_chain)


## Dashed-ghost parallelogram copies (faint). _ghost_b is b drawn off a's tip,
## _ghost_a is a drawn off b's tip; together with the inputs they close the
## parallelogram whose shared diagonal is the resultant.
func _build_parallelogram_ghosts() -> void:
	_ghost_b = _create_arrow("GhostB", COLOR_B)
	_board_root.add_child(_ghost_b)
	_ghost_a = _create_arrow("GhostA", COLOR_A)
	_board_root.add_child(_ghost_a)
	_set_arrow_alpha(_ghost_a, 0.4)
	_set_arrow_alpha(_ghost_b, 0.4)


# ═════════════════════════════════════════════════════════════════════════
# LABELS, NEEDLE, PANEL, READOUTS
# ═════════════════════════════════════════════════════════════════════════

func _build_board_labels() -> void:
	_label_a = _make_label("a", COLOR_A, 22)
	_board_root.add_child(_label_a)
	_label_b = _make_label("b", COLOR_B, 22)
	_board_root.add_child(_label_b)
	_label_result = _make_label("a+b", COLOR_RESULT, 24)
	_board_root.add_child(_label_result)


## A thin brass needle near the resultant tip that pegs to a marked "equality"
## notch only when a and b are parallel (|a+b| == |a|+|b|). Built as a small
## rotating pointer; we rotate it by the slack between detour and straight length.
func _build_inequality_needle() -> void:
	_inequality_needle = Node3D.new()
	_inequality_needle.name = "InequalityNeedle"
	_board_root.add_child(_inequality_needle)

	# Dial backing.
	var dial: MeshInstance3D = MeshInstance3D.new()
	var dial_cyl: CylinderMesh = CylinderMesh.new()
	dial_cyl.top_radius = 0.05
	dial_cyl.bottom_radius = 0.05
	dial_cyl.height = 0.004
	dial.mesh = dial_cyl
	dial.material_override = _local_material(Color(0.12, 0.13, 0.16), 0.0, 0.6, 0.3)
	dial.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)  # face the board normal (+Z)
	_inequality_needle.add_child(dial)

	# The needle itself (a thin brass pointer along +Y from the dial centre).
	var needle: MeshInstance3D = MeshInstance3D.new()
	needle.name = "Needle"
	var n_box: BoxMesh = BoxMesh.new()
	n_box.size = Vector3(0.006, 0.05, 0.003)
	needle.mesh = n_box
	needle.material_override = _local_material(COLOR_BRASS, 0.6, 0.3, 0.8)
	needle.position = Vector3(0.0, 0.025, 0.005)
	_inequality_needle.add_child(needle)

	# Equality notch (small green tick at the "parallel" peg position, top-centre).
	var notch: MeshInstance3D = MeshInstance3D.new()
	var notch_box: BoxMesh = BoxMesh.new()
	notch_box.size = Vector3(0.004, 0.014, 0.003)
	notch.mesh = notch_box
	notch.material_override = _local_material(Color(0.4, 1.0, 0.5), 0.7, 0.3, 0.5)
	notch.position = Vector3(0.0, 0.052, 0.006)
	_inequality_needle.add_child(notch)


func _build_info_panel() -> void:
	# Floating two-column plate: live numbers left, substituting formula right.
	# Positioned above and behind the board so it does not occlude the slab.
	_info_label = create_info_panel(
		"Vector Addition",
		Vector3(0.0, pedestal_height + BOARD_HEIGHT + 0.9, -0.55),
		Vector2(2.6, 1.0),
		"a + b = (ax+bx, ay+by)",
		"tip-to-tail = parallelogram\n|a+b| <= |a| + |b|")


func _build_readouts() -> void:
	# Headline billboard above the action.
	_readout_label = create_readout(
		Vector3(0.0, pedestal_height + BOARD_HEIGHT + 0.45, 0.0), COLOR_RESULT)
	# Triangle-inequality billboard, just below the headline.
	_inequality_label = create_readout(
		Vector3(0.0, pedestal_height + BOARD_HEIGHT + 0.12, 0.0), COLOR_BRASS)
	if _inequality_label:
		_inequality_label.font_size = 44


# ═════════════════════════════════════════════════════════════════════════
# CONTROLS — precision sliders + chain/parallelogram toggle
# ═════════════════════════════════════════════════════════════════════════

func _build_controls() -> void:
	var rail_y: float = pedestal_height - 0.18
	var rail_z: float = 0.45

	# Seat |a|, |b| sliders + the toggle on the canonical Braun ControlPanel.
	var panel = ControlPanelScript.new()
	panel.name = "ControlPlate"
	panel.position = Vector3(0.0, rail_y, rail_z) * SCENE_SCALE
	add_child(panel)

	_slider_a = panel.add_slider("|a|", "|a|")
	_config_mag_slider(_slider_a, a_start.length(), "_on_slider_a_moved")

	# Toggle in the middle: CHAIN / PARALLELOGRAM.
	_toggle_button = panel.add_button("CHAIN / PARA")
	_toggle_button.set("pressed_color", COLOR_RESULT)
	_toggle_button.set("released_color", COLOR_A)
	if _toggle_button.has_signal("pressed"):
		_toggle_button.connect("pressed", Callable(self, "_on_toggle_pressed"))
	if _toggle_button.has_method("update_colors"):
		_toggle_button.call_deferred("update_colors")

	_slider_b = panel.add_slider("|b|", "|b|")
	_config_mag_slider(_slider_b, b_start.length(), "_on_slider_b_moved")


## Wire a magnitude slider to SLIDER_MIN_MAG..MAX_MAG with its start length + handler.
func _config_mag_slider(slider: Node3D, mag_length: float, handler: String) -> void:
	if slider == null:
		return
	if slider.has_method("set_range"):
		slider.call("set_range", SLIDER_MIN_MAG, SLIDER_MAX_MAG)
	if slider.has_method("set_normalized_value"):
		slider.call("set_normalized_value", inverse_lerp(SLIDER_MIN_MAG, SLIDER_MAX_MAG, mag_length))
	if slider.has_signal("slider_moved"):
		slider.connect("slider_moved", Callable(self, handler))


func _on_slider_a_moved(_v) -> void:
	if _slider_a == null:
		return
	var norm: float = 0.5
	if _slider_a.has_method("get_normalized_value"):
		norm = float(_slider_a.call("get_normalized_value"))
	var target_mag: float = lerpf(SLIDER_MIN_MAG, SLIDER_MAX_MAG, clampf(norm, 0.0, 1.0))
	var a: Vector2 = _read_a()
	var dir: Vector2 = a.normalized()
	if dir.length() < 0.001:
		dir = Vector2(1.0, 0.0)
	_write_a(dir * target_mag)


func _on_slider_b_moved(_v) -> void:
	if _slider_b == null:
		return
	var norm: float = 0.5
	if _slider_b.has_method("get_normalized_value"):
		norm = float(_slider_b.call("get_normalized_value"))
	var target_mag: float = lerpf(SLIDER_MIN_MAG, SLIDER_MAX_MAG, clampf(norm, 0.0, 1.0))
	var b: Vector2 = _read_b()
	var dir: Vector2 = b.normalized()
	if dir.length() < 0.001:
		dir = Vector2(0.0, 1.0)
	_write_b(dir * target_mag)


func _on_toggle_pressed() -> void:
	_parallelogram_emphasis = not _parallelogram_emphasis


# ═════════════════════════════════════════════════════════════════════════
# READ / WRITE the input vectors in grid-cell coordinates
# ═════════════════════════════════════════════════════════════════════════

## Read a in grid cells from its grab-puck endpoint (board-root local space).
func _read_a() -> Vector2:
	if _a_end_node == null:
		return a_start
	return _point_to_cell(_a_end_node.position) - _point_to_cell(Vector3.ZERO)


## Read b in grid cells. b's grab line is drawn from its own root; we read the tip
## offset directly (b is a free vector, tail position is cosmetic).
func _read_b() -> Vector2:
	if _b_end_node == null:
		return b_start
	return _point_to_cell(_b_end_node.position) - _point_to_cell(Vector3.ZERO)


## Write a (cells) into a's tip-puck endpoint position.
func _write_a(a: Vector2) -> void:
	if _a_end_node == null:
		return
	var p: Vector3 = _board_point(a, 0.012)
	var origin_p: Vector3 = _board_point(Vector2.ZERO, 0.012)
	_a_end_node.position = (p - origin_p)
	_refresh_line(_vector_a)


## Write b (cells) into b's tip-puck endpoint position. The b arrow ROOT is kept
## at the origin pin so b's endpoint stores b relative to origin; we redraw b
## tip-to-tail visually in _update_geometry().
func _write_b(b: Vector2) -> void:
	if _b_end_node == null:
		return
	var p: Vector3 = _board_point(b, 0.012)
	var origin_p: Vector3 = _board_point(Vector2.ZERO, 0.012)
	_b_end_node.position = (p - origin_p)
	_refresh_line(_vector_b)


## Intentionally a no-op for the line.tscn visual: we draw a/b with our own emissive
## board arrows (_arrow_a / _arrow_b_chain), so we must NOT call refresh_connections()
## here — that would respawn the hidden metallic segment. The grab-puck endpoints are
## positioned directly by _write_a / _write_b, so nothing else needs refreshing.
func _refresh_line(_arrow: Node3D) -> void:
	pass


# ═════════════════════════════════════════════════════════════════════════
# PER-FRAME GEOMETRY UPDATE
# ═════════════════════════════════════════════════════════════════════════

func _refresh_all() -> void:
	var a: Vector2 = _read_a()
	var b: Vector2 = _read_b()
	_update_geometry(a, b)
	_update_text(a, b)


func _update_geometry(a: Vector2, b: Vector2) -> void:
	var origin_p: Vector3 = _board_point(Vector2.ZERO, 0.012)
	var a_tip: Vector3 = _board_point(a, 0.012)
	var b_off_a: Vector3 = _board_point(a + b, 0.012)   # b's tip when drawn off a's tip
	var result_tip: Vector3 = _board_point(a + b, 0.014) # slightly proud so it reads on top
	var a_off_b: Vector3 = _board_point(b + a, 0.012)    # (same point — parallelogram corner)
	var b_tip_from_origin: Vector3 = _board_point(b, 0.012)

	# a drawn from the origin to a's tip (amber). The grab puck rides at a_tip.
	_position_arrow(_arrow_a, origin_p, a_tip)

	# b drawn tip-to-tail off a's tip (the chain copy).
	_position_arrow(_arrow_b_chain, a_tip, b_off_a)

	# Resultant a+b from origin (NEVER grabbable, snaps to math).
	_position_arrow(_arrow_result, origin_p, result_tip)

	# Parallelogram ghosts: ghost_b off a's tip already shown as chain; the ghost
	# pair we draw are the OTHER two sides — a copy of a drawn off b's tip, and a
	# copy of b drawn from origin — so both interpretations appear at once.
	_position_arrow(_ghost_a, b_tip_from_origin, a_off_b)   # a, off b's tip
	_position_arrow(_ghost_b, origin_p, b_tip_from_origin)  # b, from origin

	# Degenerate / parallel detection: when a and b are (anti)parallel the
	# parallelogram collapses and the triangle inequality hits equality. Flip the
	# resultant to the degenerate red and peg the needle.
	var is_parallel: bool = _is_parallel(a, b)
	_recolor_arrow(_arrow_result, COLOR_DEGENERATE if is_parallel else COLOR_RESULT)

	# Emphasis: glow the chain or the parallelogram ghosts.
	_set_arrow_alpha(_arrow_b_chain, 1.0 if not _parallelogram_emphasis else 0.35)
	_set_arrow_alpha(_ghost_a, 0.85 if _parallelogram_emphasis else 0.4)
	_set_arrow_alpha(_ghost_b, 0.85 if _parallelogram_emphasis else 0.4)

	# Board labels follow the geometry — each sits at the midpoint of its own arrow.
	if _label_a:
		_label_a.position = (origin_p + a_tip) * 0.5 + Vector3(0.04, 0.04, 0.02)
	if _label_b:
		_label_b.position = (a_tip + b_off_a) * 0.5 + Vector3(0.04, 0.0, 0.02)
	if _label_result:
		_label_result.position = result_tip + Vector3(0.05, 0.05, 0.02)

	# Inequality needle: place at the resultant tip and rotate by the "slack"
	# between the detour |a|+|b| and the straight |a+b|. At equality (parallel)
	# slack -> 0 and the needle points to the top notch.
	if _inequality_needle:
		_inequality_needle.position = result_tip + Vector3(0.12, 0.0, 0.02)
		var detour: float = a.length() + b.length()
		var straight: float = (a + b).length()
		var slack: float = 0.0
		if detour > 0.0001:
			slack = clampf(1.0 - straight / detour, 0.0, 1.0)  # 0 at equality
		var needle_node: Node3D = _inequality_needle.get_node_or_null("Needle")
		if needle_node:
			# 0 slack -> 0 rotation (point up to notch); more slack -> swing left.
			needle_node.rotation = Vector3(0.0, 0.0, slack * deg_to_rad(70.0))


func _update_text(a: Vector2, b: Vector2) -> void:
	var r: Vector2 = a + b
	var mag_a: float = a.length()
	var mag_b: float = b.length()
	var mag_r: float = r.length()
	var detour: float = mag_a + mag_b
	var angle_deg: float = rad_to_deg(atan2(r.y, r.x))

	# Left column: live numbers.
	if _info_label:
		var lines: Array = []
		lines.append("a = (%.1f, %.1f)" % [a.x, a.y])
		lines.append("b = (%.1f, %.1f)" % [b.x, b.y])
		lines.append("a+b = (%.1f, %.1f)" % [r.x, r.y])
		lines.append("|a| = %.2f" % mag_a)
		lines.append("|b| = %.2f" % mag_b)
		lines.append("|a+b| = %.2f" % mag_r)
		lines.append("angle = %.1f deg" % angle_deg)
		_info_label.text = "\n".join(lines)

	# Headline readout (substitutes the actual integers into the sum).
	if _readout_label:
		_readout_label.text = "(%.0f,%.0f) + (%.0f,%.0f) = (%.0f,%.0f)" % [
			a.x, a.y, b.x, b.y, r.x, r.y]

	# Triangle-inequality readout: |a+b| <= |a|+|b|, both numbers live.
	if _inequality_label:
		var rel: String = "="
		if mag_r < detour - 0.01:
			rel = "<"
		_inequality_label.text = "|a+b| %s |a|+|b|   (%.2f %s %.2f)" % [rel, mag_r, rel, detour]
		# Green when equality (parallel), brass otherwise.
		if _is_parallel(a, b):
			_inequality_label.modulate = Color(0.4, 1.0, 0.5)
		else:
			_inequality_label.modulate = COLOR_BRASS


# ═════════════════════════════════════════════════════════════════════════
# ARROW HELPERS — copied from catapult.gd (map-rotation-safe live arrows)
# ═════════════════════════════════════════════════════════════════════════

## Build an arrow (shaft cylinder + cone head). Copied from catapult.gd:292.
func _create_arrow(arrow_name: String, color: Color) -> Node3D:
	var arrow := Node3D.new()
	arrow.name = arrow_name

	var shaft := MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = ARROW_THICKNESS
	cylinder.bottom_radius = ARROW_THICKNESS
	cylinder.height = 1.0
	shaft.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	shaft.material_override = mat
	arrow.add_child(shaft)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = ARROW_THICKNESS * 2.5
	cone.height = ARROW_THICKNESS * 5.0
	head.mesh = cone
	head.material_override = mat
	arrow.add_child(head)

	return arrow


## Position an arrow from start to end. BOTH start and end are in the arrow's
## PARENT-local space (here: board_root-local, the same space _board_point returns
## and the grid lines / origin pin / grab-pucks live in). We build the arrow's
## local basis explicitly so its +Y axis runs start->end, then offset the shaft and
## head along that LOCAL +Y. This keeps the whole arrow flat on the board plane and
## correct under the tilted, scaled board_root — no global look_at round-trip, so
## the parent's rotation/scale can never throw the meshes off the segment.
func _position_arrow(arrow: Node3D, start: Vector3, end: Vector3) -> void:
	if arrow == null:
		return
	var dir: Vector3 = end - start
	var length: float = dir.length()
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true

	# Orthonormal basis (in parent-local space) with +Y == the start->end direction.
	var y_axis: Vector3 = dir / length
	var up: Vector3 = Vector3.FORWARD
	if absf(y_axis.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var x_axis: Vector3 = up.cross(y_axis).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()
	arrow.transform = Transform3D(Basis(x_axis, y_axis, z_axis), start)

	var shaft: Node3D = arrow.get_node("Shaft")
	var head: Node3D = arrow.get_node("Head")

	# The shaft + head meshes are modelled along local +Y; offset them along +Y so
	# the cone tip lands exactly on `end` and the shaft fills the gap to the head.
	var shaft_length: float = maxf(length - ARROW_THICKNESS * 5.0, 0.01)
	shaft.scale = Vector3(1.0, shaft_length, 1.0)
	shaft.position = Vector3(0.0, shaft_length * 0.5, 0.0)
	head.position = Vector3(0.0, length - ARROW_THICKNESS * 2.5, 0.0)


# ═════════════════════════════════════════════════════════════════════════
# MATERIAL / LABEL UTILITIES (from catapult.gd patterns)
# ═════════════════════════════════════════════════════════════════════════

func _local_material(color: Color, emission_energy: float = 0.0,
		roughness: float = 0.6, metallic: float = 0.2) -> StandardMaterial3D:
	var key: String = "%s|%.2f|%.2f|%.2f" % [str(color), emission_energy, roughness, metallic]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	_mat_cache[key] = mat
	return mat


func _make_label(text: String, color: Color, font_size: int = 22) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = font_size
	label.outline_size = maxi(2, int(font_size / 6.0))
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.0012
	label.no_depth_test = false
	label.render_priority = 60
	return label


## Set the albedo alpha on an arrow's shaft + head materials (for the ghost/
## emphasis fade). Duplicates the material the first time so we do not mutate a
## shared instance.
func _set_arrow_alpha(arrow: Node3D, alpha: float) -> void:
	if arrow == null:
		return
	for child_name in ["Shaft", "Head"]:
		var mesh: MeshInstance3D = arrow.get_node_or_null(child_name)
		if mesh == null:
			continue
		var mat := mesh.material_override as StandardMaterial3D
		if mat == null:
			continue
		if alpha < 0.999:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var c: Color = mat.albedo_color
		c.a = alpha
		mat.albedo_color = c


## Recolour an arrow's shaft + head (used to flip the resultant to degenerate red).
func _recolor_arrow(arrow: Node3D, color: Color) -> void:
	if arrow == null:
		return
	for child_name in ["Shaft", "Head"]:
		var mesh: MeshInstance3D = arrow.get_node_or_null(child_name)
		if mesh == null:
			continue
		var mat := mesh.material_override as StandardMaterial3D
		if mat == null:
			continue
		var keep_a: float = mat.albedo_color.a
		var new_c: Color = Color(color.r, color.g, color.b, keep_a)
		mat.albedo_color = new_c
		mat.emission = color


## True when a and b are (anti)parallel within a small angular tolerance — the
## degenerate state where the triangle inequality reaches equality.
func _is_parallel(a: Vector2, b: Vector2) -> bool:
	if a.length() < 0.05 or b.length() < 0.05:
		return false
	var cross: float = a.x * b.y - a.y * b.x
	# Normalise the cross by the magnitudes so the tolerance is angular.
	var norm_cross: float = absf(cross) / (a.length() * b.length())
	return norm_cross < 0.04


# ═════════════════════════════════════════════════════════════════════════
# GRID CONFIG
# ═════════════════════════════════════════════════════════════════════════

func apply_grid_config(config: Dictionary) -> void:
	if config == null:
		return
	# Let the base handle scale_multiplier (and rebuild if already built).
	super.apply_grid_config(config)

	var needs_local_rebuild: bool = false
	if config.has("a_start") and config["a_start"] is Vector2:
		a_start = config["a_start"]
		needs_local_rebuild = true
	if config.has("b_start") and config["b_start"] is Vector2:
		b_start = config["b_start"]
		needs_local_rebuild = true
	if config.has("snap_to_grid"):
		snap_to_grid = bool(config["snap_to_grid"])
	if config.has("pedestal_height"):
		pedestal_height = float(config["pedestal_height"])
		needs_local_rebuild = true

	# If the base already rebuilt for a scale change, our values are baked in on
	# the next build. Only force a local rebuild when a DNA knob changed but scale
	# did not (so the base did not already rebuild).
	if needs_local_rebuild and _scene_built and not config.has("scale_multiplier"):
		rebuild()
