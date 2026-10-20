extends SceneTree

var detail: Script
var failures: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	print("[wall-frames] ", "PASS " if passed else "FAIL ", label)
	if not passed: failures.append(label)

func build(mode: String, extra: Dictionary = {}) -> Node3D:
	var hall := Node3D.new()
	root.add_child(hall)
	var tile: Array = []
	for z in range(12):
		var row: Array = []
		for x in range(9):
			row.append("4" if x == 0 or x == 8 or (z in [0,11] and x != 4) else "1")
		tile.append(row)
	var opts := {"wall_frames":mode, "wall_features_max":12, "ceiling":false,
		"showing_proxies":true, "chapter":"randomness", "pearl":"test",
		"speak_lines":[{"token":"seed", "text":"The same seed keeps a beginning."}],
		"speak_adopt":{"7":"seed"}, "showing_rules":[
			{"index":4,"pearl":"test","text":"A kept observation"},
			{"index":3,"pearl":"other","text":"A different hall's caption"}]}
	opts.merge(extra,true)
	detail.dress_segment(hall,tile,9,12,{},-1,opts)
	return hall

func transforms(hall: Node3D, name: String) -> Array:
	var node := hall.get_node_or_null(name) as MultiMeshInstance3D
	var out: Array = []
	if node != null:
		# The dummy renderer returns identity for every MultiMesh readback.
		if DisplayServer.get_name() == "headless":
			return node.get_meta("em_xforms", [])
		for i in node.multimesh.instance_count:
			out.append(node.multimesh.get_instance_transform(i))
	return out

func ids(hall: Node3D, key: String) -> Array:
	var out: Array = []
	for child in hall.get_children():
		if child.has_meta(key): out.append(child.get_meta(key))
	out.sort()
	return out

func run() -> void:
	detail = load("res://commons/scenes/em/em_detail.gd")
	var all := build("all")
	var content := build("content")
	var off := build("off")
	check("legacy mode has blank frames available", ids(all,"em_showing").size() > 2)
	check("content retains only authored line and local caption", ids(content,"em_showing") == [4,7])
	check("cards and pick targets agree", ids(content,"em_showing_card") == ids(content,"em_showing"))
	check("book binding keeps its saved index", ids(content,"em_speak") == [7])
	check("book line stays at the same place", content.get_node("Speak7").position.is_equal_approx(all.get_node("Speak7").position))
	check("book token remains editable", content.get_node("Speak7").get_meta("em_speak_token") == "seed")
	for name in ["WallFrames","WallFields","WallMounts"]:
		var before := transforms(all,name)
		var after := transforms(content,name)
		check(name+" keeps stable instance indices", before.size() == after.size() and not before.is_empty())
		var stride: int = 4 if name == "WallFrames" else 1
		var consistent := true
		for i in after.size():
			if int(i / stride) in [4,7]:
				consistent = consistent and (after[i] as Transform3D).is_equal_approx(before[i])
			else:
				consistent = consistent and (after[i] as Transform3D).basis.get_scale().length_squared() < 1e-9
		check(name+" hides whole empty works", consistent)
		check("off builds no "+name, transforms(off,name).is_empty())
	check("off leaves no labels or ghost edit targets", ids(off,"em_showing").is_empty() and ids(off,"em_speak").is_empty() and ids(off,"em_showing_card").is_empty())
	for name in ["DoorHeads","FloorSeams","Skirting","ArrisTrim"]:
		check(name+" survives frame changes unchanged", not transforms(all,name).is_empty() and transforms(all,name) == transforms(content,name) and transforms(all,name) == transforms(off,name))
	check("detail adds no collision", all.find_children("*","CollisionShape3D",true,false).is_empty() and off.find_children("*","CollisionShape3D",true,false).is_empty())
	var bare := build("all",{"fill_walls":false})
	check("existing bare hall policy still wins", ids(bare,"em_showing").is_empty())
	check("invalid per-map value can inherit museum policy", detail.wall_frame_mode("invalid","content") == "content")
	# A removed place must never swallow an adopted/nearest sentence.
	var culled := build("content", {"showing_rules":[{"index":7,"pearl":"test","remove":true}]})
	check("line survives removal of its former wall place", ids(culled,"em_speak").size() == 1 and ids(culled,"em_speak") != [7])
	for hall in [all,content,off,bare,culled]: hall.free()
	print("WALL FRAMES: ", "PASS" if failures.is_empty() else "FAIL "+str(failures))
	quit(0 if failures.is_empty() else 1)
