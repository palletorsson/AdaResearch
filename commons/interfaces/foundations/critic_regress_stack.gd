# critic_regress_stack.gd
# Add a critic to check the system. Now add a critic to check the critic.
# The blind spot never closes — it MOVES. This artifact is where it moved to.
#
# The naive repair for Gödel is a meta-level: an overseer, a constitution, a
# second model marking the first one's work. But the overseer is also an
# algorithm, with its own axioms and its own slope. You have not removed the
# bias. You have relocated it. That is the conservation of the irreducible,
# stated one level up, and it is the law this object walks.

extends Node3D

class_name CriticRegressStack

# @identity
# essence: criticism is conserved — every added critic moves the unexamined ground, none abolishes it
# desire: show the blind spot as a real object with a position, so that adding a critic visibly MOVES it rather than deleting it
# critical_parameter: relocation — where the blind spot ends up under five ways of arranging critics
# triggers: approach to read the aim lines; each critic's lens points at what it can see, and nothing points at the dark mark
# emerges: why "add an overseer" is a decision about where to put the pile, not a solution
# needs: VR area interaction [has], mouse click [has]
# relationships: answers rice_verifier_booth (which proves the internal check cannot exist); contrasts negative_control_fixture (the one honest move available); beside godel_statement_plaque
# truth: you can relocate inductive bias, you cannot remove it — a critic is a choice of where the blind spot sits, and `sealed` is the only arrangement that hides that choice

# ─────────────────────────────────────────────────────────────────────────────
# DNA — ONE AXIS: relocation
#
#   relocation  WHERE THE BLIND SPOT ENDS UP
#               single · stacked · circular · outside · sealed
#
# The dark mark is the SAME OBJECT under every value — same size, same material,
# same unlit black. Only its position changes, because that is the entire claim.
# An axis that made the mark shrink as critics were added would be arguing the
# opposite of the truth line, and would be a lie told in geometry.
#
#   single    AT THE BASE.     One critic, lens down. The mark sits directly beneath
#                              it, in its own footing — the thing it stands on and
#                              therefore cannot look at.
#   stacked   AT THE TOP.      Three critics, each watching the one below. The mark
#                              has travelled to the crown: the last critic in the
#                              chain is unwatched, and the chain bought that by
#                              being long. This is the posture that feels safest.
#   circular  DISTRIBUTED.     Three critics in a ring, each checking its neighbour.
#                              No critic is unwatched — and the mark moves to the
#                              CENTRE, the thing the ring collectively faces away
#                              from. Mutual audit relocates it inward, not away.
#   outside   SMALLER, AND ON  A fourth body of different stock — warm, matte, not of
#             THE OUTSIDER.    the stack's metal — standing apart and aimed in. The
#                              mark shrinks (a differently-constructed check really
#                              does catch more) and reappears on the outsider's own
#                              base. This is the best available arrangement and it
#                              is still not zero.
#   sealed    INVISIBLE.       A smooth shell over the whole stack. No mark anywhere.
#                              Nothing has been fixed; the mark is inside the shell.
#                              The most reassuring value, and the sterilising one.
#
# The dark spot (sieve Q3): the artifact cannot show you the blind spot of the
# ARRANGEMENT ITSELF — the fact that "critic", "checks", and "blind spot" are
# categories chosen by a maker. That regress is left open, because closing it
# would require a sixth value claiming to be outside all five, which is the
# exact error the object is about.

@export_enum("single", "stacked", "circular", "outside", "sealed") var relocation: String = "stacked": set = _set_relocation

@export var unit_size: float = 0.26
@export var stack_pitch: float = 0.34

@export var critic_color: Color = Color(0.28, 0.31, 0.38)
@export var lens_color: Color = Color(0.50, 0.78, 1.0)
@export var outsider_color: Color = Color(0.62, 0.44, 0.28)
@export var shell_color: Color = Color(0.78, 0.80, 0.84)
## The blind spot. Identical under every value — only its position is the argument.
@export var mark_color: Color = Color(0.02, 0.02, 0.03)
@export var mark_radius: float = 0.085

const RELOCATIONS: PackedStringArray = ["single", "stacked", "circular", "outside", "sealed"]

signal arrangement_changed(mode: String)

var _parts: Array[Node] = []
var _built: bool = false


func _ready() -> void:
	_build_base()
	_build_arrangement()
	_built = true


func _set_relocation(v: String) -> void:
	relocation = v
	if _built:
		_rebuild()


func _build_base() -> void:
	var pad: MeshInstance3D = _box(Vector3(0.9, 0.04, 0.9), Color(0.12, 0.13, 0.16))
	pad.position = Vector3(0.0, 0.02, 0.0)
	add_child(pad)


func _rebuild() -> void:
	for n in _parts:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.queue_free()
	_parts.clear()
	_build_arrangement()
	arrangement_changed.emit(relocation)


