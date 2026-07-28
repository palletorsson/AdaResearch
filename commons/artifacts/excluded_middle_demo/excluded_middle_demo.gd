# excluded_middle_demo.gd
# Law of excluded middle: P ∨ ¬P
# Brouwer rejected this for non-constructive proofs

extends Node3D
class_name ExcludedMiddleDemo

# @identity
# essence: P ∨ ¬P — the law of excluded middle; Brouwer: "not always!"
# desire: see two glowing spheres (P and ¬P) with the disjunction between them, and toggle Brouwer's rejection
# critical_parameter: show_rejection — flips between classical acceptance and intuitionistic doubt
# triggers: VR slider toggles rejection mode; label text changes to reflect Brouwer's position
# emerges: the discomfort of undecidable propositions — some P genuinely cannot be decided
# needs: VR horizontal slider for rejection toggle [has]
# relationships: unlocks constructive_proof (if LEM is rejected, only constructive proofs survive); unlocks brouwer_choice_sequence; contrasts godel_statement_plaque (unprovable vs undecidable)
# truth: the law of excluded middle is not a law of logic — it is a philosophical commitment about what "true" means

## What stands between P and ¬P, and whether either disjunct is guaranteed a body.
##
##   classical  the shipped pair — two lit spheres, a disjunction glyph, and nothing
##              at all in the space between them. The empty middle IS the law.
##   third      an undecided proposition gets a body: a matte grey sphere at the
##              origin, with both poles dimmed to a tenth of their emission. Two
##              things that classically could not both be dark are both dark.
##   spectrum   the binary is replaced by seven graded spheres on a rail —
##              many-valued logic, where the middle is a continuum, not a gap.
##   half       ¬P is not built. A question-mark plate stands where its body was,
##              and a witness cube sits under P. Constructive logic as a fact about
##              what is standing in the room rather than a sentence in a caption.
##
## This is the axis the artifact is named after. Before promotion the middle was
## empty air in every placement — which is precisely the classical position the
## piece was written to doubt.
@export_enum("classical", "third", "spectrum", "half") var middle: String = "classical"

@export var show_rejection: bool = true

## Allow-list. Anything a map spells wrong falls back to the shipped look rather
## than stranding the placement with a middle nobody asked for.
const MIDDLES: PackedStringArray = ["classical", "third", "spectrum", "half"]

# --- shipped geometry constants (metres) ---------------------------------
const P_POS: Vector3 = Vector3(-0.2, 0.0, 0.0)
const NOT_P_POS: Vector3 = Vector3(0.2, 0.0, 0.0)
const POLE_R: float = 0.1
const LABEL_Y: float = 0.15

const GREEN: Color = Color(0.2, 0.8, 0.3)
const RED: Color = Color(0.8, 0.2, 0.2)
## The shipped emission colours, kept literally rather than derived, so the
## default value is the pre-promotion look to the last decimal.
const GREEN_EM: Color = Color(0.1, 0.5, 0.2)
const RED_EM: Color = Color(0.5, 0.1, 0.1)
## Undecided. No emission — the point is that it does not declare itself.
const GREY: Color = Color(0.45, 0.45, 0.48)
const COOL_WHITE: Color = Color(0.86, 0.9, 0.96)

## New bodies with no shipped emission colour of their own light at roughly the
## same ratio the poles do, so they belong to the family instead of inventing a
## second register.
const EMISSION_RATIO: float = 0.6
## `third` dims both poles to a tenth rather than killing them — dark, not absent.
const DIM_ENERGY: float = 0.1

## spectrum: seven bodies at 0.08 m pitch, radius 0.05, so the row spans
## -0.24 .. +0.24 and the spheres INTERSECT. The overlap is the argument — a
## continuum has no gaps in it.
const ROW_COUNT: int = 7
const ROW_R: float = 0.05
const ROW_PITCH: float = 0.08
const RAIL_SIZE: Vector3 = Vector3(0.5, 0.01, 0.01)
const RAIL_Y: float = -0.08

## half: the plate that stands in for the body nobody constructed, and the
## witness that P does have.
const PLATE_SIZE: Vector3 = Vector3(0.14, 0.1, 0.02)
const WITNESS_CUBE: float = 0.05
const POST_H: float = 0.06
const POST_R: float = 0.008

var _true_sphere: MeshInstance3D
var _false_sphere: MeshInstance3D
var _label: Label3D
var _slider: Node
var _control_panel: Node3D

## Only nodes THIS script added. Freeing get_children() would take the grid's
## label plates, packaging and tag markers with it.
var _owned: Array[Node] = []
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

