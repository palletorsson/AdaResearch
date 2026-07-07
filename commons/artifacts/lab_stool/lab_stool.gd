extends Node3D
class_name LabStool

# @identity
# essence: an adjustable swivel stool — the Aperture/Portal/Black Mesa lab vocabulary for "perch here while you work the bench". Round seat on a vertical post, splayed five-pointed star base OR continuous ring base, optional Portal-orange accent strip around the seat edge. Static furniture, not actually adjustable in-scene — the "adjustable" is a posture the seat HEIGHT remembers.
# desire: the stool wants to mark the spot where a researcher sat. It is the negative space of presence — empty, but shaped by the body that wasn't there. Every workbench wants a stool nearby so the bench doesn't read as a museum case.
# critical_parameter: base_style — "five_star" reads as office/ergonomic furniture (movable, individual, "this seat is mine"), "ring" reads as institutional/cleanroom lab (cast-in-place, bolted, "this seat is the lab's"). Same posture, different ownership.
# triggers: _ready() builds seat + post + base from exports; apply_grid_config rebuilds
# emerges: five-star + accent strip = "ergonomic, personal, current"; ring + no strip = "institutional, communal, archival"; tall seat (0.85+) = bar/bench-side; short seat (0.45) = drafting-table or floor-work
# needs: round seat CylinderMesh [present]; vertical post CylinderMesh [present]; 5-pointed star base (5 BoxMesh legs at 72°) OR TorusMesh ring [present]; optional emissive accent strip [present]
# relationships: sibling to large_table (a table without a stool is uninhabited — the stool is the table's promise of a person); cousin to fume_hood (the stool is what a person sits on while they watch the hood do its work); peer to chair2 (both seat the player; chair2 says "rest", lab_stool says "work")
# truth: a stool is not just a seat at a height. It is a decision that THINKING here happens at hip-rotation distance from the work — close enough to touch, free enough to spin away. The post is the axis. The body, briefly, becomes a wheel.

## An adjustable swivel lab stool.
##
## Built procedurally from DNA. Origin is at the bottom center of the base,
## the post points up +Y, the seat is centered above origin at `seat_height`.
## base_style toggles between a 5-pointed star (office furniture) and a ring
## (institutional/cleanroom).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
## Top-of-seat height — 0.65m is standard work-stool, 0.85m is bar-stool.
@export var seat_height: float = 0.65
@export var seat_radius: float = 0.18
@export var base_radius: float = 0.32

@export_group("Color")
@export var seat_color: Color = Color(0.08, 0.08, 0.10)
@export var post_color: Color = Color(0.22, 0.22, 0.24)
@export var accent_color: Color = Color(1.0, 0.45, 0.10)

@export_group("Base")
## "five_star" — 5 radiating BoxMesh legs at 72° intervals (office furniture).
## "ring" — TorusMesh ring around the foot (institutional / cleanroom).
@export var base_style: String = "five_star"

@export_group("Accent")
## Thin emissive strip wrapping the edge of the seat — Portal-orange by default.
@export var accent_strip: bool = true

# ── Constants ─────────────────────────────────────────────────────────

const SEAT_THICKNESS: float = 0.04
const POST_RADIUS: float = 0.025
const STAR_LEG_THICKNESS: float = 0.04
const STAR_LEG_HEIGHT: float = 0.05
const RING_TUBE_RADIUS: float = 0.022
const ACCENT_STRIP_HEIGHT: float = 0.010
const ACCENT_STRIP_THICKNESS: float = 0.005

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_stool()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_stool()


