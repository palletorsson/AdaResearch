extends Node3D
class_name FloorGrate

# @identity
# essence: a walkable industrial metal grating tile — Portal 2 / Half-Life under-foot vocabulary. A perimeter steel frame around a regular lattice of crossing flat bars (bar_count_x running along +X, bar_count_z running along +Z), all in dark steel. The bars sit BELOW the walking surface so the grate drops cleanly onto a floor. Optional Portal-orange safety stripe along the front edge, optional bar-by-bar brightness variation when wear_factor > 0. The lab's confession that the FLOOR itself is also infrastructure — air flows through it, things drain through it, something is HAPPENING below your feet.
# desire: every chamber wants its FLOOR to be more than ground. A grate says the floor is POROUS — air, light, water, and information can pass through it. The grate wants the player to look DOWN, to be reminded that the lab has a SUBSURFACE, that the chamber is one floor in a stack of architectural decisions. It wants its lattice to read as MEASURED, GRIDDED, REPEATED — visual rhythm under the body.
# critical_parameter: wear_factor — 0 reads as NEW INSTALL ("this lab was just built, the metal is uniform"), > 0 reads as USED INFRASTRUCTURE ("people have walked here, hosed it down, dropped things — the grate has remembered the lab's history"). The same lattice, two different times.
# triggers: _ready() builds perimeter frame + X-running bars + Z-running cross bars + optional accent stripe from exports, varying bar brightness if wear_factor > 0; apply_grid_config rebuilds
# emerges: small bar_count_x + bar_count_z = "coarse industrial grating, drain"; large counts = "fine catwalk mesh, walkable"; accent_visible=true reads as "this is a marked safety zone, do not cross"; wear_factor high = "the lab has aged here". Three knobs, very different rooms.
# needs: outer perimeter frame border (4 thin BoxMesh pieces) [present]; bar_count_x bars running along +X, evenly spaced across Z [present]; bar_count_z cross-bars running along +Z, evenly spaced across X [present]; bar brightness alternation when wear_factor > 0 [present]; optional accent edge stripe on the -Z side [present]
# relationships: sibling to ceiling_vent (both are the lab's POROUS SURFACES — the grate below, the vent above, air moves through both); cousin to cable_tray (cable_tray is the ceiling's organisational lattice, floor_grate is the floor's — both confess that the room is a SECTION through a larger building); peer to large_table (a table sits ON a floor — but a grate is the lab admitting that the FLOOR ITSELF is also a designed surface, not just a default ground)
# truth: a floor grate is not just a metal sheet you walk on. It is the lab admitting that DOWN is also a direction — that the experiment has SUBSURFACE physics: air return, water drainage, fallen-thing-retrieval, sound damping. The grate makes the floor SHARED with the architecture beneath it, and that shared-ness is the lab's most quiet confession that nothing in the chamber is truly self-contained.

## A walkable industrial floor grate.
##
## Built procedurally from DNA exports. Origin is at the CENTER OF THE
## TOP (WALKABLE) SURFACE — y=0 is the surface you walk on. The bars
## extend downward in -Y by grate_height, so the grate drops cleanly onto
## a floor surface.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var grate_width: float = 1.0           # X
@export var grate_depth: float = 1.0           # Z
@export var grate_height: float = 0.05         # total thickness, below walkable

@export_group("Lattice")
@export_range(2, 32, 1) var bar_count_x: int = 8
@export_range(2, 32, 1) var bar_count_z: int = 8

@export_group("Color")
@export var bar_color: Color = Color(0.20, 0.22, 0.25)
@export var frame_color: Color = Color(0.14, 0.14, 0.16)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

@export_group("Frame")
@export var frame_visible: bool = true

@export_group("Accent")
@export var accent_visible: bool = false

@export_group("Wear")
@export_range(0.0, 1.0, 0.05) var wear_factor: float = 0.0

# ── Constants ─────────────────────────────────────────────────────────

const FRAME_THICKNESS: float = 0.025
const BAR_THICKNESS: float = 0.012
const ACCENT_STRIP_HEIGHT: float = 0.008
const ACCENT_STRIP_THICKNESS: float = 0.012

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_grate()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_grate()


