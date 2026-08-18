## VR Tile Pattern Editor
## A VR workspace wrapping PatternTilePuzzle with a live-updating floor carpet.
## Edit patterns on a grid at desk height, see them tile across the floor in real-time.
## VR controllers: BY = cycle lattice, AX = cycle group, trigger = toggle symmetry mode.
## Desktop: M = toggle symmetry, Arrow keys = cycle lattice/group, 1-8 = select color.

# @identity
# essence: VR workspace = PatternTilePuzzle (tilted editing board at desk height) + live-updating floor carpet (MultiMesh tile texture regenerated on every pattern_changed signal) + optional wall preview panel
# desire: to design a floor while standing on it — to grab a colored cube, place it on the tilted editing board, and see the tile pattern propagate immediately across the floor beneath your feet, closing the loop between authorship and inhabitation
# critical_parameter: carpet_repeats — controls how many times the source tile repeats across the floor; at Vector2i(8,8) the floor becomes a demonstration of infinite repetition; at (2,2) the relationship between source and repeat is obvious
# triggers: PatternTilePuzzle emits cell_changed → _update_carpet_texture regenerates the carpet ImageTexture; VR BY buttons cycle wallpaper lattice; VR AX buttons cycle group within lattice; trigger toggles symmetry mode
# emerges: the live-update loop creates an authorship experience that traditional pattern editors lack — you feel yourself as both designer and inhabitant simultaneously, which embodies the array's core claim about index-to-value mapping
# needs: floor carpet MultiMesh [has]; wall preview panel [has]; label for current mode [has]; VR controller button routing [has via handle_vr_button forwarded to puzzle]; grab cubes for editing [has via PatternTilePuzzle]
# relationships: wraps PatternTilePuzzle as the editing logic; vr_tile_editor_mirror token uses MIRROR_XY repeat mode by default; connects to array_carpet for carpet-only display without editing
# truth: the tile editor is a live proof that a 4×4 array, held in hand, can generate an infinite floor — the editing board is the source code and the carpet is the running program

class_name VRTileEditor
extends Node3D

# --- Configuration ---

@export var tile_size: int = 4
@export var repeat_mode: int = 3  ## MIRROR_XY (kaleidoscope) by default

@export_group("Carpet")
@export var carpet_size: Vector2 = Vector2(3.0, 3.0)
@export var carpet_repeats: Vector2i = Vector2i(8, 8)
@export var carpet_offset: Vector3 = Vector3(0.0, 0.01, -1.5)

@export_group("Workspace")
@export var grid_height: float = 0.9  ## Table height in meters
@export var grid_tilt: float = -30.0  ## Tilt toward user (degrees)
@export var show_wall_preview: bool = true
@export var wall_preview_size: Vector2 = Vector2(2.0, 2.0)

@export_group("DNA")
## AXIS — WHICH BOUNDARY THE FIELD ADMITS. You edit a 4x4 tile in your hands and the floor
## under your feet becomes it, eight times over in each direction — and the floor arrives
## seamless, as if it had always been that, with nothing in it to say where one copy ends.
## That silence is the strongest claim the room makes and it is never argued for. What the
## carpet declares about its own repetition is the axis.
##
##   none      the legacy lineage, byte for byte — an unbroken field, the repeat denied
##   edge      only the outer kerb: the floor admits it is a made object with an end, and
##             still says nothing about repeating
##   cell      one unit cell framed and posted, once, among its copies — the tile you are
##             holding, found in the floor and named
##   lattice   a batten on every unit boundary: the floor re-read as the array it is
##
## Shared word for word with [[pattern_maker_station]], the same species one room over.
## One question, one vocabulary.
@export_enum("none", "edge", "cell", "lattice") var boundary: String = "none"
const BOUNDARIES: PackedStringArray = ["none", "edge", "cell", "lattice"]

# --- Internal ---

var _puzzle: Node  ## PatternTilePuzzle instance
var _floor_carpet: MeshInstance3D
var _wall_preview: MeshInstance3D
var _mode_label: Label3D
var _title_label: Label3D
var _left_controller: Node3D
var _right_controller: Node3D
var _carpet_material: StandardMaterial3D


