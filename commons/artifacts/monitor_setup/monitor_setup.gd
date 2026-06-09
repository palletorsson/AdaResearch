extends Node3D
class_name MonitorSetup

# @identity
# essence: a cyberpunk multi-screen display rig — a vented computer tower on a dark metal
#   desk, a vertical clamp-pole bristling with angled neon poster-screens at staggered heights,
#   cables draping between the screens and the base. Blade Runner street-vendor energy meets a
#   security desk: a YELLOW "MOBS" ad up top, a white "RONIN-TX9" schematic, a magenta-blue
#   "NEON STRANGER" model poster, and a red "SECURITY BREACH" monitor watching from below.
# desire: a lab needs a corner that reads as a SURVEILLANCE / BROADCAST node — a place where
#   screens talk back. Not a single nameplate (info_screen does that) but a CLUSTER, a wall of
#   competing signals, the visual noise of a cyberpunk control booth condensed onto one footprint.
# critical_parameter: screen_glow + the four poster textures — the rig is defined by what its
#   screens SAY and how hard they glow. Dim them and it's furniture; light them and it's a node.
# triggers: _ready() draws 5 procedural ImageTextures once, builds the desk/tower/keyboard/device,
#   the clamp-pole with collar rings, 4 angled poster-screens + 1 base monitor, and draping cables.
#   apply_grid_config() re-reads DNA from the grid system and rebuilds.
# emerges: the room gains a watcher. The player feels observed, advertised-to, networked. The rig
#   is the structural form of MEDIATED PRESENCE — identity broadcast as a stack of glowing claims.
# needs: a floor to stand on (origin at the desk base, rig grows +Y); a viewer roughly on +Z to
#   read the screens; emissive rendering on so the glow lands.
# relationships: cousin to info_screen (one labeled screen vs. a competing wall of them); sibling
#   to surreal_lab (both are dense sci-fi instrument clusters); pairs with any cyberpunk street map.
# truth: a single screen informs; a STACK of screens persuades, surveils, and overwhelms. This rig
#   is the structural form of the BROADCAST WALL — too many signals, all lit from within, all true.

## A cyberpunk multi-screen display rig: a clamp-pole of angled neon poster-screens
## rising from a desk with a vented computer tower, keyboard, glowing device, and a
## "security breach" monitor, with cables draping between the screens and the base.
##
## All procedural. Origin sits at the desk base; the rig grows upward in +Y and the
## screens face roughly +Z. Five emissive ImageTextures are drawn once at build time.

# ── DNA: toggles ──────────────────────────────────────────────────────

@export_group("Toggles")
@export var show_cables: bool = true
@export var screen_glow: bool = true

@export_group("Glow")
@export_range(0.0, 4.0) var screen_emission: float = 1.3

# ── Constants ─────────────────────────────────────────────────────────

const TEX_W: int = 256
const TEX_H: int = 180

const DESK_W: float = 1.4
const DESK_D: float = 0.7
const DESK_H: float = 0.08
const DESK_TOP_Y: float = 0.9          # desktop surface height

const POLE_RADIUS: float = 0.035
const POLE_TOP_Y: float = 2.0          # pole reaches ~2m

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false
var _metal_mat: StandardMaterial3D
var _dark_mat: StandardMaterial3D
var _cable_mat: StandardMaterial3D

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_build_all()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_all()


func _read_metadata_overrides() -> void:
	if has_meta("config_show_cables"):
		show_cables = _to_bool(get_meta("config_show_cables"), show_cables)
	if has_meta("config_screen_glow"):
		screen_glow = _to_bool(get_meta("config_screen_glow"), screen_glow)
	if has_meta("config_screen_emission"):
		screen_emission = float(str(get_meta("config_screen_emission")))


func _to_bool(value, fallback: bool) -> bool:
	var s: String = str(value).strip_edges().to_lower()
	if s == "true" or s == "1" or s == "yes" or s == "on":
		return true
	if s == "false" or s == "0" or s == "no" or s == "off":
		return false
	return fallback


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build orchestration ───────────────────────────────────────────────

func _build_all() -> void:
	_built = true
	_build_shared_materials()
	_build_desk_base()
	_build_tower()
	_build_keyboard()
	_build_device()
	_build_pole()
	_build_screens()
	if show_cables:
		_build_cables()


