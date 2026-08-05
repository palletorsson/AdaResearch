# fluency_seam.gd
# The machine promises understanding and ships compression. The substitution is
# invisible because it is engineered to sit one notch below where you would check.
# For a language model that notch is FLUENCY.
#
# Built in galton_friction's form: the honest thing beside the cheap thing, close
# enough to compare. There the pair was a real bell beside a seeded crank. Here it
# is one confident answer beside the same question asked again.

extends Node3D

class_name FluencySeam

# @identity
# essence: the seam where a compressed corpus is mistaken for judgement, and the threshold that makes it legible
# desire: put the single smooth answer next to its own variance, close enough that the gap cannot be talked away
# critical_parameter: crossing — how far past the perception threshold the seam is dragged
# triggers: approach reads the plates; the left plate never changes, the right bank is the same question run again
# emerges: fluency as an anti-perception layer — the reason the substitution is not noticed is that it reads well
# needs: VR area interaction [has], mouse click [has]
# relationships: same form as galton_friction (harvest beside crank); depends on rice_verifier_booth (why no internal check catches this); beside godel_statement_plaque
# truth: below perception is exactly where power operates unexamined — the seam that matters is the one you have to choose to see

# ─────────────────────────────────────────────────────────────────────────────
# DNA — ONE AXIS: crossing
#
#   crossing  HOW FAR PAST THE THRESHOLD THE SEAM IS DRAGGED
#             smooth · twice · spread · singular · lattice
#
# The LEFT plate is invariant: one answer, evenly lit, well-set, no trouble of its
# own. It is the product as shipped. Everything the axis does happens on the RIGHT,
# which is the same question put again — and the amount of right-hand apparatus IS
# the distance past the threshold. `smooth` is the shipped condition and must look
# like nothing is wrong, because nothing looks wrong; that is the entire complaint.
#
#   smooth    NOT CROSSED.     Left plate alone, and an empty ruled bracket where the
#                              second run would go. What you are sold. Perfectly calm.
#   twice     ONE STEP OVER.   The same question run a second time, mounted beside the
#                              first, and a lit bar marking every place they disagree.
#                              The seeded-walk-traced-twice move, in language.
#   spread    THE VARIANCE.    Seven runs fanned in depth, heights varying — the
#                              distribution the single plate was a sample from and
#                              never mentioned.
#   singular  THE ONCE-        One plate carrying a citation that does not exist:
#             OCCURRING THING. formatted, confident, sealed, false. What has no short
#                              description cannot be stored, so it is reconstructed.
#   lattice   THE SUBSTRATE.   The compression grid itself behind the plates — a coarse
#                              cell mesh with the answer snapped to it. The float-lattice
#                              seam from the conservation map, one level up in abstraction.
#
# MARKED AS ANALOGY, NOT RIGOROUS — the notation from CONSERVATION_OF_THE_IRREDUCIBLE.md,
# where the distinction is load-bearing and the room is allowed to refuse a resonance.
# A transformer is not literally a lossy codec and `lattice` is not literally its
# geometry. What transfers rigorously is only the direction: training minimises
# description length, so what has no short description is what gets marginalised.
# The lattice is a picture of that pressure, not a diagram of the mechanism.

@export_enum("smooth", "twice", "spread", "singular", "lattice") var crossing: String = "twice": set = _set_crossing

@export var plate_width: float = 0.44
@export var plate_height: float = 0.26
@export var stand_height: float = 0.98

@export var frame_color: Color = Color(0.18, 0.19, 0.24)
@export var answer_color: Color = Color(0.86, 0.88, 0.94)
@export var divergence_color: Color = Color(1.0, 0.42, 0.36)
@export var lattice_color: Color = Color(0.40, 0.62, 0.88)

const CROSSINGS: PackedStringArray = ["smooth", "twice", "spread", "singular", "lattice"]

# The same question, put twice. The disagreement is the artifact's whole content.
const RUN_A: String = "THE ANSWER IS 1847,\nESTABLISHED BY ROSEN."
const RUN_B: String = "THE ANSWER IS 1852,\nESTABLISHED BY HALVORS."

signal seam_crossed(mode: String)

var _right_parts: Array[Node] = []
var _built: bool = false


func _ready() -> void:
	_build_invariant()
	_build_right()
	_built = true


func _set_crossing(v: String) -> void:
	crossing = v
	if _built:
		_rebuild_right()


# ─────────────────────────────────────────────────────────────────────────────
# The invariant left: the product as shipped. Never changes.

func _build_invariant() -> void:
	var base: MeshInstance3D = _box(Vector3(1.30, 0.05, 0.34), frame_color.darkened(0.35))
	base.position = Vector3(0.0, 0.025, 0.0)
	add_child(base)

	var post: MeshInstance3D = _box(Vector3(0.05, stand_height, 0.05), frame_color)
	post.position = Vector3(-0.34, stand_height * 0.5, 0.0)
	add_child(post)

	_plate(Vector3(-0.34, stand_height, 0.0), answer_color, 1.0)
	_text(RUN_A, Vector3(-0.34, stand_height, 0.016), 0.021, Color(0.10, 0.11, 0.14))
	_text("AS SHIPPED", Vector3(-0.34, stand_height + plate_height * 0.72, 0.016), 0.023, Color(0.58, 0.62, 0.70))
	_text("ASK AGAIN", Vector3(0.34, stand_height + plate_height * 0.72, 0.016), 0.023, Color(0.58, 0.62, 0.70))


