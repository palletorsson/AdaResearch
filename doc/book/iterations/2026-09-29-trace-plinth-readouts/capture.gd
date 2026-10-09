extends "res://tools/probes/transformation_encounters.gd"
## Native museum inspection: each smaller display rests on its own support.

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(2.0).timeout
	var pens: Array[Node3D] = []
	for node in hall.find_children("*", "Node3D", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("/point/draw_dot.gd"):
			pens.append(node)
	if pens.size()!=5:
		failures.append("Expected five drawing instruments")
		return
	pens.sort_custom(func(a,b):return a.global_position.x < b.global_position.x)
	observations["readouts"] = []
	var middle := Vector3.ZERO
	for pen in pens:
		var panel: Node3D = pen.get("_data_panel")
		var shell: MeshInstance3D = panel.get_node("Casing/Shell")
		var bounds := shell.global_transform * shell.get_aabb()
		var mounted: bool = pen.get("_data_mount_ready")
		var seat: Vector3 = pen.get("_data_mount_surface")
		observations.readouts.append({"name":str(pen.name),"position":xyz(panel.global_position),"front":xyz(panel.global_basis.z.normalized()),"scale":xyz(panel.global_basis.get_scale()),"bounds_min":xyz(bounds.position),"bounds_size":xyz(bounds.size),"support":xyz(seat),"empty_count":pen.get("_data_count_label").text,"visible":panel.visible,"mounted":mounted})
		if not mounted or absf(bounds.position.y-seat.y)>.005 or not panel.visible:
			failures.append("Display not visibly resting on its plinth: "+str(pen.name))
		middle += panel.global_position
	middle /= pens.size()
	var eye := Vector3(middle.x,1.7,middle.z-3.4)
	await snapshot("on-the-plinths",eye,middle,64)
	var panel: Node3D = pens[1].get("_data_panel")
	await snapshot("empty-and-on",panel.global_position+Vector3(0,0.65,-1.1),panel.global_position,48)
	for pen in pens:
		pen.set_process(false)
		pen.record_only_when_grabbed=false
		pen.data_table_update_interval=0.0
		var grip: Node3D = pen.get("_grab_point")
		var home := grip.global_transform
		for i in range(16):
			grip.global_position=home.origin+Vector3(sin(i*.38)*.22,.15+cos(i*.38)*.15,-.1)
			pen.call("_process",.2)
		grip.global_transform=home
	await snapshot("drawing-and-reading",eye,middle,64)
	await snapshot("readout-close",panel.global_position+Vector3(0,.65,-1.1),panel.global_position,48)
	var pose := panel.global_transform
	pens[1].clear_trail()
	observations["clear_keeps_mount"] = panel.global_transform.is_equal_approx(pose) and panel.visible and pens[1].get("_data_count_label").text=="0 POINTS"
	if not observations.clear_keeps_mount:failures.append("Clearing should keep the display on its plinth")
	observations["capture_complete"] = true

func finish() -> void:
	if not bool(observations.get("capture_complete",false)):failures.append("Capture did not finish")
	var result := {"room":map_id,"observations":observations,"failures":failures,"passed":failures.is_empty(),"scope":"Native museum inspection of actual support contact and zero-state readouts; supplied short gestures for the filled displays. No headset legibility trial."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if failures.is_empty() else 1)
