# qfep_formula_3d.gd
# 3D visualization of the QFEP formula using TextMesh
# QFE = F − λE(S) + φΔE(S,t)

extends Node3D
class_name QFEPFormula3D

# @identity
# essence: A spatial reading of Ada's QFEP research proposal, not a calculated QFE value.
# desire: Let a visitor question prediction, variation and change before accepting a formula.
# critical_parameter: highlighted_term; posture and emphasis control the reading.
# triggers: reading_study:on adds three term buttons and connects only this hall's lambda/phi rails.
# emerges: The colours and questions follow the controls. No entropy or player force is computed.
# needs: Tracked-hand and headset reading checks; a specified state space and objective for any numerical model.
# relationships: lambda_slider, phi_slider; compare with the independently controlled bifurcation_diagram.
# book_role: A proposal that the preceding mathematical encounters teach us to question.
# truth: A positive coefficient does not inherently welcome change; consequences depend on the model and objective.

# Term colors
const COLOR_QFE := Color(1.0, 1.0, 1.0)       # White - result
const COLOR_F := Color(0.4, 0.6, 1.0)         # Blue - order
const COLOR_LAMBDA := Color(0.3, 1.0, 0.5)    # Green - entropy drive
const COLOR_E := Color(1.0, 0.4, 0.4)         # Red - entropy
const COLOR_PHI := Color(1.0, 0.5, 1.0)       # Magenta - rate term
const COLOR_OPERATOR := Color(0.7, 0.7, 0.7)  # Gray - operators

# The generative "dark spot" term φΔE(S,t) — the open part of the formula.
# These term ids idle a touch brighter so the equation reads as un-sealed even
# when nothing is highlighted: an authored emphasis, not an objective calculation.
const GENERATIVE_TERMS := ["phi", "delta", "E_rate"]
const GENERATIVE_IDLE_BONUS := 0.25

# --- DNA (promoted 2026-07-29, stage 2) -------------------------------------
# posture: the stance of the equation in space — how a reader meets it.
#   line (shipped) one horizontal row, centred: the formula as a printed sentence
#   stack  one term per row: the formula as a balance sheet, terms as line items
#   arc    bent around the reader: the formula as a lens you stand at the focus of
#   ring   closed circle: no vantage shows the whole equation at once — a horizon
# emphasis: which term is lit from the start, i.e. which reading the room argues.
#   none (shipped) nothing highlighted until something calls highlight_term()
#   phi/delta/E_rate  the generative dark spot, the formula as becoming
#   lambda/E          the cost, the formula as accounting
#   F / QFE           the order, or the result
const POSTURES: Array = ["line", "stack", "arc", "ring"]
const EMPHASES: Array = ["none", "QFE", "F", "lambda", "E", "phi", "delta", "E_rate"]

@export_enum("line", "stack", "arc", "ring") var posture: String = "line"
@export_enum("none", "QFE", "F", "lambda", "E", "phi", "delta", "E_rate") var emphasis: String = "none"

# Animation settings
@export var animate := true
@export var pulse_speed := 2.0
@export var glow_intensity := 0.3

# Font settings
@export var font_size := 0.15
@export var depth := 0.02
## Opt-in local controls and term-reading panel for the synthesis hall.
@export var reading_study: bool = false
var _reading_study: Node3D

# Term references
var term_nodes: Dictionary = {}
var materials: Dictionary = {}

# Arrangement bookkeeping — filled by _add_term, consumed by _arrange
var _term_order: Array[String] = []
var _term_start: Dictionary = {}
var _term_width: Dictionary = {}
var _built: bool = false

# Current highlight
var highlighted_term := ""

# Signals
signal term_highlighted(term_name: String)
signal term_selected(term_name: String)

func _ready():
	_create_formula()
	_setup_materials()
	_apply_emphasis()
	_built = true

	# Add to interactable group
	add_to_group("interactable")
	add_to_group("qfep_display")
	_sync_reading_study()

