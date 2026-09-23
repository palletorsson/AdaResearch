@tool
extends XRToolsInteractableSlider
## Native metre limits and detents; solve in the track's local coordinates.
func _process(_delta: float) -> void:
	if grabbed_handles.is_empty(): return
	var held: Array[Vector3] = []
	var offset := 0.0
	for handle: XRToolsInteractableHandle in grabbed_handles:
		held.append(handle.global_position)
		offset += to_local(handle.global_position).x - to_local(handle.handle_origin.global_position).x
	move_slider(slider_position + offset / grabbed_handles.size())
	# Moving the parent must not move the still-held hand a second time.
	for i in grabbed_handles.size(): grabbed_handles[i].global_position = held[i]
