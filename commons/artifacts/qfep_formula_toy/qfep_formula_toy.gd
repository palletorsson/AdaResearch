extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name QfepFormulaToy

## @identity
## name: "The formula made yours"
## tier: small
## lineage: The formula itself as a held object (~0.4m). QFE = F − λE(S) + φΔE(S,t)
##   rendered as a small glowing 3D inscription you could pocket — each term a
##   little floating glyph-plate on a thin spine, the terms pulsing in turn
##   (F, then −λE, then +φΔE) so you read the equation as a sequence of breaths
##   rather than a static line. A sculpture of an idea, sized for the hand.
## truth: "NOT A CLAIM TO READ BUT A MACHINE TO THINK WITH."
## applications: the QFEP equation as a fidget, a keepsake, a thinking-token; the
##   formula detached from the page so it can be turned over, pocketed, kept.

@export var pulse_rate: float = 0.5
@export var spin_rate: float = 0.12
@export var spine_col: Color = Color(0.30, 0.36, 0.52)
@export var qfe_col: Color = Color(0.58, 0.90, 1.0)
@export var f_col: Color = Color(0.55, 0.92, 0.99)
@export var lambda_col: Color = Color(0.62, 0.55, 0.98)
@export var phi_col: Color = Color(0.55, 0.99, 0.78)
@export var plate_col: Color = Color(0.08, 0.10, 0.16)
@export var label_col: Color = Color(0.92, 0.96, 1.0)

var _t: float = 0.0
var _rig: Node3D = null
var _term_plates: Array[MeshInstance3D] = []
var _term_glyphs: Array[Label3D] = []
var _term_cols: Array[Color] = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("pulse_rate"):
		pulse_rate = clampf(float(config["pulse_rate"]), 0.1, 1.2)
	if config.has("spin_rate"):
		spin_rate = clampf(float(config["spin_rate"]), 0.0, 0.5)
	if config.has("qfe_col"):
		qfe_col = _parse_color(config["qfe_col"], qfe_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_rig = null
	_term_plates.clear()
	_term_glyphs.clear()
	_term_cols.clear()
	_build()


func _build() -> void:
	# A slowly-turning rig holds the inscription so it reads from any side.
	_rig = Node3D.new()
	_rig.name = "FormulaRig"
	add_child(_rig)

	# Thin vertical spine — the backbone the terms hang on.
	_rig.add_child(_cylinder(Vector3(0.0, 0.18, 0.0), 0.008, 0.36, _glow_mat(spine_col, 0.6)))
	# Small foot so it can rest in the palm or on a surface, no base plinth.
	_rig.add_child(_sphere(Vector3(0.0, 0.0, 0.0), 0.022, _steel_mat(Color(0.24, 0.27, 0.34))))
	_rig.add_child(_sphere(Vector3(0.0, 0.36, 0.0), 0.014, _glow_mat(qfe_col, 1.1)))

	# The terms, bottom -> top, each a little glyph-plate on a thin arm.
	# (the four terms: QFE, F, -lambda*E(S), +phi*dE(S,t))
	var terms: Array = [
		{"y": 0.30, "text": "QFE =", "col": qfe_col, "w": 0.13},
		{"y": 0.235, "text": "F", "col": f_col, "w": 0.07},
		{"y": 0.165, "text": "- lambda E(S)", "col": lambda_col, "w": 0.20},
		{"y": 0.085, "text": "+ phi dE(S,t)", "col": phi_col, "w": 0.20},
	]

	for i in range(terms.size()):
		var term: Dictionary = terms[i]
		var y: float = float(term["y"])
		var col: Color = term["col"]
		var w: float = float(term["w"])
		# Alternate sides so the spine reads as a little double-helix of glyphs.
		var side: float = 1.0 if i % 2 == 0 else -1.0
		var px: float = side * (w * 0.5 + 0.02)
		var center := Vector3(px, y, 0.0)
		# Connector arm from spine to plate.
		_rig.add_child(_cylinder_between(Vector3(0.0, y, 0.0), Vector3(px - side * w * 0.5, y, 0.0), 0.004, _glow_mat(col, 0.7)))
		# Glyph-plate (a thin glowing tablet).
		var plate: MeshInstance3D = _box(center, Vector3(w, 0.04, 0.012), _matte_mat(plate_col, 0.4))
		_rig.add_child(plate)
		_rig.add_child(_box(center + Vector3(0, 0, 0.007), Vector3(w * 0.96, 0.034, 0.004), _glow_mat(col, 0.4)))
		_term_plates.append(plate)
		_term_cols.append(col)
		# The glyph text, billboarded so it always faces the reader.
		var glyph: Label3D = _billboard_label(str(term["text"]), center + Vector3(0.0, 0.0, 0.02), 11, col)
		_rig.add_child(glyph)
		_term_glyphs.append(glyph)

	# Billboard title (on the static node, not the spinning rig).
	add_child(_billboard_label("THE FORMULA MADE YOURS", Vector3(0.0, 0.4, 0.0), 13, label_col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Gently turn the whole inscription so the terms read from every side.
	if _rig != null:
		_rig.rotation.y = _t * TAU * spin_rate

	# Pulse the terms in turn — F, then -lambda E, then +phi dE, then QFE — so the
	# equation is read as a sequence of breaths.
	var n: int = _term_plates.size()
	if n == 0:
		return
	var phase: float = fmod(_t * pulse_rate, float(n))
	for i in range(n):
		# Distance (cyclic) of this term from the moving read-head.
		var d: float = absf(phase - float(i))
		d = minf(d, float(n) - d)
		var lit: float = clampf(1.0 - d, 0.0, 1.0)
		var energy: float = 0.4 + lit * 1.3
		var plate: MeshInstance3D = _term_plates[i]
		var col: Color = _term_cols[i]
		plate.material_override = _glow_mat(col, energy * 0.6)
		plate.scale = Vector3.ONE * (1.0 + lit * 0.08)
		var glyph: Label3D = _term_glyphs[i]
		glyph.modulate = Color(col.r, col.g, col.b, 0.55 + lit * 0.45)