func _create_formula():
	# Create the formula: QFE = F − λE(S) + φΔE(S,t)
	# Position each term horizontally
	
	var x_offset: float = 0.0
	var spacing: float = 0.02
	
	# QFE
	x_offset = _add_term("QFE", "QFE", x_offset, COLOR_QFE)
	x_offset += spacing
	
	# =
	x_offset = _add_term("equals", "=", x_offset, COLOR_OPERATOR)
	x_offset += spacing
	
	# F
	x_offset = _add_term("F", "F", x_offset, COLOR_F)
	x_offset += spacing
	
	# −
	x_offset = _add_term("minus1", "−", x_offset, COLOR_OPERATOR)
	x_offset += spacing
	
	# λ
	x_offset = _add_term("lambda", "λ", x_offset, COLOR_LAMBDA)
	
	# E(S)
	x_offset = _add_term("E", "E(S)", x_offset, COLOR_E)
	x_offset += spacing
	
	# +
	x_offset = _add_term("plus", "+", x_offset, COLOR_OPERATOR)
	x_offset += spacing
	
	# φ
	x_offset = _add_term("phi", "φ", x_offset, COLOR_PHI)
	
	# Δ
	x_offset = _add_term("delta", "Δ", x_offset, COLOR_PHI)
	
	# E(S,t)
	x_offset = _add_term("E_rate", "E(S,t)", x_offset, COLOR_E)
	
	# Arrange — `line` is the shipped centring pass, untouched
	_arrange(x_offset)


## The posture axis. `line` runs the original centring loop verbatim, so every
## term geometry uses measured glyph widths to keep the equation readable.
func _arrange(total_width: float) -> void:
	match posture:
		"stack":
			_arrange_stack()
		"arc":
			_arrange_curved(total_width, deg_to_rad(110.0))
		"ring":
			_arrange_curved(total_width, TAU)
		_:
			# Center the formula
			for child in get_children():
				if child is MeshInstance3D:
					child.position.x -= total_width / 2.0


## One term per row — the equation as a list of items rather than a sentence.
func _arrange_stack() -> void:
	var row: float = font_size * 1.5
	var count: int = _term_order.size()
	for i in range(count):
		var term_id: String = _term_order[i]
		var mesh_instance: MeshInstance3D = term_nodes[term_id]
		var w: float = float(_term_width[term_id])
		mesh_instance.position = Vector3(
			-w / 2.0,
			(float(count - 1) / 2.0 - float(i)) * row,
			0.0
		)
		mesh_instance.rotation = Vector3.ZERO


## Bend the line around the reader. Each term keeps its place in the reading
## order but is turned to face the centre — at TAU the equation closes on itself
## and no single vantage holds all of it.
func _arrange_curved(total_width: float, sweep: float) -> void:
	var span: float = max(total_width, 0.001)
	var radius: float = max(span / max(sweep, 0.001), font_size * 2.0)
	for i in range(_term_order.size()):
		var term_id: String = _term_order[i]
		var mesh_instance: MeshInstance3D = term_nodes[term_id]
		var center_x: float = float(_term_start[term_id]) + float(_term_width[term_id]) / 2.0
		var a: float = (center_x / span - 0.5) * sweep
		mesh_instance.position = Vector3(sin(a) * radius, 0.0, cos(a) * radius)
		mesh_instance.rotation = Vector3(0.0, a + PI, 0.0)

func _add_term(term_id: String, text: String, x_pos: float, color: Color) -> float:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = term_id
	
	var text_mesh := TextMesh.new()
	text_mesh.text = text
	text_mesh.font_size = int(font_size * 1000)  # TextMesh uses integer font size
	text_mesh.depth = depth
	text_mesh.pixel_size = 0.001  # Scale factor
	text_mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	mesh_instance.mesh = text_mesh
	mesh_instance.position = Vector3(x_pos, 0, 0)
	
	# Create material
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.5
	mesh_instance.material_override = material
	
	add_child(mesh_instance)
	term_nodes[term_id] = mesh_instance
	materials[term_id] = material

	# Measure the rendered glyphs; centred meshes plus guessed character widths
	# made lambda/E and phi/delta overlap in the line arrangement.
	var term_width: float = text_mesh.get_aabb().size.x + font_size * 0.12

	_term_order.append(term_id)
	_term_start[term_id] = x_pos
	_term_width[term_id] = term_width

	return x_pos + term_width

func _setup_materials():
	# Materials are created in _add_term
	pass

func _process(_delta):
	if not animate:
		return
	
	# Subtle pulse animation on all terms
	var time: float = Time.get_ticks_msec() / 1000.0
	
	for term_id in materials:
		var mat: StandardMaterial3D = materials[term_id]
		var base_energy: float = 0.5
		
		# Highlighted term pulses more
		if term_id == highlighted_term:
			base_energy = 1.0 + sin(time * pulse_speed * 2) * 0.5
		else:
			base_energy = 0.3 + sin(time * pulse_speed + hash(term_id) % 10) * glow_intensity
			# The generative term φΔE(S,t) never fully dims — the open/dark-spot
			# part of the formula keeps a warmer idle glow than the closed terms.
			if term_id in GENERATIVE_TERMS:
				base_energy += GENERATIVE_IDLE_BONUS

		mat.emission_energy_multiplier = base_energy