func _read_metadata_overrides() -> void:
	if has_meta("config_grate_width"):
		grate_width = float(String(get_meta("config_grate_width")))
	if has_meta("config_grate_depth"):
		grate_depth = float(String(get_meta("config_grate_depth")))
	if has_meta("config_grate_height"):
		grate_height = float(String(get_meta("config_grate_height")))
	if has_meta("config_bar_count_x"):
		bar_count_x = int(String(get_meta("config_bar_count_x")))
	if has_meta("config_bar_count_z"):
		bar_count_z = int(String(get_meta("config_bar_count_z")))
	if has_meta("config_bar_color"):
		bar_color = _parse_color(String(get_meta("config_bar_color")), bar_color)
	if has_meta("config_frame_color"):
		frame_color = _parse_color(String(get_meta("config_frame_color")), frame_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_frame_visible"):
		var fv := String(get_meta("config_frame_visible")).to_lower()
		frame_visible = fv in ["true", "1", "yes", "on"]
	if has_meta("config_accent_visible"):
		var av := String(get_meta("config_accent_visible")).to_lower()
		accent_visible = av in ["true", "1", "yes", "on"]
	if has_meta("config_wear_factor"):
		wear_factor = float(String(get_meta("config_wear_factor")))


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_grate() -> void:
	_built = true
	if frame_visible:
		_build_frame()
	_build_bars_x()
	_build_bars_z()
	if accent_visible:
		_build_accent_stripe()


func _make_frame_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.roughness = 0.5
	mat.metallic = 0.7
	return mat


func _build_frame() -> void:
	# Four thin box pieces around the outer edge. The frame's top sits at y=0
	# (the walkable surface). The frame extends downward by grate_height.
	var root := Node3D.new()
	root.name = "Frame"
	add_child(root)

	var mat := _make_frame_mat()
	var center_y: float = -grate_height * 0.5

	# Front (+Z)
	var f := MeshInstance3D.new()
	f.name = "FrameFront"
	var fm := BoxMesh.new()
	fm.size = Vector3(grate_width, grate_height, FRAME_THICKNESS)
	f.mesh = fm
	f.material_override = mat
	f.position = Vector3(0.0, center_y, grate_depth * 0.5 - FRAME_THICKNESS * 0.5)
	root.add_child(f)

	# Back (-Z)
	var b := MeshInstance3D.new()
	b.name = "FrameBack"
	var bm := BoxMesh.new()
	bm.size = Vector3(grate_width, grate_height, FRAME_THICKNESS)
	b.mesh = bm
	b.material_override = mat
	b.position = Vector3(0.0, center_y, -grate_depth * 0.5 + FRAME_THICKNESS * 0.5)
	root.add_child(b)

	# Left (-X)
	var l := MeshInstance3D.new()
	l.name = "FrameLeft"
	var lm := BoxMesh.new()
	lm.size = Vector3(FRAME_THICKNESS, grate_height, grate_depth - FRAME_THICKNESS * 2.0)
	l.mesh = lm
	l.material_override = mat
	l.position = Vector3(-grate_width * 0.5 + FRAME_THICKNESS * 0.5, center_y, 0.0)
	root.add_child(l)

	# Right (+X)
	var r := MeshInstance3D.new()
	r.name = "FrameRight"
	var rm := BoxMesh.new()
	rm.size = Vector3(FRAME_THICKNESS, grate_height, grate_depth - FRAME_THICKNESS * 2.0)
	r.mesh = rm
	r.material_override = mat
	r.position = Vector3(grate_width * 0.5 - FRAME_THICKNESS * 0.5, center_y, 0.0)
	root.add_child(r)


func _interior_min_x() -> float:
	var inset: float = (FRAME_THICKNESS if frame_visible else 0.0)
	return -grate_width * 0.5 + inset


func _interior_max_x() -> float:
	var inset: float = (FRAME_THICKNESS if frame_visible else 0.0)
	return grate_width * 0.5 - inset


func _interior_min_z() -> float:
	var inset: float = (FRAME_THICKNESS if frame_visible else 0.0)
	return -grate_depth * 0.5 + inset


func _interior_max_z() -> float:
	var inset: float = (FRAME_THICKNESS if frame_visible else 0.0)
	return grate_depth * 0.5 - inset


func _vary_bar_color(index: int, total: int) -> Color:
	# Mix bar_color toward brighter / duller alternates based on wear_factor.
	if wear_factor <= 0.0:
		return bar_color
	# Alternate brightness pattern, magnitude proportional to wear_factor.
	var mag: float = clamp(wear_factor, 0.0, 1.0) * 0.25
	var phase: int = index % 3
	var delta: float = 0.0
	if phase == 0:
		delta = mag
	elif phase == 1:
		delta = -mag * 0.6
	else:
		delta = mag * 0.3
	var r: float = clamp(bar_color.r + delta, 0.0, 1.0)
	var g: float = clamp(bar_color.g + delta, 0.0, 1.0)
	var b: float = clamp(bar_color.b + delta, 0.0, 1.0)
	return Color(r, g, b, bar_color.a)


func _build_bars_x() -> void:
	# bar_count_x bars running along +X, evenly distributed across the Z interior.
	var root := Node3D.new()
	root.name = "BarsX"
	add_child(root)

	var min_z: float = _interior_min_z()
	var max_z: float = _interior_max_z()
	var interior_z: float = max_z - min_z
	if interior_z <= 0.0 or bar_count_x <= 0:
		return
	var pitch_z: float = interior_z / float(bar_count_x + 1)

	var bar_length_x: float = _interior_max_x() - _interior_min_x()
	var center_x: float = (_interior_max_x() + _interior_min_x()) * 0.5
	# Bars sit so their TOP surface is flush with y=0 (the walkable surface).
	# Use a bar height slightly less than grate_height so the perimeter frame
	# remains the dominant outline at the edges.
	var bar_h: float = grate_height * 0.85
	var bar_y: float = -bar_h * 0.5

	for i in range(bar_count_x):
		var bar := MeshInstance3D.new()
		bar.name = "BarX_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(bar_length_x, bar_h, BAR_THICKNESS)
		bar.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _vary_bar_color(i, bar_count_x)
		mat.roughness = 0.55
		mat.metallic = 0.7
		bar.material_override = mat
		var z: float = min_z + pitch_z * float(i + 1)
		bar.position = Vector3(center_x, bar_y, z)
		root.add_child(bar)


func _build_bars_z() -> void:
	# bar_count_z cross-bars running along +Z, evenly distributed across the X interior.
	var root := Node3D.new()
	root.name = "BarsZ"
	add_child(root)

	var min_x: float = _interior_min_x()
	var max_x: float = _interior_max_x()
	var interior_x: float = max_x - min_x
	if interior_x <= 0.0 or bar_count_z <= 0:
		return
	var pitch_x: float = interior_x / float(bar_count_z + 1)

	var bar_length_z: float = _interior_max_z() - _interior_min_z()
	var center_z: float = (_interior_max_z() + _interior_min_z()) * 0.5
	# Cross-bars sit slightly LOWER than X-bars so they read as the under-lattice.
	var bar_h: float = grate_height * 0.7
	var bar_y: float = -grate_height * 0.5 - 0.001

	for i in range(bar_count_z):
		var bar := MeshInstance3D.new()
		bar.name = "BarZ_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(BAR_THICKNESS, bar_h, bar_length_z)
		bar.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _vary_bar_color(i + 100, bar_count_z)
		mat.roughness = 0.55
		mat.metallic = 0.7
		bar.material_override = mat
		var x: float = min_x + pitch_x * float(i + 1)
		bar.position = Vector3(x, bar_y, center_z)
		root.add_child(bar)


func _build_accent_stripe() -> void:
	# Painted accent stripe along the -Z front edge of the grate.
	# (-Z is the "front" as specified — opposite the +Z side.)
	var strip := MeshInstance3D.new()
	strip.name = "AccentStripe"
	var bm := BoxMesh.new()
	bm.size = Vector3(grate_width * 0.98, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_THICKNESS)
	strip.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Paint just under the walkable surface (y just below 0), along -Z edge.
	var y: float = -ACCENT_STRIP_HEIGHT * 0.5 - 0.001
	var z: float = -grate_depth * 0.5 + ACCENT_STRIP_THICKNESS * 0.5
	strip.position = Vector3(0.0, y, z)
	add_child(strip)


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
