extends "res://algorithms/fractals/box_counting_dimension/box_counting_dimension.gd"
## Keep source evidence visibility, avoiding a typed MeshInstance array lookup
## for its ordinary Node3D container during initial loading.
func _mute_tags(muted: bool) -> void:
	for child in get_children():
		if child == _point_cloud or child == _grid_instance or child == _plot_instance:
			continue
		if child is MeshInstance3D and _evidence_parts.has(child):
			continue
		if child.name == "CaptureAnchor":
			continue
		_set_muted(child, muted)