func _build_arrangement() -> void:
	match relocation:
		"single":
			_critic(Vector3(0.0, 0.30, 0.0), critic_color, Vector3(0.0, -1.0, 0.0))
			_mark(Vector3(0.0, 0.055, 0.0), mark_radius)
			_caption("ONE CRITIC — THE MARK IS ITS FOOTING", 0.62)

		"stacked":
			for i in range(3):
				var y: float = 0.30 + float(i) * stack_pitch
				_critic(Vector3(0.0, y, 0.0), critic_color.lightened(float(i) * 0.06), Vector3(0.0, -1.0, 0.0))
			# Travelled to the crown. The last critic is the unwatched one.
			_mark(Vector3(0.0, 0.30 + 2.0 * stack_pitch + 0.24, 0.0), mark_radius)
			_caption("THREE CRITICS — THE MARK MOVED UP", 1.42)

		"circular":
			var r: float = 0.30
			for i in range(3):
				var a: float = float(i) * (TAU / 3.0)
				var p := Vector3(cos(a) * r, 0.34, sin(a) * r)
				# Each lens aims at its neighbour, not at the centre.
				var na: float = float(i + 1) * (TAU / 3.0)
				var target := Vector3(cos(na) * r, 0.34, sin(na) * r)
				_critic(p, critic_color, (target - p).normalized())
			_mark(Vector3(0.0, 0.34, 0.0), mark_radius)
			_caption("MUTUAL AUDIT — THE MARK MOVED INWARD", 0.72)

		"outside":
			for i in range(3):
				var y2: float = 0.30 + float(i) * stack_pitch
				_critic(Vector3(0.0, y2, 0.0), critic_color, Vector3(0.0, -1.0, 0.0))
			# A body of different stock, aimed in from beyond the pad.
			var op := Vector3(0.62, 0.30, 0.42)
			_critic(op, outsider_color, (Vector3(0.0, 0.64, 0.0) - op).normalized())
			# Smaller — a differently-constructed check really does catch more.
			_mark(Vector3(0.62, 0.055, 0.42), mark_radius * 0.45)
			_caption("A CHECK OF OTHER STOCK — SMALLER, NOT ZERO", 1.42)

		_:  # "sealed"
			for i in range(3):
				var y3: float = 0.30 + float(i) * stack_pitch
				_critic(Vector3(0.0, y3, 0.0), critic_color.darkened(0.3), Vector3(0.0, -1.0, 0.0))
			var shell: MeshInstance3D = _box(Vector3(0.52, 1.30, 0.52), shell_color)
			shell.position = Vector3(0.0, 0.70, 0.0)
			var smat: StandardMaterial3D = shell.material_override as StandardMaterial3D
			if smat != null:
				smat.metallic = 0.7
				smat.roughness = 0.18
			_keep(shell)
			# No mark anywhere. Nothing was fixed; it is inside the shell.
			_caption("NO MARK VISIBLE", 1.46)


# ─────────────────────────────────────────────────────────────────────────────

## One critic: a body, and a lens aimed at whatever it is able to see.
func _critic(pos: Vector3, col: Color, aim: Vector3) -> void:
	var body: MeshInstance3D = _box(Vector3(unit_size, unit_size * 0.72, unit_size), col)
	body.position = pos
	_keep(body)

	var lens: MeshInstance3D = _sphere(unit_size * 0.17, lens_color)
	lens.position = pos + aim * (unit_size * 0.46)
	_emissive(lens, lens_color, 1.1)
	_keep(lens)

	# The aim line — what this critic can see. Nothing ever points at the mark.
	var span: float = 0.20
	var beam: MeshInstance3D = _box(Vector3(0.012, span, 0.012), lens_color)
	beam.position = pos + aim * (unit_size * 0.46 + span * 0.5)
	if absf(aim.y) < 0.9:
		beam.rotation.z = PI * 0.5
		beam.rotation.y = atan2(aim.x, aim.z)
	_emissive(beam, lens_color, 0.5)
	_keep(beam)


## The blind spot. Same object every time; only the position argues.
func _mark(pos: Vector3, radius: float) -> void:
	var m: MeshInstance3D = _sphere(radius, mark_color)
	m.position = pos
	var mat: StandardMaterial3D = m.material_override as StandardMaterial3D
	if mat != null:
		mat.metallic = 0.0
		mat.roughness = 1.0
	_keep(m)


func _caption(text: String, y: float) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 64
	l.pixel_size = 0.024 / 64.0
	l.modulate = Color(0.70, 0.73, 0.80)
	l.position = Vector3(0.0, y, 0.36)
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.double_sided = true
	add_child(l)
	_parts.append(l)


func _keep(n: Node) -> void:
	if n.get_parent() == null:
		add_child(n)
	_parts.append(n)


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


static func normalise_relocation(value: String, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if RELOCATIONS.has(v):
		return v
	return fallback


func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("relocation"):
		return
	relocation = normalise_relocation(str(config_data["relocation"]), relocation)
	print("CriticRegressStack: relocation=%s" % relocation)