func _build_shared_materials() -> void:
	_metal_mat = StandardMaterial3D.new()
	_metal_mat.albedo_color = Color(0.22, 0.23, 0.27)
	_metal_mat.metallic = 0.85
	_metal_mat.roughness = 0.35

	_dark_mat = StandardMaterial3D.new()
	_dark_mat.albedo_color = Color(0.07, 0.07, 0.09)
	_dark_mat.metallic = 0.4
	_dark_mat.roughness = 0.6

	_cable_mat = StandardMaterial3D.new()
	_cable_mat.albedo_color = Color(0.04, 0.04, 0.05)
	_cable_mat.metallic = 0.1
	_cable_mat.roughness = 0.85


# ── Desk base ─────────────────────────────────────────────────────────

func _build_desk_base() -> void:
	# Desktop slab
	var top := MeshInstance3D.new()
	top.name = "DeskTop"
	var tm := BoxMesh.new()
	tm.size = Vector3(DESK_W, DESK_H, DESK_D)
	top.mesh = tm
	top.material_override = _dark_mat
	top.position = Vector3(0.0, DESK_TOP_Y - DESK_H * 0.5, 0.0)
	add_child(top)

	# Two leg slabs (left, right)
	var leg_h: float = DESK_TOP_Y - DESK_H
	var leg_x: float = DESK_W * 0.5 - 0.08
	for i in 2:
		var leg := MeshInstance3D.new()
		leg.name = "DeskLeg_%d" % i
		var lm := BoxMesh.new()
		lm.size = Vector3(0.1, leg_h, DESK_D - 0.1)
		leg.mesh = lm
		leg.material_override = _metal_mat
		var sx: float = leg_x
		if i == 0:
			sx = -leg_x
		leg.position = Vector3(sx, leg_h * 0.5, 0.0)
		add_child(leg)


# ── Computer tower (vented front) ─────────────────────────────────────

func _build_tower() -> void:
	var tower_w: float = 0.26
	var tower_h: float = 0.5
	var tower_d: float = 0.42
	var base_x: float = -DESK_W * 0.5 + tower_w * 0.5 + 0.05
	var base_y: float = DESK_TOP_Y + tower_h * 0.5

	var tower := MeshInstance3D.new()
	tower.name = "Tower"
	var bm := BoxMesh.new()
	bm.size = Vector3(tower_w, tower_h, tower_d)
	tower.mesh = bm
	tower.material_override = _metal_mat
	tower.position = Vector3(base_x, base_y, 0.0)
	add_child(tower)

	# Vent slats on the front face (+Z), drawn as thin dark inset bars
	var vent_mat := StandardMaterial3D.new()
	vent_mat.albedo_color = Color(0.02, 0.02, 0.03)
	vent_mat.roughness = 0.95
	var front_z: float = tower_d * 0.5 + 0.002
	for i in 5:
		var vent := MeshInstance3D.new()
		vent.name = "TowerVent_%d" % i
		var vm := BoxMesh.new()
		vm.size = Vector3(tower_w * 0.62, 0.018, 0.01)
		vent.mesh = vm
		vent.material_override = vent_mat
		var vy: float = base_y + 0.14 - float(i) * 0.04
		vent.position = Vector3(base_x, vy, front_z)
		add_child(vent)

	# Power LED — small emissive dot
	var led := MeshInstance3D.new()
	led.name = "TowerLED"
	var lm := BoxMesh.new()
	lm.size = Vector3(0.02, 0.02, 0.01)
	led.mesh = lm
	led.material_override = _make_emissive_mat(Color(0.2, 1.0, 0.4), 2.0)
	led.position = Vector3(base_x, base_y - 0.18, front_z)
	add_child(led)


# ── Keyboard slab ─────────────────────────────────────────────────────

func _build_keyboard() -> void:
	var kb := MeshInstance3D.new()
	kb.name = "Keyboard"
	var km := BoxMesh.new()
	km.size = Vector3(0.4, 0.02, 0.16)
	kb.mesh = km
	var kb_mat := StandardMaterial3D.new()
	kb_mat.albedo_color = Color(0.12, 0.12, 0.14)
	kb_mat.metallic = 0.3
	kb_mat.roughness = 0.7
	kb.material_override = kb_mat
	kb.position = Vector3(0.18, DESK_TOP_Y + 0.02, DESK_D * 0.5 - 0.14)
	kb.rotation = Vector3(0.0, deg_to_rad(-6.0), 0.0)
	add_child(kb)

	# A faint grid of key bumps suggested with a few small boxes
	var key_mat := StandardMaterial3D.new()
	key_mat.albedo_color = Color(0.18, 0.18, 0.2)
	key_mat.roughness = 0.6
	for r in 2:
		for c in 6:
			var key := MeshInstance3D.new()
			key.name = "Key_%d_%d" % [r, c]
			var keym := BoxMesh.new()
			keym.size = Vector3(0.045, 0.012, 0.04)
			key.mesh = keym
			key.material_override = key_mat
			var kx: float = 0.18 - 0.13 + float(c) * 0.052
			var kz: float = DESK_D * 0.5 - 0.18 + float(r) * 0.05
			key.position = Vector3(kx, DESK_TOP_Y + 0.035, kz)
			add_child(key)


