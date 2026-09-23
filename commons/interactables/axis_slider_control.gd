@tool
extends Node3D
var _interaction: Node3D
func _ready() -> void:
	var joint: Node3D = get_node("SliderOrigin/InteractableSlider")
	joint.slider_moved.connect(_on_moved)
	_on_moved(joint.slider_value)
	if not Engine.is_editor_hint():
		_interaction = preload("res://commons/interactables/scalar_pointer.gd").attach(self, joint, Vector3.UP)
func _on_moved(value: float) -> void:
	get_node("Frame/Label3DValue").text = "%+.2f" % value
func pointer_event(event: XRToolsPointerEvent) -> void:
	if is_instance_valid(_interaction): _interaction.pointer_event(event)
