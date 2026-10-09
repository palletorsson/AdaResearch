extends Node3D
var _costume_on := true
var _studio := false
var _bake_mode := false
var _vr := false
var _dollhouse := false
var _wardrobe: Node
var _costume_hall := ""
var _player: Node3D
var _cam: Camera3D
var _vr_cam: Camera3D
var _vr_eye_name := ""
var _segments: Array = []
var _next_z := 0.0
const EYE := 1.65
const BUILD_AHEAD_M := 20.0

func _costume_walk() -> void:
	if not _costume_on or _studio or _bake_mode:
		return
	if _vr:
		var head: Camera3D = _vr_eye()
		if head == null:
			return
		if not is_instance_valid(_wardrobe) or not _wardrobe.call("wears_head", head):
			_wardrobe = null
			_costume_hall = ""
			for candidate in get_tree().get_nodes_in_group("costume_wardrobes"):
				if candidate.has_method("wears_head") and candidate.call("wears_head", head):
					_wardrobe = candidate
					break
	elif not is_instance_valid(_player):
		return
	if not is_instance_valid(_wardrobe) or not is_instance_valid(_wardrobe.get("costume")):
		return
	var z: float = _eye_pos().z
	var here: String = ""
	for sv in _segments:
		var sd: Dictionary = sv
		if z >= float(sd.get("z0", 0.0)) and z <= float(sd.get("z1", 0.0)):
			var seg: Node3D = _node_or_null(sd.get("node"))
			if seg != null and seg.has_meta("em_chapter"):
				here = String(seg.get_meta("em_chapter"))
			break
	if here == "" or here == _costume_hall:
		return
	_costume_hall = here
	if _wardrobe.call("give", here):
		print("[em-costume] walked into %s — it is on the body now" % here)

func _vr_eye() -> Camera3D:
	if _vr_cam != null and is_instance_valid(_vr_cam):
		var o: Node = _vr_cam.get_parent()
		while o != null and not (o is XROrigin3D):
			o = o.get_parent()
		if o != null and bool(o.get("current")):
			return _vr_cam
		_vr_cam = null          # the origin lost `current` — resolve again
	var origins: Array = []
	_collect_of_type(get_tree().get_root(), "XROrigin3D", origins)
	var pick: Node = null
	for og in origins:
		if bool(og.get("current")):
			pick = og
			break
	if pick == null and not origins.is_empty():
		pick = origins[origins.size() - 1]     # the most recently added rig — the loaded scene's
	if pick == null:
		return null
	var cams: Array = []
	_collect_of_type(pick, "XRCamera3D", cams)
	if cams.is_empty():
		return null
	_vr_cam = cams[0]
	var nm: String = str(pick.get_path())
	if nm != _vr_eye_name:
		_vr_eye_name = nm
	return _vr_cam

func _collect_of_type(n: Node, type_name: String, out: Array) -> void:
	if n.is_class(type_name):
		out.append(n)
	for c in n.get_children():
		_collect_of_type(c, type_name, out)

func _eye_pos() -> Vector3:
	if _studio:
		return Vector3(7.5, EYE, 8.0)     # a standing eye in the first hall: nothing culls, nothing streams
	if _bake_mode:
		# the bake has no walker: the eye stands just short of the built edge, so
		# the stream builds one segment per frame and frees the rooms behind
		return Vector3(7.5, EYE, _next_z - BUILD_AHEAD_M + 0.5)
	if _vr:
		var e := _vr_eye()
		return e.global_position if e != null else Vector3(7.5, EYE, 0.0)
	if _dollhouse and _player != null:
		# the CAMERA is a perch 30 m behind and 46 m above — the doll is the
		# visitor. Cull, streaming, the door, the acoustics and the toggle's
		# resume all follow the DOLL ("player position should be the same in
		# 3d as in iso").
		return _player.position + Vector3(0, EYE, 0)
	return _cam.global_position if _cam != null else Vector3.ZERO

func _node_or_null(v: Variant) -> Node3D:
	if v == null or not is_instance_valid(v):
		return null
	return v as Node3D
