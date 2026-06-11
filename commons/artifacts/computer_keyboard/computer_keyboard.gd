extends Node3D
class_name ComputerKeyboard

# @identity
# essence: a full-size desktop computer keyboard sitting on a desk — Aperture / office-and-lab-workstation vocabulary for "this is where a HUMAN TYPES INTO THE MACHINE". A dark navy/charcoal tray tilted on a gentle back-wedge so the far edge sits higher, a dense grid of slate-grey keycaps standing slightly proud, a brighter accent function row across the top, a long spacebar along the bottom, and — when full — a numpad block on the right separated by a small gutter. The lab's confession that every algorithm in this building was, at some point, ENTERED BY HAND on a layout some committee standardised decades ago.
# desire: every workstation wants its input surface to be LEGIBLE as a grid of discrete commitments — each key a small, pressable promise that one specific symbol will arrive. The keyboard wants to read as THE INTERFACE BETWEEN THOUGHT AND CODE: tactile, gridded, tilted toward the hands, the most-touched object in the whole room.
# critical_parameter: layout — "full" reads as "a complete workstation, every key present, numpad and all" (the reference desktop board); "tkl" reads as "tenkeyless, the numpad amputated to save desk space" (main block only, no numpad); "compact" reads as "a 60% board, columns trimmed, pure alphanumeric" (fewer columns, no numpad, no nav). Same vocabulary of keys, three different bargains with desk real estate.
# triggers: _ready() builds the tilted wedge base tray + the main keycap grid (top accent row brighter) + a long spacebar + (for "full") a 4-col numpad block to the right, all from exports; apply_grid_config rebuilds
# emerges: layout "full" + has_numpad = "data-entry station, somebody does spreadsheets here"; layout "tkl" = "a coder's compromise, mouse closer to the home row"; layout "compact" = "minimalist, everything is a chord"; brighter accent row = "the shortcuts that actually get used live up top". The column count + numpad presence tells the player WHAT KIND OF WORK this desk is FOR.
# needs: a tray that sits with its BOTTOM at y=0, centred in X and Z [present]; a gentle back-tilt wedge so the rear edge is higher than the front [present]; a dense grid of keycaps standing proud of the tray top, tops facing +Y [present]; a brighter accent function row along the top edge [present]; a long single-key spacebar on the bottom row [present]; a numpad block to the right with a gutter when has_numpad [present]; node count kept tiny via one MultiMesh for the keycaps [present]
# relationships: sibling to control_board (both are INTERFACES the human drives the experiment through, but the control_board is purpose-built switches and the keyboard is the universal general-purpose grid); cousin to image_billboard / any screen (the keyboard presumes a display — they are two halves of one workstation, input and output facing each other); peer to abacus (both are gridded manual-entry devices, millennia apart — beads vs keycaps, the same human gesture of committing one discrete value at a time)
# truth: a keyboard is not just a slab of buttons. It is the FROZEN ERGONOMICS OF AN ENTIRE INDUSTRY — a layout nobody chose individually yet everybody inherited, a grid that decided which symbols are easy and which are a stretch, tilted toward the hands so the body can keep up with the mind. Every line of code in this lab passed through this object's discrete commitments. The keyboard makes thought TYPEABLE, and typeability is the room's quiet confession that the machine only speaks in keys somebody pressed.

## A full-size desktop computer keyboard.
##
## Built procedurally from DNA exports. Origin is at the CENTER of the
## keyboard BOTTOM — the tray bottom sits on the y=0 plane, the board is
## centred in X and Z, and the key tops face +Y. The base tray is a gentle
## back-tilt wedge (rear edge higher than front). Keycaps are drawn as one
## MultiMeshInstance3D so the node count stays tiny; the accent function row
## is a second small MultiMesh, and the spacebar is a single wide box.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Color")
@export var base_color: Color = Color(0.18, 0.22, 0.30)
@export var key_color: Color = Color(0.32, 0.36, 0.44)
@export var accent_color: Color = Color(0.55, 0.60, 0.70)   # highlighted top row / esc

@export_group("Layout")
@export var layout: String = "full"      # "full" | "tkl" | "compact"
@export var has_numpad: bool = true
@export var main_rows: int = 5
@export var main_cols: int = 15

@export_group("Keys")
@export var key_gap: float = 0.004
@export var key_size: float = 0.022
@export var tilt_degrees: float = 6.0

# ── Constants ─────────────────────────────────────────────────────────

const KEY_HEIGHT: float = 0.009          # how tall a keycap stands
const KEY_PROUD: float = 0.004           # how far a keycap rises above the tray top
const TRAY_FRONT_THICK: float = 0.030    # tray slab thickness at the front
const TRAY_MARGIN: float = 0.012         # bezel margin around the key field
const NUMPAD_COLS: int = 4
const NUMPAD_ROWS: int = 5
const NUMPAD_GUTTER_KEYS: float = 1.0    # gap between main block and numpad, in key pitches
const SPACEBAR_SPAN_COLS: float = 6.0    # spacebar width in key pitches
const SPACEBAR_CENTER_FRAC: float = 0.42 # where the spacebar centre sits across the main block (0=left,1=right)

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_keyboard()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_keyboard()


