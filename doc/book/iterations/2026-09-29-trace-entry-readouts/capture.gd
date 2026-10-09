extends "res://tools/probes/transformation_encounters.gd"
## Visual inspection in the real museum, with supplied short drawing gestures.

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(2.0).timeout
	var pens: Array[Node3D] = []
	for node in hall.find_children("*", "Node3D", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("/point/draw_dot.gd"):
			pens.append(node)
	if pens.is_empty():
		failures.append("Drawing collection not found")
		return
	pens.sort_custom(func(a,b): return a.global_position.x < b.global_position.x)
	observations["readouts"] = []
	var middle := Vector3.ZERO
	for pen in pens:
		pen.set_process(false)
		pen.record_only_when_grabbed = false
		pen.data_table_update_interval = 0.0
		var grip: Node3D = pen.get("_grab_point")
		var home := grip.global_transform
		for i in range(16):
			grip.global_position = home.origin + Vector3(sin(i*0.38)*0.22,0.05+cos(i*0.38)*0.15,-0.10)
			pen.call("_process",0.2)
		grip.global_transform = home
		var panel: Node3D = pen.get("_data_panel")
		middle += panel.global_position
		observations.readouts.append({"name":str(pen.name),"scale":xyz(panel.global_basis.get_scale()),"front":xyz(panel.global_basis.z.normalized()),"position":xyz(panel.global_position),"rows":pen._trail_points.size()})
	middle /= pens.size()
	var eye := Vector3(middle.x,1.7,middle.z-3.6)
	for pen in pens: pen.apply_grid_config({"data_table_scale":1.0,"data_table_yaw":0})
	await snapshot("before-from-entry",eye,middle,64)
	for pen in pens: pen.apply_grid_config({"data_table_scale":0.7,"data_table_yaw":180})
	await snapshot("after-from-entry",eye,middle,64)
	var panel: Node3D = pens[1].get("_data_panel")
	await snapshot("readout-close",panel.global_position+Vector3(0,0.55,-1.2),panel.global_position,48)
	observations["capture_complete"] = true

func finish() -> void:
	if not bool(observations.get("capture_complete",false)): failures.append("Capture did not finish")
	var result := {"room":map_id,"observations":observations,"failures":failures,"passed":failures.is_empty(),"scope":"Native museum images of the actual drawing collection. Short gestures supplied to expose readouts; no headset legibility test. Before view uses the previous size/heading on the same live instruments."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if failures.is_empty() else 1)