func _ready() -> void:
	_create_puzzle()
	_create_floor_carpet()
	if show_wall_preview:
		_create_wall_preview()
	_create_labels()
	_find_controllers()
	# DNA: appended LAST, after the puzzle, the carpet, the wall preview and the labels, so
	# every child index above it is what it was. "none" adds nothing.
	_build_boundary()
	call_deferred("_apply_initial_config")
	call_deferred("_update_carpet_texture")


# --- Puzzle Setup ---

func _create_puzzle() -> void:
	var scene: PackedScene = load("res://commons/primitives/arrays/pattern_tile_puzzle.tscn")
	if not scene:
		push_error("VRTileEditor: Could not load pattern_tile_puzzle.tscn")
		return

	_puzzle = scene.instantiate()
	_puzzle.name = "PatternTilePuzzle"

	# Position at desk height, tilted toward user
	_puzzle.position = Vector3(0.0, grid_height, -0.3)
	_puzzle.rotation_degrees.x = grid_tilt

	# Connect signals for live carpet updates
	if _puzzle.has_signal("cell_changed"):
		_puzzle.cell_changed.connect(_on_cell_changed)
	if _puzzle.has_signal("repeat_mode_changed"):
		_puzzle.repeat_mode_changed.connect(_on_mode_changed)
	if _puzzle.has_signal("wallpaper_group_changed"):
		_puzzle.wallpaper_group_changed.connect(_on_group_changed)

	add_child(_puzzle)


func _apply_initial_config() -> void:
	if not _puzzle:
		return
	var config: Dictionary = {
		"tile_size": tile_size,
		"repeat_mode": repeat_mode,
	}
	if _puzzle.has_method("apply_grid_config"):
		_puzzle.apply_grid_config(config)
	_update_mode_label()


# --- Floor Carpet ---

func _create_floor_carpet() -> void:
	_floor_carpet = MeshInstance3D.new()
	_floor_carpet.name = "FloorCarpet"

	var quad: QuadMesh = QuadMesh.new()
	quad.size = carpet_size
	_floor_carpet.mesh = quad

	_floor_carpet.rotation_degrees.x = -90  # Lie flat on floor
	_floor_carpet.position = carpet_offset

	# Create shared material
	_carpet_material = StandardMaterial3D.new()
	_carpet_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_carpet_material.roughness = 0.85
	_floor_carpet.material_override = _carpet_material

	add_child(_floor_carpet)


func _update_carpet_texture() -> void:
	if not _puzzle or not is_instance_valid(_puzzle):
		return
	if not _puzzle.has_method("_get_tiled_color"):
		return

	var p_tile_size: int = _puzzle.tile_size if "tile_size" in _puzzle else tile_size
	var p_palette: Array = _puzzle.palette if "palette" in _puzzle else []
	if p_palette.is_empty():
		return

	# Texture resolution = repeats × tile_size
	var tex_w: int = carpet_repeats.x * p_tile_size
	var tex_h: int = carpet_repeats.y * p_tile_size
	if tex_w <= 0 or tex_h <= 0:
		return

	var image: Image = Image.create(tex_w, tex_h, false, Image.FORMAT_RGBA8)

	for py in range(tex_h):
		for px in range(tex_w):
			var color_idx: int = _puzzle._get_tiled_color(px, py)
			var color: Color = p_palette[color_idx] if color_idx < p_palette.size() else Color.WHITE
			image.set_pixel(px, py, color)

	var texture: ImageTexture = ImageTexture.create_from_image(image)

	# Update floor carpet
	if _carpet_material:
		_carpet_material.albedo_texture = texture

	# Update wall preview
	if _wall_preview and is_instance_valid(_wall_preview):
		var wall_mat: StandardMaterial3D = _wall_preview.material_override as StandardMaterial3D
		if wall_mat:
			wall_mat.albedo_texture = texture


# --- Wall Preview ---