# --- Grid config ------------------------------------------------------------

## Grid hook. `emphasis` is applied IN PLACE — it only moves the highlight, so it
## never needs a rebuild. `posture` rebuilds the geometry, but ONLY when it really
## changed and only after _ready has built once: an unguarded rebuild here would
## free the terms out from under every shipped placement.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_posture: String = posture
	if config_data.has("reading_study"):
		reading_study = str(config_data.reading_study).to_lower() in ["on", "true", "1"]
		if _built: _sync_reading_study()

	if config_data.has("posture"):
		posture = _pick_axis(str(config_data["posture"]), POSTURES, posture)
	if config_data.has("emphasis"):
		var want: String = _pick_axis(str(config_data["emphasis"]), EMPHASES, emphasis)
		if want != emphasis:
			emphasis = want
			if _built:
				_apply_emphasis()

	if not _built:
		return
	if posture == before_posture:
		return
	_rebuild_now()


## Accept an axis value only if it names something we actually build.
## Case-insensitive on the way in, canonical on the way out — the term ids are
## mixed case ("QFE", "E_rate") and must survive the round trip.
func _pick_axis(raw: String, allowed: Array, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	for a in allowed:
		if str(a).to_lower() == v:
			return str(a)
	return fallback


func _apply_emphasis() -> void:
	highlighted_term = "" if emphasis == "none" else emphasis


func _rebuild_now() -> void:
	for term_id in term_nodes:
		var node: Node = term_nodes[term_id]
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	term_nodes.clear()
	materials.clear()
	_term_order.clear()
	_term_start.clear()
	_term_width.clear()
	_create_formula()
	_setup_materials()
	_apply_emphasis()
	if is_instance_valid(_reading_study): _reading_study.refresh()


func _sync_reading_study() -> void:
	if reading_study and not is_instance_valid(_reading_study):
		_reading_study = preload("res://commons/interfaces/qfep/formula_display/synthesis_reading_study.gd").new()
		_reading_study.name = "ReadingStudy"
		add_child(_reading_study)
	elif not reading_study and is_instance_valid(_reading_study):
		remove_child(_reading_study)
		_reading_study.queue_free()
		_reading_study = null


# Highlight a specific term
func highlight_term(term_name: String):
	highlighted_term = term_name
	term_highlighted.emit(term_name)

# Clear highlight
func clear_highlight():
	highlighted_term = ""

# Get term info for tooltips
func get_term_info(term_name: String) -> Dictionary:
	match term_name:
		"QFE":
			return {
				"name": "Queer Free Energy",
				"description": "Ada's research proposal; this display does not compute a value."
			}
		"F":
			return {
				"name": "Free Energy",
				"description": "A model-relative free-energy cost; requires a specified probabilistic model."
			}
		"lambda":
			return {
				"name": "Lambda (λ)",
				"description": "Weight on E(S). The rail colours are authored interpretations."
			}
		"E":
			return {
				"name": "Entropy E(S)",
				"description": "Entropy of specified states and probabilities; not a direct measure of freedom."
			}
		"phi":
			return {
				"name": "Phi (φ)",
				"description": "Weight on entropy change; its effect depends on the objective."
			}
		"delta":
			return {
				"name": "Delta (Δ)",
				"description": "Change over an interval; a rate also needs elapsed time."
			}
		"E_rate":
			return {
				"name": "E(S,t)",
				"description": "Entropy considered over time; the display does not measure it."
			}
		_:
			return {}

# Called when lambda slider changes (can be connected)
func on_lambda_changed(value: float):
	# Adjust lambda term color based on value
	if materials.has("lambda"):
		var mat: StandardMaterial3D = materials["lambda"]
		if value < 0.3:
			mat.albedo_color = COLOR_F  # Blue for order
			mat.emission = COLOR_F
		elif value < 0.5:
			mat.albedo_color = COLOR_LAMBDA  # Green for edge
			mat.emission = COLOR_LAMBDA
		else:
			mat.albedo_color = COLOR_E  # Red for chaos
			mat.emission = COLOR_E

# Called when phi slider changes
func on_phi_changed(value: float):
	if materials.has("phi"):
		var mat: StandardMaterial3D = materials["phi"]
		if value < 0:
			mat.albedo_color = Color(0.5, 0.3, 0.7)  # Purple for resist
			mat.emission = Color(0.5, 0.3, 0.7)
		else:
			mat.albedo_color = COLOR_PHI  # Magenta for embrace
			mat.emission = COLOR_PHI
