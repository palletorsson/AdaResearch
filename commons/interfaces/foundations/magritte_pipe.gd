# @identity
# essence: sign != signified -- a procedural pipe mesh with label saying this is not a pipe
# desire: a pipe you can see and inspect but that insists it is not what it appears to be
# critical_parameter: layers array -- maps representation levels (paint, canvas, word, variable) as strata
# triggers: static display; player proximity reveals layer explanations; contradiction is always present
# emerges: the gap between name and thing becomes tangible -- every data structure is a Magritte painting
# needs: procedural pipe mesh [has]; label system [has]; layer explanation text [has]; VR interaction [missing]
# relationships: foundational for artmathematics sequence; sign/signified gap extends to all formal systems
# truth: representation is a gap pretending to be a bridge -- computation runs on signs detached from signified.

# magritte_pipe.gd
# "Ceci n'est pas une pipe" — This is not a pipe
# René Magritte's 1929 painting that exposes the gap between signifier and signified
#
# The representation is not the thing.
# The map is not the territory.
# The model is not the world.
#
# In QFEP terms: F (free energy / predictive model) ≠ reality
# There is always a gap — and that gap is where queerness lives.

extends Node3D

class_name MagrittePipe

signal representation_questioned()
signal layer_revealed(layer_name: String)

## Pipe visual parameters
@export var pipe_color: Color = Color(0.4, 0.25, 0.15)
@export var frame_color: Color = Color(0.7, 0.6, 0.4)
@export var background_color: Color = Color(0.9, 0.88, 0.82)

## Show the classic text
@export var show_text: bool = true

## Current layer of representation
@export var current_layer: int = 0

# The layers of representation
var layers: Array[String] = [
	"Ceci n'est pas une pipe.",           # This is not a pipe
	"Ceci n'est pas une image.",          # This is not an image
	"Ceci n'est pas une représentation.", # This is not a representation
	"Ceci n'est pas un signe.",           # This is not a sign
	"Ceci n'est pas.",                    # This is not.
	"...",                                 # ...
]

var layer_explanations: Array[String] = [
	"The painting of a pipe is not a pipe.",
	"The digital model of the painting is not the painting.",
	"The concept of representation is not representation itself.",
	"The sign that points is not what it points to.",
	"Negation itself is a representation.",
	"The gap between sign and signified is irreducible.",
]

# Internal
var _frame: MeshInstance3D
var _canvas: MeshInstance3D
var _pipe_model: Node3D
var _text_label: Label3D
var _explanation_label: Label3D
var _interactable: Area3D
var _animation_time: float = 0.0

func _ready() -> void:
	_create_frame()
	_create_canvas()
	_create_pipe()
	_create_text()
	_create_interactable()
	_update_display()
	print("MagrittePipe: Ready — 'The map is not the territory'")

func _create_frame() -> void:
	_frame = MeshInstance3D.new()
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(0.8, 0.6, 0.05)
	_frame.mesh = frame_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.metallic = 0.1
	mat.roughness = 0.8
	_frame.material_override = mat
	
	add_child(_frame)

func _create_canvas() -> void:
	_canvas = MeshInstance3D.new()
	var canvas_mesh = BoxMesh.new()
	canvas_mesh.size = Vector3(0.7, 0.5, 0.01)
	_canvas.mesh = canvas_mesh
	_canvas.position.z = 0.03
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = background_color
	mat.metallic = 0.0
	mat.roughness = 1.0
	_canvas.material_override = mat
	
	add_child(_canvas)

