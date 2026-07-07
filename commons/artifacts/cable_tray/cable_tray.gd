extends Node3D
class_name CableTray

# @identity
# essence: a horizontal cable tray — two steel side rails, evenly-spaced perpendicular rungs forming a ladder pattern, and a small bundle of differently-colored cables running through it. The industrial ceiling cue from Half-Life, Mirror's Edge, Aperture: it says "this is a real engineered space where cables are routed somewhere"
# desire: every lab needs to suggest that power and signal travel somewhere. A cable tray makes the building feel like a SYSTEM — the chamber isn't a sealed box, it's a node in a network of infrastructure
# critical_parameter: cable_count + cable_colors — the cables are the only thing in the artifact with chromatic variety. Match colors to a project's signal palette (power=brown, data=blue, network=yellow, ground=dark) for accidental honesty
# triggers: _ready() builds 2 side rails + N rungs + M cables along the length. apply_grid_config() rebuilds from grid metadata
# emerges: the ceiling reads as carrying SIGNAL through the building. Stretch the tray across a long ceiling and the room reads as part of a larger facility. Industrial atmosphere without competing for attention
# needs: a ceiling to hang from (tray is mounted with its top near a ceiling); a long-enough span to read as a "channel" not a "box"; cable_count <= cable_colors.size() (else cables wrap around the palette)
# relationships: sibling to ceiling_vent (both are ceiling industrial cues); cousin to lab_room's ceiling (the tray runs ALONG the ceiling, not in it); pairs with control_board / electromagneticfieldgenerator (those are where the cables go)
# truth: the cable_tray is the structural form of CONTINUITY. It says: the experiment in this room is connected to other rooms, to power, to data, to the rest of the facility. The chamber is a NODE, not an island

## A ceiling-mounted cable tray — Aperture/Portal industrial style.
##
## Builds 2 thin side rails along the length, N short rung segments
## spanning the rails (the ladder pattern), and M long thin cylinders
## representing routed cables in the cable_colors palette.
##
## Origin is at the TRAY CENTER. The tray extends in ±X along the
## length, lies flat in the XZ plane, with cables running parallel to
## the length axis (X). Mount with the tray's local +Y pointing UP
## toward the ceiling.
##
## Use as: an industrial atmosphere cue running across a lab ceiling.
## Stretch one across the long axis of a room — it confirms the chamber
## is wired into a larger facility without competing with the workbench.

# ── DNA: dimensions ───────────────────────────────────────────────────

@export_group("Dimensions")
@export var tray_length: float = 3.0
@export var tray_width: float = 0.18
@export var tray_height: float = 0.08

@export_group("Rails + rungs")
@export var rung_count: int = 12
@export var tray_color: Color = Color(0.32, 0.36, 0.40)         # dark steel gray

@export_group("Cables")
@export var cable_count: int = 4
@export var cable_colors: PackedColorArray = PackedColorArray([
	Color(0.15, 0.15, 0.17),   # dark
	Color(0.35, 0.20, 0.18),   # brown
	Color(0.20, 0.20, 0.45),   # blue
	Color(0.55, 0.50, 0.18),   # yellow
])

# ── Constants ─────────────────────────────────────────────────────────

const RAIL_THICKNESS: float = 0.025
const RUNG_THICKNESS: float = 0.012
const CABLE_RADIUS: float = 0.012
const CABLE_RADIAL_SEGMENTS: int = 8

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_tray()


func _read_metadata_overrides() -> void:
	if has_meta("config_tray_length"):
		tray_length = float(str(get_meta("config_tray_length")))
	if has_meta("config_tray_width"):
		tray_width = float(str(get_meta("config_tray_width")))
	if has_meta("config_tray_height"):
		tray_height = float(str(get_meta("config_tray_height")))
	if has_meta("config_rung_count"):
		rung_count = int(str(get_meta("config_rung_count")))
	if has_meta("config_tray_color"):
		tray_color = _parse_color(str(get_meta("config_tray_color")), tray_color)
	if has_meta("config_cable_count"):
		cable_count = int(str(get_meta("config_cable_count")))


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_tray()


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_tray() -> void:
	_built = true
	_build_rails()
	_build_rungs()
	_build_cables()


# ── Side rails: 2 long thin runners along the length ──────────────────

