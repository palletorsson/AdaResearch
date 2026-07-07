extends Node3D
class_name CatalystPickup

# @identity
# essence: a pedestal with a glowing token floating above it. The closing
#   gesture of a lab chamber — the thing you walk up to AFTER understanding
#   the apparatus. Grabbing it tells the LabManager that you've completed
#   this chamber's sequence; the corresponding catalyst-bracelet mode
#   unlocks. The chamber stops being a museum and becomes a course; the
#   bracelet remembers what you learned.
# desire: every lab chamber's apparatus teaches an algorithm. The pickup
#   is the moment "I learned" becomes "I have." Without it, the chamber
#   is an exhibit; with it, the chamber graduates the player.
# critical_parameter: sequence_name — IS the catalyst-bracelet mode this
#   pedestal unlocks. Already wired into LabManager via is_sequence_completed,
#   so the bracelet sees the mode automatically once this pickup fires.
# triggers: _ready() builds pedestal + floating orb + sign. On
#   `catalyst_taken` (via VR interactable area OR the apply_grid_config
#   `claimed: true` flag), the orb dims, the pedestal accent goes green,
#   and LabManager.complete_sequence_external(sequence_name) is called.
# emerges: same pedestal, different chamber: drop it in Monte_Carlo_Room
#   with sequence_name=randomness, the bracelet's chaos mode unlocks
#   after pickup. Drop it in Foundations_Crisis_Hall with sequence_name=
#   foundationscrisis, that sequence's reward fires.
# needs: pedestal CylinderMesh; floating orb SphereMesh with emission;
#   orb pulses (Tween or modulate animation); Label3D ring at base with
#   the catalyst name; optional interactable_area for VR grab.
# relationships: bridges lab_room (the chamber container) and
#   becoming_catalyst (the bracelet that gains modes). Both already exist;
#   this is the connector.
# truth: the chamber teaches the algorithm; the catalyst is the
#   algorithm-as-tool; the pickup is the moment the tool enters the hand.

## A pedestal + floating glowing token. Grab it to complete a sequence.
## Origin = bottom center of the pedestal. Orb floats at +Y above the
## pedestal top. Sign reads in +Z (player approach direction).

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Identity")
## The spine sequence this pickup represents — e.g. "randomness",
## "foundationscrisis", "fractals". Must match one of LabManager's
## known sequence rewards (and one of becoming_catalyst's mode_def
## sequence fields) for the bracelet's mode to unlock automatically.
@export var sequence_name: String = "randomness"
## The label displayed on the front of the pedestal.
@export var label_text: String = "RANDOMNESS CATALYST"

@export_group("Dimensions")
@export var pedestal_radius: float = 0.18
@export var pedestal_height: float = 0.65
@export var orb_radius: float = 0.07
@export var orb_float_height: float = 0.18

@export_group("Color")
## Color of the floating catalyst orb. Match the sequence's mode color:
##   randomness=chaos red-orange, fractals=violet, cellular_automata=green,
##   color=full-spectrum, wavefunctions=cyan, etc.
@export var orb_color: Color = Color(0.95, 0.55, 0.20)
@export var orb_emission: float = 2.0
@export var pedestal_color: Color = Color(0.20, 0.20, 0.24)
@export var label_color: Color = Color(0.95, 0.96, 0.98)
@export var accent_color: Color = Color(0.95, 0.55, 0.20)

@export_group("State")
## When true, the orb has been collected — orb dims, pedestal accent
## turns green, no pickup fires on next interaction. Map data can set
## this to start the pickup in the "already-taken" state for tutorials.
@export var claimed: bool = false

@export_group("Animation")
## When true, the orb pulses in size + emission over time (kept simple
## via a Tween in _ready). Set false for static decorative versions.
@export var pulsing: bool = true

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false
var _orb: MeshInstance3D = null
var _orb_material: StandardMaterial3D = null
var _accent_ring: MeshInstance3D = null


# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_pickup()
	if pulsing and not claimed:
		_start_pulse()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for child in get_children():
			child.queue_free()
		_orb = null
		_orb_material = null
		_accent_ring = null
		_built = false
		_build_pickup()
		if pulsing and not claimed:
			_start_pulse()


func _read_metadata_overrides() -> void:
	if has_meta("config_sequence_name"):
		sequence_name = str(get_meta("config_sequence_name"))
	if has_meta("config_label_text"):
		label_text = str(get_meta("config_label_text"))
	if has_meta("config_orb_color"):
		orb_color = _parse_color(str(get_meta("config_orb_color")), orb_color)
	if has_meta("config_pedestal_color"):
		pedestal_color = _parse_color(str(get_meta("config_pedestal_color")), pedestal_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_claimed"):
		var v: String = str(get_meta("config_claimed")).to_lower()
		claimed = (v == "true" or v == "1" or v == "yes")
	if has_meta("config_pulsing"):
		var v2: String = str(get_meta("config_pulsing")).to_lower()
		pulsing = (v2 == "true" or v2 == "1" or v2 == "yes")
	if has_meta("config_pedestal_height"):
		pedestal_height = float(str(get_meta("config_pedestal_height")))
	if has_meta("config_orb_radius"):
		orb_radius = float(str(get_meta("config_orb_radius")))


func _parse_color(s: String, fallback: Color) -> Color:
	var parts: PackedStringArray = s.split(",")
	if parts.size() < 3:
		return fallback
	var r: float = float(parts[0])
	var g: float = float(parts[1])
	var b: float = float(parts[2])
	var a: float = 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)


