extends Node3D
class_name EmergencyButton

# @identity
# essence: a red mushroom E-stop on a yellow hazard plate — the universal industrial vocabulary for "press this and everything stops". Square or rounded yellow base plate, large alarm-red mushroom dome on a small ring, a label below reading "EMERGENCY STOP", and a strong emissive glow on the dome when it is NOT pressed. Wall-mountable or on a small podium.
# desire: the button wants to be the most VISIBLE thing in the room — yellow against any wall, red against any palette, glowing against any lighting. It is the chamber's promise that the experiment is interruptible. It is also a small THREAT that the experiment might NEED to be interrupted.
# critical_parameter: pressed — false reads as "armed, alert, hot" (mushroom proud, glowing, label readable), true reads as "fired, latched, locked-out" (mushroom depressed, glow dim, the room is in alarm-state). The button has two postures, and they ARE the two states the room can be in.
# triggers: _ready() builds plate + mushroom + ring base + label + optional podium stand from exports; apply_grid_config rebuilds
# emerges: armed + wall = "every chamber's standard safety"; pressed + podium = "this is a museum piece, an interrupted experiment"; black-text label + bright dome = "instructions for the body in emergency"; podium mount + dim = "props, theatrical"
# needs: yellow hazard plate BoxMesh [present]; red mushroom CylinderMesh top_radius > bottom_radius [present]; small ring base CylinderMesh around the dome [present]; baked label_text quad painted on plate face [present]; emissive glow when not pressed [present]; depression offset when pressed [present]; optional podium pillar [present]
# relationships: sibling to exit_sign (both are the room's emergency vocabulary — the sign promises escape, the button promises stop); cousin to control_board (the control_board operates an experiment, the button TERMINATES it — they are bookends); peer to fume_hood (a hood without a nearby E-stop is a hood the lab doesn't trust)
# truth: an emergency button is not just a switch. It is the room's MORAL ESCAPE HATCH — the promise that consent to participate in the experiment includes the right to withdraw it instantly. The mushroom shape is so that a falling body, slumping, palm-down, will press it.

## A red mushroom emergency stop button on a yellow hazard plate.
##
## Built procedurally from DNA. Origin is at the CENTER of the plate, the
## front face of the plate is at +Z and the mushroom points +Z. When
## mounting="podium", a short stand drops below origin. When mounting="wall",
## the back of the plate is at z=0 so it mounts flush to a wall plane.

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Colors")
@export var button_color: Color = Color(0.95, 0.10, 0.10)
@export var plate_color: Color = Color(0.98, 0.85, 0.10)
@export var text_color: Color = Color(0.05, 0.05, 0.05)

@export_group("Dimensions")
@export var button_radius: float = 0.05
@export var plate_width: float = 0.18
@export var plate_height: float = 0.18

@export_group("Text")
@export var label_text: String = "EMERGENCY STOP"

@export_group("State")
## When true, the mushroom is depressed and the emissive glow is dimmed.
@export var pressed: bool = false

@export_group("Mounting")
## "wall" — flush against a wall (back of plate at z=0).
## "podium" — adds a short pillar stand below the plate so it stands free.
@export var mounting: String = "wall"

# ── Constants ─────────────────────────────────────────────────────────

const PLATE_THICKNESS: float = 0.014
const MUSHROOM_BOTTOM_FRAC: float = 0.65   # bottom radius as fraction of top
const MUSHROOM_HEIGHT: float = 0.04
const MUSHROOM_RAISE: float = 0.018         # rest above the plate when armed
const PRESSED_DROP_FRAC: float = 0.25       # depression amount when pressed
const RING_RADIUS_FRAC: float = 1.25        # ring outer radius vs mushroom bottom
const RING_HEIGHT: float = 0.006
const PODIUM_HEIGHT: float = 0.95
const PODIUM_HALF_WIDTH: float = 0.045
const LABEL_Y_OFFSET_FRAC: float = 0.30     # label below center, frac of plate_height

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_button()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		_clear_built_children()
		_built = false
		_build_button()


func _read_metadata_overrides() -> void:
	if has_meta("config_button_color"):
		button_color = _parse_color(str(get_meta("config_button_color")), button_color)
	if has_meta("config_plate_color"):
		plate_color = _parse_color(str(get_meta("config_plate_color")), plate_color)
	if has_meta("config_text_color"):
		text_color = _parse_color(str(get_meta("config_text_color")), text_color)
	if has_meta("config_button_radius"):
		button_radius = float(str(get_meta("config_button_radius")))
	if has_meta("config_plate_width"):
		plate_width = float(str(get_meta("config_plate_width")))
	if has_meta("config_plate_height"):
		plate_height = float(str(get_meta("config_plate_height")))
	if has_meta("config_label_text"):
		label_text = str(get_meta("config_label_text"))
	if has_meta("config_pressed"):
		var v := str(get_meta("config_pressed")).to_lower()
		pressed = v in ["true", "1", "yes", "on"]
	if has_meta("config_mounting"):
		mounting = str(get_meta("config_mounting")).to_lower()


func _clear_built_children() -> void:
	for c in get_children():
		c.queue_free()


# ── Build ─────────────────────────────────────────────────────────────

