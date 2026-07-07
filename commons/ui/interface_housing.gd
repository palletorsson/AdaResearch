@tool
## InterfaceHousing — the constructed-instrument FORMS that aren't the cabinet
## console: pedestal, tower, table, monitor_bank, grid_board. Each wraps the
## shared board primitive (ControlPanel) in a distinct stand so the form reads
## as its archetype, and forwards the board API so callers populate it the same
## way. Default Braun look (skins come later). See doc/INTERFACE_OVERHAUL.md.
class_name InterfaceHousing
extends Node3D

const ControlPanelScript := preload("res://commons/ui/control_panel.gd")

const STEEL := Color(0.56, 0.57, 0.60)
const TRIM := Color(0.30, 0.31, 0.34)
const DARK := Color(0.12, 0.13, 0.15)
const LED := Color(0.22, 0.92, 0.33)
const GRIDC := Color(0.35, 0.75, 0.95)

var form: String = "pedestal"
var _board   # ControlPanel — the shared primitive every form mounts
var _content: Node3D   # content host for container/apparatus forms (vitrine/tank/dish/frame/launcher)


func setup(p_form: String, title: String) -> void:
	form = p_form
	_board = ControlPanelScript.new()
	_board.name = "Board"
	_board.title = title
	add_child(_board)
	match form:
		"pedestal": _build_pedestal()
		"table": _build_table()
		"tower": _build_tower()
		"monitor_bank": _build_monitor_bank()
		"grid_board": _build_grid_board()
		"vitrine": _build_vitrine()
		"tank": _build_tank()
		"dish": _build_dish()
		"frame": _build_frame()
		"launcher": _build_launcher()
		_: _build_pedestal()


# ── board API forwarding ───────────────────────────────────────────────
func add_slider(label: String, param := "") -> Node3D: return _board.add_slider(label, param)
func add_button(label: String) -> Node3D: return _board.add_button(label)
func add_dial(label: String, param := "") -> Node3D: return _board.add_dial(label, param)
func add_joystick(label: String, param := "") -> Node3D: return _board.add_joystick(label, param)
func add_readout(text := "") -> Object: return _board.add_readout(text)
func set_title(t: String) -> void: _board.title = t
func board() -> Node3D: return _board
## The content host (vitrine/tank/dish/frame/launcher) — the artifact fills it
## with its scene (specimen, liquid, cells, suspended apparatus, trajectory).
func content() -> Node3D: return _content


# ── forms ──────────────────────────────────────────────────────────────
## PEDESTAL — slim podium with an angled HEAD continuous with the column; the
## board recesses INTO the head's face so board + pedestal read as ONE unit
## (not a panel perched on a post). Works for tall + short boards alike.
func _build_pedestal() -> void:
	_board.position = Vector3(0, 1.07, 0.14)   # proud of the head face
	# Angled head the board sits in (tilt matches the board's -20°).
	var head := _box(Vector3(0, 1.07, 0.03), Vector3(0.66, 0.52, 0.13), STEEL)
	head.rotation_degrees.x = -20.0
	_add(head, "Head")
	# Column continuous up into the head + a base foot.
	_add(_box(Vector3(0, 0.46, -0.05), Vector3(0.34, 0.94, 0.22), STEEL), "Column")
	_add(_box(Vector3(0, 0.03, -0.05), Vector3(0.46, 0.06, 0.34), TRIM), "Foot")


## TABLE — horizontal plan surface on legs; the board lies near-flat as a plan.
func _build_table() -> void:
	# A table with legs and a CONSOLE AT THE BACK — an upright riser/hutch at the
	# rear edge carrying the board (facing the front), leaving the surface as the
	# work area. Reads as a workbench-with-back-console.
	_add(_box(Vector3(0, 0.76, 0), Vector3(1.05, 0.05, 0.70), STEEL), "Surface")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add(_box(Vector3(sx * 0.46, 0.38, sz * 0.30), Vector3(0.06, 0.74, 0.06), TRIM), "Leg")
	# Back console riser at the rear edge, rising from the tabletop.
	_add(_box(Vector3(0, 1.0, -0.30), Vector3(0.82, 0.46, 0.09), STEEL), "BackConsole")
	_add(_box(Vector3(0, 0.79, -0.30), Vector3(0.88, 0.04, 0.13), TRIM), "BackConsoleFoot")
	# Board projects a bit OUT from the back console (a shelf bracket bridges it).
	_add(_box(Vector3(0, 0.88, -0.20), Vector3(0.5, 0.07, 0.18), TRIM), "BoardShelf")
	_board.position = Vector3(0, 1.04, -0.10)
	_board.tilt_degrees = -16.0


