extends "res://algorithms/cellularautomata/crossway_ca/CrosswayCA.gd"
## An early stochastic snapshot can have no active row. Export a bounded later
## source state, never fabricated cells; native timing and rules are unchanged.
func prepare_editor_preview() -> void:
	var advances: int = 0
	while not _has_drawn_cell() and advances < grid_height * 2 + 1:
		update_bridge()
		animate_cells(0)
		advances += 1
	if advances > 0: set_meta("void_preview_kind", "source_snapshot_advanced_%d_rows" % advances)
	if _has_drawn_cell(): return
	set_meta("void_preview_kind", "empty_sample_arrangement_marker")
	var marker := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(2,.1,2)
	marker.mesh = cube
	add_child(marker)
	var note := Label3D.new()
	note.text = "CROSSWAY / EMPTY SOURCE STATE\nArrangement marker only"
	note.font_size = 32; note.pixel_size = .01; note.position.y = 1
	add_child(note)

func _has_drawn_cell() -> bool:
	for column in cell_nodes:
		for cell in column:
			if is_instance_valid(cell) and cell.visible: return true
	return false