func _build_button() -> void:
	_built = true
	if mounting == "podium":
		_build_podium()
	_build_plate()
	_build_ring_base()
	_build_mushroom()
	_build_label()


func _plate_front_z() -> float:
	# Plate centered at z = PLATE_THICKNESS/2 so its back sits at z = 0 (wall).
	# Front face is at z = PLATE_THICKNESS.
	return PLATE_THICKNESS


func _build_podium() -> void:
	# Short BoxMesh pillar dropping from below the plate to the floor.
	var podium := MeshInstance3D.new()
	podium.name = "Podium"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(PODIUM_HALF_WIDTH * 2.0, PODIUM_HEIGHT, PODIUM_HALF_WIDTH * 2.0)
	podium.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.22, 0.24)
	mat.roughness = 0.45
	mat.metallic = 0.55
	podium.material_override = mat
	# Plate origin is taken as plate-center. Place podium so its top sits at
	# the bottom edge of the plate.
	podium.position = Vector3(0.0, -plate_height * 0.5 - PODIUM_HEIGHT * 0.5, _plate_front_z() * 0.5)
	add_child(podium)

	# Small foot pad.
	var foot := MeshInstance3D.new()
	foot.name = "PodiumFoot"
	var fm := BoxMesh.new()
	fm.size = Vector3(PODIUM_HALF_WIDTH * 2.6, 0.02, PODIUM_HALF_WIDTH * 2.6)
	foot.mesh = fm
	foot.material_override = mat
	foot.position = Vector3(0.0, -plate_height * 0.5 - PODIUM_HEIGHT + 0.01, _plate_front_z() * 0.5)
	add_child(foot)


func _build_plate() -> void:
	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(plate_width, plate_height, PLATE_THICKNESS)
	plate.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = plate_color
	mat.roughness = 0.55
	mat.metallic = 0.05
	# A touch of emission so the hazard yellow reads bright even in dim chambers.
	mat.emission_enabled = true
	mat.emission = plate_color
	mat.emission_energy_multiplier = 0.18
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	plate.material_override = mat
	plate.position = Vector3(0.0, 0.0, PLATE_THICKNESS * 0.5)
	add_child(plate)


func _build_ring_base() -> void:
	# Small black ring around the mushroom base. Cylinder lying along +Z.
	var ring := MeshInstance3D.new()
	ring.name = "RingBase"
	var ring_outer := button_radius * RING_RADIUS_FRAC
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = ring_outer
	ring_mesh.bottom_radius = ring_outer
	ring_mesh.height = RING_HEIGHT
	ring.mesh = ring_mesh
	# Rotate cylinder so its axis points +Z (default axis is +Y).
	ring.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.10, 0.10)
	mat.roughness = 0.5
	mat.metallic = 0.5
	ring.material_override = mat
	var z := _plate_front_z() + RING_HEIGHT * 0.5
	ring.position = Vector3(0.0, 0.0, z)
	add_child(ring)


func _build_mushroom() -> void:
	# Red mushroom — top_radius bigger than bottom_radius, axis along +Z.
	var mush := MeshInstance3D.new()
	mush.name = "Mushroom"
	var mesh := CylinderMesh.new()
	mesh.top_radius = button_radius
	mesh.bottom_radius = button_radius * MUSHROOM_BOTTOM_FRAC
	mesh.height = MUSHROOM_HEIGHT
	mush.mesh = mesh
	# Rotate so the cylinder axis points +Z; the wider top faces the player.
	# Default cylinder runs along +Y with top at +Y; we want the wider end at +Z.
	mush.rotation = Vector3(deg_to_rad(-90.0), 0.0, 0.0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = button_color
	mat.roughness = 0.35
	mat.metallic = 0.05
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if not pressed:
		mat.emission_enabled = true
		mat.emission = button_color
		mat.emission_energy_multiplier = 1.8
	else:
		# Dim residual glow when latched/pressed.
		mat.emission_enabled = true
		mat.emission = button_color
		mat.emission_energy_multiplier = 0.25
	mush.material_override = mat

	# Z position: ring sits on plate front; mushroom rises further by MUSHROOM_RAISE.
	# Center of the cylinder (after rotation) is at z = ring_top + height/2 - raise_drop.
	var ring_top_z := _plate_front_z() + RING_HEIGHT
	var raise_amount := MUSHROOM_RAISE
	if pressed:
		raise_amount *= (1.0 - PRESSED_DROP_FRAC)
	var center_z := ring_top_z + raise_amount + MUSHROOM_HEIGHT * 0.5
	mush.position = Vector3(0.0, 0.0, center_z)
	add_child(mush)


func _build_label() -> void:
	# Bake the label text directly onto the plate surface — no floating Label3D.
	# world_size: width spans ~88% of the plate; height is ~18% (one text row).
	var w: float = plate_width * 0.88
	var h: float = plate_height * 0.18
	var quad: MeshInstance3D = BakedText.make_panel_mesh(
		label_text,
		plate_color,
		text_color,
		Vector2(w, h)
	)
	if quad == null:
		return
	quad.name = "LabelBaked"
	# Position: same y as old Label3D (below centre), z proud of plate front by 0.003m.
	var y := -plate_height * LABEL_Y_OFFSET_FRAC
	var z := _plate_front_z() + 0.003
	quad.position = Vector3(0.0, y, z)
	add_child(quad)


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
