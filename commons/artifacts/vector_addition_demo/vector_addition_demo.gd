# vector_addition_demo.gd
# Interactive vector addition: A + B = C
# VR-enabled with grabbable arrow endpoints
#
# Visualizes the parallelogram law: 
# Place vectors head-to-tail, resultant is the diagonal
#
# UPGRADED VISUALS - Sleek modern look with glow effects

extends Node3D

class_name VectorAdditionDemo

## Display settings
@export var max_vector_length: float = 1.2
@export var arrow_thickness: float = 0.006  # Small for exhibition

## Vector A
@export var vector_a: Vector3 = Vector3(0.8, 0.3, 0.0):
	set(value):
		vector_a = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_vectors()

## Vector B  
@export var vector_b: Vector3 = Vector3(0.2, 0.6, 0.3):
	set(value):
		vector_b = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_vectors()

# Sleek color palette
var color_a: Color = Color(1.0, 0.35, 0.4)      # Coral
var color_b: Color = Color(0.3, 0.85, 0.95)     # Cyan  
var color_result: Color = Color(0.4, 1.0, 0.5)  # Neon green
var color_ghost: Color = Color(0.5, 0.5, 0.6, 0.35)

var _arrow_a: Node3D
var _arrow_b: Node3D
var _arrow_result: Node3D
var _arrow_a_ghost: Node3D
var _arrow_b_ghost: Node3D
var _handle_a: Node3D
var _handle_b: Node3D
var _title_panel: Node3D
var _formula_panel: Node3D
var _ground: Node3D
var _axes: Node3D

# Vector labels
var _label_a: Label3D
var _label_b: Label3D
var _label_result: Label3D

# VR Controls
var _control_panel: Node3D

# Animation
var _time: float = 0.0

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

func _ready():
	# Use the visual helper
	_ground = VectorVisuals.create_ground(self, max_vector_length * 2.5)
	_axes = VectorVisuals.create_axes(self, max_vector_length * 1.3)
	
	_create_arrows()
	_create_handles()
	_create_labels()
	_create_vr_controls()
	_update_vectors()

func _create_arrows():
	# Main arrows - thin
	_arrow_a = VectorVisuals.create_arrow(self, "ArrowA", color_a, arrow_thickness)
	_arrow_b = VectorVisuals.create_arrow(self, "ArrowB", color_b, arrow_thickness)
	_arrow_result = VectorVisuals.create_arrow(self, "ArrowResult", color_result, arrow_thickness)
	
	# Ghost arrows for parallelogram
	_arrow_a_ghost = VectorVisuals.create_arrow(self, "ArrowAGhost", color_a, arrow_thickness, true)
	_arrow_b_ghost = VectorVisuals.create_arrow(self, "ArrowBGhost", color_b, arrow_thickness, true)

func _create_handles():
	_handle_a = VectorVisuals.create_handle(self, "HandleA", color_a, 0.045)
	_handle_a.position = vector_a
	
	_handle_b = VectorVisuals.create_handle(self, "HandleB", color_b, 0.045)
	_handle_b.position = vector_b
	
	# Add XRToolsPickable if available
	_make_pickable(_handle_a)
	_make_pickable(_handle_b)

func _make_pickable(_handle: Node3D):
	if ResourceLoader.exists("res://addons/godot-xr-tools/objects/pickable.gd"):
		# Create a RigidBody3D wrapper for XR picking
		pass  # Handle via Area3D for now