func _build_rails() -> void:
	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = tray_color
	rail_mat.roughness = 0.5
	rail_mat.metallic = 0.5

	var half_w := tray_width * 0.5

	# Front rail (+Z)
	var front := MeshInstance3D.new()
	front.name = "RailFront"
	var fm := BoxMesh.new()
	fm.size = Vector3(tray_length, tray_height, RAIL_THICKNESS)
	front.mesh = fm
	front.material_override = rail_mat
	front.position = Vector3(0.0, 0.0, half_w - RAIL_THICKNESS * 0.5)
	add_child(front)

	# Back rail (-Z)
	var back := MeshInstance3D.new()
	back.name = "RailBack"
	var bm := BoxMesh.new()
	bm.size = Vector3(tray_length, tray_height, RAIL_THICKNESS)
	back.mesh = bm
	back.material_override = rail_mat
	back.position = Vector3(0.0, 0.0, -half_w + RAIL_THICKNESS * 0.5)
	add_child(back)


# ── Rungs: perpendicular short segments forming the ladder pattern ────

func _build_rungs() -> void:
	if rung_count <= 0:
		return
	var rungs_root := Node3D.new()
	rungs_root.name = "Rungs"
	add_child(rungs_root)

	var rung_mat := StandardMaterial3D.new()
	rung_mat.albedo_color = tray_color
	rung_mat.roughness = 0.55
	rung_mat.metallic = 0.45

	# Inner span between rails (rungs span this width)
	var inner_w := tray_width - RAIL_THICKNESS * 2.0
	# Evenly distribute rungs along the length with margin from ends
	var margin := tray_length * 0.04
	var span := tray_length - margin * 2.0
	var step := span / float(max(rung_count - 1, 1))
	# Rungs sit at the bottom of the rails (the "floor" of the tray)
	var rung_y := -tray_height * 0.5 + RUNG_THICKNESS * 0.5

	for i in range(rung_count):
		var rung := MeshInstance3D.new()
		rung.name = "Rung%d" % i
		var m := BoxMesh.new()
		m.size = Vector3(RUNG_THICKNESS, RUNG_THICKNESS, inner_w)
		rung.mesh = m
		rung.material_override = rung_mat
		var x: float
		if rung_count == 1:
			x = 0.0
		else:
			x = -span * 0.5 + step * float(i)
		rung.position = Vector3(x, rung_y, 0.0)
		rungs_root.add_child(rung)


# ── Cables: long thin cylinders running parallel along the tray ───────

func _build_cables() -> void:
	if cable_count <= 0 or cable_colors.is_empty():
		return
	var cables_root := Node3D.new()
	cables_root.name = "Cables"
	add_child(cables_root)

	# Distribute cables across the inner width of the tray, sitting on
	# top of the rung floor.
	var inner_w := tray_width - RAIL_THICKNESS * 2.0 - CABLE_RADIUS * 2.0
	var step_z := 0.0
	if cable_count > 1:
		step_z = inner_w / float(cable_count - 1)
	var start_z := -inner_w * 0.5 if cable_count > 1 else 0.0

	# Cables sit slightly above the rung floor (so they read as resting in the tray)
	var cable_y := -tray_height * 0.5 + RUNG_THICKNESS + CABLE_RADIUS

	for i in range(cable_count):
		var cable := MeshInstance3D.new()
		cable.name = "Cable%d" % i
		var c := CylinderMesh.new()
		c.top_radius = CABLE_RADIUS
		c.bottom_radius = CABLE_RADIUS
		c.height = tray_length * 0.98
		c.radial_segments = CABLE_RADIAL_SEGMENTS
		cable.mesh = c
		var mat := StandardMaterial3D.new()
		var col := cable_colors[i % cable_colors.size()]
		mat.albedo_color = col
		mat.roughness = 0.7
		mat.metallic = 0.05
		cable.material_override = mat
		# CylinderMesh's axis is Y by default; we want it along X.
		# Rotate -90° around Z so its long axis aligns with X.
		cable.rotation = Vector3(0.0, 0.0, PI * 0.5)
		var z: float
		if cable_count == 1:
			z = 0.0
		else:
			z = start_z + step_z * float(i)
		cable.position = Vector3(0.0, cable_y, z)
		cables_root.add_child(cable)


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
