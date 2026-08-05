# negative_control_fixture.gd
# A gauge that reads GREEN, and a lever that plants a known fault in what it
# measures. Until the lever has been pulled and the needle has swung to RED,
# the green means nothing at all.
#
# This is the one honest move left after Rice: you cannot prove the instrument
# correct, but you can prove it CAPABLE OF FAILING. The project's gates carry it
# as `--self-test` — inject a known fault, watch yourself fail, refuse to be
# believed until you have. The negative control as a fixture, not a heroic act.

extends Node3D

class_name NegativeControlFixture

# @identity
# essence: an instrument that earns its green light by first being made to go red
# desire: hold the fault lever where a hand can reach it, so that trusting the gauge requires having broken it
# critical_parameter: proof — the five states an instrument can be in with respect to having demonstrated it can fail
# triggers: pull the lever to inject the planted fault; the needle should swing; if it does not, the instrument is the `silent` value
# emerges: why a passing test is evidence of nothing until the same harness has been seen to fail
# needs: VR area interaction [has], mouse click [has], XR grab [has conceptual]
# relationships: answers rice_verifier_booth (the limit) and critic_regress_stack (the regress) with the only move that survives both; beside godel_statement_plaque
# truth: a green light is a claim about the world AND a claim about the instrument, and only the second one can be checked from here

# ─────────────────────────────────────────────────────────────────────────────
# DNA — ONE AXIS: proof
#
#   proof   WHAT THIS INSTRUMENT HAS DEMONSTRATED ABOUT ITS OWN CAPACITY TO FAIL
#           unproven · injected · certified · silent · absent
#
# The gauge, dial, needle and body are identical under every value. What changes
# is the LEVER, the needle's angle, and whether a red record is mounted beside the
# green lamp. Two of the five read GREEN — `unproven` and `certified` — and they
# are indistinguishable at a glance, which is the axis's whole argument. The
# difference is not in the reading. It is in the history.
#
#   unproven   GREEN, UNTESTED.  Lamp lit, lever still wired shut with its factory
#                                seal, no record card. Reads exactly like a working
#                                instrument. Is exactly like a broken one.
#   injected   RED, MID-PROOF.   Lever thrown, fault card seated in the port, needle
#                                hard over into the red arc. The instrument failing
#                                on purpose — the only moment it says anything true.
#   certified  GREEN, EARNED.    Lamp lit, lever thrown and released, and the red
#                                record mounted BESIDE the green — the failure kept
#                                rather than absorbed. The only trustworthy green.
#   silent     GREEN, FAULT IN.  Lever thrown, fault card seated, needle still resting
#                                in the green. The instrument that cannot fail, and is
#                                therefore worth nothing. Looks the most reliable of
#                                the five. This is what the WAV joiner was.
#   absent     NO LEVER.         Body, dial and lamp, and a blanked plate where the
#                                injection port should be. Nothing can be planted, so
#                                nothing can be shown. Most software ships like this.
#
# WHY `certified` KEEPS THE RED CARD AND DOES NOT CLEAR IT. An instrument that
# passes its self-test and then presents a clean face has compressed away the
# evidence of its own fallibility — the same slope, applied to its own history.
# The museum ruling of 2026-08-01 kept the old score beside the new one for
# exactly this reason. Preserving the record is an anti-erasure move, and it is
# the difference between `certified` and `unproven` being legible at all.
#
# The dark spot (sieve Q3): the fixture cannot show whether the planted fault is
# REPRESENTATIVE. A control proves the instrument can move; it does not prove it
# moves for the faults nobody thought to plant. That is left open, because a value
# claiming to cover it would be the `silent` value wearing a better name.

@export_enum("unproven", "injected", "certified", "silent", "absent") var proof: String = "certified": set = _set_proof

@export var body_width: float = 0.54
@export var body_height: float = 0.80
@export var dial_radius: float = 0.17

@export var body_color: Color = Color(0.19, 0.20, 0.25)
@export var dial_color: Color = Color(0.90, 0.90, 0.88)
@export var pass_color: Color = Color(0.40, 0.88, 0.55)
@export var fail_color: Color = Color(0.95, 0.31, 0.27)
@export var seal_color: Color = Color(0.85, 0.72, 0.30)

