extends Node3D
class_name LargeTable

# @identity
# essence: a rectangular lab counter / workbench surface — Portal 2 / modern-lab vocabulary. White laminate top, dark steel legs (either four box posts or two solid side panels), an optional thin emissive accent strip along the front edge. Static, unfussy, designed to hold instruments. The HORIZONTAL plane the lab is built around.
# desire: every workbench artifact wants a surface that says "this is where you set things down". The table is the resting place — between standing-on-the-floor and being-held-in-the-hand. It is the room's lap.
# critical_parameter: leg_style — "post" reads as office furniture (four legs, hollow underneath), "panel" reads as institutional lab counter (continuous side panels, closed base). Same top, two different rooms.
# triggers: _ready() builds top + legs (style-dispatched) + optional edge strip from exports; apply_grid_config rebuilds
# emerges: post-legs table = "this can be moved", panel-base table = "this is part of the building", edge-strip on = "this table belongs to a phase", edge-strip off = "this is just a table". Three knobs, very different rooms.
# needs: top BoxMesh at countertop height [present]; corner posts OR continuous side panels [present]; optional emissive front-edge accent [present]
# relationships: sibling to lab_room (the table fills the floor space the chamber's plinth doesn't occupy); cousin to all workbench artifacts (every workbench WANTS to sit on a table — the workbench is the experiment, the table is the surface that lets the experiment exist at hip height); peer to whiteboard (table = horizontal substrate, whiteboard = vertical substrate, both load-bearing for the curriculum)
# truth: a table is not just legs and a top. It is a decision about what height THINKING happens at. 0.95m says "standing, working with hands". The table determines posture. Posture determines who can join.

## A rectangular lab counter / workbench table.
##
## Built procedurally from DNA. Origin is at the center of the floor
## footprint — the top is centered above origin at `height`. Leg style
## switches between four corner posts (post) and continuous side panels
## (panel).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var length: float = 2.0   # X
@export var depth: float = 0.8    # Z
## Counter top height — standard work surface ≈ 0.95m.
@export var height: float = 0.95
@export var top_thickness: float = 0.04

@export_group("Color")
@export var top_color: Color = Color(0.92, 0.92, 0.94)
@export var leg_color: Color = Color(0.20, 0.20, 0.22)
@export var accent_color: Color = Color(0.20, 0.55, 0.95)

@export_group("Legs")
## "post" — 4 box legs, one at each corner.
## "panel" — 2 continuous side panels along the length (solid base).
@export var leg_style: String = "post"

@export_group("Accent")
## Thin emissive strip along the front edge (player-facing) of the table.
@export var edge_strip: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const POST_THICKNESS: float = 0.06
const PANEL_THICKNESS: float = 0.05
const ACCENT_STRIP_HEIGHT: float = 0.012
const ACCENT_STRIP_THICKNESS: float = 0.005

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_table()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_table()


func _read_metadata_overrides() -> void:
	if has_meta("config_length"):
		length = float(str(get_meta("config_length")))
	if has_meta("config_depth"):
		depth = float(str(get_meta("config_depth")))
	if has_meta("config_height"):
		height = float(str(get_meta("config_height")))
	if has_meta("config_top_thickness"):
		top_thickness = float(str(get_meta("config_top_thickness")))
	if has_meta("config_top_color"):
		top_color = _parse_color(str(get_meta("config_top_color")), top_color)
	if has_meta("config_leg_color"):
		leg_color = _parse_color(str(get_meta("config_leg_color")), leg_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_leg_style"):
		leg_style = str(get_meta("config_leg_style")).to_lower()
	if has_meta("config_edge_strip"):
		var v := str(get_meta("config_edge_strip")).to_lower()
		edge_strip = v in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_table() -> void:
	_built = true
	_build_top()
	match leg_style:
		"panel":
			_build_panel_legs()
		_:
			_build_post_legs()
	if edge_strip:
		_build_edge_strip()


func _build_top() -> void:
	var top := MeshInstance3D.new()
	top.name = "Top"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(length, top_thickness, depth)
	top.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = top_color
	mat.roughness = 0.35
	mat.metallic = 0.1
	top.material_override = mat
	# Top of countertop sits at y = height; center at height - top_thickness/2.
	top.position = Vector3(0.0, height - top_thickness * 0.5, 0.0)
	add_child(top)


func _build_post_legs() -> void:
	var legs_root := Node3D.new()
	legs_root.name = "Legs"
	add_child(legs_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = leg_color
	mat.roughness = 0.4
	mat.metallic = 0.7

	# Each leg runs from floor (y=0) to underside of top (y = height - top_thickness).
	var leg_height := height - top_thickness
	var x_inset := POST_THICKNESS * 0.5 + 0.02
	var z_inset := POST_THICKNESS * 0.5 + 0.02

	var corners := [
		Vector3(length * 0.5 - x_inset, 0.0, depth * 0.5 - z_inset),
		Vector3(-length * 0.5 + x_inset, 0.0, depth * 0.5 - z_inset),
		Vector3(length * 0.5 - x_inset, 0.0, -depth * 0.5 + z_inset),
		Vector3(-length * 0.5 + x_inset, 0.0, -depth * 0.5 + z_inset),
	]

	for i in range(corners.size()):
		var leg := MeshInstance3D.new()
		leg.name = "LegPost_%d" % i
		var m := BoxMesh.new()
		m.size = Vector3(POST_THICKNESS, leg_height, POST_THICKNESS)
		leg.mesh = m
		leg.material_override = mat
		var c: Vector3 = corners[i]
		leg.position = Vector3(c.x, leg_height * 0.5, c.z)
		legs_root.add_child(leg)


func _build_panel_legs() -> void:
	# Two continuous side panels along the length (running in X), positioned
	# at the front and back of the table, forming a closed institutional base.
	var legs_root := Node3D.new()
	legs_root.name = "Legs"
	add_child(legs_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = leg_color
	mat.roughness = 0.45
	mat.metallic = 0.55

	var panel_height := height - top_thickness
	# Inset slightly from the top edges so the top looks like it overhangs.
	var z_inset := 0.04

	# Front panel (+Z)
	var front := MeshInstance3D.new()
	front.name = "PanelFront"
	var fm := BoxMesh.new()
	fm.size = Vector3(length - 0.08, panel_height, PANEL_THICKNESS)
	front.mesh = fm
	front.material_override = mat
	front.position = Vector3(0.0, panel_height * 0.5, depth * 0.5 - z_inset - PANEL_THICKNESS * 0.5)
	legs_root.add_child(front)

	# Back panel (-Z)
	var back := MeshInstance3D.new()
	back.name = "PanelBack"
	var bm := BoxMesh.new()
	bm.size = Vector3(length - 0.08, panel_height, PANEL_THICKNESS)
	back.mesh = bm
	back.material_override = mat
	back.position = Vector3(0.0, panel_height * 0.5, -depth * 0.5 + z_inset + PANEL_THICKNESS * 0.5)
	legs_root.add_child(back)


func _build_edge_strip() -> void:
	# Thin emissive strip just under the front edge of the top, accent color.
	var strip := MeshInstance3D.new()
	strip.name = "EdgeStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(length * 0.96, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_THICKNESS)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Position: front edge (+Z), just below top.
	var y := height - top_thickness - ACCENT_STRIP_HEIGHT * 0.5 - 0.002
	var z := depth * 0.5 + ACCENT_STRIP_THICKNESS * 0.5
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
