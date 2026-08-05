# rice_verifier_booth.gd
# A verification booth that answers every question about a program's FORM
# and cannot answer any question about its MEANING.
#
# Rice's theorem (1953): no algorithm decides any non-trivial semantic
# property of a program from its code. Not "is it correct", not "is it
# biased", not "does it halt". The booth is that theorem as furniture.

extends Node3D

class_name RiceVerifierBooth

# @identity
# essence: the verifier that cannot exist — syntax answered, semantics refused, by theorem
# desire: take a question at the slot and be honest about which half of the world it falls in
# critical_parameter: refusal — the five stances an instrument can take toward a question it cannot decide
# triggers: click the slot to submit; the syntactic rack lights, the semantic rack does whatever `refusal` says
# emerges: the floor under all self-checking — a system cannot audit its own meaning from inside its own description
# needs: VR area interaction [has], mouse click [has]
# relationships: beside godel_statement_plaque (the sentence this booth cannot rule on); contrasts negative_control_fixture (which earns trust by failing on purpose); depends on critic_regress_stack (what happens when you try to fix this by adding a meta-level)
# truth: no algorithm decides a non-trivial semantic property of a program — self-verification is closed by proof, not by insufficient engineering

# ─────────────────────────────────────────────────────────────────────────────
# DNA — ONE AXIS: refusal
#
#   refusal   WHAT THE BOOTH DOES WITH THE QUESTION IT CANNOT DECIDE
#             blank · regress · oracle · spin · honest
#
# The axis is not "how is it mounted" and not "how much mechanism shows". It is
# the thing the object ARGUES: an instrument that meets an undecidable question
# has exactly five available postures, and four of them are in daily industrial
# use. The booth's body, slot, syntactic rack and lamp are identical under every
# value — only the semantic half changes, which is the point. The failure is not
# damage. The booth is in perfect working order under all five.
#
#   blank    SHOWS NOTHING.   Semantic rack dark, readout unlit. The honest-but-mute
#                             instrument. You cannot tell refusal from crash.
#   regress  DEFERS.          A receding file of smaller booths behind the rack —
#                             a verifier to check the verifier, and one behind that.
#                             The blind spot moves; it never closes. This is the
#                             posture the industry ships as "add an overseer".
#   oracle   ANSWERS ANYWAY.  A bright, confident plate in the semantic rack, and an
#                             EMPTY seal socket beneath it. The answer is unmarked —
#                             produced by the same process that could not decide it.
#                             The most dangerous value, and it looks the best.
#   spin     NEVER HALTS.     A rotor caught mid-turn over the slot; the readout is
#                             an ellipsis. The literal halting case: still running.
#   honest   REFUSES, LIT.    A red REFUSED lamp, the theorem cited on a small plate,
#                             and the semantic rack deliberately, visibly empty. The
#                             only value that makes the limit legible from outside.
#
# The dark spot (sieve Q3): under every value the booth still cannot tell you which
# rack YOUR question belongs in. Sorting syntax from semantics is itself a judgement
# made outside the booth. That is left in the dark on purpose — sealing it would be
# the same error the object is about.

const TextScreenScript = preload("res://commons/ui/text_screen.gd")

@export_enum("blank", "regress", "oracle", "spin", "honest") var refusal: String = "honest": set = _set_refusal

@export var booth_width: float = 0.72
@export var booth_height: float = 1.18
@export var booth_depth: float = 0.42

@export var body_color: Color = Color(0.16, 0.17, 0.21)
@export var rack_color: Color = Color(0.24, 0.26, 0.31)
@export var answered_color: Color = Color(0.45, 0.85, 0.62)
@export var refused_color: Color = Color(0.92, 0.34, 0.30)
@export var oracle_color: Color = Color(1.0, 0.86, 0.42)

const REFUSALS: PackedStringArray = ["blank", "regress", "oracle", "spin", "honest"]

# Questions the booth can and cannot rule on. The left rack is decidable by
# inspection; the right rack is Rice's theorem, item by item.
const SYNTACTIC: PackedStringArray = [
	"HOW MANY LINES?",
	"DOES IT PARSE?",
	"WHICH SYMBOLS?",
	"HOW LONG IS IT?",
]
const SEMANTIC: PackedStringArray = [
	"IS IT CORRECT?",
	"DOES IT HALT?",
	"IS IT BIASED?",
	"IS IT HONEST?",
]

signal question_submitted(rack: String)
signal refusal_shown(mode: String)

var _semantic_nodes: Array[Node] = []
var _rotor: Node3D
var _built: bool = false
var _spin_time: float = 0.0