const PROOFS: PackedStringArray = ["unproven", "injected", "certified", "silent", "absent"]

signal fault_injected()
signal needle_moved(angle_deg: float)

var _parts: Array[Node] = []
var _built: bool = false


func _ready() -> void:
	_build_body()
	_build_state()
	_built = true


func _set_proof(v: String) -> void:
	proof = v
	if _built:
		_rebuild()


# ─────────────────────────────────────────────────────────────────────────────
# The invariant instrument.

func _build_body() -> void:
	var base: MeshInstance3D = _box(Vector3(body_width + 0.10, 0.05, 0.30), body_color.darkened(0.4))
	base.position = Vector3(0.0, 0.025, 0.0)
	add_child(base)

	var case_mesh: MeshInstance3D = _box(Vector3(body_width, body_height, 0.20), body_color)
	case_mesh.position = Vector3(0.0, body_height * 0.5 + 0.05, 0.0)
	add_child(case_mesh)

	# The dial face — same under every value.
	var dial := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = dial_radius
	cyl.bottom_radius = dial_radius
	cyl.height = 0.012
	dial.mesh = cyl
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = dial_color
	dmat.roughness = 0.35
	dial.material_override = dmat
	dial.rotation.x = PI * 0.5
	dial.position = Vector3(0.0, body_height * 0.68, 0.106)
	add_child(dial)

	# Green arc left, red arc right. The needle chooses.
	_arc_marks(-1.0, pass_color)
	_arc_marks(1.0, fail_color)

	_text("SELF-TEST", Vector3(0.0, body_height * 0.68 + dial_radius + 0.05, 0.115), 0.026, Color(0.72, 0.75, 0.82))


func _arc_marks(dir: float, col: Color) -> void:
	for i in range(4):
		var a: float = deg_to_rad(20.0 + float(i) * 17.0) * dir
		var r: float = dial_radius * 0.80
		var m: MeshInstance3D = _box(Vector3(0.014, 0.030, 0.006), col)
		m.position = Vector3(sin(a) * r, body_height * 0.68 + cos(a) * r, 0.114)
		m.rotation.z = -a
		_emissive(m, col, 0.6)
		add_child(m)


# ─────────────────────────────────────────────────────────────────────────────

func _rebuild() -> void:
	for n in _parts:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()
	_parts.clear()
	_build_state()


func _build_state() -> void:
	var reads_green: bool = proof != "injected"
	var lamp_col: Color = pass_color if reads_green else fail_color
	# -50 deg sits in the green arc, +50 in the red.
	var needle_deg: float = -50.0 if reads_green else 50.0

	_needle(needle_deg)
	_lamp(lamp_col)

	match proof:
		"unproven":
			_lever(false, true)
			_keep(_text("NEVER TESTED", Vector3(0.0, body_height * 0.22, 0.115), 0.022, seal_color))

		"injected":
			_lever(true, false)
			_fault_card()
			_keep(_text("FAULT IN — NEEDLE MOVED", Vector3(0.0, body_height * 0.22, 0.115), 0.021, fail_color))

		"certified":
			_lever(true, false)
			# The red record, kept beside the green rather than absorbed by it.
			var card: MeshInstance3D = _box(Vector3(0.20, 0.13, 0.008), Color(0.14, 0.06, 0.06))
			card.position = Vector3(body_width * 0.52, body_height * 0.46, 0.06)
			_keep(card)
			var stripe: MeshInstance3D = _box(Vector3(0.18, 0.022, 0.010), fail_color)
			stripe.position = Vector3(body_width * 0.52, body_height * 0.50, 0.068)
			_emissive(stripe, fail_color, 1.1)
			_keep(stripe)
			_keep(_text("FAILED ONCE\nON PURPOSE", Vector3(body_width * 0.52, body_height * 0.44, 0.072), 0.018, Color(0.86, 0.62, 0.60)))
			_keep(_text("GREEN, EARNED", Vector3(0.0, body_height * 0.22, 0.115), 0.022, pass_color))

		"silent":
			_lever(true, false)
			_fault_card()
			# Fault seated, needle unmoved. The instrument that cannot fail.
			_keep(_text("FAULT IN — NEEDLE STILL", Vector3(0.0, body_height * 0.22, 0.115), 0.021, seal_color))

		_:  # "absent"
			# A blanked plate where the injection port should be.
			var blank: MeshInstance3D = _box(Vector3(0.16, 0.09, 0.010), body_color.lightened(0.10))
			blank.position = Vector3(0.0, body_height * 0.36, 0.106)
			_keep(blank)
			_keep(_text("NO PORT", Vector3(0.0, body_height * 0.22, 0.115), 0.022, Color(0.60, 0.62, 0.68)))