func _create_wall_preview() -> void:
	_wall_preview = MeshInstance3D.new()
	_wall_preview.name = "WallPreview"

	var quad: QuadMesh = QuadMesh.new()
	quad.size = wall_preview_size
	_wall_preview.mesh = quad

	# Position to the left, angled toward user
	_wall_preview.position = Vector3(-2.0, 1.5, -2.0)
	_wall_preview.rotation_degrees.y = 30.0

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.85
	_wall_preview.material_override = mat

	add_child(_wall_preview)


# --- Labels ---

func _create_labels() -> void:
	# Title label
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.font_size = 24
	_title_label.text = "VR Tile Editor"
	_title_label.modulate = Color(0.9, 0.85, 0.7)
	_title_label.position = Vector3(0.0, grid_height + 0.35, -0.3)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_title_label)

	# Mode label
	_mode_label = Label3D.new()
	_mode_label.name = "ModeLabel"
	_mode_label.font_size = 20
	_mode_label.text = ""
	_mode_label.modulate = Color(1.0, 1.0, 0.8)
	_mode_label.position = Vector3(0.0, grid_height + 0.25, -0.3)
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_mode_label)

	_update_mode_label()


func _update_mode_label() -> void:
	if not _mode_label or not _puzzle:
		return

	var text: String = ""
	var sym_mode: int = _puzzle.symmetry_mode if "symmetry_mode" in _puzzle else 0

	if sym_mode == 1:  # WALLPAPER
		var group: int = _puzzle.wallpaper_group if "wallpaper_group" in _puzzle else 0
		var group_info: Dictionary = WallpaperGroups.get_group_info(group)
		if group_info:
			text = "%s — %s" % [group_info.get("name", "Unknown"), group_info.get("lattice", "")]
		else:
			text = "Wallpaper Group %d" % group
	else:  # LEGACY
		var mode_names: Array[String] = [
			"Simple Repeat", "Mirror X", "Mirror Y",
			"Mirror XY (Kaleidoscope)", "Rotate 90°", "Rotate 180°",
			"Brick X", "Brick Y", "Herringbone", "Diamond"
		]
		var mode: int = _puzzle.repeat_mode if "repeat_mode" in _puzzle else 0
		text = mode_names[mode] if mode < mode_names.size() else "Mode %d" % mode

	_mode_label.text = text


# --- VR Controller Discovery ---

func _find_controllers() -> void:
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	var root: Node = get_tree().root

	_left_controller = _find_node_recursive(root, "LeftController")
	if not _left_controller:
		_left_controller = _find_node_recursive(root, "LeftHand")

	_right_controller = _find_node_recursive(root, "RightController")
	if not _right_controller:
		_right_controller = _find_node_recursive(root, "RightHand")

	if _left_controller and _left_controller.has_signal("button_pressed"):
		_left_controller.button_pressed.connect(_on_button_pressed.bind("left_hand"))
	if _right_controller and _right_controller.has_signal("button_pressed"):
		_right_controller.button_pressed.connect(_on_button_pressed.bind("right_hand"))

	if _left_controller or _right_controller:
		print("VRTileEditor: Controllers found (L:%s R:%s)" % [
			_left_controller.name if _left_controller else "none",
			_right_controller.name if _right_controller else "none"
		])


func _find_node_recursive(node: Node, name_contains: String) -> Node:
	if node.name.containsn(name_contains):
		return node
	for child in node.get_children():
		var found: Node = _find_node_recursive(child, name_contains)
		if found:
			return found
	return null


# --- VR Button Handling ---

func _on_button_pressed(button: String, controller_name: String) -> void:
	if _puzzle and _puzzle.has_method("handle_vr_button"):
		_puzzle.handle_vr_button(button, controller_name)
	# Always refresh after button press (symmetry_mode has no signal)
	_update_mode_label()
	_update_carpet_texture()


# --- Signal Callbacks ---

func _on_cell_changed(_x: int, _y: int, _color_index: int) -> void:
	_update_carpet_texture()


func _on_mode_changed(_mode: int) -> void:
	_update_carpet_texture()
	_update_mode_label()


func _on_group_changed(_group: int) -> void:
	_update_carpet_texture()
	_update_mode_label()