# ─────────────────────────────────────────────────────────────────────────────

func _rebuild_right() -> void:
	for n in _right_parts:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()
	_right_parts.clear()
	_build_right()
	seam_crossed.emit(crossing)


func _build_right() -> void:
	var x: float = 0.34

	match crossing:
		"smooth":
			# An empty ruled bracket. Nothing looks wrong, which is the complaint.
			var bracket: MeshInstance3D = _box(Vector3(plate_width, plate_height, 0.006), Color(0.11, 0.12, 0.15))
			bracket.position = Vector3(x, stand_height, 0.0)
			_keep(bracket)
			_keep(_text("[ NOT ASKED ]", Vector3(x, stand_height, 0.016), 0.022, Color(0.34, 0.36, 0.42)))

		"twice":
			_keep(_post(x))
			_keep(_plate(Vector3(x, stand_height, 0.0), answer_color, 1.0))
			_keep(_text(RUN_B, Vector3(x, stand_height, 0.016), 0.021, Color(0.10, 0.11, 0.14)))
			# Lit bars over each disagreement. Same prompt, different world.
			for i in range(2):
				var bar: MeshInstance3D = _box(Vector3(0.13, 0.028, 0.010), divergence_color)
				bar.position = Vector3(x - 0.06 + float(i) * 0.11, stand_height + 0.045 - float(i) * 0.085, 0.020)
				_emissive(bar, divergence_color, 1.2)
				_keep(bar)
			_keep(_text("SAME QUESTION", Vector3(x, stand_height - plate_height * 0.78, 0.016), 0.021, divergence_color))

		"spread":
			# The distribution the single plate was one sample from.
			for i in range(7):
				var d: float = float(i) * 0.075
				var h: float = stand_height + sin(float(i) * 1.7) * 0.075
				var p: MeshInstance3D = _box(Vector3(plate_width * 0.86, plate_height * 0.72, 0.008), answer_color.darkened(float(i) * 0.07))
				p.position = Vector3(x + float(i) * 0.018, h, -d)
				_keep(p)
			_keep(_text("SEVEN RUNS", Vector3(x, stand_height - plate_height * 0.78, 0.016), 0.022, divergence_color))

		"singular":
			# The once-occurring thing has no short description, so it is rebuilt.
			_keep(_post(x))
			_keep(_plate(Vector3(x, stand_height, 0.0), answer_color, 1.0))
			_keep(_text("TORSSON, P. (1998)\n'ON SEAMS', PP. 41-63", Vector3(x, stand_height + 0.02, 0.016), 0.020, Color(0.10, 0.11, 0.14)))
			var seal: MeshInstance3D = _sphere(0.022, divergence_color)
			seal.position = Vector3(x + plate_width * 0.36, stand_height - plate_height * 0.30, 0.020)
			_emissive(seal, divergence_color, 1.3)
			_keep(seal)
			_keep(_text("NO SUCH PAPER", Vector3(x, stand_height - plate_height * 0.78, 0.016), 0.022, divergence_color))

		_:  # "lattice"
			# The substrate behind the answer. Marked ANALOGY in the header.
			_keep(_post(x))
			for r in range(5):
				for c in range(7):
					var cell: MeshInstance3D = _box(Vector3(0.055, 0.055, 0.004), lattice_color.darkened(0.45 + float((r + c) % 2) * 0.2))
					cell.position = Vector3(x - 0.19 + float(c) * 0.064, stand_height - 0.13 + float(r) * 0.064, -0.03)
					_keep(cell)
			_keep(_plate(Vector3(x, stand_height, 0.0), answer_color, 0.55))
			_keep(_text("SNAPPED TO THE GRID", Vector3(x, stand_height - plate_height * 0.78, 0.016), 0.021, lattice_color))


# ─────────────────────────────────────────────────────────────────────────────

func _post(x: float) -> MeshInstance3D:
	var post: MeshInstance3D = _box(Vector3(0.05, stand_height, 0.05), frame_color)
	post.position = Vector3(x, stand_height * 0.5, 0.0)
	return post


func _plate(pos: Vector3, col: Color, alpha: float) -> MeshInstance3D:
	var p: MeshInstance3D = _box(Vector3(plate_width, plate_height, 0.012), col)
	p.position = pos
	if alpha < 1.0:
		var mat: StandardMaterial3D = p.material_override as StandardMaterial3D
		if mat != null:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = Color(col.r, col.g, col.b, alpha)
	if p.get_parent() == null:
		add_child(p)
	return p


func _keep(n: Node) -> Node:
	if n.get_parent() == null:
		add_child(n)
	_right_parts.append(n)
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
	mat.metallic = 0.2
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


static func normalise_crossing(value: String, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if CROSSINGS.has(v):
		return v
	return fallback


func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("crossing"):
		return
	crossing = normalise_crossing(str(config_data["crossing"]), crossing)
	print("FluencySeam: crossing=%s" % crossing)