# ── Small glowing device ──────────────────────────────────────────────

func _build_device() -> void:
	var body := MeshInstance3D.new()
	body.name = "Device"
	var dm := BoxMesh.new()
	dm.size = Vector3(0.12, 0.06, 0.1)
	body.mesh = dm
	body.material_override = _dark_mat
	var dev_x: float = DESK_W * 0.5 - 0.16
	var dev_y: float = DESK_TOP_Y + 0.03
	var dev_z: float = -0.05
	body.position = Vector3(dev_x, dev_y, dev_z)
	add_child(body)

	# Emissive readout on top of the device using its own little texture
	var readout := MeshInstance3D.new()
	readout.name = "DeviceReadout"
	var rm := QuadMesh.new()
	rm.size = Vector2(0.09, 0.05)
	readout.mesh = rm
	var rmat := StandardMaterial3D.new()
	rmat.albedo_texture = _make_device_texture()
	rmat.emission_enabled = true
	rmat.emission_texture = rmat.albedo_texture
	rmat.emission_energy_multiplier = _glow_energy() * 1.1
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	readout.material_override = rmat
	readout.rotation = Vector3(deg_to_rad(-90.0), 0.0, 0.0)
	readout.position = Vector3(dev_x, dev_y + 0.031, dev_z)
	add_child(readout)


# ── Vertical clamp-pole + collar rings ────────────────────────────────

func _build_pole() -> void:
	var pole := MeshInstance3D.new()
	pole.name = "Pole"
	var cm := CylinderMesh.new()
	var pole_len: float = POLE_TOP_Y - DESK_TOP_Y
	cm.top_radius = POLE_RADIUS
	cm.bottom_radius = POLE_RADIUS
	cm.height = pole_len
	pole.mesh = cm
	pole.material_override = _metal_mat
	var pole_x: float = -0.1
	pole.position = Vector3(pole_x, DESK_TOP_Y + pole_len * 0.5, -0.18)
	add_child(pole)

	# Collar / clamp rings at staggered heights
	var collar_ys := [1.15, 1.45, 1.75, 1.95]
	for i in collar_ys.size():
		var collar := MeshInstance3D.new()
		collar.name = "Collar_%d" % i
		var cmesh := CylinderMesh.new()
		cmesh.top_radius = POLE_RADIUS * 2.0
		cmesh.bottom_radius = POLE_RADIUS * 2.0
		cmesh.height = 0.05
		collar.mesh = cmesh
		var collar_mat := StandardMaterial3D.new()
		collar_mat.albedo_color = Color(0.3, 0.31, 0.34)
		collar_mat.metallic = 0.9
		collar_mat.roughness = 0.3
		collar.material_override = collar_mat
		collar.position = Vector3(pole_x, float(collar_ys[i]), -0.18)
		add_child(collar)


# ── Screens: 4 poster-screens on the pole + 1 monitor on the base ──────

func _build_screens() -> void:
	var pole_x: float = -0.1
	var pole_z: float = -0.18

	# Each entry: texture, local pos offset, yaw deg, pitch deg, width, height
	# Top: YELLOW "MOBS" ad
	_add_poster_screen(
		"Screen_Mobs", _make_mobs_texture(),
		Vector3(pole_x + 0.02, 1.84, pole_z + 0.18),
		8.0, -10.0, 0.5, 0.36)

	# Mid-left: WHITE "RONIN-TX9" schematic
	_add_poster_screen(
		"Screen_Ronin", _make_ronin_texture(),
		Vector3(pole_x - 0.34, 1.5, pole_z + 0.14),
		28.0, -4.0, 0.42, 0.3)

	# Mid-right: magenta→blue "NEON STRANGER" poster
	_add_poster_screen(
		"Screen_Stranger", _make_stranger_texture(),
		Vector3(pole_x + 0.34, 1.52, pole_z + 0.14),
		-26.0, -4.0, 0.42, 0.3)

	# Lower-right wide MONITOR: red "SECURITY BREACH"
	_add_monitor_screen(
		"Screen_Breach", _make_breach_texture(),
		Vector3(0.42, DESK_TOP_Y + 0.27, -0.04),
		-12.0, 4.0, 0.5, 0.32)


