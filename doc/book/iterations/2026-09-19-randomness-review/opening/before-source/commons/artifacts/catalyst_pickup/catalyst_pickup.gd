extends Node3D
class_name CatalystPickup

# Preload (not the global class_name) so a freshly-created kit resolves headless too.
const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

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

@export_group("DNA")
## AXIS — ON WHAT TERMS THE REWARD IS OFFERED. `sequence_name` says WHICH catalyst;
## `claimed` says whether it is still there. Neither says the thing a room actually
## communicates before you reach: what this apparatus thinks its prize IS, and what it
## expects of you. The same orb, the same completion event, five different institutions
## around it — and a chamber that ends in a vending slot has taught something different
## from a chamber that ends in a shrine, even when the code path is identical.
##
##   plinth   free-standing — the legacy lineage, byte for byte. A bare column, a lit
##            ring, an orb floating in open air. Nothing between you and it; take it.
##   vitrine  behind glass — four posts, a glazed case and a capping plate over the orb,
##            with DO NOT HANDLE printed on the rail. The reward has become an EXHIBIT:
##            the chamber went back to being a museum at the last moment.
##   clamp    held by the machine — three worn-metal fingers rise off the pedestal rim
##            and close on the orb, an interlock band burning at their root. It is not
##            offered, it is GRIPPED; the apparatus must let go first.
##   shrine   venerated — three stepped rings ring the foot, a stele stands behind the
##            orb carrying the sequence's name, two embers flank it. Approach, don't grab.
##            Knowledge as relic rather than tool.
##   chute    vended — a dispenser cabinet wraps the pedestal top with a dark delivery
##            slot, a catch tray and a DISPENSE readout below the orb. The reward is
##            transactional: an output of a machine you fed, not a thing you understood.
##
## Appearance only. Nothing here adds a collider or touches take_catalyst(), so the grab
## and the LabManager completion event are identical at every value.
@export_enum("plinth", "vitrine", "clamp", "shrine", "chute") var offer: String = "plinth"
const OFFERS: PackedStringArray = ["plinth", "vitrine", "clamp", "shrine", "chute"]

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
	if has_meta("config_offer"):
		var o: String = str(get_meta("config_offer")).strip_edges().to_lower()
		offer = o if OFFERS.has(o) else offer


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

	# OFFER dressing, appended LAST so every node built above keeps its index and
	# position on the legacy path. "plinth" falls through and adds nothing at all.
	match offer:
		"vitrine":
			_offer_vitrine()
		"clamp":
			_offer_clamp()
		"shrine":
			_offer_shrine()
		"chute":
			_offer_chute()
		_:
			pass                                  # "plinth" — the legacy lineage

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


# ── OFFER ────────────────────────────────────────────────────────────────────
# One axis, five institutions around one orb. Built from HangarKit (worn_metal,
# painted_metal, rams_body, emissive, stencil, readout, three_color_bar, box) so the
# pedestal stays inside the cabinet grammar the lab props share. Nothing below adds a
# collider or an animation: every value is a claim a still can hold.

## VITRINE — behind glass. Four posts off a seating rail, a glazed case and a capping
## plate over the orb, DO NOT HANDLE printed on the rail. The chamber graduates you and
## then, at the last moment, puts the diploma in a display case.
func _offer_vitrine() -> void:
	var base: float = pedestal_height + 0.055
	var orb_y: float = pedestal_height + orb_float_height
	var half: float = maxf(pedestal_radius * 1.20, orb_radius * 2.6)
	var case_h: float = maxf(orb_y + orb_radius * 2.2 - base, 0.22)
	var steel: StandardMaterial3D = HangarKit.worn_metal(pedestal_color.lightened(0.36))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.60, 0.69, 0.76, 0.20)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic = 0.15
	add_child(HangarKit.box(Vector3(0.0, base - 0.016, 0.0),
		Vector3(half * 2.18, 0.032, half * 2.18), steel))
	for sx in [1.0, -1.0]:
		for sz in [1.0, -1.0]:
			var px: float = sx * half
			var pz: float = sz * half
			add_child(HangarKit.box(Vector3(px, base + case_h * 0.5, pz),
				Vector3(0.024, case_h, 0.024), steel))
	add_child(HangarKit.box(Vector3(0.0, base + case_h * 0.5, 0.0),
		Vector3(half * 2.0, case_h, half * 2.0), glass))
	add_child(HangarKit.box(Vector3(0.0, base + case_h + 0.015, 0.0),
		Vector3(half * 2.18, 0.030, half * 2.18), steel))
	var q: MeshInstance3D = HangarKit.stencil("DO NOT HANDLE",
		Vector2(half * 1.7, 0.026), Color(0.90, 0.91, 0.94))
	if q:
		q.position = Vector3(0.0, base - 0.016, half * 1.10 + 0.004)
		add_child(q)