# --- Desktop Keyboard Fallback ---

func _unhandled_input(event: InputEvent) -> void:
	if not _puzzle:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_M:
				# Toggle symmetry mode (legacy ↔ wallpaper)
				if _puzzle.has_method("handle_vr_button"):
					_puzzle.handle_vr_button("primary_click", "right_hand")
				_update_mode_label()
				_update_carpet_texture()
			KEY_LEFT:
				# Previous group within lattice
				if _puzzle.has_method("handle_vr_button"):
					_puzzle.handle_vr_button("ax_button", "left_hand")
				_update_mode_label()
				_update_carpet_texture()
			KEY_RIGHT:
				# Next group within lattice
				if _puzzle.has_method("handle_vr_button"):
					_puzzle.handle_vr_button("ax_button", "right_hand")
				_update_mode_label()
				_update_carpet_texture()
			KEY_UP:
				# Previous lattice
				if _puzzle.has_method("handle_vr_button"):
					_puzzle.handle_vr_button("by_button", "left_hand")
				_update_mode_label()
				_update_carpet_texture()
			KEY_DOWN:
				# Next lattice
				if _puzzle.has_method("handle_vr_button"):
					_puzzle.handle_vr_button("by_button", "right_hand")
				_update_mode_label()
				_update_carpet_texture()


# --- Grid System Integration ---

func apply_grid_config(config_data: Dictionary) -> void:
	# Handle VR editor-specific keys
	if config_data.has("carpet_size_x"):
		carpet_size.x = float(config_data["carpet_size_x"])
	if config_data.has("carpet_size_y"):
		carpet_size.y = float(config_data["carpet_size_y"])
	if config_data.has("carpet_repeats_x"):
		carpet_repeats.x = int(config_data["carpet_repeats_x"])
	if config_data.has("carpet_repeats_y"):
		carpet_repeats.y = int(config_data["carpet_repeats_y"])
	if config_data.has("grid_height"):
		grid_height = float(config_data["grid_height"])
	if config_data.has("grid_tilt"):
		grid_tilt = float(config_data["grid_tilt"])
	if config_data.has("show_wall_preview"):
		show_wall_preview = bool(config_data["show_wall_preview"])

	# Store puzzle-relevant keys for initial config
	if config_data.has("tile_size"):
		tile_size = int(config_data["tile_size"])
	if config_data.has("repeat_mode"):
		repeat_mode = int(config_data["repeat_mode"])

	# Delegate to puzzle if it's ready
	if _puzzle and _puzzle.has_method("apply_grid_config"):
		_puzzle.apply_grid_config(config_data)

	# Rebuild carpet mesh if size changed
	if _floor_carpet:
		var quad: QuadMesh = _floor_carpet.mesh as QuadMesh
		if quad and quad.size != carpet_size:
			quad.size = carpet_size

	if config_data.has("boundary"):
		var bnd_tok: String = str(config_data["boundary"]).strip_edges().to_lower()
		boundary = bnd_tok if BOUNDARIES.has(bnd_tok) else boundary
	# Rebuilt here as well as in _ready, because the grid calls this DEFERRED — a map token
	# arrives after the carpet has already been laid.
	_build_boundary()

	# Refresh
	_update_carpet_texture()
	_update_mode_label()


# ═══════════════════════════════════════════════════════════════════
# BOUNDARY — one axis, four answers to "what does this field admit"
# ═══════════════════════════════════════════════════════════════════
# Laid on the carpet plane and touching nothing else: the tile texture, the puzzle, the wall
# preview and the VR routing are untouched, and no collider is added — you can still walk
# across your own floor. "none" returns before building anything.

var _boundary_root: Node3D