func _add_poster_screen(node_name: String, tex: ImageTexture, pos: Vector3, yaw_deg: float, pitch_deg: float, w: float, h: float) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	root.rotation = Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0.0)
	add_child(root)

	# Backing plate (thin dark box)
	var back := MeshInstance3D.new()
	back.name = "Backing"
	var bm := BoxMesh.new()
	bm.size = Vector3(w + 0.03, h + 0.03, 0.02)
	back.mesh = bm
	back.material_override = _dark_mat
	root.add_child(back)

	# Emissive front face (quad)
	var face := MeshInstance3D.new()
	face.name = "Face"
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	face.mesh = qm
	face.material_override = _make_screen_material(tex)
	face.position = Vector3(0.0, 0.0, 0.012)
	root.add_child(face)

	# Small clamp arm linking it toward the pole
	var arm := MeshInstance3D.new()
	arm.name = "ClampArm"
	var am := BoxMesh.new()
	am.size = Vector3(0.025, 0.025, 0.18)
	arm.mesh = am
	arm.material_override = _metal_mat
	arm.position = Vector3(0.0, 0.0, -0.1)
	root.add_child(arm)


func _add_monitor_screen(node_name: String, tex: ImageTexture, pos: Vector3, yaw_deg: float, pitch_deg: float, w: float, h: float) -> void:
	var root := Node3D.new()
	root.name = node_name
	root.position = pos
	root.rotation = Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0.0)
	add_child(root)

	# Bezel — slightly chunkier than a poster
	var bezel := MeshInstance3D.new()
	bezel.name = "Bezel"
	var bm := BoxMesh.new()
	bm.size = Vector3(w + 0.05, h + 0.05, 0.04)
	bezel.mesh = bm
	bezel.material_override = _dark_mat
	root.add_child(bezel)

	# Emissive front face
	var face := MeshInstance3D.new()
	face.name = "Face"
	var qm := QuadMesh.new()
	qm.size = Vector2(w, h)
	face.mesh = qm
	face.material_override = _make_screen_material(tex)
	face.position = Vector3(0.0, 0.0, 0.022)
	root.add_child(face)

	# Stand neck + foot on the desk
	var neck := MeshInstance3D.new()
	neck.name = "MonitorNeck"
	var nm := BoxMesh.new()
	nm.size = Vector3(0.04, 0.18, 0.03)
	neck.mesh = nm
	neck.material_override = _metal_mat
	neck.position = Vector3(0.0, -h * 0.5 - 0.09, -0.02)
	root.add_child(neck)


# ── Cables: draping tubes from screens to base ────────────────────────

func _build_cables() -> void:
	# Cable A: from the "MOBS" top screen down to the tower
	_add_cable(Vector3(-0.08, 1.8, -0.02), Vector3(-0.5, DESK_TOP_Y + 0.05, 0.05), 0.018)
	# Cable B: from the "NEON STRANGER" right screen down to the device
	_add_cable(Vector3(0.22, 1.5, -0.04), Vector3(0.5, DESK_TOP_Y + 0.03, -0.05), 0.014)
	# Cable C: from the breach monitor to the tower
	_add_cable(Vector3(0.32, DESK_TOP_Y + 0.18, -0.06), Vector3(-0.42, DESK_TOP_Y + 0.02, 0.0), 0.014)


func _add_cable(p_from: Vector3, p_to: Vector3, radius: float) -> void:
	# Draping cable approximated as a chain of short cylinder segments along a
	# sagging arc (a simple downward-bowed quadratic between the two endpoints).
	var root := Node3D.new()
	root.name = "Cable"
	add_child(root)

	var segments: int = 8
	var sag: float = 0.18
	var prev: Vector3 = p_from
	for i in range(1, segments + 1):
		var t: float = float(i) / float(segments)
		var point: Vector3 = p_from.lerp(p_to, t)
		# Parabolic sag: max at t=0.5, zero at the ends
		point.y -= sag * (4.0 * t * (1.0 - t))
		_add_cable_segment(root, prev, point, radius)
		prev = point


