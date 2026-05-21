extends Node3D
class_name Autoclave

# @identity
# essence: a front-loading sterilizer drum — chemistry / biolab vocabulary. A rectangular glossy-steel cabinet with a heavy round door inset into the front face, a wheel-handle latch on the side of the door, a darker recessed interior cavity visible behind it, a small status LED in the top corner, a Portal-orange accent stripe across the top, and an "AUTOCLAVE" Label3D above the door. The architectural form of HEAT-AND-PRESSURE-AS-PURIFICATION
# desire: every lab wants a way to make the small ritual of decontamination visible — to say "things go in dirty, come out clean". The autoclave wants to be the architectural form of CONTAINED TRANSFORMATION via heat. A box with a circular threshold that closes against the world, locks, and applies pressure inside. The wheel-handle says: this is a serious door
# critical_parameter: door_open — closed reads as ACTIVE-CYCLE (sealed, working, do not interrupt), open reads as BETWEEN-USES (load in, take out, the interior visible). Same cabinet, two very different moments in the lab's cycle of cleanliness. The door is a hinge between phases
# triggers: _ready() builds cabinet body + recessed front door (closed or swung 90° open on left edge) + interior cavity + wheel handle + accent stripe + status LED + signage label; apply_grid_config rebuilds
# emerges: closed door + green LED = "cycle running, don't open". Open door + green LED = "ready for next load". Open door + no LED = "out of service". Status_indicator off entirely = "ambiguous, undecided". Same shell, four narratives of operational state
# needs: rectangular cabinet body [present]; round front door inset slightly [present]; wheel handle on the right of the door [present]; darker interior cavity when door open [present]; status LED in top-right [present]; accent stripe across top [present]; "AUTOCLAVE" label above door [present]
# relationships: peer to fume_hood (both = contained-transformation enclosures; hood = release-vapors, autoclave = sterilize-with-pressure); sibling to specimen_jar (autoclave processes containers TO MAKE specimen-jars-able-to-hold-clean-things — the jar's enabling condition); cousin to safety_shower + fire_extinguisher (the lab's vocabulary of HARM-RECOVERY — but the autoclave PREVENTS, the others RESPOND); the architectural admission that lab work generates contamination and contamination must be cycled out
# truth: an autoclave is the architectural form of the lab's RITUAL OF CLEANLINESS. The circle of the door is the cycle. The wheel handle says: closing requires effort, opening requires effort, this is a threshold defended against accident. Without it, the lab would have to pretend that everything stays clean by itself. WITH it, the lab admits that contamination is a constant input and decontamination must be made architectural

## A front-loading sterilizer drum on a rectangular cabinet.
##
## Built procedurally from DNA exports. Origin is at the bottom center
## of the cabinet footprint, on the floor. Faces +Z (the door, handle,
## status LED, and signage all sit on the +Z face). When `door_open` is
## true the round door swings 90° around the Y-axis on its left edge,
## exposing the darker interior cavity.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var body_width: float = 0.6
@export var body_height: float = 0.9
@export var body_depth: float = 0.7
## Radius of the round front door — must fit inside the front face.
@export var door_radius: float = 0.22

@export_group("Color")
## Glossy steel cabinet shell.
@export var body_color: Color = Color(0.78, 0.80, 0.82)
## Dark steel door disc.
@export var door_color: Color = Color(0.30, 0.30, 0.32)
## Darker steel interior cavity (visible when door open).
@export var interior_color: Color = Color(0.12, 0.12, 0.14)
@export var accent_color: Color = Color(0.95, 0.50, 0.10)

@export_group("Door")
## When true, the round door pivots 90° open around the Y-axis on its left edge.
@export var door_open: bool = false

@export_group("Status")
## When true, a small emissive LED appears in the top corner.
@export var status_indicator: bool = true
## LED color — safety green when the autoclave is running.
@export var status_color: Color = Color(0.30, 0.85, 0.40)

@export_group("Signage")
@export var signage_text: String = "AUTOCLAVE"
@export var signage_color: Color = Color(0.98, 0.98, 0.98)

# ── Constants ─────────────────────────────────────────────────────────