func _build_boundary() -> void:
	if is_instance_valid(_boundary_root):
		_boundary_root.queue_free()
		_boundary_root = null
	if boundary == "none":
		return
	var sx: float = maxf(carpet_size.x, 0.2)
	var sz: float = maxf(carpet_size.y, 0.2)
	var nx: int = clampi(carpet_repeats.x, 1, 32)
	var nz: int = clampi(carpet_repeats.y, 1, 32)
	var cx: float = sx / float(nx)
	var cz: float = sz / float(nz)
	var cell: float = minf(cx, cz)

	var root := Node3D.new()
	root.name = "Boundary"
	root.position = carpet_offset + Vector3(0, 0.004, 0)
	add_child(root)
	_boundary_root = root

	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.87, 0.85, 0.79)
	stone.roughness = 0.55
	stone.metallic = 0.05

	match boundary:
		"edge":
			_boundary_kerb(root, sx, sz, cell, stone)
		"cell":
			_boundary_cell(root, sx, sz, cx, cz, nx, nz, stone)
		"lattice":
			_boundary_lattice(root, sx, sz, cx, cz, nx, nz, stone)
		_:
			pass


## EDGE — a kerb round the whole carpet, set just inside so it lands on the weave rather
## than floating off it.
func _boundary_kerb(root: Node3D, sx: float, sz: float, cell: float, mat: Material) -> void:
	var k: float = cell * 0.30
	var t: float = cell * 0.22
	var ex: float = sx * 0.5 - k * 0.5
	var ez: float = sz * 0.5 - k * 0.5
	root.add_child(_bnd_box(Vector3(0, t * 0.5, -ez), Vector3(sx, t, k), mat))
	root.add_child(_bnd_box(Vector3(0, t * 0.5, ez), Vector3(sx, t, k), mat))
	root.add_child(_bnd_box(Vector3(-ex, t * 0.5, 0), Vector3(k, t, sz), mat))
	root.add_child(_bnd_box(Vector3(ex, t * 0.5, 0), Vector3(k, t, sz), mat))


## CELL — ONE unit cell framed and posted, aligned to a real tile boundary (the tiles run
## from -side/2 in steps of one cell, so with an even repeat count the geometric centre is a
## JOIN, and a frame drawn there would straddle four copies).
func _boundary_cell(root: Node3D, sx: float, sz: float, cx: float, cz: float,
		nx: int, nz: int, mat: Material) -> void:
	var ax: float = -sx * 0.5 + (float(nx / 2) + 0.5) * cx
	var az: float = -sz * 0.5 + (float(nz / 2) + 0.5) * cz
	var cell: float = minf(cx, cz)
	var b: float = cell * 0.12
	var t: float = cell * 0.25
	var hx: float = cx * 0.5
	var hz: float = cz * 0.5
	root.add_child(_bnd_box(Vector3(ax, t * 0.5, az - hz), Vector3(cx + b, t, b), mat))
	root.add_child(_bnd_box(Vector3(ax, t * 0.5, az + hz), Vector3(cx + b, t, b), mat))
	root.add_child(_bnd_box(Vector3(ax - hx, t * 0.5, az), Vector3(b, t, cz + b), mat))
	root.add_child(_bnd_box(Vector3(ax + hx, t * 0.5, az), Vector3(b, t, cz + b), mat))
	var p: float = cell * 0.18
	var ph: float = cell * 0.55
	for raw_ox in [-1.0, 1.0]:
		var ox: float = float(raw_ox)
		for raw_oz in [-1.0, 1.0]:
			var oz: float = float(raw_oz)
			root.add_child(_bnd_box(Vector3(ax + ox * hx, ph * 0.5, az + oz * hz),
				Vector3(p, ph, p), mat))


## LATTICE — a batten on every internal unit boundary. The outer edge is left to `edge`, so
## the two values stay separate claims.
func _boundary_lattice(root: Node3D, sx: float, sz: float, cx: float, cz: float,
		nx: int, nz: int, mat: Material) -> void:
	var cell: float = minf(cx, cz)
	var b: float = cell * 0.10
	var t: float = cell * 0.12
	for i in range(1, nx):
		root.add_child(_bnd_box(Vector3(-sx * 0.5 + float(i) * cx, t * 0.5, 0),
			Vector3(b, t, sz), mat))
	for j in range(1, nz):
		root.add_child(_bnd_box(Vector3(0, t * 0.5, -sz * 0.5 + float(j) * cz),
			Vector3(sx, t, b), mat))


func _bnd_box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi
