extends Node3D
class_name DataLaborCounter

# @identity
# essence: a small counter panel running two numbers in lockstep — items labelled, human-hours accrued — standing over a wall of tally marks that adds one scratch per four hundred labels and eventually grows taller than the readout it belongs to
# desire: to give ghost work a body; the labour behind a training set is normally a rate in someone else's spreadsheet, and a rate is exactly the form in which it disappears
# critical_parameter: labels_per_hour against labels_per_mark — the first sets how fast the hours grind under the items, the second how fast the physical pile overtakes the panel; both are read from the same running total, so the two readings can never disagree
# triggers: _process accrues items at labels_per_second, derives hours by division, and pushes a new tally mark onto the pile every labels_per_mark items; the fifth mark of each bundle is the diagonal, so the wall is countable, not decorative
# emerges: the output number flies and the hours number crawls and the pile rises anyway — by the end of a run the scratches stand in front of the readout and you have to look past the labour to read the throughput
# needs: TextScreen [commons/ui/text_screen.gd, present] for the panel; Label3D for the live digits, because baking a new texture per number would leak one ImageTexture per tick; a MultiMesh for the marks
# relationships: the cost side of the criticalalgorithms room — attention_economy_sim shows what a system extracts from the viewer, this shows what it extracted before the viewer arrived
# truth: the counter is not lying. Both numbers are true and they are the same number divided differently — which is how a labour cost becomes a throughput figure, and how the pile stays out of the report.

## Data Labor Counter — the ghost-work readout.
##
## Everything is procedural in _ready(). One plinth, one TextScreen panel on its
## stand, one MultiMesh wall of tally marks that only ever grows.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"

## Labels produced per second of wall time. Fast and smooth — this is the number
## the system is proud of.
@export var labels_per_second: float = 340.0
## Labels one human hour buys. The realistic figure for annotation piecework, and
## the reason the hours column climbs at a pace nobody puts on a slide.
@export var labels_per_hour: float = 900.0
## Labels behind one scratch on the wall.
@export var labels_per_mark: int = 400
## Marks already on the wall when you arrive. The shift did not start with you.
@export var seed_marks: int = 150
## Slots on the wall. When they run out the surplus becomes UNCOUNTED and stays
## on the panel — the pile is never cleared, it is only allowed to overflow.
@export var max_marks: int = 250

const PLINTH_W := 0.62
const PANEL_W := 0.62
const PANEL_ASPECT := 0.62          # matches TextScreen.ASPECT
const STAND_H := 0.72
const BASE_Y := 0.06

const MARK_H := 0.085
const MARK_T := 0.010
const MARK_PITCH := 0.022           # gap between the verticals of one bundle
const BUNDLE_PITCH := 0.105
const ROW_PITCH := 0.115
const BUNDLES_PER_ROW := 5
const PILE_Z := 0.18
const PILE_Y0 := 0.09

const AMBER := Color(1.0, 0.72, 0.30)
const COOL := Color(0.62, 0.82, 1.0)
const DIM := Color(0.55, 0.60, 0.70)

var _labels: float = 0.0
var _marks: int = 0
var _uncounted: int = 0

var _items_label: Label3D
var _hours_label: Label3D
var _overflow_label: Label3D
var _mark_field: MultiMeshInstance3D

var _built: bool = false
var _created: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true
	set_process(true)


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	# The seeded state is internally consistent: the pile and the counter are
	# two readings of one running total, so they can never be caught disagreeing.
	_marks = clampi(seed_marks, 0, max_marks)
	_labels = float(_marks) * float(maxi(1, labels_per_mark))
	_uncounted = 0

	_build_plinth()
	_build_panel()
	_build_pile()
	_refresh_readout()


func _build_plinth() -> void:
	var plinth := MeshInstance3D.new()
	plinth.name = "Plinth"
	var box := BoxMesh.new()
	box.size = Vector3(PLINTH_W, BASE_Y, PLINTH_W)
	plinth.mesh = box
	plinth.position = Vector3(0.0, BASE_Y * 0.5, 0.0)
	plinth.material_override = _grid_material(
		Color(0.16, 0.17, 0.21), Color(0.42, 0.47, 0.58), 0.4)
	_own(plinth)


