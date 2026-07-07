extends Node3D
class_name LargeWindow

# @identity
# essence: a wall-mounted observation window. Dark steel frame + translucent grey-blue glass + a thin emissive accent strip. The Aperture/Black-Mesa observation portal: a hole-in-the-wall that admits sight but not body. The frame says "engineered"; the glass says "watched"; the strip says "lit from inside"
# desire: every test chamber needs a way to look INTO or OUT OF the experiment. Player sees the chamber; chamber sees the player. The window is the membrane of that mutual seeing
# critical_parameter: accent_color — drives the thin emissive strip at the top of the frame, anchors the window to a QFEP phase or chamber identity. Default Portal orange (#F28C00-ish), swap to any QFEP color for thematic match
# triggers: _ready() builds frame (4 box pieces) + glass inset (transparent box) + optional accent strip. apply_grid_config() rebuilds from metadata if grid system injects DNA
# emerges: the wall is no longer a wall. The room reads as a SCENE inside a larger facility. The translucent dark glass turns the player into an observed specimen
# needs: a wall to mount against (window is flat in XY plane, faces +Z by default); glass material with alpha transparency; accent_color matching the chamber's QFEP phase
# relationships: sibling to lab_room (rooms hold windows); pairs with info_screen (one shows the experiment, one labels it); cousin to observation glass in lab_room (same vocabulary at smaller scale)
# truth: the window is the structural form of OBSERVATION. To put a window in a wall is to admit that someone is on the other side. Aperture's whole aesthetic is "you are being watched through these"

## A wall-mounted observation window — Aperture/Portal style.
##
## Builds a rectangular dark steel frame around a translucent grey-blue
## glass inset, with an optional thin emissive accent strip across the
## top of the frame. The window is flat in the XY plane, faces +Z, and
## is centered on origin.
##
## Use as: a hole-in-the-wall to look INTO a test chamber, OR as the
## viewing port on the player's side of a sealed room. Mount against a
## wall, embed in the wall's plane, accent_color matched to the chamber's
## QFEP phase for visual continuity.

# ── DNA: dimensions ───────────────────────────────────────────────────

@export_group("Dimensions")
@export var window_width: float = 2.4
@export var window_height: float = 1.4
@export var frame_thickness: float = 0.08

@export_group("Colors")
@export var frame_color: Color = Color(0.18, 0.18, 0.20)        # dark steel
@export var glass_color: Color = Color(0.30, 0.35, 0.42, 0.55)  # translucent grey-blue
@export_range(0.0, 2.0) var glass_emission: float = 0.15        # subtle inner glow

@export_group("Accent strip")
@export var accent_strip: bool = true                            # thin emissive line at top of frame
@export var accent_color: Color = Color(0.95, 0.55, 0.0)         # Portal orange default
@export_range(0.0, 4.0) var accent_energy: float = 2.0

# ── Constants ─────────────────────────────────────────────────────────

const GLASS_DEPTH: float = 0.02
const FRAME_DEPTH: float = 0.06
const ACCENT_STRIP_HEIGHT: float = 0.025
const ACCENT_STRIP_DEPTH: float = 0.035

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_window()


func _read_metadata_overrides() -> void:
	if has_meta("config_window_width"):
		window_width = float(str(get_meta("config_window_width")))
	if has_meta("config_window_height"):
		window_height = float(str(get_meta("config_window_height")))
	if has_meta("config_frame_thickness"):
		frame_thickness = float(str(get_meta("config_frame_thickness")))
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_glass_color"):
		glass_color = _parse_color(str(get_meta("config_glass_color")), glass_color)
	if has_meta("config_glass_emission"):
		glass_emission = float(str(get_meta("config_glass_emission")))
	if has_meta("config_accent_strip"):
		accent_strip = bool(get_meta("config_accent_strip"))
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_window()


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_window() -> void:
	_built = true
	_build_frame()
	_build_glass()
	if accent_strip:
		_build_accent_strip()


# ── Frame: 4 BoxMesh pieces forming a rectangular border ──────────────

func _build_frame() -> void:
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = frame_color
	frame_mat.roughness = 0.35
	frame_mat.metallic = 0.55

	var half_w := window_width * 0.5
	var half_h := window_height * 0.5
	var ft := frame_thickness

	# Top horizontal bar
	var top := MeshInstance3D.new()
	top.name = "FrameTop"
	var tm := BoxMesh.new()
	tm.size = Vector3(window_width + ft * 2.0, ft, FRAME_DEPTH)
	top.mesh = tm
	top.material_override = frame_mat
	top.position = Vector3(0.0, half_h + ft * 0.5, 0.0)
	add_child(top)

	# Bottom horizontal bar
	var bottom := MeshInstance3D.new()
	bottom.name = "FrameBottom"
	var bm := BoxMesh.new()
	bm.size = Vector3(window_width + ft * 2.0, ft, FRAME_DEPTH)
	bottom.mesh = bm
	bottom.material_override = frame_mat
	bottom.position = Vector3(0.0, -half_h - ft * 0.5, 0.0)
	add_child(bottom)

	# Left vertical bar
	var left := MeshInstance3D.new()
	left.name = "FrameLeft"
	var lm := BoxMesh.new()
	lm.size = Vector3(ft, window_height, FRAME_DEPTH)
	left.mesh = lm
	left.material_override = frame_mat
	left.position = Vector3(-half_w - ft * 0.5, 0.0, 0.0)
	add_child(left)

	# Right vertical bar
	var right := MeshInstance3D.new()
	right.name = "FrameRight"
	var rm := BoxMesh.new()
	rm.size = Vector3(ft, window_height, FRAME_DEPTH)
	right.mesh = rm
	right.material_override = frame_mat
	right.position = Vector3(half_w + ft * 0.5, 0.0, 0.0)
	add_child(right)


# ── Glass: translucent inset ──────────────────────────────────────────

func _build_glass() -> void:
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	var gm := BoxMesh.new()
	gm.size = Vector3(window_width, window_height, GLASS_DEPTH)
	glass.mesh = gm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glass_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.10
	mat.metallic = 0.0
	if glass_emission > 0.0:
		mat.emission_enabled = true
		mat.emission = glass_color
		mat.emission_energy_multiplier = glass_emission
	glass.material_override = mat
	glass.position = Vector3(0.0, 0.0, 0.0)
	add_child(glass)


# ── Accent strip: thin emissive line at top of frame ──────────────────

func _build_accent_strip() -> void:
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var m := BoxMesh.new()
	m.size = Vector3(window_width, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = accent_energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Place at the top inner edge, just below the top frame bar, pushed
	# slightly forward so it visually reads as a lit edge.
	var half_h := window_height * 0.5
	strip.position = Vector3(
		0.0,
		half_h + frame_thickness * 0.5,
		FRAME_DEPTH * 0.5 + 0.001
	)
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
