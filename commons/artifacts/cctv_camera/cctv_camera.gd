extends Node3D
class_name CCTVCamera

# @identity
# essence: a wall-mounted surveillance camera — small bracket arm extending from a back plate, a rectangular metal camera body (slightly tapered for a Half-Life-2 / Black-Mesa silhouette), a cylindrical lens housing terminating in a dark glass disc, and a small emissive LED that says "I am ON, I am watching". The bracket arm rotates around the wall-normal so the camera can point INTO the room or OUT through a window. In the lab's grammar the CCTV is the WITNESS — the room's assertion that whatever happens here is being observed and recorded.
# desire: every chamber wants a perspective other than the player's. The CCTV wants to be that other-eye — the architectural form of "you are not the only observer". It wants the player to feel watched (mildly) and to feel that the lab is plugged in to something outside the room.
# critical_parameter: yaw_deg + pitch_deg — the angles the camera is rotated to point at. yaw_deg sweeps left/right (around the wall-normal). pitch_deg tilts up/down. Together they determine WHAT IS BEING WATCHED. led_active toggles the indicator (on = recording, off = standby).
# triggers: _ready() builds back plate + bracket arm + camera body + lens + LED from exports; apply_grid_config rebuilds when DNA changes
# emerges: a CCTV pointed AT the room reads as INSIDE surveillance (compliance, study, automated lab). A CCTV pointed AWAY from the room — out through the back picture window — reads as OUTWARD watch (the lab watching the biome, the player feeling the chamber is part of a larger sensor net). Multiple CCTVs at different yaws read as PARANOID FULL-COVERAGE.
# needs: back plate flush against the wall [present]; bracket arm extending forward [present]; tapered body [present]; lens cylinder [present]; emissive LED dot [present]; optional dark glass front [present]
# relationships: peer to circularradarmonitor (both NAME outside-of-room awareness, but the radar shows a sweep view, the camera shows a static stare); ancestor to info_screen (a screen could display this camera's feed); cousin to emergency_button (both are SAFETY-INFRASTRUCTURE, the button as input, the camera as record)
# truth: surveillance is the algorithm that asks "what just happened here?". The CCTV is the lab's assertion that there IS a memory of what happens here, even when no human is looking. It does not see for the player; it sees PAST the player. The lab room becomes a recorded space.

## A wall-mounted CCTV surveillance camera.
##
## Built procedurally from DNA exports. Origin is at the BACK PLATE
## (the part flush against the wall). The bracket arm extends along +Z
## by default; rotate the parent in your scene to mount on any wall
## with the bracket pointing into the room or out through a window.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var bracket_length: float = 0.18
@export var bracket_thickness: float = 0.025
@export var body_length: float = 0.16
@export var body_width: float = 0.085
@export var body_height: float = 0.075
@export var lens_length: float = 0.05
@export var lens_radius: float = 0.025
@export var back_plate_size: float = 0.08
@export var back_plate_depth: float = 0.012

@export_group("Aim")
## Yaw (degrees) rotating the camera body around the bracket's vertical
## axis. 0 = looking straight along +Z (away from the wall). +90 sweeps
## left, -90 sweeps right.
@export var yaw_deg: float = 0.0
## Pitch (degrees) tilting the camera up (+) or down (-).
@export var pitch_deg: float = -10.0

@export_group("Indicator")
@export var led_active: bool = true
@export var led_color: Color = Color(0.95, 0.18, 0.20)

