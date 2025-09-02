extends XRToolsPickable

@export var alternate_material : Material
@onready var task_manager_controller = $"../../../../TaskContainerModel/TaskManagerController"
@export  var we_are = "explore_images"

# Original material
var _original_material : Material

# Current controller holding this object
var _current_controller : XRController3D

# Debug label (optional for debug purposes)
@onready var debug_label: Label3D = $"../Label3D"

# Store the original Y position to reset when dropped
var _original_position: Vector3

var score = 0

func _on_grabbed(pickable: Variant, by: Variant) -> void:
	
	if is_in_group("teslasphere"):
		emit_signal("item_grabbed")
		debug_label.text = "item_grabbed"
	else:
		task_manager_controller.update_task_progress(we_are)
		debug_label.text = "item_grabbed"