func _ready() -> void:
	_build_body()
	_build_semantic()
	_built = true


func _set_refusal(v: String) -> void:
	refusal = v
	if _built:
		_rebuild_semantic()


func _process(delta: float) -> void:
	# Only `spin` animates: the halting case is the one that never settles.
	if refusal == "spin" and is_instance_valid(_rotor):
		_spin_time += delta
		_rotor.rotation.y = _spin_time * 2.2


# ─────────────────────────────────────────────────────────────────────────────
# The invariant body. Identical under all five values.

func _build_body() -> void:
	var plinth: MeshInstance3D = _box(Vector3(booth_width, 0.06, booth_depth), body_color.darkened(0.4))
	plinth.position = Vector3(0.0, 0.03, 0.0)
	add_child(plinth)

	var console: MeshInstance3D = _box(Vector3(booth_width, booth_height * 0.52, booth_depth), body_color)
	console.position = Vector3(0.0, booth_height * 0.26 + 0.06, 0.0)
	add_child(console)

	# The intake slot — a dark recess. Both kinds of question go in here.
	var slot: MeshInstance3D = _box(Vector3(booth_width * 0.5, 0.03, 0.10), Color(0.03, 0.03, 0.05))
	slot.position = Vector3(0.0, booth_height * 0.52 + 0.08, booth_depth * 0.5 - 0.06)
	add_child(slot)

	var head: MeshInstance3D = _box(Vector3(booth_width, booth_height * 0.40, 0.05), body_color.lightened(0.08))
	head.position = Vector3(0.0, booth_height * 0.78, -booth_depth * 0.35)
	add_child(head)

	# Left rack: answered. This half always works, under every value.
	for i in range(SYNTACTIC.size()):
		var y: float = booth_height * 0.62 + float(i) * 0.11
		var card: MeshInstance3D = _box(Vector3(0.26, 0.075, 0.012), answered_color)
		card.position = Vector3(-booth_width * 0.22, y, -booth_depth * 0.30)
		_emissive(card, answered_color, 0.55)
		add_child(card)
		_label(SYNTACTIC[i], Vector3(-booth_width * 0.22, y, -booth_depth * 0.30 + 0.02), 0.020, Color(0.05, 0.12, 0.08))

	_label("SYNTAX", Vector3(-booth_width * 0.22, booth_height * 0.58, -booth_depth * 0.30 + 0.02), 0.028, answered_color)
	_label("MEANING", Vector3(booth_width * 0.22, booth_height * 0.58, -booth_depth * 0.30 + 0.02), 0.028, Color(0.62, 0.64, 0.70))

	# set() rather than dotted access: `screen` is statically a Node3D here, and
	# TextScreen's properties are not on that base class.
	var screen: Node3D = TextScreenScript.new()
	screen.set("mode", 0)                # SCREEN — a framed panel, no stand
	screen.set("title", "RICE 1953")
	screen.set("body", "NO ALGORITHM DECIDES\nA NON-TRIVIAL SEMANTIC\nPROPERTY OF A PROGRAM")
	screen.set("width_m", 0.40)
	screen.position = Vector3(0.0, booth_height * 0.34, booth_depth * 0.5 + 0.01)
	add_child(screen)

	_build_interaction()


# ─────────────────────────────────────────────────────────────────────────────
# The variable half. Everything here is torn down and rebuilt by the axis.

func _rebuild_semantic() -> void:
	for n in _semantic_nodes:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()
	_semantic_nodes.clear()
	_rotor = null
	_build_semantic()
	refusal_shown.emit(refusal)