## TOWER — tall vertical rack; readout panel sits FLUSH and VERTICAL on the
## upper face (a tilted desk board would perch wrong), LED rows below (server_rack).
func _build_tower() -> void:
	_board.position = Vector3(0, 1.18, 0.17)
	_board.tilt_degrees = 0.0   # flush-vertical on the rack face, not a desk tilt
	_add(_box(Vector3(0, 0.72, -0.04), Vector3(0.58, 1.44, 0.36), STEEL), "Frame")
	_add(_box(Vector3(0, 0.02, -0.04), Vector3(0.66, 0.05, 0.44), TRIM), "Foot")
	# Stacked LED rows on the lower face — the "data tower" read.
	var y := 0.20
	var row := 0
	while y < 0.92:
		var on := (row * 7 + 3) % 5 != 0
		var strip := _box(Vector3(0, y, 0.145), Vector3(0.42, 0.03, 0.01), _emat(LED if on else DARK, 0.7 if on else 0.0))
		_add(strip, "LedRow")
		y += 0.10
		row += 1


## MONITOR BANK — desk console + a pole carrying extra angled screens (control_board).
func _build_monitor_bank() -> void:
	# Board recessed into an angled HEAD on the desk (integrated, not perched).
	_board.position = Vector3(0, 1.16, 0.30)
	_board.tilt_degrees = -24.0
	var head := _box(Vector3(0, 1.16, 0.20), Vector3(0.74, 0.48, 0.13), STEEL)
	head.rotation_degrees.x = -24.0
	_add(head, "Head")
	_add(_box(Vector3(0, 0.5, -0.06), Vector3(0.7, 1.0, 0.4), STEEL), "Desk")
	_add(_box(Vector3(0, 0.03, -0.06), Vector3(0.8, 0.06, 0.46), TRIM), "Foot")
	# Pole rooted INTO the desk (bracket), two screens MOUNTED on arms (not floating).
	_add(_box(Vector3(0, 1.02, -0.22), Vector3(0.18, 0.10, 0.18), TRIM), "PoleRoot")
	_add(_box(Vector3(0, 1.55, -0.22), Vector3(0.07, 1.2, 0.07), TRIM), "Pole")
	for i in [-1.0, 1.0]:
		_add(_box(Vector3(i * 0.22, 1.75, -0.20), Vector3(0.42, 0.05, 0.05), TRIM), "ScreenArm")
		var scr := _box(Vector3(i * 0.42, 1.75, -0.16), Vector3(0.5, 0.34, 0.03), _emat(DARK, 0.0))
		scr.rotation_degrees.y = -i * 22.0
		_add(scr, "Screen")
		var glow := _box(Vector3(i * 0.42, 1.75, -0.144), Vector3(0.44, 0.28, 0.006), _emat(GRIDC, 0.35))
		glow.rotation_degrees.y = -i * 22.0
		_add(glow, "ScreenGlow")


## GRID BOARD — upright stem; board readout up top, an N×N cell grid on a panel
## in FRONT of the stem (grid_editor / pattern peg board).
func _build_grid_board() -> void:
	_board.position = Vector3(0, 1.48, 0.0)
	_board.tilt_degrees = -6.0
	_add(_box(Vector3(0, 0.66, -0.10), Vector3(0.22, 1.32, 0.16), STEEL), "Stem")
	_add(_box(Vector3(0, 0.03, -0.10), Vector3(0.36, 0.06, 0.30), TRIM), "Foot")
	# Grid panel + cells, centred at chest height, proud of the stem face.
	var n := 5
	var cell := 0.11
	var span := n * cell
	var gy := 0.86           # grid centre height
	var gz := 0.06           # proud of the stem so it is never occluded
	_add(_box(Vector3(0, gy, gz - 0.012), Vector3(span + 0.05, span + 0.05, 0.02), DARK), "GridPanel")
	var o := -span * 0.5 + cell * 0.5
	for r in n:
		for c in n:
			var on := ((r * 3 + c * 5) % 7) < 3
			var q := _box(Vector3(o + c * cell, gy + o + r * cell, gz),
				Vector3(cell * 0.82, cell * 0.82, 0.006),
				_emat(GRIDC if on else Color(0.18, 0.20, 0.23), 0.5 if on else 0.0))
			_add(q, "Cell")