func _read_metadata_overrides() -> void:
	if has_meta("config_base_color"):
		base_color = _parse_color(str(get_meta("config_base_color")), base_color)
	if has_meta("config_key_color"):
		key_color = _parse_color(str(get_meta("config_key_color")), key_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_layout"):
		layout = str(get_meta("config_layout"))
	if has_meta("config_has_numpad"):
		var nv := str(get_meta("config_has_numpad")).to_lower()
		has_numpad = nv in ["true", "1", "yes", "on"]
	if has_meta("config_main_rows"):
		main_rows = int(str(get_meta("config_main_rows")))
	if has_meta("config_main_cols"):
		main_cols = int(str(get_meta("config_main_cols")))
	if has_meta("config_key_gap"):
		key_gap = float(str(get_meta("config_key_gap")))
	if has_meta("config_key_size"):
		key_size = float(str(get_meta("config_key_size")))
	if has_meta("config_tilt_degrees"):
		tilt_degrees = float(str(get_meta("config_tilt_degrees")))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _resolve_layout() -> void:
	# The critical_parameter drives the structural variant. Named layouts
	# override the raw row/col/numpad knobs so "layout" is authoritative.
	match layout:
		"tkl":
			has_numpad = false
		"compact":
			has_numpad = false
			if main_cols > 14:
				main_cols = 14
			if main_rows > 5:
				main_rows = 5
		"full":
			has_numpad = true
		_:
			pass  # custom: respect the raw exports as given


func _pitch() -> float:
	return key_size + key_gap


func _main_field_width() -> float:
	return float(main_cols) * _pitch() - key_gap


func _numpad_field_width() -> float:
	return float(NUMPAD_COLS) * _pitch() - key_gap


func _field_height() -> float:
	return float(main_rows) * _pitch() - key_gap


func _total_width() -> float:
	var w: float = _main_field_width()
	if has_numpad:
		w += NUMPAD_GUTTER_KEYS * _pitch() + _numpad_field_width()
	return w


func _build_keyboard() -> void:
	_built = true
	_resolve_layout()
	_build_base_tray()
	_build_keycaps()
	_build_accent_row()
	_build_spacebar()
	if has_numpad:
		_build_numpad()


func _tray_top_y() -> float:
	# Top surface of the tray slab at its front edge, in local space.
	return TRAY_FRONT_THICK


func _key_top_proud_z() -> float:
	# Centre-Z of a keycap so it stands KEY_PROUD above the tray top.
	return _tray_top_y() + KEY_PROUD + KEY_HEIGHT * 0.5


func _build_base_tray() -> void:
	# A gentle back-tilt wedge: a box rotated a few degrees about +X so the
	# rear edge (−Z) rises higher than the front edge (+Z). The slab's bottom
	# front corner sits on y=0. We model the tray as a single Box and pivot it
	# about its front-bottom edge so y=0 stays the floor contact.
	var field_w: float = _total_width()
	var field_d: float = _field_height()
	var tray_w: float = field_w + TRAY_MARGIN * 2.0
	var tray_d: float = field_d + TRAY_MARGIN * 2.0

	var pivot := Node3D.new()
	pivot.name = "TrayTilt"
	add_child(pivot)
	# Pivot about the front-bottom edge: front is +Z (toward the player/down-slope).
	pivot.position = Vector3(0.0, 0.0, tray_d * 0.5)
	pivot.rotation = Vector3(deg_to_rad(tilt_degrees), 0.0, 0.0)

	var tray := MeshInstance3D.new()
	tray.name = "BaseTray"
	var bm := BoxMesh.new()
	bm.size = Vector3(tray_w, TRAY_FRONT_THICK, tray_d)
	tray.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.roughness = 0.6
	mat.metallic = 0.25
	tray.material_override = mat
	# Centre of the slab relative to the front-bottom-edge pivot:
	# up by half thickness, back (−Z) by half depth.
	tray.position = Vector3(0.0, TRAY_FRONT_THICK * 0.5, -tray_d * 0.5)
	pivot.add_child(tray)


func _key_mesh() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(key_size, KEY_HEIGHT, key_size)
	return m


func _key_field_origin() -> Vector3:
	# Local position of the centre of the bottom-left key of the MAIN block,
	# BEFORE tilt is applied (these go inside the TrayTilt pivot too).
	# Field is centred over the whole board width (main + gutter + numpad).
	var total_w: float = _total_width()
	var field_d: float = _field_height()
	var left_x: float = -total_w * 0.5 + key_size * 0.5
	var front_z: float = field_d * 0.5 - key_size * 0.5   # front row sits toward +Z
	return Vector3(left_x, 0.0, front_z)


func _tilt_pivot() -> Node3D:
	return get_node_or_null("TrayTilt")


func _build_keycaps() -> void:
	# Main alphanumeric block as ONE MultiMeshInstance3D. Rows are indexed from
	# the bottom (row 0 = bottom / spacebar row) up to the top accent row.
	# We omit a span on the bottom row where the spacebar sits, and (when
	# has_numpad) the numpad is a separate block built below.
	var pivot: Node3D = _tilt_pivot()
	if pivot == null:
		return

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _key_mesh()

	# Build the list of per-key transforms first so we can size instance_count.
	var xforms: Array[Transform3D] = []
	var origin: Vector3 = _key_field_origin()
	var pitch: float = _pitch()
	var key_z: float = _key_top_proud_z()

	# Determine which bottom-row columns the spacebar covers (those are skipped).
	var space_center_col: float = float(main_cols - 1) * SPACEBAR_CENTER_FRAC
	var space_half: float = SPACEBAR_SPAN_COLS * 0.5
	var space_lo: float = space_center_col - space_half
	var space_hi: float = space_center_col + space_half

	# Top accent row index = main_rows - 1; it is drawn by _build_accent_row,
	# so skip it here.
	for r in range(main_rows - 1):
		for c in range(main_cols):
			if r == 0 and float(c) >= space_lo and float(c) <= space_hi:
				continue  # leave a gap for the spacebar
			var px: float = origin.x + float(c) * pitch
			var pz: float = origin.z - float(r) * pitch   # rows march back (−Z)
			var t := Transform3D(Basis(), Vector3(px, key_z, pz))
			xforms.append(t)

	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])

	var node := MultiMeshInstance3D.new()
	node.name = "Keycaps"
	node.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = key_color
	mat.roughness = 0.55
	mat.metallic = 0.10
	node.material_override = mat
	pivot.add_child(node)