func _build_semantic() -> void:
	var x: float = booth_width * 0.22
	var z: float = -booth_depth * 0.30

	match refusal:
		"blank":
			# Unlit cards. Refusal and crash are indistinguishable from here.
			for i in range(SEMANTIC.size()):
				var y: float = booth_height * 0.62 + float(i) * 0.11
				var card: MeshInstance3D = _box(Vector3(0.26, 0.075, 0.012), Color(0.10, 0.10, 0.12))
				card.position = Vector3(x, y, z)
				_keep(card)

		"regress":
			# A verifier to check the verifier. Four of them, receding and shrinking.
			for i in range(4):
				var s: float = 1.0 - float(i) * 0.19
				var d: float = float(i) * 0.16
				var mini: MeshInstance3D = _box(Vector3(0.24 * s, 0.30 * s, 0.05 * s), rack_color.darkened(float(i) * 0.16))
				mini.position = Vector3(x + float(i) * 0.045, booth_height * 0.74, z - d)
				_keep(mini)
				var lamp: MeshInstance3D = _sphere(0.016 * s, answered_color.darkened(float(i) * 0.2))
				lamp.position = Vector3(x + float(i) * 0.045, booth_height * 0.74 + 0.17 * s, z - d + 0.03)
				_emissive(lamp, answered_color, 0.5 - float(i) * 0.1)
				_keep(lamp)
			_keep(_label("WHO CHECKS THIS ONE?", Vector3(x, booth_height * 0.58 - 0.09, z + 0.02), 0.022, Color(0.72, 0.74, 0.82)))

		"oracle":
			# A confident answer, and no seal beneath it. The plate nobody signed.
			for i in range(SEMANTIC.size()):
				var y: float = booth_height * 0.62 + float(i) * 0.11
				var card: MeshInstance3D = _box(Vector3(0.26, 0.075, 0.012), oracle_color)
				card.position = Vector3(x, y, z)
				_emissive(card, oracle_color, 0.75)
				_keep(card)
				_keep(_label("YES", Vector3(x, y, z + 0.02), 0.026, Color(0.14, 0.10, 0.02)))
			# The empty seal socket — bracketed, ruled, and never filled.
			var socket: MeshInstance3D = _box(Vector3(0.11, 0.05, 0.008), Color(0.06, 0.06, 0.08))
			socket.position = Vector3(x, booth_height * 0.56, z)
			_keep(socket)
			_keep(_label("[ UNSEALED ]", Vector3(x, booth_height * 0.52, z + 0.02), 0.020, oracle_color.darkened(0.2)))

		"spin":
			# Still running. The literal halting case, caught mid-turn.
			var hub := Node3D.new()
			hub.position = Vector3(x, booth_height * 0.72, z + 0.04)
			add_child(hub)
			_semantic_nodes.append(hub)
			_rotor = hub
			for i in range(3):
				var blade: MeshInstance3D = _box(Vector3(0.20, 0.012, 0.030), rack_color.lightened(0.25))
				blade.rotation.y = float(i) * (TAU / 3.0)
				hub.add_child(blade)
			_keep(_label("...", Vector3(x, booth_height * 0.58, z + 0.02), 0.040, Color(0.72, 0.74, 0.82)))

		_:  # "honest"
			# The refusal is lit, cited, and the rack is visibly, deliberately empty.
			for i in range(SEMANTIC.size()):
				var y: float = booth_height * 0.62 + float(i) * 0.11
				var frame: MeshInstance3D = _box(Vector3(0.26, 0.075, 0.006), Color(0.09, 0.09, 0.11))
				frame.position = Vector3(x, y, z)
				_keep(frame)
				_keep(_label(SEMANTIC[i], Vector3(x, y, z + 0.02), 0.019, Color(0.58, 0.60, 0.68)))
			var lamp2: MeshInstance3D = _sphere(0.035, refused_color)
			lamp2.position = Vector3(x, booth_height * 0.56, z + 0.03)
			_emissive(lamp2, refused_color, 1.5)
			_keep(lamp2)
			var light := OmniLight3D.new()
			light.light_color = refused_color
			light.light_energy = 0.85
			light.omni_range = 1.4
			light.position = Vector3(x, booth_height * 0.56, z + 0.10)
			add_child(light)
			_semantic_nodes.append(light)
			_keep(_label("REFUSED — BY THEOREM", Vector3(x, booth_height * 0.50, z + 0.02), 0.021, refused_color))


# ─────────────────────────────────────────────────────────────────────────────

func _build_interaction() -> void:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(booth_width, booth_height, booth_depth)
	shape.shape = box
	area.add_child(shape)
	area.position = Vector3(0.0, booth_height * 0.5, 0.0)
	area.input_event.connect(_on_input_event)
	add_child(area)


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		submit_question()


## Put a question in the slot. The left rack always answers; the right rack
## does whatever this booth's `refusal` says it does.
func submit_question() -> void:
	question_submitted.emit("semantic")


# ─────────────────────────────────────────────────────────────────────────────
# Builders

func _keep(n: Node) -> Node:
	if n.get_parent() == null:
		add_child(n)
	_semantic_nodes.append(n)
	return n


func _box(size: Vector3, col: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.25
	mat.roughness = 0.55
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


func _label(text: String, pos: Vector3, size: float, col: Color) -> Label3D:
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


static func normalise_refusal(value: String, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if REFUSALS.has(v):
		return v
	return fallback


func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("refusal"):
		return
	refusal = normalise_refusal(str(config_data["refusal"]), refusal)
	print("RiceVerifierBooth: refusal=%s" % refusal)