func _build_panel() -> void:
	# Configure BEFORE add_child — TextScreen's setters rebuild only when already
	# in-tree, so driving them after adding forces one queue_free/rebuild per
	# property. Set first, add last.
	var ts := TextScreenScript.new()
	ts.name = "CounterPanel"
	ts.mode = 1                     # Mode.STAND — screen carried at reading height
	ts.width_m = PANEL_W
	ts.stand_height = STAND_H
	ts.position = Vector3(0.0, BASE_Y, -0.02)
	if ts.has_method("set_text"):
		ts.set_text("DATA LABOR", "")
	_own(ts)

	# Live digits are Label3D, not baked text. BakedTextAlbedo caches one
	# ImageTexture per distinct string; a counter would mint a new one every tick
	# and never release it. Label3D is the only honest choice for a number that
	# moves.
	var face := Node3D.new()
	face.name = "PanelFace"
	face.position = Vector3(0.0, BASE_Y + STAND_H, -0.02 + 0.014)
	_own(face)

	face.add_child(_static_line("ITEMS LABELLED", 0.076, DIM, 26, 0.0011))
	_items_label = _static_line("0", 0.030, COOL, 40, 0.0013)
	face.add_child(_items_label)
	face.add_child(_static_line("HUMAN-HOURS ACCRUED", -0.036, DIM, 26, 0.0011))
	_hours_label = _static_line("0", -0.082, AMBER, 40, 0.0013)
	face.add_child(_hours_label)
	_overflow_label = _static_line("", -0.135, Color(1.0, 0.42, 0.40), 24, 0.0011)
	face.add_child(_overflow_label)


func _static_line(txt: String, y: float, tint: Color, fsize: int, px: float) -> Label3D:
	var lab := Label3D.new()
	lab.text = txt
	lab.font_size = fsize
	lab.pixel_size = px
	lab.modulate = tint
	lab.outline_size = 0
	lab.shaded = false
	lab.position = Vector3(0.0, y, 0.0)
	return lab


## The wall. One MultiMesh of unit-height bars; each instance is one scratch,
## scaled and (for every fifth) rotated into the diagonal that closes a bundle.
## Slots are laid out in tally order, so visible_instance_count IS the count —
## the diagonal appears exactly when the fifth mark is made.
func _build_pile() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bar := BoxMesh.new()
	bar.size = Vector3(MARK_T, 1.0, MARK_T)
	mm.mesh = bar
	mm.instance_count = maxi(1, max_marks)

	for k in range(mm.instance_count):
		mm.set_instance_transform(k, _mark_transform(k))
		# Older marks are cooler and dimmer; the newest scratches are warm. The
		# wall reads as strata, not as a texture.
		var age: float = float(k) / float(maxi(1, max_marks - 1))
		mm.set_instance_color(k, Color(0.58, 0.60, 0.66).lerp(AMBER, age * 0.8))
	mm.visible_instance_count = clampi(_marks, 0, mm.instance_count)

	_mark_field = MultiMeshInstance3D.new()
	_mark_field.name = "TallyWall"
	_mark_field.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.55
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.35
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_mark_field.material_override = mat
	_own(_mark_field)


