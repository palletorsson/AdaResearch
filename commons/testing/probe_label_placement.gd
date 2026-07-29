# probe_label_placement.gd — does the caption cross the thing it captions?
#
# LabelFramer now sizes its plates correctly (it used to size them from a
# billboarded Label3D's diagonal CUBE, which made every plate a slab). Size was
# the framer's job and it is fixed. PLACEMENT is the artifact's job, and it is
# still wrong in several of them: labels sit at the same height as the body, so
# a correctly sized opaque plate still lands in front of it.
#
# Eyeballing 164 gallery tiles is not a measurement. This instantiates each
# artifact, runs the real framer, and reports the overlap between the caption
# plates and the artifact's own geometry — as a fraction of the body's frontal
# area, which is what a viewer actually loses.
#
#   godot --path . --xr-mode off --no-window \
#     --script res://commons/testing/probe_label_placement.gd -- --spec=<json>
#
# spec: {"scenes": [{"token": "...", "scene": "res://..."}, ...]}
extends SceneTree

const LabelFramer := preload("res://commons/grid/LabelFramer.gd")

var _spec_path: String = ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--spec="):
			_spec_path = a.split("=", 1)[1]
	_run.call_deferred()


## Union of every MeshInstance3D that is NOT caption furniture and NOT inside a
## Label3D — i.e. the artifact's actual body.
func _collect(node: Node, in_label: bool, plates: Array, body: Array) -> void:
	var is_label: bool = in_label or (node is Label3D)
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		var box: AABB = mi.global_transform * mi.get_aabb()
		if mi.has_meta("label_plate"):
			plates.append(box)
		elif not is_label:
			body.append(box)
	for c in node.get_children():
		_collect(c, is_label, plates, body)


func _union(boxes: Array) -> AABB:
	if boxes.is_empty():
		return AABB()
	var out: AABB = boxes[0]
	for i in range(1, boxes.size()):
		out = out.merge(boxes[i])
	return out


## Frontal overlap: how much of the body's XY footprint a plate covers, ignoring
## depth. A plate BEHIND the body still reads as background, so depth is checked
## separately and only counted when the plate is in front.
func _frontal_overlap(plate: AABB, body: AABB) -> float:
	var x_overlap: float = minf(plate.position.x + plate.size.x, body.position.x + body.size.x) \
		- maxf(plate.position.x, body.position.x)
	var y_overlap: float = minf(plate.position.y + plate.size.y, body.position.y + body.size.y) \
		- maxf(plate.position.y, body.position.y)
	if x_overlap <= 0.0 or y_overlap <= 0.0:
		return 0.0
	var body_area: float = maxf(body.size.x * body.size.y, 0.0001)
	return (x_overlap * y_overlap) / body_area


func _run() -> void:
	if _spec_path == "" or not FileAccess.file_exists(_spec_path):
		push_error("probe_label_placement: no spec")
		quit(1)
		return
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_spec_path))
	var results: Array = []

	for entry in spec.get("scenes", []):
		var token: String = str(entry.get("token", "?"))
		var path: String = str(entry.get("scene", ""))
		if not ResourceLoader.exists(path):
			print("MISS %s" % token)
			continue
		var inst: Node = load(path).instantiate()
		# Set swept @exports BEFORE add_child so _ready builds this variant.
		#
		# MEASURING ONLY THE DEFAULT IS THE TRAP THIS PROJECT KEEPS FALLING INTO.
		# The DNA sweep hit it (geodesic_dome scored INERT because the harness never
		# set the station its axis needs), and the first version of THIS probe hit it
		# too: it passed liar_loop at crossing=0 while the `both` value still had a
		# caption lying across the bulbs, because `both` is not the default and the
		# probe never built it. An instrument that only ever sees the shipped value
		# cannot speak about the others.
		var params: Dictionary = entry.get("params", {})
		for k in params.keys():
			if k in inst:
				inst.set(k, params[k])
		root.add_child(inst)
		await process_frame
		LabelFramer.frame_labels(inst)
		await process_frame

		var plates: Array = []
		var body: Array = []
		_collect(inst, false, plates, body)
		var body_box: AABB = _union(body)
		var worst: float = 0.0
		var crossing: int = 0
		for p in plates:
			var f: float = _frontal_overlap(p, body_box)
			# Only count a plate that is at or in front of the body's back face.
			var in_front: bool = (p.position.z + p.size.z) > body_box.position.z
			if f > 0.02 and in_front:
				crossing += 1
				worst = maxf(worst, f)
		results.append({"token": token, "plates": plates.size(),
			"crossing": crossing, "worst_frac": worst})
		print("%-28s plates=%-3d crossing=%-3d worst_pct_of_body=%.1f" % [
			token, plates.size(), crossing, worst * 100.0])
		inst.queue_free()
		await process_frame

	var out: String = str(spec.get("out", "res://ada_run/label_placement.json"))
	var f2 := FileAccess.open(out, FileAccess.WRITE)
	f2.store_string(JSON.stringify({"results": results}, " "))
	f2.close()
	print("probe_label_placement: %d artifacts -> %s" % [results.size(), out])
	quit(0)
