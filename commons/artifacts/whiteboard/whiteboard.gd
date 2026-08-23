extends Node3D
class_name Whiteboard

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: a wall-mounted whiteboard with a dark frame, a near-white writing surface, and an optional small pen tray at the bottom. text_lines is baked as stacked ink rows ONTO the board face to render formulas, diagrams, or notes — making the curriculum visible on the architecture itself.
# desire: the curriculum should not live only in artifacts in the player's hand. It should also live on the wall — half-erased, partially formed, mid-thought — as if a researcher was here a moment ago and stepped out for coffee. Every lab gets a board.
# critical_parameter: text_lines — the whiteboard is the substrate; what's WRITTEN on it is the experiment. A blank board is staging. A board with "S = k log W" is a thesis. A board with five lines of crossed-out attempts is a process.
# triggers: _ready() builds surface, frame, tray, and bakes text_lines into stacked ink rows on the board face; apply_grid_config rebuilds (so map-data can drop fresh formulas onto walls without changing the scene file)
# emerges: empty whiteboard = "the lab is ready", whiteboard with one formula = "the lecture has begun", whiteboard with many lines including crossed-out attempts = "thinking happened here". The same prop carries an arc.
# needs: emissive-free near-white surface [present]; dark frame as 4 box pieces [present]; thin tray ledge at the bottom [present]; stacked rows of text BAKED into the board face via BakedText.make_text_block — ink on the surface, not floating Label3D [present]
# relationships: sibling to lab_room (the board fills the wall the chamber leaves blank); the whiteboard is the CURRICULUM-AS-SUBSTRATE — it is where Ada Research stops being navigation and becomes writing; cousin to art_history_gallery (both pin meaning to walls)
# truth: a whiteboard is the wall's confession that the room is a place of thought. It is the only surface in the lab that admits revision. Every formula on it is half-true and half-erasable, which is exactly what every formula in Ada Research is.

## A wall-mounted whiteboard with optional pre-rendered text.
##
## Built procedurally from DNA. The board faces +Z (mount on a -Z wall
## and the writing surface points into the room). text_lines is baked as
## stacked ink rows ONTO the surface, top-down, just proud of the board
## face (the integrated-text principle — no floating Label3D nodes).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var board_width: float = 2.4
@export var board_height: float = 1.2

@export_group("Color")
@export var frame_color: Color = Color(0.18, 0.18, 0.20)
@export var board_color: Color = Color(0.96, 0.96, 0.98)
@export var text_color: Color = Color(0.10, 0.10, 0.14)
@export var tray_color: Color = Color(0.55, 0.55, 0.58)

@export_group("Text")
@export var text_lines: PackedStringArray = PackedStringArray()
@export var text_size: int = 24

@export_group("Tray")
@export var show_tray: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const SURFACE_THICKNESS: float = 0.04
const FRAME_THICKNESS: float = 0.05
const FRAME_DEPTH: float = 0.06
const TRAY_DEPTH: float = 0.10  # how far the tray protrudes
const TRAY_HEIGHT: float = 0.04
const TEXT_MARGIN_LEFT: float = 0.10  # left padding for text rows
const TEXT_MARGIN_TOP: float = 0.10   # top padding for first row

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("ada_writable_board")
	_read_metadata_overrides()
	_build_board()


func write_surfaces() -> Array:
	## The writing face in GLOBAL space — draw_dot's pen writes ON this plane
	## (2026-08-23, "wire the pen to the whiteboard"). Computed per call, so a
	## re-posed board answers with its current face.
	var xf := global_transform
	return [{
		"origin": xf * Vector3(0.0, board_height * 0.5, SURFACE_THICKNESS),
		"normal": (xf.basis * Vector3(0, 0, 1)).normalized(),
		"u": (xf.basis * Vector3(1, 0, 0)).normalized(),
		"v": (xf.basis * Vector3(0, 1, 0)).normalized(),
		"half_w": board_width * 0.5,
		"half_h": board_height * 0.5,
	}]


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_board()


func _read_metadata_overrides() -> void:
	if has_meta("config_board_width"):
		board_width = float(str(get_meta("config_board_width")))
	if has_meta("config_board_height"):
		board_height = float(str(get_meta("config_board_height")))
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_board_color"):
		board_color = _parse_color(str(get_meta("config_board_color")), board_color)
	if has_meta("config_text_color"):
		text_color = _parse_color(str(get_meta("config_text_color")), text_color)
	if has_meta("config_tray_color"):
		tray_color = _parse_color(str(get_meta("config_tray_color")), tray_color)
	if has_meta("config_text_size"):
		text_size = int(str(get_meta("config_text_size")))
	if has_meta("config_text_lines"):
		# Accept comma-separated, pipe-separated, or newline-separated strings.
		var raw := str(get_meta("config_text_lines"))
		text_lines = _parse_text_lines(raw)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_board() -> void:
	_built = true
	_build_surface()
	_build_frame()
	if show_tray:
		_build_tray()
	_build_text_lines()


func _build_surface() -> void:
	# The writing surface — a thin near-white box, centered on origin in X/Y,
	# pushed forward in +Z so the back sits at z=0.
	var surf := MeshInstance3D.new()
	surf.name = "Surface"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(board_width, board_height, SURFACE_THICKNESS)
	surf.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = board_color
	mat.roughness = 0.25
	mat.metallic = 0.0
	surf.material_override = mat
	surf.position = Vector3(0.0, board_height * 0.5, SURFACE_THICKNESS * 0.5)
	add_child(surf)