func _add_cable_segment(parent: Node3D, a: Vector3, b: Vector3, radius: float) -> void:
	var seg := MeshInstance3D.new()
	seg.name = "Seg"
	var mid: Vector3 = (a + b) * 0.5
	var dir: Vector3 = b - a
	var length: float = dir.length()
	if length < 0.0001:
		return
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = length
	seg.mesh = cm
	seg.material_override = _cable_mat
	seg.position = mid
	# Orient the cylinder (default +Y axis) along dir
	var up := Vector3(0.0, 1.0, 0.0)
	var ndir: Vector3 = dir.normalized()
	var dot: float = up.dot(ndir)
	if dot < -0.9999:
		seg.rotation = Vector3(PI, 0.0, 0.0)
	elif dot < 0.9999:
		var axis: Vector3 = up.cross(ndir).normalized()
		var angle: float = acos(clampf(dot, -1.0, 1.0))
		seg.transform.basis = Basis(axis, angle)
	parent.add_child(seg)


# ── Material helpers ──────────────────────────────────────────────────

func _glow_energy() -> float:
	if screen_glow:
		return screen_emission
	return 0.0


func _make_emissive_mat(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.roughness = 0.6
	return mat


func _make_screen_material(tex: ImageTexture) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = _glow_energy()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


# ── Procedural screen textures ────────────────────────────────────────
# Drawing helpers operate on an Image. Faux text = small filled bars.

func _new_image(bg: Color) -> Image:
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	return img


func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var x0: int = clampi(x, 0, TEX_W)
	var y0: int = clampi(y, 0, TEX_H)
	var x1: int = clampi(x + w, 0, TEX_W)
	var y1: int = clampi(y + h, 0, TEX_H)
	for py in range(y0, y1):
		for px in range(x0, x1):
			img.set_pixel(px, py, color)


# A row of short bars to read as a line of text.
func _text_bars(img: Image, x: int, y: int, count: int, bar_w: int, bar_h: int, gap: int, color: Color) -> void:
	for i in count:
		var bx: int = x + i * (bar_w + gap)
		# Vary bar width a touch so it reads as words, not a comb
		var w: int = bar_w
		if i % 3 == 0:
			w = bar_w + 2
		if i % 5 == 4:
			w = maxi(2, bar_w - 2)
		_fill_rect(img, bx, y, w, bar_h, color)


func _radial_burst(img: Image, cx: int, cy: int, inner: Color, outer: Color) -> void:
	var max_d: float = sqrt(float(TEX_W * TEX_W + TEX_H * TEX_H)) * 0.5
	for py in TEX_H:
		for px in TEX_W:
			var dx: float = float(px - cx)
			var dy: float = float(py - cy)
			var d: float = sqrt(dx * dx + dy * dy) / max_d
			var t: float = clampf(d, 0.0, 1.0)
			img.set_pixel(px, py, inner.lerp(outer, t))


func _h_gradient(img: Image, left: Color, right: Color) -> void:
	for px in TEX_W:
		var t: float = float(px) / float(TEX_W - 1)
		var col: Color = left.lerp(right, t)
		for py in TEX_H:
			img.set_pixel(px, py, col)


# (1) YELLOW poster — big blocky dark "MOBS" + accent badge
func _make_mobs_texture() -> ImageTexture:
	var bg := Color(0.98, 0.82, 0.06)
	var img := _new_image(bg)
	var ink := Color(0.08, 0.07, 0.05)
	# Top strip "ALL NEW"
	_text_bars(img, 18, 16, 7, 14, 10, 6, ink)
	# Big blocky "MOBS" — four heavy glyph blocks with notches
	var gy: int = 56
	var gh: int = 62
	var gx: int = 22
	var gw: int = 44
	var ggap: int = 12
	for i in 4:
		var bx: int = gx + i * (gw + ggap)
		_fill_rect(img, bx, gy, gw, gh, ink)
		# carve a light notch to suggest a letter
		_fill_rect(img, bx + 12, gy + 14, gw - 24, gh - 34, bg)
	# Accent badge (red corner)
	_fill_rect(img, TEX_W - 56, 12, 44, 30, Color(0.85, 0.12, 0.18))
	_text_bars(img, TEX_W - 50, 22, 3, 9, 8, 4, Color(1, 1, 1))
	# bottom tag line
	_text_bars(img, 22, 150, 9, 12, 8, 5, ink)
	return ImageTexture.create_from_image(img)


# (2) WHITE poster — thin schematic lines + "RONIN-TX9" bars + yellow splash
func _make_ronin_texture() -> ImageTexture:
	var bg := Color(0.94, 0.95, 0.96)
	var img := _new_image(bg)
	var line := Color(0.1, 0.12, 0.16)
	# Header bars "RONIN-TX9"
	_text_bars(img, 16, 14, 9, 13, 11, 5, line)
	# Schematic frame
	_fill_rect(img, 28, 44, 200, 2, line)   # top
	_fill_rect(img, 28, 132, 200, 2, line)  # bottom
	_fill_rect(img, 28, 44, 2, 90, line)    # left
	_fill_rect(img, 226, 44, 2, 90, line)   # right
	# Internal schematic lines
	for i in 5:
		var yy: int = 56 + i * 16
		_fill_rect(img, 40, yy, 80 + i * 14, 1, line)
	# A couple of vertical leaders
	_fill_rect(img, 150, 50, 1, 76, line)
	_fill_rect(img, 190, 50, 1, 76, line)
	# Yellow splash accent
	_fill_rect(img, 178, 96, 40, 26, Color(0.98, 0.82, 0.06))
	# Footer code bars
	_text_bars(img, 30, 150, 11, 9, 8, 4, line)
	return ImageTexture.create_from_image(img)


# (3) magenta→blue gradient — faux face silhouette + "NEON STRANGER" bars
func _make_stranger_texture() -> ImageTexture:
	var img := _new_image(Color(0.5, 0.1, 0.6))
	_h_gradient(img, Color(0.85, 0.1, 0.6), Color(0.12, 0.25, 0.85))
	var glow := Color(0.95, 0.85, 1.0)
	# Face silhouette: head oval (block) + shoulders, in a darker tone
	var face := Color(0.06, 0.03, 0.12)
	_fill_rect(img, 96, 40, 64, 70, face)        # head block
	_fill_rect(img, 70, 104, 116, 50, face)      # shoulders
	# Glowing eyes
	_fill_rect(img, 110, 64, 14, 8, glow)
	_fill_rect(img, 134, 64, 14, 8, glow)
	# "NEON STRANGER" title bars (top)
	_text_bars(img, 16, 12, 10, 11, 10, 4, glow)
	# "MODEL 205X" bars (bottom)
	_text_bars(img, 24, 158, 8, 12, 9, 5, glow)
	return ImageTexture.create_from_image(img)


# (4) red radial-burst monitor — dark hooded blob + "SECURITY BREACH" bar
func _make_breach_texture() -> ImageTexture:
	var img := _new_image(Color(0.5, 0.0, 0.0))
	_radial_burst(img, TEX_W / 2, TEX_H / 2 + 10, Color(1.0, 0.25, 0.15), Color(0.25, 0.0, 0.02))
	var dark := Color(0.02, 0.0, 0.02)
	# Hooded figure: hood arc (block) + body
	_fill_rect(img, 100, 44, 56, 44, dark)       # hood top
	_fill_rect(img, 92, 80, 72, 64, dark)        # cloak body
	# Dark face void inside hood
	_fill_rect(img, 114, 60, 28, 24, Color(0.0, 0.0, 0.0))
	# "SECURITY BREACH" warning bar across the top
	_fill_rect(img, 0, 6, TEX_W, 22, Color(0.0, 0.0, 0.0, 0.85))
	_text_bars(img, 14, 11, 14, 11, 12, 3, Color(1.0, 0.25, 0.2))
	# Bottom scan bar
	_fill_rect(img, 0, TEX_H - 14, TEX_W, 10, Color(0.0, 0.0, 0.0, 0.7))
	_text_bars(img, 12, TEX_H - 12, 12, 10, 6, 4, Color(1.0, 0.4, 0.3))
	return ImageTexture.create_from_image(img)


# (5) small device readout — tiny graph + status bars
func _make_device_texture() -> ImageTexture:
	var img := _new_image(Color(0.02, 0.04, 0.06))
	var green := Color(0.2, 1.0, 0.5)
	# Baseline
	_fill_rect(img, 8, TEX_H - 40, TEX_W - 16, 2, green * 0.5)
	# A jagged "signal" as a row of vertical bars of varied height
	var heights := [30, 70, 45, 90, 55, 110, 60, 80, 40, 95, 50, 75]
	for i in heights.size():
		var bx: int = 14 + i * 19
		var bh: int = int(heights[i])
		_fill_rect(img, bx, TEX_H - 40 - bh, 10, bh, green)
	# Status text bars top
	_text_bars(img, 12, 14, 8, 12, 9, 5, green)
	return ImageTexture.create_from_image(img)