## CLAMP — held by the machine. Three worn-metal fingers rise off the pedestal rim,
## angle in and close their pads on the orb, with a red interlock band burning at their
## root. The reward is not offered; the apparatus has it, and must let go first.
func _offer_clamp() -> void:
	var top: float = pedestal_height
	var orb_y: float = pedestal_height + orb_float_height
	var steel: StandardMaterial3D = HangarKit.worn_metal(pedestal_color.lightened(0.38))
	var pad: StandardMaterial3D = HangarKit.painted_metal(Color(0.16, 0.17, 0.20), 0.40)
	var r: float = pedestal_radius * 0.86
	var post_h: float = maxf(orb_y - orb_radius - top - 0.02, 0.08)
	for i in range(3):
		var arm := Node3D.new()
		arm.name = "ClampArm_%d" % i
		arm.rotation.y = TAU * float(i) / 3.0
		add_child(arm)
		arm.add_child(HangarKit.box(Vector3(r, top + post_h * 0.5, 0.0),
			Vector3(0.052, post_h, 0.052), steel))
		var knuckle: MeshInstance3D = HangarKit.box(
			Vector3(r * 0.72, top + post_h + 0.042, 0.0), Vector3(0.15, 0.036, 0.05), steel)
		knuckle.rotation_degrees = Vector3(0.0, 0.0, 34.0)
		arm.add_child(knuckle)
		arm.add_child(HangarKit.box(Vector3(orb_radius + 0.026, orb_y - orb_radius * 0.15, 0.0),
			Vector3(0.034, 0.058, 0.05), pad))
	var band := MeshInstance3D.new()
	band.name = "ClampInterlock"
	var tm := TorusMesh.new()
	tm.inner_radius = pedestal_radius * 0.98
	tm.outer_radius = pedestal_radius * 1.24
	band.mesh = tm
	band.material_override = HangarKit.emissive(Color(0.92, 0.20, 0.12), 2.0)
	band.position = Vector3(0.0, top + 0.058, 0.0)
	add_child(band)


## SHRINE — venerated. Three stepped rings around the foot, a stele standing behind the
## orb with the sequence's name cut into it, two embers flanking at the step line. The
## algorithm as relic: you are asked to approach it, not to pick it up.
func _offer_shrine() -> void:
	var stone: StandardMaterial3D = HangarKit.rams_body(pedestal_color.lightened(0.44), 0.20)
	var trim: StandardMaterial3D = HangarKit.worn_metal(pedestal_color.lightened(0.24))
	var radii: PackedFloat32Array = PackedFloat32Array([
		pedestal_radius * 2.6, pedestal_radius * 2.05, pedestal_radius * 1.5])
	for i in range(3):
		var step := MeshInstance3D.new()
		step.name = "ShrineStep_%d" % i
		var cm := CylinderMesh.new()
		cm.top_radius = radii[i]
		cm.bottom_radius = radii[i]
		cm.height = 0.055
		cm.radial_segments = 28
		step.mesh = cm
		step.material_override = stone
		step.position = Vector3(0.0, 0.0275 + 0.055 * float(i), 0.0)
		add_child(step)
	var st_h: float = pedestal_height * 0.62
	var st_y: float = pedestal_height + orb_float_height + 0.02
	var st_z: float = -pedestal_radius * 0.95
	add_child(HangarKit.box(Vector3(0.0, st_y, st_z),
		Vector3(pedestal_radius * 1.5, st_h, 0.045), trim))
	var q: MeshInstance3D = HangarKit.stencil(sequence_name.to_upper(),
		Vector2(pedestal_radius * 1.3, 0.05), accent_color.lightened(0.35))
	if q:
		q.position = Vector3(0.0, st_y + st_h * 0.28, st_z + 0.026)
		add_child(q)
	for s in [1.0, -1.0]:
		var sf: float = s
		add_child(HangarKit.box(Vector3(sf * pedestal_radius * 1.78, 0.195, 0.0),
			Vector3(0.05, 0.075, 0.05), HangarKit.emissive(accent_color, 1.8)))


## CHUTE — vended. A dispenser cabinet wraps the pedestal top: a dark delivery mouth, a
## tilted catch tray, a DISPENSE readout and a Rams bar, with the orb sitting above the
## machine like an output. The cabinet swallows the accent ring, which is the point —
## the lit ring said "reward"; the slot says "transaction".
func _offer_chute() -> void:
	var top: float = pedestal_height
	var body: StandardMaterial3D = HangarKit.painted_metal(pedestal_color.lightened(0.18), 0.35)
	var trim: StandardMaterial3D = HangarKit.worn_metal(pedestal_color.lightened(0.36))
	var w: float = pedestal_radius * 2.5
	var d: float = pedestal_radius * 1.95
	var cab_h: float = pedestal_height * 0.52
	var cy: float = top - cab_h * 0.5 + 0.06
	var fz: float = d * 0.5
	add_child(HangarKit.box(Vector3(0.0, cy, 0.0), Vector3(w, cab_h, d), body))
	add_child(HangarKit.box(Vector3(0.0, cy + cab_h * 0.5 + 0.013, 0.0),
		Vector3(w * 1.06, 0.026, d * 1.06), trim))
	add_child(HangarKit.box(Vector3(0.0, cy - cab_h * 0.22, fz + 0.005),
		Vector3(w * 0.62, 0.075, 0.02),
		HangarKit.painted_metal(Color(0.03, 0.035, 0.045), 0.6, 0.2, 0.9)))
	var tray: MeshInstance3D = HangarKit.box(Vector3(0.0, cy - cab_h * 0.30, fz + 0.055),
		Vector3(w * 0.66, 0.016, 0.10), trim)
	tray.rotation_degrees = Vector3(-14.0, 0.0, 0.0)
	add_child(tray)
	var screen: Node3D = HangarKit.readout("DISPENSE", ["1 REMAINING"],
		Vector2(w * 0.62, w * 0.26), Color(0.88, 0.86, 0.80),
		Color(0.09, 0.09, 0.11), Color(0.09, 0.09, 0.11))
	if screen:
		screen.position = Vector3(0.0, cy + cab_h * 0.20, fz + 0.035)
		add_child(screen)
	var bar: Node3D = HangarKit.three_color_bar(w * 0.66, 0.030,
		[accent_color, HangarKit.DISPLAY_DARK, pedestal_color.lightened(0.52)])
	bar.position = Vector3(0.0, cy - cab_h * 0.44, fz + 0.02)
	add_child(bar)
