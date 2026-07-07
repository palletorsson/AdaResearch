extends Node3D
class_name CeilingVent

# @identity
# essence: a rectangular ceiling air vent — recessed cavity, dark steel frame, evenly-spaced light-gray slats. The industrial cue that says "this is a built environment, air moves through these walls, somewhere a system is running." Aperture / Half-Life ceilings without a ceiling-vent would feel unfinished
# desire: every constructed space needs ATMOSPHERE — not the kind made of fog, but the kind made of small honest details. The vent is one of those details. It does not perform; it just is. Its existence implies HVAC, implies maintenance, implies a building that was BUILT
# critical_parameter: slat_count — the rhythm of the slats is the visual signature. Few slats = louver-like, many slats = grille-like. Default 8 reads as "standard industrial vent"
# triggers: _ready() builds recessed cavity + thin frame border + N slats + optional airflow glow. apply_grid_config() rebuilds when grid system injects DNA
# emerges: the ceiling stops being a blank plane and becomes ARCHITECTURE. Light hits the slats and casts soft striped shadows. The space reads as engineered, not as a Godot scene
# needs: a ceiling to mount against (vent is flat in XZ plane, recessed UP into ceiling); a ceiling color that matches (vent recess is slightly darker than the ceiling); slat_count > 0
# relationships: sibling to cable_tray (both are industrial ceiling cues); cousin to lab_room's ceiling (vent goes IN the ceiling); pairs with HVAC SFX if added (not part of artifact, but implied)
# truth: the vent is the structural form of INFRASTRUCTURE acknowledged. Buildings have systems. Showing that systems exist makes the building feel REAL. The vent doesn't need to function; it needs to SIGNAL that something elsewhere functions

## A ceiling air vent — Aperture/Portal industrial style.
##
## Builds a recessed rectangular cavity, dark steel frame, evenly-spaced
## light-gray slats running across the long dimension, and optional
## subtle blue airflow glow behind the slats.
##
## Origin is at the OPENING PLANE (the bottom of the vent — the side
## facing INTO the room). Mount the vent's local origin flush with the
## ceiling surface; the recess extends UP into the ceiling (+Y).
##
## Use as: an industrial atmosphere cue. Drop several across a lab
## ceiling — they don't compete with the workbench for attention; they
## just confirm that this is a real engineered space.

# ── DNA: dimensions ───────────────────────────────────────────────────

@export_group("Dimensions")
@export var vent_length: float = 0.9
@export var vent_width: float = 0.4
@export var recess_depth: float = 0.08

@export_group("Colors")
@export var frame_color: Color = Color(0.18, 0.18, 0.22)        # dark steel frame
@export var slat_color: Color = Color(0.78, 0.78, 0.80)         # light gray slats

@export_group("Slats")
@export var slat_count: int = 8

@export_group("Airflow")
@export var airflow_glow: bool = false                           # decorative subtle airflow indicator
@export var airflow_color: Color = Color(0.45, 0.65, 0.95)
@export_range(0.0, 4.0) var airflow_energy: float = 0.8

# ── Constants ─────────────────────────────────────────────────────────

const FRAME_THICKNESS: float = 0.025
const FRAME_DEPTH: float = 0.012
const SLAT_THICKNESS: float = 0.012
const RECESS_INSET: float = 0.015   # the cavity is slightly smaller than the frame outer

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_vent()


func _read_metadata_overrides() -> void:
	if has_meta("config_vent_length"):
		vent_length = float(str(get_meta("config_vent_length")))
	if has_meta("config_vent_width"):
		vent_width = float(str(get_meta("config_vent_width")))
	if has_meta("config_recess_depth"):
		recess_depth = float(str(get_meta("config_recess_depth")))
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_slat_color"):
		slat_color = _parse_color(str(get_meta("config_slat_color")), slat_color)
	if has_meta("config_slat_count"):
		slat_count = int(str(get_meta("config_slat_count")))
	if has_meta("config_airflow_glow"):
		airflow_glow = bool(get_meta("config_airflow_glow"))
	if has_meta("config_airflow_color"):
		airflow_color = _parse_color(str(get_meta("config_airflow_color")), airflow_color)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_vent()


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_vent() -> void:
	_built = true
	_build_recess()
	_build_frame()
	if airflow_glow:
		_build_airflow_indicator()
	_build_slats()


# ── Recess: dark cavity set INSIDE the ceiling ────────────────────────

func _build_recess() -> void:
	var recess := MeshInstance3D.new()
	recess.name = "Recess"
	var m := BoxMesh.new()
	# The recess is slightly smaller than the frame outer so the frame
	# sits proud of the cavity opening.
	var inner_l := vent_length - RECESS_INSET * 2.0
	var inner_w := vent_width - RECESS_INSET * 2.0
	m.size = Vector3(inner_l, recess_depth, inner_w)
	recess.mesh = m
	var mat := StandardMaterial3D.new()
	# Slightly darker than the frame to read as "shadowed cavity"
	mat.albedo_color = frame_color * 0.55
	mat.roughness = 0.85
	mat.metallic = 0.0
	recess.material_override = mat
	# Position cavity so its BOTTOM face is at y=0 (the opening plane).
	recess.position = Vector3(0.0, recess_depth * 0.5, 0.0)
	add_child(recess)