## Synchronous, and from the @export values alone — the sweep harness sets
## `middle` before the node enters the tree and never calls apply_grid_config.
func _build_all() -> void:
	_create_spheres()
	_create_label()
	_setup_controls()


func _own(n: Node) -> void:
	add_child(n)
	_owned.append(n)


func _create_spheres() -> void:
	match middle:
		"third":
			_build_third()
		"spectrum":
			_build_spectrum()
		"half":
			_build_half()
		_:
			_build_classical()


## The shipped look, byte for byte: two lit poles, a disjunction glyph at the
## origin, and empty air between them.
func _build_classical() -> void:
	_true_sphere = _make_sphere(POLE_R, P_POS, GREEN, GREEN_EM, 1.0)
	_own(_true_sphere)
	_own(_pole_label("P", P_POS.x))

	_false_sphere = _make_sphere(POLE_R, NOT_P_POS, RED, RED_EM, 1.0)
	_own(_false_sphere)
	_own(_pole_label("¬P", NOT_P_POS.x))

	_own(_disjunction_glyph(0.0))


## A proposition that is neither, standing between two that no longer light on
## their own. The grey body is matte on purpose — it makes no claim.
func _build_third() -> void:
	_true_sphere = _make_sphere(POLE_R, P_POS, GREEN, GREEN_EM, DIM_ENERGY)
	_own(_true_sphere)
	_own(_pole_label("P", P_POS.x))

	_false_sphere = _make_sphere(POLE_R, NOT_P_POS, RED, RED_EM, DIM_ENERGY)
	_own(_false_sphere)
	_own(_pole_label("¬P", NOT_P_POS.x))

	_own(_make_sphere(POLE_R, Vector3.ZERO, GREY, GREY, 0.0))
	# Lifted clear of the third body it can no longer sit inside.
	_own(_disjunction_glyph(0.16))


## Many-valued logic. The two poles are not built separately — they are the ends
## of the row, and the row has no gap anywhere along it.
func _build_spectrum() -> void:
	var span: float = ROW_PITCH * float(ROW_COUNT - 1)
	for i in range(ROW_COUNT):
		var t: float = float(i) / float(ROW_COUNT - 1)
		var x: float = -span * 0.5 + ROW_PITCH * float(i)
		var col: Color = GREEN.lerp(GREY, t * 2.0) if t < 0.5 else GREY.lerp(RED, (t - 0.5) * 2.0)
		_own(_make_sphere(ROW_R, Vector3(x, 0.0, 0.0), col, _derived_emission(col), 1.0))

	_own(_pole_label("P", P_POS.x))
	_own(_pole_label("¬P", NOT_P_POS.x))

	# The rail replaces the disjunction glyph: a scale, not a choice of two.
	var rail: MeshInstance3D = MeshInstance3D.new()
	var rm: BoxMesh = BoxMesh.new()
	rm.size = RAIL_SIZE
	rail.mesh = rm
	rail.position = Vector3(0.0, RAIL_Y, 0.0)
	rail.material_override = _cool_white_material()
	_own(rail)


## The constructive reading. Only the side you have actually built a witness for
## has a body; the other side is a question mark on a plate.
func _build_half() -> void:
	_true_sphere = _make_sphere(POLE_R, P_POS, GREEN, GREEN_EM, 1.0)
	_own(_true_sphere)
	_own(_pole_label("P", P_POS.x))

	# The witness: a constructed object, sitting on its post under the claim.
	var cube: MeshInstance3D = MeshInstance3D.new()
	var cm: BoxMesh = BoxMesh.new()
	cm.size = Vector3(WITNESS_CUBE, WITNESS_CUBE, WITNESS_CUBE)
	cube.mesh = cm
	cube.position = Vector3(P_POS.x, -POLE_R - WITNESS_CUBE * 0.5, 0.0)
	cube.material_override = _emissive_material(GREEN, GREEN_EM, 1.0)
	_own(cube)

	var post: MeshInstance3D = MeshInstance3D.new()
	var pm: CylinderMesh = CylinderMesh.new()
	pm.top_radius = POST_R
	pm.bottom_radius = POST_R
	pm.height = POST_H
	post.mesh = pm
	post.position = Vector3(P_POS.x, -POLE_R - WITNESS_CUBE - POST_H * 0.5, 0.0)
	post.material_override = _cool_white_material()
	_own(post)

	# ¬P has no body. The plate stands exactly where the sphere would have been.
	var plate: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = PLATE_SIZE
	plate.mesh = bm
	plate.position = NOT_P_POS
	plate.material_override = _cool_white_material()
	_own(plate)

	var q: Label3D = Label3D.new()
	q.text = "?"
	q.pixel_size = 0.0015
	q.font_size = 48
	q.modulate = Color(0.08, 0.09, 0.12)
	q.position = Vector3(0.0, 0.0, PLATE_SIZE.z * 0.5 + 0.002)
	plate.add_child(q)

	_own(_pole_label("¬P", NOT_P_POS.x))
	_own(_disjunction_glyph(0.0))


