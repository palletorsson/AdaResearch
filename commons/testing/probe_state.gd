extends SceneTree

## Confirm in the REAL map whether the lab JSON / token edits took effect:
##  - wall annotations present? (should be GONE — show_wall_annotations:false)
##  - origin beam height (token beam_height:10.5) — actual world span of the beam
##  - lab floor world Y (to compute "3 m into the lab")
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_state.gd

const MAP_CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _find_named(node: Node, parts: Array, out: Array) -> void:
	var n := node.name.to_lower()
	for p in parts:
		if n.find(p) != -1:
			out.append(node); break
	for c in node.get_children():
		_find_named(c, parts, out)


func _find_script(node: Node, suffix: String, out: Array) -> void:
	var scr = node.get_script()
	if scr != null and str(scr.resource_path).ends_with(suffix):
		out.append(node)
	for c in node.get_children():
		_find_script(c, suffix, out)


func _run() -> void:
	change_scene_to_file(MAP_CATALOG)
	await process_frame
	await process_frame
	current_scene.call("load_map_fresh", "Point_One")
	for i in range(220):
		await process_frame

	# Wall annotations (Label3D "AnnotationEast/West")
	var anno: Array = []
	_find_named(current_scene, ["annotationeast", "annotationwest", "wallannotation"], anno)
	print("[st] wall-annotation nodes present: %d (expect 0)" % anno.size())

	# Origin beam
	var origins: Array = []
	_find_script(current_scene, "/origin/origin.gd", origins)
	for o in origins:
		var op: Vector3 = (o as Node3D).global_position
		var beam: Node = o.find_child("OriginBeam", true, false)
		print("[st] origin world=%s" % op)
		if beam is Node3D:
			# beam centre + half-height tell the top world Y.
			var mesh: CylinderMesh = (beam as MeshInstance3D).mesh
			var bc: Vector3 = (beam as Node3D).global_position
			var top_y: float = bc.y + mesh.height * 0.5
			print("[st]   beam height=%.2f  base_y=%.3f  top_y=%.3f" %
				[mesh.height, bc.y - mesh.height * 0.5, top_y])

	# Lab floor Y
	var labs: Array = []
	_find_script(current_scene, "lab_room.gd", labs)
	for l in labs:
		var fl: Array = []
		_find_named(l, ["floorwest", "flooreast"], fl)
		if fl.size() > 0:
			print("[st] lab floor world Y=%.3f → 3m into lab = world Y %.3f" %
				[(fl[0] as Node3D).global_position.y, (fl[0] as Node3D).global_position.y + 3.0])
	quit(0)