func _needle(deg: float) -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(0.0, body_height * 0.68, 0.115)
	add_child(pivot)
	_parts.append(pivot)

	var n: MeshInstance3D = _box(Vector3(0.010, dial_radius * 0.86, 0.006), Color(0.10, 0.10, 0.12))
	n.position = Vector3(0.0, dial_radius * 0.43, 0.0)
	pivot.add_child(n)
	pivot.rotation.z = -deg_to_rad(deg)
	needle_moved.emit(deg)


func _lamp(col: Color) -> void:
	var bulb: MeshInstance3D = _sphere(0.030, col)
	bulb.position = Vector3(-body_width * 0.32, body_height * 0.34, 0.112)
	_emissive(bulb, col, 1.6)
	_keep(bulb)

	var light := OmniLight3D.new()
	light.light_color = col
	light.light_energy = 0.7
	light.omni_range = 1.1
	light.position = Vector3(-body_width * 0.32, body_height * 0.34, 0.20)
	add_child(light)
	_parts.append(light)


## The fault lever. `thrown` swings it down; `sealed` wires it shut.
func _lever(thrown: bool, sealed_shut: bool) -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(body_width * 0.30, body_height * 0.40, 0.106)
	add_child(pivot)
	_parts.append(pivot)

	var arm: MeshInstance3D = _box(Vector3(0.024, 0.17, 0.024), Color(0.55, 0.57, 0.62))
	arm.position = Vector3(0.0, 0.085, 0.0)
	pivot.add_child(arm)

	var knob: MeshInstance3D = _sphere(0.028, fail_color if thrown else Color(0.42, 0.44, 0.50))
	knob.position = Vector3(0.0, 0.175, 0.0)
	if thrown:
		_emissive(knob, fail_color, 0.9)
	pivot.add_child(knob)

	pivot.rotation.z = deg_to_rad(62.0) if thrown else 0.0

	if sealed_shut:
		# Factory seal — the lever has never been pulled.
		var wire: MeshInstance3D = _box(Vector3(0.11, 0.008, 0.008), seal_color)
		wire.position = Vector3(body_width * 0.30 - 0.045, body_height * 0.40 + 0.02, 0.118)
		_emissive(wire, seal_color, 0.8)
		_keep(wire)


func _fault_card() -> void:
	var card: MeshInstance3D = _box(Vector3(0.15, 0.085, 0.008), Color(0.30, 0.10, 0.10))
	card.position = Vector3(0.0, body_height * 0.36, 0.108)
	_keep(card)
	_keep(_text("KNOWN FAULT", Vector3(0.0, body_height * 0.36, 0.116), 0.017, Color(0.95, 0.80, 0.78)))
	fault_injected.emit()


# ─────────────────────────────────────────────────────────────────────────────

func _keep(n: Node) -> Node:
	if n.get_parent() == null:
		add_child(n)
	_parts.append(n)
	return n


func _text(text: String, pos: Vector3, size: float, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 64
	l.pixel_size = size / 64.0
	l.modulate = col
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.double_sided = true
	add_child(l)
	return l


func _box(size: Vector3, col: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.3
	mat.roughness = 0.5
	mi.material_override = mat
	return mi


func _sphere(radius: float, col: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mi.material_override = mat
	return mi


func _emissive(mi: MeshInstance3D, col: Color, energy: float) -> void:
	var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy


static func normalise_proof(value: String, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if PROOFS.has(v):
		return v
	return fallback


func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("proof"):
		return
	proof = normalise_proof(str(config_data["proof"]), proof)
	print("NegativeControlFixture: proof=%s" % proof)