const DOOR_THICKNESS: float = 0.04
const DOOR_INSET: float = 0.015
const INTERIOR_DEPTH_FACTOR: float = 0.45   # vs body_depth
const HANDLE_RADIUS: float = 0.04
const HANDLE_THICKNESS: float = 0.022
const HANDLE_HUB_RADIUS: float = 0.012
const HANDLE_HUB_LENGTH: float = 0.05
const ACCENT_STRIP_HEIGHT: float = 0.018
const ACCENT_STRIP_DEPTH: float = 0.006
const LED_RADIUS: float = 0.012
const LABEL_PIXEL_SIZE: float = 0.0028
const LABEL_FONT_SIZE: int = 36

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_autoclave()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_autoclave()


func _read_metadata_overrides() -> void:
	if has_meta("config_body_width"):
		body_width = float(String(get_meta("config_body_width")))
	if has_meta("config_body_height"):
		body_height = float(String(get_meta("config_body_height")))
	if has_meta("config_body_depth"):
		body_depth = float(String(get_meta("config_body_depth")))
	if has_meta("config_door_radius"):
		door_radius = float(String(get_meta("config_door_radius")))
	if has_meta("config_body_color"):
		body_color = _parse_color(String(get_meta("config_body_color")), body_color)
	if has_meta("config_door_color"):
		door_color = _parse_color(String(get_meta("config_door_color")), door_color)
	if has_meta("config_interior_color"):
		interior_color = _parse_color(String(get_meta("config_interior_color")), interior_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(String(get_meta("config_accent_color")), accent_color)
	if has_meta("config_door_open"):
		var d := String(get_meta("config_door_open")).to_lower()
		door_open = d in ["true", "1", "yes", "on"]
	if has_meta("config_status_indicator"):
		var s := String(get_meta("config_status_indicator")).to_lower()
		status_indicator = s in ["true", "1", "yes", "on"]
	if has_meta("config_status_color"):
		status_color = _parse_color(String(get_meta("config_status_color")), status_color)
	if has_meta("config_signage_text"):
		signage_text = String(get_meta("config_signage_text"))
	if has_meta("config_signage_color"):
		signage_color = _parse_color(String(get_meta("config_signage_color")), signage_color)


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_autoclave() -> void:
	_built = true
	_build_cabinet()
	_build_interior_cavity()
	_build_door_assembly()
	_build_accent_strip()
	if status_indicator:
		_build_status_led()
	if signage_text != "":
		_build_signage()


func _build_cabinet() -> void:
	var body := MeshInstance3D.new()
	body.name = "Cabinet"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(body_width, body_height, body_depth)
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.30
	mat.metallic = 0.75
	body.material_override = mat
	body.position = Vector3(0.0, body_height * 0.5, 0.0)
	add_child(body)


# A darker recessed cavity at the front center — the autoclave's interior.
# Always present; visible only when the door is open.
func _build_interior_cavity() -> void:
	var interior_depth: float = body_depth * INTERIOR_DEPTH_FACTOR
	var cavity := MeshInstance3D.new()
	cavity.name = "InteriorCavity"
	var mesh := BoxMesh.new()
	# Slightly smaller than the door radius footprint so it reads as recessed.
	var inner_size: float = door_radius * 1.75
	mesh.size = Vector3(inner_size, inner_size, interior_depth)
	cavity.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = interior_color
	mat.roughness = 0.7
	mat.metallic = 0.4
	cavity.material_override = mat
	# Center the cavity at the door height, recessed back into the cabinet from the +Z face.
	var door_y: float = body_height * 0.55
	cavity.position = Vector3(0.0, door_y, body_depth * 0.5 - interior_depth * 0.5 - DOOR_INSET)
	add_child(cavity)


# Door pivots around a Y-axis at its left edge (-X side) when open.
# The pivot Node3D contains the disc + handle as a unit.
func _build_door_assembly() -> void:
	var door_y: float = body_height * 0.55
	var pivot := Node3D.new()
	pivot.name = "DoorPivot"
	# Pivot sits at the left edge of the disc, on the front face.
	var pivot_x: float = -door_radius
	var pivot_z: float = body_depth * 0.5 - DOOR_INSET
	pivot.position = Vector3(pivot_x, door_y, pivot_z)
	if door_open:
		# Swing 90° open around +Y, so the disc rotates from +Z toward +X.
		pivot.rotation = Vector3(0.0, -PI * 0.5, 0.0)
	add_child(pivot)

	# Door disc — CylinderMesh, axis along +Y by default, rotated so the disc faces +Z.
	var door := MeshInstance3D.new()
	door.name = "Door"
	var dmesh := CylinderMesh.new()
	dmesh.top_radius = door_radius
	dmesh.bottom_radius = door_radius
	dmesh.height = DOOR_THICKNESS
	door.mesh = dmesh
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = door_color
	dmat.roughness = 0.35
	dmat.metallic = 0.80
	door.material_override = dmat
	# Rotate so the cylinder's +Y axis becomes +Z (disc faces +Z).
	door.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	# In pivot-local space, the disc center is +door_radius along +X from the pivot.
	door.position = Vector3(door_radius, 0.0, DOOR_THICKNESS * 0.5)
	pivot.add_child(door)

	# Wheel handle on the right side of the door (in disc-local +X direction).
	var handle := MeshInstance3D.new()
	handle.name = "WheelHandle"
	var hmesh := TorusMesh.new()
	hmesh.inner_radius = HANDLE_RADIUS - HANDLE_THICKNESS
	hmesh.outer_radius = HANDLE_RADIUS
	handle.mesh = hmesh
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = door_color.lerp(Color(0.18, 0.18, 0.20), 0.4)
	hmat.roughness = 0.40
	hmat.metallic = 0.70
	handle.material_override = hmat
	# Lay torus flat against the +Z face of the door (default torus normal is +Y).
	# We want the torus to lie in the XY plane facing +Z — leave default rotation.
	# Position: right side of the disc, slightly forward.
	handle.position = Vector3(door_radius + door_radius * 0.55, 0.0, DOOR_THICKNESS + HANDLE_THICKNESS * 0.5)
	pivot.add_child(handle)

	# Small hub at handle center.
	var hub := MeshInstance3D.new()
	hub.name = "WheelHub"
	var hubmesh := CylinderMesh.new()
	hubmesh.top_radius = HANDLE_HUB_RADIUS
	hubmesh.bottom_radius = HANDLE_HUB_RADIUS
	hubmesh.height = HANDLE_HUB_LENGTH
	hub.mesh = hubmesh
	hub.material_override = hmat
	# Cylinder's +Y axis to +Z so it sticks straight out from the door.
	hub.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	hub.position = Vector3(door_radius + door_radius * 0.55, 0.0, DOOR_THICKNESS + HANDLE_HUB_LENGTH * 0.5)
	pivot.add_child(hub)


func _build_accent_strip() -> void:
	var strip := MeshInstance3D.new()
	strip.name = "AccentStrip"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(body_width * 0.96, ACCENT_STRIP_HEIGHT, ACCENT_STRIP_DEPTH)
	strip.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	strip.material_override = mat
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Top of cabinet, on the +Z face.
	var y: float = body_height - ACCENT_STRIP_HEIGHT * 1.2
	var z: float = body_depth * 0.5 + ACCENT_STRIP_DEPTH * 0.5
	strip.position = Vector3(0.0, y, z)
	add_child(strip)


func _build_status_led() -> void:
	var led := MeshInstance3D.new()
	led.name = "StatusLED"
	var mesh := CylinderMesh.new()
	mesh.top_radius = LED_RADIUS
	mesh.bottom_radius = LED_RADIUS
	mesh.height = 0.004
	led.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = status_color
	mat.emission_enabled = true
	mat.emission = status_color
	mat.emission_energy_multiplier = 2.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	led.material_override = mat
	led.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Cylinder default axis is +Y; rotate to face +Z so it appears as a disc on the front face.
	led.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	# Top-right corner of the front face.
	var x: float = body_width * 0.5 - LED_RADIUS * 2.5
	var y: float = body_height - LED_RADIUS * 2.5
	var z: float = body_depth * 0.5 + 0.003
	led.position = Vector3(x, y, z)
	add_child(led)


func _build_signage() -> void:
	var label := Label3D.new()
	label.name = "Signage"
	label.text = signage_text
	label.font_size = LABEL_FONT_SIZE
	label.outline_size = 3
	label.pixel_size = LABEL_PIXEL_SIZE
	label.modulate = signage_color
	label.outline_modulate = Color(0.05, 0.05, 0.07)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Above the door, on the front face. Default Label3D faces +Z — leave default rotation.
	var y: float = body_height * 0.55 + door_radius + 0.06
	var z: float = body_depth * 0.5 + 0.005
	label.position = Vector3(0.0, y, z)
	add_child(label)


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