## Where scratch k lives. Bundles of five, five bundles to a row, rows stacking
## upward past the panel.
func _mark_transform(k: int) -> Transform3D:
	var bundle: int = k / 5
	var within: int = k % 5
	var row: int = bundle / BUNDLES_PER_ROW
	var col: int = bundle % BUNDLES_PER_ROW

	var row_span: float = float(BUNDLES_PER_ROW - 1) * BUNDLE_PITCH
	var bx: float = -row_span * 0.5 + float(col) * BUNDLE_PITCH
	var by: float = PILE_Y0 + float(row) * ROW_PITCH

	if within < 4:
		var x: float = bx - MARK_PITCH * 1.5 + float(within) * MARK_PITCH
		var basis_v: Basis = Basis().scaled(Vector3(1.0, MARK_H, 1.0))
		return Transform3D(basis_v, Vector3(x, by + MARK_H * 0.5, PILE_Z))
	# The fifth mark: the diagonal struck across the four.
	var basis_d: Basis = Basis(Vector3(0, 0, 1), deg_to_rad(72.0))
	basis_d = basis_d.scaled(Vector3(1.0, MARK_H * 1.45, 1.0))
	return Transform3D(basis_d, Vector3(bx, by + MARK_H * 0.5, PILE_Z + 0.008))


func _own(n: Node) -> void:
	add_child(n)
	_created.append(n)


# ═══════════════════════════════════════════════════════════════════
# THE SHIFT
# ═══════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_labels += labels_per_second * delta

	var want: int = int(_labels / float(maxi(1, labels_per_mark)))
	if want != _marks + _uncounted:
		var cap: int = maxi(1, max_marks)
		if want <= cap:
			_marks = want
			_uncounted = 0
		else:
			_marks = cap
			_uncounted = want - cap
		if _mark_field and _mark_field.multimesh:
			_mark_field.multimesh.visible_instance_count = clampi(
				_marks, 0, _mark_field.multimesh.instance_count)
	_refresh_readout()


func _refresh_readout() -> void:
	var items: int = int(_labels)
	# One number, two divisions. The hours are not a separate measurement — they
	# are the same total priced in bodies, which is why they can never catch up.
	var hours: int = int(_labels / maxf(1.0, labels_per_hour))
	if _items_label:
		_items_label.text = _group(items)
	if _hours_label:
		_hours_label.text = _group(hours)
	if _overflow_label:
		_overflow_label.text = "" if _uncounted <= 0 else "UNCOUNTED  +%s" % _group(_uncounted)


## Thousands grouping, so the item count reads as a magnitude at a glance and
## the hour count visibly does not.
func _group(n: int) -> String:
	var s: String = str(absi(n))
	var out: String = ""
	var c: int = 0
	var i: int = s.length() - 1
	while i >= 0:
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = " " + out
		i -= 1
	return ("-" + out) if n < 0 else out


# ═══════════════════════════════════════════════════════════════════
# MATERIAL + CONFIG
# ═══════════════════════════════════════════════════════════════════

func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


## Free only what this script made, then rebuild synchronously in place. Nothing
## deferred: the grid frames labels and grounds the artifact immediately after
## add_child, and a deferred rebuild would land after both and undo them.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_items_label = null
	_hours_label = null
	_overflow_label = null
	_mark_field = null
	_build_all()


## Grid config. Keys: "labels_per_second", "labels_per_hour", "labels_per_mark",
## "seed_marks", "max_marks".
func apply_grid_config(config_data: Dictionary) -> void:
	var before_mark: int = labels_per_mark
	var before_seed: int = seed_marks
	var before_max: int = max_marks

	if config_data.has("labels_per_second"):
		labels_per_second = maxf(0.0, float(config_data["labels_per_second"]))
	if config_data.has("labels_per_hour"):
		labels_per_hour = maxf(1.0, float(config_data["labels_per_hour"]))
	if config_data.has("labels_per_mark"):
		labels_per_mark = maxi(1, int(config_data["labels_per_mark"]))
	if config_data.has("seed_marks"):
		seed_marks = maxi(0, int(config_data["seed_marks"]))
	if config_data.has("max_marks"):
		max_marks = clampi(int(config_data["max_marks"]), 5, 600)

	if not _built:
		return  # _ready has not run yet; it will build with these values.
	if labels_per_mark == before_mark and seed_marks == before_seed and max_marks == before_max:
		# Only the rates moved — no geometry changes. Rebuilding here would throw
		# away framing that curation_station applies right after config and never
		# re-applies.
		return

	_rebuild_now()
