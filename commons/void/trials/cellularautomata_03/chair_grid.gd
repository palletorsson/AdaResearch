extends "res://algorithms/cellularautomata/CAchairtests/CAGrid.gd"
## Source reset hides an empty MultiMesh, then seeds it without re-enabling its
## visible count. Restore visibility after the unchanged source visualization.
func update_visualization() -> void:
	super.update_visualization()
	if get_occupied_count() > 0:
		multimesh_instance.multimesh.visible_instance_count = -1