# --- builders ------------------------------------------------------------

func _make_sphere(radius: float, pos: Vector3, albedo: Color, emission: Color, energy: float) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.position = pos
	mi.material_override = _emissive_material(albedo, emission, energy)
	return mi


## energy <= 0 means matte: the material carries no emission at all.
func _emissive_material(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = albedo
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


func _derived_emission(albedo: Color) -> Color:
	return Color(
		albedo.r * EMISSION_RATIO,
		albedo.g * EMISSION_RATIO,
		albedo.b * EMISSION_RATIO)


func _cool_white_material() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = COOL_WHITE
	m.roughness = 0.35
	m.emission_enabled = true
	m.emission = COOL_WHITE
	m.emission_energy_multiplier = 0.35
	return m


func _pole_label(text: String, x: float) -> Label3D:
	var l: Label3D = Label3D.new()
	l.text = text
	l.pixel_size = 0.001
	l.font_size = 16
	l.position = Vector3(x, LABEL_Y, 0.0)
	return l


func _disjunction_glyph(y: float) -> Label3D:
	var l: Label3D = Label3D.new()
	l.text = "∨"
	l.pixel_size = 0.002
	l.font_size = 24
	l.position = Vector3(0.0, y, 0.0)
	return l


func _create_label() -> void:
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	if show_rejection:
		_label.text = "LAW OF EXCLUDED MIDDLE\nP ∨ ¬P\n\nBrouwer: \"Not always!\"\nSome P cannot be decided."
	else:
		_label.text = "LAW OF EXCLUDED MIDDLE\nP ∨ ¬P\n\"Either true or false\""
	_label.position = Vector3(0, -0.25, 0)
	_own(_label)


func _setup_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl == null:
		# Headless runs that cannot resolve the rack template must still leave the
		# spheres standing — an aborted _ready() reads as an inert axis.
		return
	var panel = RackTpl.create_panel("EXCLUDED MIDDLE", [
		[{"type": "slider_h", "label": "REJECTION", "default": 1.0}],
	])
	if panel == null or not (panel is Node3D):
		return
	_control_panel = panel
	_control_panel.position = Vector3(0, 0.5, 0.6)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	_own(_control_panel)

	_slider = _control_panel.find_child("Param_0", true, false)
	if _slider and _slider.has_signal("slider_moved"):
		_slider.slider_moved.connect(_on_rejection_changed)
	if _slider and _slider.has_method("set_normalized_value"):
		_slider.set_normalized_value(1.0 if show_rejection else 0.0)


func _on_rejection_changed(_pos = null) -> void:
	if _slider and _slider.has_method("get_normalized_value"):
		var val = _slider.get_normalized_value()
		show_rejection = val > 0.5
		if is_instance_valid(_label):
			_owned.erase(_label)
			remove_child(_label)
			_label.queue_free()
		_create_label()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Keys: "middle" (Stage-2 DNA axis), "show_rejection".
##
## Rebuild only when something actually changed. curation_station hands every
## artifact it curates {"emissive": false} immediately after framing its labels;
## an unconditional rebuild there would free the framed plates and put fresh
## billboarded ones back, discarding work done one line earlier.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_middle: String = middle
	var before_rejection: bool = show_rejection

	if config_data.has("middle"):
		middle = _pick_axis(str(config_data["middle"]), MIDDLES, middle)
	if config_data.has("show_rejection"):
		show_rejection = bool(config_data["show_rejection"])

	if not _built:
		return
	if middle == before_middle and show_rejection == before_rejection:
		return

	_rebuild_now()
	print("[ExcludedMiddleDemo] Config applied — middle=%s, show_rejection=%s" % [
		middle, show_rejection])


## Accept an axis value only if it names something we actually build. A typo in a
## map token falls back to the shipped look rather than emptying the middle in a
## way nobody asked for.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous and inline. A deferred rebuild that removes children first makes
## _auto_ground_artifact measure a zero AABB, return early, and never ground us.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_true_sphere = null
	_false_sphere = null
	_label = null
	_slider = null
	_control_panel = null
	_build_all()