func _read_metadata_overrides() -> void:
	if has_meta("config_seat_height"):
		seat_height = float(str(get_meta("config_seat_height")))
	if has_meta("config_seat_radius"):
		seat_radius = float(str(get_meta("config_seat_radius")))
	if has_meta("config_base_radius"):
		base_radius = float(str(get_meta("config_base_radius")))
	if has_meta("config_seat_color"):
		seat_color = _parse_color(str(get_meta("config_seat_color")), seat_color)
	if has_meta("config_post_color"):
		post_color = _parse_color(str(get_meta("config_post_color")), post_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_base_style"):
		base_style = str(get_meta("config_base_style")).to_lower()
	if has_meta("config_accent_strip"):
		var v := str(get_meta("config_accent_strip")).to_lower()
		accent_strip = v in ["true", "1", "yes", "on"]


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_stool() -> void:
	_built = true
	_build_seat()
	_build_post()
	match base_style:
		"ring":
			_build_ring_base()
		_:
			_build_star_base()
	if accent_strip:
		_build_accent_strip()


func _build_seat() -> void:
	var seat := MeshInstance3D.new()
	seat.name = "Seat"
	var mesh := CylinderMesh.new()
	mesh.top_radius = seat_radius
	mesh.bottom_radius = seat_radius
	mesh.height = SEAT_THICKNESS
	seat.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = seat_color
	mat.roughness = 0.55
	mat.metallic = 0.15
	seat.material_override = mat
	# Top of seat sits at y = seat_height; center the cylinder at height - thickness/2.
	seat.position = Vector3(0.0, seat_height - SEAT_THICKNESS * 0.5, 0.0)
	add_child(seat)


func _build_post() -> void:
	var post := MeshInstance3D.new()
	post.name = "Post"
	var mesh := CylinderMesh.new()
	mesh.top_radius = POST_RADIUS
	mesh.bottom_radius = POST_RADIUS
	# Post runs from base hub (small lift) to underside of seat.
	var base_hub_y := STAR_LEG_HEIGHT
	var post_height := (seat_height - SEAT_THICKNESS) - base_hub_y
	if post_height < 0.05:
		post_height = 0.05
	mesh.height = post_height
	post.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = post_color
	mat.roughness = 0.35
	mat.metallic = 0.8
	post.material_override = mat
	post.position = Vector3(0.0, base_hub_y + post_height * 0.5, 0.0)
	add_child(post)


func _build_star_base() -> void:
	# 5 radiating BoxMesh legs at 72° intervals. Origin at the base hub.
	var base_root := Node3D.new()
	base_root.name = "Base"
	add_child(base_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = post_color
	mat.roughness = 0.4
	mat.metallic = 0.6

	# Small central hub disk so the legs look anchored.
	var hub := MeshInstance3D.new()
	hub.name = "Hub"
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = STAR_LEG_THICKNESS * 1.2
	hub_mesh.bottom_radius = STAR_LEG_THICKNESS * 1.2
	hub_mesh.height = STAR_LEG_HEIGHT
	hub.mesh = hub_mesh
	hub.material_override = mat
	hub.position = Vector3(0.0, STAR_LEG_HEIGHT * 0.5, 0.0)
	base_root.add_child(hub)

	# Five legs at 72° intervals — each a BoxMesh extending outward radially.
	# Place a leg whose long axis is +X, then rotate around Y for each spoke.
	var leg_length := base_radius
	for i in range(5):
		var leg := MeshInstance3D.new()
		leg.name = "Leg_%d" % i
		var lm := BoxMesh.new()
		lm.size = Vector3(leg_length, STAR_LEG_HEIGHT, STAR_LEG_THICKNESS)
		leg.mesh = lm
		leg.material_override = mat
		# Pivot the leg so its inner end sits at origin and the leg extends +X.
		# Position the leg center half a length out, then rotate.
		var pivot := Node3D.new()
		pivot.name = "LegPivot_%d" % i
		var angle := deg_to_rad(i * 72.0)
		pivot.rotation = Vector3(0.0, angle, 0.0)
		base_root.add_child(pivot)
		leg.position = Vector3(leg_length * 0.5, STAR_LEG_HEIGHT * 0.5, 0.0)
		pivot.add_child(leg)

		# Small foot pad at the tip for that ergonomic-stool feel.
		var foot := MeshInstance3D.new()
		foot.name = "Foot_%d" % i
		var fm := CylinderMesh.new()
		fm.top_radius = STAR_LEG_THICKNESS * 0.6
		fm.bottom_radius = STAR_LEG_THICKNESS * 0.6
		fm.height = STAR_LEG_HEIGHT * 0.7
		foot.mesh = fm
		foot.material_override = mat
		foot.position = Vector3(leg_length, STAR_LEG_HEIGHT * 0.35, 0.0)
		pivot.add_child(foot)


func _build_ring_base() -> void:
	# Ring base — a TorusMesh sitting at the floor plus a small central hub.
	var base_root := Node3D.new()
	base_root.name = "Base"
	add_child(base_root)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = post_color
	mat.roughness = 0.45
	mat.metallic = 0.55

	# Central hub disc.
	var hub := MeshInstance3D.new()
	hub.name = "Hub"
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = STAR_LEG_THICKNESS * 1.3
	hub_mesh.bottom_radius = STAR_LEG_THICKNESS * 1.3
	hub_mesh.height = STAR_LEG_HEIGHT
	hub.mesh = hub_mesh
	hub.material_override = mat
	hub.position = Vector3(0.0, STAR_LEG_HEIGHT * 0.5, 0.0)
	base_root.add_child(hub)

	# Ring (torus). In Godot, TorusMesh lies in the XZ plane by default — perfect.
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var tm := TorusMesh.new()
	tm.inner_radius = base_radius - RING_TUBE_RADIUS * 2.0
	tm.outer_radius = base_radius
	ring.mesh = tm
	ring.material_override = mat
	ring.position = Vector3(0.0, RING_TUBE_RADIUS, 0.0)
	base_root.add_child(ring)

	# Three thin spokes from hub to ring so the ring reads as supported.
	for i in range(3):
		var spoke := MeshInstance3D.new()
		spoke.name = "Spoke_%d" % i
		var sm := BoxMesh.new()
		var spoke_length := base_radius - STAR_LEG_THICKNESS * 0.5
		sm.size = Vector3(spoke_length, STAR_LEG_HEIGHT * 0.6, STAR_LEG_THICKNESS * 0.6)
		spoke.mesh = sm
		spoke.material_override = mat
		var pivot := Node3D.new()
		pivot.name = "SpokePivot_%d" % i
		var angle := deg_to_rad(i * 120.0)
		pivot.rotation = Vector3(0.0, angle, 0.0)
		base_root.add_child(pivot)
		spoke.position = Vector3(spoke_length * 0.5, STAR_LEG_HEIGHT * 0.3, 0.0)
		pivot.add_child(spoke)


func _build_accent_strip() -> void:
	# Thin emissive ring around the edge of the seat. Use a TorusMesh with a
	# thin tube radius so it reads as a stripe wrapping the seat cylinder.
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := TorusMesh.new()
	mesh.inner_radius = seat_radius - ACCENT_STRIP_THICKNESS
	mesh.outer_radius = seat_radius + ACCENT_STRIP_THICKNESS * 0.5
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Position the stripe at the lower edge of the seat cylinder.
	var y := seat_height - SEAT_THICKNESS * 0.85
	strip.position = Vector3(0.0, y, 0.0)
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