func _build_frame() -> void:
	var frame_root := Node3D.new()
	frame_root.name = "Frame"
	add_child(frame_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.45
	mat.metallic = 0.4

	var ft := FRAME_THICKNESS
	var fd := FRAME_DEPTH
	var w := board_width
	var h := board_height
	var z_center := fd * 0.5  # frame extends from z=0 forward by fd

	# Top
	var top_f := MeshInstance3D.new()
	top_f.name = "FrameTop"
	var tm := BoxMesh.new()
	tm.size = Vector3(w + ft * 2.0, ft, fd)
	top_f.mesh = tm
	top_f.material_override = mat
	top_f.position = Vector3(0.0, h + ft * 0.5, z_center)
	frame_root.add_child(top_f)

	# Bottom
	var bot_f := MeshInstance3D.new()
	bot_f.name = "FrameBottom"
	var bm := BoxMesh.new()
	bm.size = Vector3(w + ft * 2.0, ft, fd)
	bot_f.mesh = bm
	bot_f.material_override = mat
	bot_f.position = Vector3(0.0, -ft * 0.5, z_center)
	frame_root.add_child(bot_f)

	# Left
	var left_f := MeshInstance3D.new()
	left_f.name = "FrameLeft"
	var lm := BoxMesh.new()
	lm.size = Vector3(ft, h, fd)
	left_f.mesh = lm
	left_f.material_override = mat
	left_f.position = Vector3(-(w * 0.5 + ft * 0.5), h * 0.5, z_center)
	frame_root.add_child(left_f)

	# Right
	var right_f := MeshInstance3D.new()
	right_f.name = "FrameRight"
	var rm := BoxMesh.new()
	rm.size = Vector3(ft, h, fd)
	right_f.mesh = rm
	right_f.material_override = mat
	right_f.position = Vector3(w * 0.5 + ft * 0.5, h * 0.5, z_center)
	frame_root.add_child(right_f)


func _build_tray() -> void:
	# Small ledge directly below the board, protruding forward to hold pens.
	var tray := MeshInstance3D.new()
	tray.name = "Tray"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(board_width * 0.95, TRAY_HEIGHT, TRAY_DEPTH)
	tray.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tray_color
	mat.roughness = 0.5
	mat.metallic = 0.3
	tray.material_override = mat
	# Tray sits just below the bottom frame, protruding forward.
	tray.position = Vector3(
		0.0,
		-FRAME_THICKNESS - TRAY_HEIGHT * 0.5,
		TRAY_DEPTH * 0.5
	)
	add_child(tray)


func _build_text_lines() -> void:
	# Pristine board: empty text_lines is intentional staging ("the lab is
	# ready"), so there is simply nothing to ink. Bail early.
	if text_lines.is_empty():
		return

	# Per-line world height, matching the old Label3D pitch so existing maps
	# render at the same scale: text_size px × pixel_size × 1.3 line-height.
	var pixel_size := 0.0035
	var line_height: float = text_size * pixel_size * 1.3
	var gap: float = line_height * 0.25
	var pitch: float = line_height + gap
	# Clamp visible lines to what fits between top/bottom margins so a long
	# lecture doesn't spill off the board (the old fit limit, gap-aware).
	var fitted: int = int((board_height - TEXT_MARGIN_TOP * 2.0) / pitch)
	var max_lines: int = fitted if fitted > 1 else 1
	var visible_count: int = text_lines.size() if text_lines.size() < max_lines else max_lines

	var lines: Array = []
	for i in range(visible_count):
		lines.append(str(text_lines[i]))

	# Bake the rows as ink ON the board face rather than floating Label3D
	# nodes in front of it (the fire_extinguisher / integrated-text principle).
	# make_text_block centres the stack on its own origin (+Z normal), top
	# line first, each quad max_width wide × line_height tall.
	var max_width: float = board_width * 0.9
	var block := BakedText.make_text_block(lines, text_color, line_height, max_width, gap)
	block.name = "TextLines"

	# Position the block origin so its TOP edge sits TEXT_MARGIN_TOP below the
	# top of the board (preserving the old top-anchored, lecture-from-the-top
	# read), centred in X, just proud of the writing surface in +Z.
	var block_total: float = pitch * float(visible_count)
	var top_y: float = board_height - TEXT_MARGIN_TOP            # board-local top edge minus margin
	var center_y: float = top_y - block_total * 0.5             # block is centred on its origin
	var z_face: float = SURFACE_THICKNESS + 0.005               # proud of the surface front
	block.position = Vector3(0.0, center_y, z_face)
	add_child(block)


# ── Helpers ───────────────────────────────────────────────────────────

func _parse_text_lines(s: String) -> PackedStringArray:
	# Accept pipe, newline, or semicolon separators (pipe most reliable
	# when coming through map_data's flat string config).
	var out: PackedStringArray = PackedStringArray()
	var parts: PackedStringArray
	if s.contains("|"):
		parts = s.split("|", false)
	elif s.contains("\n"):
		parts = s.split("\n", false)
	elif s.contains(";"):
		parts = s.split(";", false)
	else:
		parts = PackedStringArray([s])
	for p in parts:
		out.append(str(p).strip_edges())
	return out


func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