func _create_pipe() -> void:
	_pipe_model = Node3D.new()
	_pipe_model.name = "PipeModel"
	_pipe_model.position = Vector3(0, 0.08, 0.04)
	
	# Bowl of pipe
	var bowl = MeshInstance3D.new()
	var bowl_mesh = CylinderMesh.new()
	bowl_mesh.top_radius = 0.04
	bowl_mesh.bottom_radius = 0.035
	bowl_mesh.height = 0.08
	bowl.mesh = bowl_mesh
	bowl.rotation.x = PI * 0.1
	bowl.position = Vector3(-0.12, 0, 0)
	
	var pipe_mat = StandardMaterial3D.new()
	pipe_mat.albedo_color = pipe_color
	pipe_mat.metallic = 0.2
	pipe_mat.roughness = 0.6
	bowl.material_override = pipe_mat
	_pipe_model.add_child(bowl)
	
	# Stem of pipe
	var stem = MeshInstance3D.new()
	var stem_mesh = CylinderMesh.new()
	stem_mesh.top_radius = 0.012
	stem_mesh.bottom_radius = 0.015
	stem_mesh.height = 0.25
	stem.mesh = stem_mesh
	stem.rotation.z = PI * 0.5
	stem.position = Vector3(0.02, -0.02, 0)
	stem.material_override = pipe_mat
	_pipe_model.add_child(stem)
	
	# Mouthpiece
	var mouth = MeshInstance3D.new()
	var mouth_mesh = CylinderMesh.new()
	mouth_mesh.top_radius = 0.008
	mouth_mesh.bottom_radius = 0.012
	mouth_mesh.height = 0.06
	mouth.mesh = mouth_mesh
	mouth.rotation.z = PI * 0.5 + PI * 0.15
	mouth.position = Vector3(0.15, -0.04, 0)
	mouth.material_override = pipe_mat
	_pipe_model.add_child(mouth)
	
	add_child(_pipe_model)

func _create_text() -> void:
	if not show_text:
		return
	
	# Main text (the famous phrase)
	_text_label = Label3D.new()
	_text_label.text = layers[0]
	_text_label.font_size = 28
	_text_label.position = Vector3(0, -0.15, 0.04)
	_text_label.pixel_size = 0.001
	_text_label.modulate = Color(0.15, 0.12, 0.1)
	_text_label.outline_size = 0
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_text_label)
	
	# Explanation (outside frame)
	_explanation_label = Label3D.new()
	_explanation_label.text = layer_explanations[0]
	_explanation_label.font_size = 18
	_explanation_label.position = Vector3(0, -0.4, 0)
	_explanation_label.pixel_size = 0.001
	_explanation_label.modulate = Color(0.5, 0.5, 0.5, 0.8)
	_explanation_label.outline_size = 3
	_explanation_label.outline_modulate = Color.BLACK
	_explanation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_explanation_label.width = 600
	_explanation_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_explanation_label)

func _create_interactable() -> void:
	_interactable = Area3D.new()
	_interactable.name = "InteractableArea"
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.8, 0.6, 0.1)
	collision.shape = shape
	_interactable.add_child(collision)
	
	_interactable.input_event.connect(_on_input_event)
	_interactable.input_ray_pickable = true
	
	add_child(_interactable)

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_layer()

func _process(delta: float) -> void:
	_animation_time += delta
	
	# Subtle floating animation for the pipe
	if _pipe_model:
		_pipe_model.position.y = 0.08 + sin(_animation_time * 0.8) * 0.005
	
	# On higher layers, the pipe becomes more abstract
	if current_layer >= 3 and _pipe_model:
		var alpha = 1.0 - (current_layer - 3) * 0.25
		for child in _pipe_model.get_children():
			if child is MeshInstance3D:
				var mat = child.material_override as StandardMaterial3D
				if mat:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mat.albedo_color.a = max(0.1, alpha)

func _update_display() -> void:
	if _text_label and current_layer < layers.size():
		_text_label.text = layers[current_layer]
	
	if _explanation_label and current_layer < layer_explanations.size():
		_explanation_label.text = layer_explanations[current_layer]
	
	emit_signal("layer_revealed", layers[current_layer] if current_layer < layers.size() else "...")

func advance_layer() -> void:
	current_layer = (current_layer + 1) % layers.size()
	_update_display()
	emit_signal("representation_questioned")
	
	print("MagrittePipe: Layer %d — '%s'" % [current_layer, layers[current_layer]])

func reset() -> void:
	current_layer = 0
	_update_display()
	
	# Reset pipe visibility
	if _pipe_model:
		for child in _pipe_model.get_children():
			if child is MeshInstance3D:
				var mat = child.material_override as StandardMaterial3D
				if mat:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					mat.albedo_color.a = 1.0