## VITRINE — a museum glass display CASE on a plinth; content sealed inside,
## with an info board on the plinth front (Air Music Display Case, Jelly Cube).
func _build_vitrine() -> void:
	_add(_box(Vector3(0, 0.45, 0), Vector3(0.78, 0.90, 0.52), STEEL), "Plinth")
	_add(_box(Vector3(0, 0.03, 0), Vector3(0.88, 0.06, 0.62), TRIM), "Foot")
	var cy := 1.20
	var cw := 0.66
	var ch := 0.58
	var cd := 0.44
	_add(_box(Vector3(0, cy, 0), Vector3(cw, ch, cd), _glass()), "GlassCase")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add(_box(Vector3(sx * cw * 0.5, cy, sz * cd * 0.5), Vector3(0.022, ch, 0.022), TRIM), "CaseEdge")
	_add(_box(Vector3(0, cy + ch * 0.5, 0), Vector3(cw + 0.04, 0.03, cd + 0.04), TRIM), "CaseCap")
	_add(_box(Vector3(0, cy - ch * 0.5, 0), Vector3(cw + 0.02, 0.02, cd + 0.02), TRIM), "CaseSill")
	# Board projects OUT from the plinth on a shelf bracket (a proud console).
	_add(_box(Vector3(0, 0.66, 0.34), Vector3(0.52, 0.10, 0.20), TRIM), "BoardShelf")
	_board.position = Vector3(0, 0.78, 0.42)
	_board.tilt_degrees = -16.0
	_content = Node3D.new(); _content.name = "Content"
	_content.position = Vector3(0, cy, 0)
	add_child(_content)


## TANK — an open glass vessel for liquid / field / layered content with a
## surface you look down into (Wave Interference, Viscosity Layers, Gravity Well).
func _build_tank() -> void:
	_add(_box(Vector3(0, 0.42, 0), Vector3(0.86, 0.84, 0.60), STEEL), "Stand")
	_add(_box(Vector3(0, 0.03, 0), Vector3(0.94, 0.06, 0.68), TRIM), "Foot")
	var ty := 1.06
	var tw := 0.74
	var th := 0.34
	var td := 0.52
	_add(_box(Vector3(0, ty, td * 0.5), Vector3(tw, th, 0.012), _glass()), "TankWall")
	_add(_box(Vector3(0, ty, -td * 0.5), Vector3(tw, th, 0.012), _glass()), "TankWall")
	_add(_box(Vector3(tw * 0.5, ty, 0), Vector3(0.012, th, td), _glass()), "TankWall")
	_add(_box(Vector3(-tw * 0.5, ty, 0), Vector3(0.012, th, td), _glass()), "TankWall")
	_add(_box(Vector3(0, ty - th * 0.5, 0), Vector3(tw, 0.02, td), TRIM), "TankFloor")
	# rim
	for sz in [-1.0, 1.0]:
		_add(_box(Vector3(0, ty + th * 0.5, sz * td * 0.5), Vector3(tw + 0.03, 0.025, 0.03), TRIM), "TankRim")
	for sx in [-1.0, 1.0]:
		_add(_box(Vector3(sx * tw * 0.5, ty + th * 0.5, 0), Vector3(0.03, 0.025, td + 0.03), TRIM), "TankRim")
	# Board projects OUT from the stand on a shelf bracket (a proud console).
	_add(_box(Vector3(0, 0.60, 0.36), Vector3(0.54, 0.10, 0.20), TRIM), "BoardShelf")
	_board.position = Vector3(0, 0.72, 0.46)
	_board.tilt_degrees = -16.0
	_content = Node3D.new(); _content.name = "Content"
	_content.position = Vector3(0, ty - th * 0.5 + 0.01, 0)   # at the tank floor
	add_child(_content)