func _create_labels():
	# Exhibition plate - in front, tilted like museum label
	_title_panel = VectorVisuals.create_exhibition_plate(self, "TitlePanel", 
		"VECTOR ADDITION",
		"Aâƒ— + Bâƒ— = Câƒ—\nHead-to-tail method",
		Vector3(0, 0.05, max_vector_length + 0.3),
		Vector2(0.4, 0.12))
	
	# Formula panel - to the right side, facing player
	_formula_panel = VectorVisuals.create_panel(self, "FormulaPanel", "",
		Vector3(max_vector_length + 0.25, max_vector_length * 0.5, 0),
		Vector2(0.48, 0.2), 11, HORIZONTAL_ALIGNMENT_LEFT)
	_formula_panel.rotation_degrees = Vector3(0, -90, 0)
	
	# Vector labels - smaller
	_label_a = VectorVisuals.create_vector_label(self, "LabelA", "Aâƒ—", color_a)
	_label_b = VectorVisuals.create_vector_label(self, "LabelB", "Bâƒ—", color_b)
	_label_result = VectorVisuals.create_vector_label(self, "LabelResult", "Aâƒ—+Bâƒ—", color_result)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.08, max_vector_length + 0.45)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)  # Tilted up, facing +Z toward player
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.42, 0.12, 0.012)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.04, 0.04, 0.06, 0.95)
	panel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel_mat.metallic = 0.2
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.008
	_control_panel.add_child(panel_back)
	
	# Preset buttons
	var presets = [
		["ORTHO", Vector3(0.9, 0, 0), Vector3(0, 0.8, 0)],
		["ACUTE", Vector3(0.7, 0.3, 0), Vector3(0.3, 0.7, 0)],
		["3D", Vector3(0.6, 0.3, 0.3), Vector3(0.2, 0.5, 0.4)],
		["RESET", Vector3(0.8, 0.3, 0), Vector3(0.2, 0.6, 0.3)]
	]
	
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.14 + i * 0.09, 0, 0.01)
		btn.scale = Vector3(0.85, 0.85, 0.85)
		_control_panel.add_child(btn)
		_add_button_label(btn, presets[i][0])
		
		var va = presets[i][1]
		var vb = presets[i][2]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _apply_preset(va, vb))

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 9
	lbl.outline_size = 3
	lbl.outline_modulate = Color(0, 0, 0, 0.5)
	lbl.position = Vector3(0, -0.028, 0.01)
	btn.add_child(lbl)

func _apply_preset(va: Vector3, vb: Vector3):
	vector_a = va
	vector_b = vb
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func _update_vectors():
	var result = vector_a + vector_b
	
	# Position main arrows - all same thin thickness
	VectorVisuals.position_arrow(_arrow_a, Vector3.ZERO, vector_a, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_b, Vector3.ZERO, vector_b, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_result, Vector3.ZERO, result, arrow_thickness)
	
	# Ghost arrows (parallelogram)
	VectorVisuals.position_arrow(_arrow_a_ghost, vector_b, vector_b + vector_a, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_b_ghost, vector_a, vector_a + vector_b, arrow_thickness)
	
	# Update labels - offset toward +Z so they face the player
	_label_a.position = vector_a * 0.5 + Vector3(0, 0.06, 0.08)
	_label_b.position = vector_b * 0.5 + Vector3(0, 0.06, 0.08)
	_label_result.position = result * 0.5 + Vector3(0, 0.08, 0.1)
	
	# Update formula panel
	var formula_label = VectorVisuals.get_panel_label(_formula_panel)
	if formula_label:
		formula_label.text = "Aâƒ— = (%.2f, %.2f, %.2f)\n" % [vector_a.x, vector_a.y, vector_a.z]
		formula_label.text += "Bâƒ— = (%.2f, %.2f, %.2f)\n\n" % [vector_b.x, vector_b.y, vector_b.z]
		formula_label.text += "Aâƒ— + Bâƒ— = (%.2f, %.2f, %.2f)\n" % [result.x, result.y, result.z]
		formula_label.text += "|Aâƒ— + Bâƒ—| = %.3f" % result.length()

func _process(delta):
	_time += delta
	
	# Animate handles
	VectorVisuals.pulse_handle(_handle_a, delta, _time)
	VectorVisuals.pulse_handle(_handle_b, delta, _time + 1.0)
	
	# Animate arrows
	VectorVisuals.pulse_arrow(_arrow_result, delta, _time)
	
	# Check handle positions (for VR/dragging)
	if _handle_a.position != vector_a:
		vector_a = _handle_a.position
	if _handle_b.position != vector_b:
		vector_b = _handle_b.position

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_preset(Vector3(0.9, 0, 0), Vector3(0, 0.8, 0))
			KEY_2: _apply_preset(Vector3(0.7, 0.3, 0), Vector3(0.3, 0.7, 0))
			KEY_3: _apply_preset(Vector3(0.6, 0.3, 0.3), Vector3(0.2, 0.5, 0.4))
			KEY_R: _apply_preset(Vector3(0.8, 0.3, 0), Vector3(0.2, 0.6, 0.3))

func set_vectors(a: Vector3, b: Vector3):
	vector_a = a
	vector_b = b
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func get_result() -> Vector3:
	return vector_a + vector_b

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