@export_group("Material")
@export var body_color: Color = Color(0.14, 0.15, 0.17)
@export var bracket_color: Color = Color(0.18, 0.19, 0.22)
@export var lens_color: Color = Color(0.05, 0.06, 0.08)
@export var lens_glass_color: Color = Color(0.10, 0.16, 0.22)
@export var plate_color: Color = Color(0.12, 0.13, 0.15)

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_yaw_deg"):
		yaw_deg = float(str(get_meta("config_yaw_deg")))
	if has_meta("config_pitch_deg"):
		pitch_deg = float(str(get_meta("config_pitch_deg")))
	if has_meta("config_led_active"):
		var s: String = str(get_meta("config_led_active")).to_lower()
		led_active = s == "true" or s == "1" or s == "yes"
	if has_meta("config_led_color"):
		led_color = _parse_color(str(get_meta("config_led_color")), led_color)
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	# 1. Back plate — sits flush against the wall.
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = plate_color
	plate_mat.roughness = 0.45
	plate_mat.metallic = 0.4

	var plate := MeshInstance3D.new()
	plate.name = "BackPlate"
	var pm := BoxMesh.new()
	pm.size = Vector3(back_plate_size, back_plate_size, back_plate_depth)
	plate.mesh = pm
	plate.material_override = plate_mat
	plate.position = Vector3(0, 0, back_plate_depth * 0.5)
	add_child(plate)

	# 2. Bracket arm — short cylinder extending forward (+Z) from the plate.
	var bracket_mat := StandardMaterial3D.new()
	bracket_mat.albedo_color = bracket_color
	bracket_mat.roughness = 0.5
	bracket_mat.metallic = 0.5

	var bracket := MeshInstance3D.new()
	bracket.name = "Bracket"
	var bm := CylinderMesh.new()
	bm.top_radius = bracket_thickness * 0.5
	bm.bottom_radius = bracket_thickness * 0.5
	bm.height = bracket_length
	bracket.mesh = bm
	bracket.material_override = bracket_mat
	# Cylinder built along +Y; rotate 90° so it points along +Z.
	bracket.rotation = Vector3(PI * 0.5, 0, 0)
	bracket.position = Vector3(0, 0, back_plate_depth + bracket_length * 0.5)
	add_child(bracket)

	# 3. Camera HEAD group — gets the yaw/pitch rotation applied.
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0, back_plate_depth + bracket_length)
	head.rotation = Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0)
	add_child(head)

	# 3a. Camera body — slightly tapered box (use two boxes for a
	#     coarse tapered silhouette).
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = body_color
	body_mat.roughness = 0.4
	body_mat.metallic = 0.5

	var body_rear := MeshInstance3D.new()
	body_rear.name = "BodyRear"
	var brm := BoxMesh.new()
	brm.size = Vector3(body_width, body_height, body_length * 0.45)
	body_rear.mesh = brm
	body_rear.material_override = body_mat
	body_rear.position = Vector3(0, 0, body_length * 0.225)
	head.add_child(body_rear)

	var body_front := MeshInstance3D.new()
	body_front.name = "BodyFront"
	var bfm := BoxMesh.new()
	bfm.size = Vector3(body_width * 0.78, body_height * 0.85, body_length * 0.55)
	body_front.mesh = bfm
	body_front.material_override = body_mat
	body_front.position = Vector3(0, 0, body_length * 0.45 + body_length * 0.275)
	head.add_child(body_front)

	# 3b. Lens housing — short cylinder extending from the front.
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = lens_color
	lens_mat.roughness = 0.35
	lens_mat.metallic = 0.6

	var lens := MeshInstance3D.new()
	lens.name = "Lens"
	var lm := CylinderMesh.new()
	lm.top_radius = lens_radius
	lm.bottom_radius = lens_radius * 1.05
	lm.height = lens_length
	lens.mesh = lm
	lens.material_override = lens_mat
	lens.rotation = Vector3(PI * 0.5, 0, 0)
	lens.position = Vector3(0, 0, body_length + lens_length * 0.5)
	head.add_child(lens)

	# 3c. Lens glass — dark disc at the very front.
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = lens_glass_color
	glass_mat.roughness = 0.05
	glass_mat.metallic = 0.0
	glass_mat.emission_enabled = true
	glass_mat.emission = lens_glass_color * 0.4
	glass_mat.emission_energy_multiplier = 0.6

	var glass := MeshInstance3D.new()
	glass.name = "LensGlass"
	var gm := CylinderMesh.new()
	gm.top_radius = lens_radius * 0.85
	gm.bottom_radius = lens_radius * 0.85
	gm.height = 0.004
	glass.mesh = gm
	glass.material_override = glass_mat
	glass.rotation = Vector3(PI * 0.5, 0, 0)
	glass.position = Vector3(0, 0, body_length + lens_length - 0.002)
	head.add_child(glass)

	# 3d. LED indicator — small emissive dot on top of the camera body.
	if led_active:
		var led_mat := StandardMaterial3D.new()
		led_mat.albedo_color = led_color
		led_mat.emission_enabled = true
		led_mat.emission = led_color
		led_mat.emission_energy_multiplier = 2.0
		led_mat.roughness = 0.2

		var led := MeshInstance3D.new()
		led.name = "LED"
		var lem := SphereMesh.new()
		lem.radius = 0.008
		lem.height = 0.016
		led.mesh = lem
		led.material_override = led_mat
		led.position = Vector3(body_width * 0.30, body_height * 0.5 + 0.005, body_length * 0.45)
		head.add_child(led)