## DISH — a round shallow basin on a column; top-down content (Game of Life
## Petri, Coin Toss, Dice Throw, Monte Carlo scatter).
func _build_dish() -> void:
	_add(_box(Vector3(0, 0.42, 0), Vector3(0.34, 0.84, 0.34), STEEL), "Column")
	_add(_box(Vector3(0, 0.03, 0), Vector3(0.50, 0.06, 0.50), TRIM), "Foot")
	var dy := 0.88
	var dr := 0.58   # wide enough that the rim-board doesn't cover the content
	_add(_cyl(Vector3(0, dy, 0), dr, 0.05, _mat(STEEL)), "DishFloor")
	_add(_cyl(Vector3(0, dy + 0.05, 0), dr + 0.02, 0.04, _glass(Color(0.55, 0.68, 0.78, 0.10))), "DishRim")
	# Board low on the near RIM, projecting OUT past the edge toward the reader.
	_board.position = Vector3(0, dy - 0.08, dr + 0.15)
	_board.tilt_degrees = -34.0
	_content = Node3D.new(); _content.name = "Content"
	_content.position = Vector3(0, dy + 0.03, 0)   # on the dish floor
	add_child(_content)


## FRAME — an open gantry suspending mechanical content (Newton's Cradle,
## Coupled Pendulums, Spring Network, Galton Board).
func _build_frame() -> void:
	var fw := 0.72
	var fh := 1.20
	var fd := 0.42
	_add(_box(Vector3(0, 0.04, 0), Vector3(fw + 0.22, 0.08, fd + 0.22), TRIM), "Base")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add(_box(Vector3(sx * fw * 0.5, fh * 0.5, sz * fd * 0.5), Vector3(0.05, fh, 0.05), STEEL), "Post")
	_add(_box(Vector3(0, fh, fd * 0.5), Vector3(fw + 0.07, 0.05, 0.05), STEEL), "TopBeam")
	_add(_box(Vector3(0, fh, -fd * 0.5), Vector3(fw + 0.07, 0.05, 0.05), STEEL), "TopBeam")
	_add(_box(Vector3(0, fh, 0), Vector3(0.05, 0.05, fd), STEEL), "TopCross")
	# Control console low at the front, BELOW the suspended content (no overlap).
	_board.position = Vector3(0, 0.42, fd * 0.5 + 0.22)
	_board.tilt_degrees = -20.0
	_content = Node3D.new(); _content.name = "Content"
	_content.position = Vector3(0, fh, 0)   # hangs from the top beam
	add_child(_content)


## LAUNCHER — an aimed launch apparatus: a tilted barrel on a base with a
## control board; content is the trajectory from the muzzle (Firework Launcher).
func _build_launcher() -> void:
	_add(_box(Vector3(0, 0.05, 0), Vector3(0.7, 0.10, 0.6), TRIM), "Base")
	_add(_box(Vector3(0, 0.34, -0.12), Vector3(0.42, 0.5, 0.4), STEEL), "Mount")
	var barrel := _box(Vector3(0, 0.78, 0.10), Vector3(0.18, 0.72, 0.18), STEEL)
	barrel.rotation_degrees.x = 42.0   # aim up-forward
	_add(barrel, "Barrel")
	var muzzle := _box(Vector3(0, 1.02, 0.34), Vector3(0.20, 0.07, 0.20), TRIM)
	muzzle.rotation_degrees.x = 42.0
	_add(muzzle, "Muzzle")
	# Control console on a riser at the front of the base (board no longer floats).
	_add(_box(Vector3(0, 0.30, 0.26), Vector3(0.54, 0.44, 0.16), STEEL), "ConsoleRiser")
	_board.position = Vector3(0, 0.52, 0.35)
	_board.tilt_degrees = -22.0
	_content = Node3D.new(); _content.name = "Content"
	_content.position = Vector3(0, 1.10, 0.42)   # at the muzzle, trajectory start
	add_child(_content)


# ── helpers ────────────────────────────────────────────────────────────
func _glass(c: Color = Color(0.55, 0.68, 0.78, 0.14)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.08; m.metallic = 0.0
	return m


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c; m.roughness = 0.6; m.metallic = 0.1
	return m


func _cyl(pos: Vector3, radius: float, height: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius; cm.bottom_radius = radius; cm.height = height
	mi.mesh = cm; mi.position = pos; mi.material_override = mat
	return mi


func _add(n: Node3D, nm: String) -> void:
	n.name = nm
	add_child(n)


## `mat` may be a StandardMaterial3D (e.g. from _emat) or a plain Color (matte).
func _box(pos: Vector3, size: Vector3, mat) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = pos
	if mat is Color:
		var m := StandardMaterial3D.new()
		m.albedo_color = mat; m.roughness = 0.6; m.metallic = 0.1
		mi.material_override = m
	else:
		mi.material_override = mat
	return mi


func _emat(c: Color, emission: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6; m.metallic = 0.1
	if emission > 0.0:
		m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = emission
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