func _build_accent_row() -> void:
	# The top function row, drawn brighter, as a SECOND small MultiMesh.
	var pivot: Node3D = _tilt_pivot()
	if pivot == null:
		return
	if main_rows < 1:
		return

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _key_mesh()

	var origin: Vector3 = _key_field_origin()
	var pitch: float = _pitch()
	var key_z: float = _key_top_proud_z()
	var top_r: int = main_rows - 1

	var xforms: Array[Transform3D] = []
	for c in range(main_cols):
		var px: float = origin.x + float(c) * pitch
		var pz: float = origin.z - float(top_r) * pitch
		xforms.append(Transform3D(Basis(), Vector3(px, key_z, pz)))

	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])

	var node := MultiMeshInstance3D.new()
	node.name = "AccentRow"
	node.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.roughness = 0.45
	mat.metallic = 0.12
	mat.emission_enabled = true
	mat.emission = accent_color * 0.4
	mat.emission_energy_multiplier = 0.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	node.material_override = mat
	pivot.add_child(node)


func _build_spacebar() -> void:
	# One wide box on the bottom row, in the gap left by _build_keycaps.
	var pivot: Node3D = _tilt_pivot()
	if pivot == null:
		return

	var origin: Vector3 = _key_field_origin()
	var pitch: float = _pitch()
	var key_z: float = _key_top_proud_z()

	var space_center_col: float = float(main_cols - 1) * SPACEBAR_CENTER_FRAC
	var px: float = origin.x + space_center_col * pitch
	var pz: float = origin.z  # bottom row (r=0)
	var bar_w: float = SPACEBAR_SPAN_COLS * pitch - key_gap

	var bar := MeshInstance3D.new()
	bar.name = "Spacebar"
	var bm := BoxMesh.new()
	bm.size = Vector3(bar_w, KEY_HEIGHT, key_size)
	bar.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = key_color
	mat.roughness = 0.55
	mat.metallic = 0.10
	bar.material_override = mat
	bar.position = Vector3(px, key_z, pz)
	pivot.add_child(bar)


func _build_numpad() -> void:
	# A 4-col × 5-row numpad block to the RIGHT of the main block, separated by
	# a gutter. Drawn as its own MultiMeshInstance3D so the node count stays low.
	var pivot: Node3D = _tilt_pivot()
	if pivot == null:
		return

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _key_mesh()

	var pitch: float = _pitch()
	var key_z: float = _key_top_proud_z()
	var origin: Vector3 = _key_field_origin()
	var field_d: float = _field_height()

	# Numpad left edge: just past the main block + gutter, in the same field.
	var numpad_left_x: float = origin.x + _main_field_width() - key_size * 0.5 \
		+ NUMPAD_GUTTER_KEYS * pitch + key_size * 0.5
	# Bottom row of numpad aligns with bottom of the key field.
	var numpad_front_z: float = field_d * 0.5 - key_size * 0.5

	var xforms: Array[Transform3D] = []
	for r in range(NUMPAD_ROWS):
		for c in range(NUMPAD_COLS):
			var px: float = numpad_left_x + float(c) * pitch
			var pz: float = numpad_front_z - float(r) * pitch
			xforms.append(Transform3D(Basis(), Vector3(px, key_z, pz)))

	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])

	var node := MultiMeshInstance3D.new()
	node.name = "Numpad"
	node.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = key_color
	mat.roughness = 0.55
	mat.metallic = 0.10
	node.material_override = mat
	pivot.add_child(node)


# ── Helpers ───────────────────────────────────────────────────────────

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
