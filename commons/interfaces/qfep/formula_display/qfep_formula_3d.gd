# qfep_formula_3d.gd
# 3D visualization of the QFEP formula using TextMesh
# QFE = F − λE(S) + φΔE(S,t)

extends Node3D
class_name QFEPFormula3D

# Term colors
const COLOR_QFE := Color(1.0, 1.0, 1.0)       # White - result
const COLOR_F := Color(0.4, 0.6, 1.0)         # Blue - order
const COLOR_LAMBDA := Color(0.3, 1.0, 0.5)    # Green - entropy drive
const COLOR_E := Color(1.0, 0.4, 0.4)         # Red - entropy
const COLOR_PHI := Color(1.0, 0.5, 1.0)       # Magenta - rate term
const COLOR_OPERATOR := Color(0.7, 0.7, 0.7)  # Gray - operators

# Animation settings
@export var animate := true
@export var pulse_speed := 2.0
@export var glow_intensity := 0.3

# Font settings
@export var font_size := 0.15
@export var depth := 0.02

# Term references
var term_nodes: Dictionary = {}
var materials: Dictionary = {}

# Current highlight
var highlighted_term := ""

# Signals
signal term_highlighted(term_name: String)
signal term_selected(term_name: String)

func _ready():
	_create_formula()
	_setup_materials()
	
	# Add to interactable group
	add_to_group("interactable")
	add_to_group("qfep_display")

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
	
	# Center the formula
	var total_width = x_offset
	for child in get_children():
		if child is MeshInstance3D:
			child.position.x -= total_width / 2.0

func _add_term(term_id: String, text: String, x_pos: float, color: Color) -> float:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = term_id
	
	var text_mesh := TextMesh.new()
	text_mesh.text = text
	text_mesh.font_size = int(font_size * 1000)  # TextMesh uses integer font size
	text_mesh.depth = depth
	text_mesh.pixel_size = 0.001  # Scale factor
	
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
	
	# Calculate width for next term position
	# Approximate width based on text length
	var char_width: float = font_size * 0.6
	var term_width: float = text.length() * char_width
	
	return x_pos + term_width

func _setup_materials():
	# Materials are created in _add_term
	pass

func _process(delta):
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
		
		mat.emission_energy_multiplier = base_energy

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
				"description": "The unified measure of system state"
			}
		"F":
			return {
				"name": "Free Energy",
				"description": "Prediction error. Systems minimize this to find patterns."
			}
		"lambda":
			return {
				"name": "Lambda (λ)",
				"description": "Entropy drive. 0=order, 0.4=edge, 1=chaos"
			}
		"E":
			return {
				"name": "Entropy E(S)",
				"description": "Possibility space. High entropy = freedom."
			}
		"phi":
			return {
				"name": "Phi (φ)",
				"description": "Rate sensitivity. Positive = embrace change."
			}
		"delta":
			return {
				"name": "Delta (Δ)",
				"description": "Rate of change in entropy over time."
			}
		"E_rate":
			return {
				"name": "E(S,t)",
				"description": "Entropy as function of time. The becoming."
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