# ── Frame: thin border around the opening ─────────────────────────────

func _build_frame() -> void:
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = frame_color
	frame_mat.roughness = 0.45
	frame_mat.metallic = 0.4

	var half_l := vent_length * 0.5
	var half_w := vent_width * 0.5
	var ft := FRAME_THICKNESS
	# Frame sits just below the opening plane, hanging slightly into the room.
	var frame_y := -FRAME_DEPTH * 0.5

	# Front bar (along +Z edge → bar runs in X direction)
	var front := MeshInstance3D.new()
	front.name = "FrameFront"
	var fm := BoxMesh.new()
	fm.size = Vector3(vent_length + ft * 2.0, FRAME_DEPTH, ft)
	front.mesh = fm
	front.material_override = frame_mat
	front.position = Vector3(0.0, frame_y, half_w + ft * 0.5)
	add_child(front)

	# Back bar
	var back := MeshInstance3D.new()
	back.name = "FrameBack"
	var bm := BoxMesh.new()
	bm.size = Vector3(vent_length + ft * 2.0, FRAME_DEPTH, ft)
	back.mesh = bm
	back.material_override = frame_mat
	back.position = Vector3(0.0, frame_y, -half_w - ft * 0.5)
	add_child(back)

	# Left bar (running in Z direction)
	var left := MeshInstance3D.new()
	left.name = "FrameLeft"
	var lm := BoxMesh.new()
	lm.size = Vector3(ft, FRAME_DEPTH, vent_width)
	left.mesh = lm
	left.material_override = frame_mat
	left.position = Vector3(-half_l - ft * 0.5, frame_y, 0.0)
	add_child(left)

	# Right bar
	var right := MeshInstance3D.new()
	right.name = "FrameRight"
	var rm := BoxMesh.new()
	rm.size = Vector3(ft, FRAME_DEPTH, vent_width)
	right.mesh = rm
	right.material_override = frame_mat
	right.position = Vector3(half_l + ft * 0.5, frame_y, 0.0)
	add_child(right)


# ── Airflow indicator: subtle glow behind the slats ───────────────────

func _build_airflow_indicator() -> void:
	var glow := MeshInstance3D.new()
	glow.name = "AirflowGlow"
	var m := BoxMesh.new()
	# Sits inside the recess, near the back wall of the cavity.
	var inner_l := vent_length - RECESS_INSET * 2.0 - 0.04
	var inner_w := vent_width - RECESS_INSET * 2.0 - 0.04
	m.size = Vector3(inner_l, 0.005, inner_w)
	glow.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = airflow_color
	mat.emission_enabled = true
	mat.emission = airflow_color
	mat.emission_energy_multiplier = airflow_energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.material_override = mat
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Place slightly below the top of the recess cavity (so the slats
	# cast their stripes across it).
	glow.position = Vector3(0.0, recess_depth * 0.85, 0.0)
	add_child(glow)


# ── Slats: evenly-spaced strips spanning the long dimension ───────────

func _build_slats() -> void:
	if slat_count <= 0:
		return
	var slats_root := Node3D.new()
	slats_root.name = "Slats"
	add_child(slats_root)

	var slat_mat := StandardMaterial3D.new()
	slat_mat.albedo_color = slat_color
	slat_mat.roughness = 0.55
	slat_mat.metallic = 0.25

	# Slats run along X (the long dimension) and are spaced along Z.
	# Each slat is thin in Z and full in X.
	var inner_l := vent_length - RECESS_INSET * 2.0 - 0.01
	# Distribute slats evenly inside the inner width.
	# (slat_count + 1) gaps between slats, so spacing = inner_w / (slat_count + 1)
	var inner_w := vent_width - RECESS_INSET * 2.0
	var slat_z_step := inner_w / float(slat_count + 1)

	# Slats sit just inside the opening plane, hanging into the cavity
	# enough to read but not so deep they vanish.
	var slat_y := -SLAT_THICKNESS * 0.25  # very slightly below the opening plane

	for i in range(slat_count):
		var slat := MeshInstance3D.new()
		slat.name = "Slat%d" % i
		var sm := BoxMesh.new()
		sm.size = Vector3(inner_l, SLAT_THICKNESS, SLAT_THICKNESS)
		slat.mesh = sm
		slat.material_override = slat_mat
		# z position: i goes 0..slat_count-1, slot i+1 in the gap pattern
		var z := -inner_w * 0.5 + slat_z_step * float(i + 1)
		slat.position = Vector3(0.0, slat_y, z)
		slats_root.add_child(slat)


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
