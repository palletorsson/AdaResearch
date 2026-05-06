extends Node3D
class_name ArtifactPlaceholder

@export var label_prefix: String = "MISSING"

func _ready() -> void:
	var lookup_name: String = str(get_meta("artifact_lookup_name", name))
	var reason: String = str(get_meta("placeholder_reason", "")).strip_edges()
	var label_node: Node = get_node_or_null("Label3D")
	if label_node and label_node is Label3D:
		var label: Label3D = label_node
		if reason.is_empty():
			label.text = "%s: %s" % [label_prefix, lookup_name]
		else:
			label.text = "%s: %s (%s)" % [label_prefix, lookup_name, reason]
