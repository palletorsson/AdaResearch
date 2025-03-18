# DebugHelper.gd
extends Node
class_name DebugHelper
# Updates the provided Label3D node with the given message.
# DebugHelper.debug_label = $PathToYourDebugLabel
# DebugHelper.update_debug_label("Debug initialized.")

static func update_debug_label(label: Label3D, message: String) -> void:
	if label:
		label.text = message