# ── Build ─────────────────────────────────────────────────────────────

func _build_pickup() -> void:
	# Pedestal column
	var ped := MeshInstance3D.new()
	ped.name = "Pedestal"
	var ped_mesh := CylinderMesh.new()
	ped_mesh.top_radius = pedestal_radius
	ped_mesh.bottom_radius = pedestal_radius * 1.10
	ped_mesh.height = pedestal_height
	ped.mesh = ped_mesh
	var ped_mat := StandardMaterial3D.new()
	ped_mat.albedo_color = pedestal_color
	ped_mat.metallic = 0.65
	ped_mat.roughness = 0.35
	ped.material_override = ped_mat
	ped.position = Vector3(0.0, pedestal_height * 0.5, 0.0)
	add_child(ped)

	# Accent ring around the top of the pedestal — green when claimed, sequence colour otherwise
	_accent_ring = MeshInstance3D.new()
	_accent_ring.name = "AccentRing"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = pedestal_radius * 0.95
	ring_mesh.outer_radius = pedestal_radius * 1.08
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 8
	_accent_ring.mesh = ring_mesh
	var ring_mat := StandardMaterial3D.new()
	var ring_color: Color = Color(0.30, 0.85, 0.40) if claimed else accent_color
	ring_mat.albedo_color = ring_color
	ring_mat.emission_enabled = true
	ring_mat.emission = ring_color
	ring_mat.emission_energy_multiplier = 1.5
	_accent_ring.material_override = ring_mat
	_accent_ring.position = Vector3(0.0, pedestal_height + 0.005, 0.0)
	add_child(_accent_ring)

	# Floating orb above the pedestal
	_orb = MeshInstance3D.new()
	_orb.name = "Orb"
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = orb_radius
	orb_mesh.height = orb_radius * 2.0
	orb_mesh.radial_segments = 24
	orb_mesh.rings = 16
	_orb.mesh = orb_mesh
	_orb_material = StandardMaterial3D.new()
	if claimed:
		# Dim the orb — the catalyst was already taken
		_orb_material.albedo_color = Color(0.35, 0.35, 0.40)
		_orb_material.emission_enabled = true
		_orb_material.emission = Color(0.15, 0.15, 0.18)
		_orb_material.emission_energy_multiplier = 0.4
	else:
		_orb_material.albedo_color = orb_color
		_orb_material.emission_enabled = true
		_orb_material.emission = orb_color
		_orb_material.emission_energy_multiplier = orb_emission
	_orb_material.metallic = 0.2
	_orb_material.roughness = 0.20
	_orb.material_override = _orb_material
	_orb.position = Vector3(0.0, pedestal_height + orb_float_height, 0.0)
	add_child(_orb)

	# Label3D on the front of the pedestal showing the catalyst name
	if label_text != "":
		var label := Label3D.new()
		label.name = "Label"
		label.text = label_text
		label.font_size = 32
		label.outline_size = 3
		label.pixel_size = 0.004
		label.modulate = label_color
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.no_depth_test = false
		label.position = Vector3(0.0, pedestal_height * 0.55, pedestal_radius + 0.005)
		add_child(label)

		# Status sub-label — "READY" when not claimed, "TAKEN" when claimed
		var status := Label3D.new()
		status.name = "Status"
		status.text = ("TAKEN" if claimed else "READY")
		status.font_size = 20
		status.outline_size = 2
		status.pixel_size = 0.004
		status.modulate = Color(0.30, 0.85, 0.40) if claimed else accent_color
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status.no_depth_test = false
		status.position = Vector3(0.0, pedestal_height * 0.32, pedestal_radius + 0.005)
		add_child(status)

	_built = true


func _start_pulse() -> void:
	# Gentle scale + emission pulse on the orb to mark it as "available."
	if _orb == null or _orb_material == null:
		return
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_orb, "scale", Vector3.ONE * 1.12, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_orb, "scale", Vector3.ONE * 0.94, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ── Pickup API ────────────────────────────────────────────────────────

## Called by an interactable_area or a map_data-supplied trigger when
## the player grabs the orb. Fires the LabManager completion event,
## then visually marks the pedestal as taken.
func take_catalyst() -> void:
	if claimed:
		print("CatalystPickup[%s]: already taken" % sequence_name)
		return

	# Tell the LabManager — the canonical event that unlocks the bracelet
	var lab_mgr: Node = get_node_or_null("/root/LabManager")
	if lab_mgr != null:
		# Prefer the public completion entry point if it exists
		if lab_mgr.has_method("complete_sequence_external"):
			lab_mgr.call("complete_sequence_external", sequence_name)
			print("CatalystPickup: → LabManager.complete_sequence_external(%s)" % sequence_name)
		elif lab_mgr.has_method("_on_sequence_completed"):
			# Fall back to the internal handler (visible in the source)
			lab_mgr.call("_on_sequence_completed", sequence_name)
			print("CatalystPickup: → LabManager._on_sequence_completed(%s)" % sequence_name)
		else:
			push_warning("CatalystPickup: LabManager has no completion entry point")
	else:
		push_warning("CatalystPickup: no LabManager autoload — completion event dropped")

	claimed = true
	# Rebuild visually so the orb dims + status flips to TAKEN
	for child in get_children():
		child.queue_free()
	_built = false
	_build_pickup()
