extends Node
## The hand message — what just changed, printed where the body is.
##
## 2026-10-22, Palle: "message on the hand when update is done". Every revision this
## game answers (commons/bridge/live_update.gd, via VRLink.update_acked) and every
## answer the bridge gives a spawn / move / remove from this hand (spawn_result) is
## written as one line on the left wrist: a Label3D above the controller, facing the
## eye, kept for a few seconds, the last three lines stacked. On desktop the same
## lines are a toast in the bottom-left corner. Created by VRLink beside the spawn menu.
##
## Lines read like:
##   floor 3 · museum-point_lines-31-12 moved to [-16.75, -2.5] facing 0 · in place
##   floor 3 rebuilt: parts rebuilds the floor
##   refused: conflict — base revision … is not what this Void holds
##   spawned spawn-film_profile_travels-143019 · saved as …ded40510-f10

const HOLD_S := 6.0
const LINES := 3
const PIXEL := 0.0009

var _link: Node = null
var _label: Label3D = null       # VR
var _toast: Label = null         # desktop
var _layer: CanvasLayer = null
var _lines: Array = []           # [{text, at}]
var _mounted := false
var _tries := 0


func _ready() -> void:
	_link = get_parent()
	if _link != null and _link.has_signal("update_acked"):
		_link.update_acked.connect(_on_ack)
		_link.spawn_result.connect(_on_spawn_result)


func _process(_delta: float) -> void:
	if not _mounted:
		_tries += 1
		if _tries % 30 == 1:
			_mount()
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	var keep: Array = []
	for l in _lines:
		if now - float(l["at"]) < HOLD_S:
			keep.append(l)
	if keep.size() != _lines.size():
		_lines = keep
		_redraw()
	if _label != null and is_instance_valid(_label):
		# face the eye, stay upright
		var cam: Camera3D = get_viewport().get_camera_3d()
		if cam != null:
			var to_eye: Vector3 = cam.global_position - _label.global_position
			to_eye.y = 0.0
			if to_eye.length() > 0.01:
				_label.global_transform.basis = Basis.looking_at(-to_eye.normalized(), Vector3.UP)


func _xr_active() -> bool:
	var vp: Viewport = get_viewport()
	return vp != null and vp.use_xr and XRServer.primary_interface != null


func _left_hand() -> Node3D:
	for n in get_tree().get_nodes_in_group("player"):
		if n is XROrigin3D:
			for c in (n as Node).get_children():
				if c is XRController3D and String((c as Node).name).to_lower().begins_with("left"):
					return c as Node3D
	return null


func _mount() -> void:
	if _xr_active():
		var left: Node3D = _left_hand()
		if left == null:
			return
		_label = Label3D.new()
		_label.name = "HandMessage"
		_label.pixel_size = PIXEL
		_label.font_size = 40
		_label.outline_size = 8
		_label.modulate = Color("f7d3e4")
		_label.outline_modulate = Color(0.08, 0.06, 0.1, 0.9)
		_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		_label.no_depth_test = true
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_label.position = Vector3(0.0, 0.16, -0.02)
		_label.text = ""
		left.add_child(_label)
		_mounted = true
		print("[hand-message] on %s" % left.name)
	else:
		_layer = CanvasLayer.new()
		_layer.name = "HandMessageLayer"
		_layer.layer = 61
		add_child(_layer)
		_toast = Label.new()
		_toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		_toast.offset_left = 24
		_toast.offset_bottom = -24
		_toast.offset_top = -140
		_toast.offset_right = 900
		_toast.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_toast.add_theme_font_size_override("font_size", 18)
		_toast.add_theme_color_override("font_color", Color("f7d3e4"))
		_toast.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.1, 0.9))
		_toast.add_theme_constant_override("outline_size", 6)
		_toast.text = ""
		_layer.add_child(_toast)
		_mounted = true
		print("[hand-message] desktop toast ready")


func say(text: String) -> void:
	_lines.append({"text": text, "at": Time.get_ticks_msec() / 1000.0})
	while _lines.size() > LINES:
		_lines.pop_front()
	print("[hand-message] " + text)
	_redraw()


func _redraw() -> void:
	var out: PackedStringArray = []
	for l in _lines:
		out.append(String(l["text"]))
	var text: String = "\n".join(out)
	if _label != null and is_instance_valid(_label):
		_label.text = text
	if _toast != null and is_instance_valid(_toast):
		_toast.text = text


## ————————————————————————————————————————————————————————————————————
## What to say
## ————————————————————————————————————————————————————————————————————

func _on_ack(a: Dictionary) -> void:
	var status: String = String(a.get("status", ""))
	var reason: String = String(a.get("reason", ""))
	var mode: String = String(a.get("mode", ""))
	var scene: String = String(a.get("scene", ""))
	var detail: String = String(a.get("detail", ""))
	var ops: Array = a.get("ops", [])
	if status == "rejected" and reason in ["already_current", "duplicate", "obsolete", "stale_replay"]:
		return   # the quiet refusals: nothing changed, nothing to announce
	var where: String = ""
	if scene == "void":
		where = "floor %s" % _floor_of(a, ops)
	elif String(a.get("map_id", "")) != "":
		where = String(a.get("map_id", ""))
	if status == "applied" and mode == "in_place":
		var first: String = ""
		for op_v in ops:
			var op: Dictionary = op_v
			if bool(op.get("ok", false)):
				first = String(op.get("detail", ""))
				break
		if first == "":
			first = detail
		var n: int = ops.size()
		say("%s · %s%s · in place" % [where, first, (" (+%d more)" % (n - 1)) if n > 1 else ""])
	elif status == "applied" and mode == "data":
		say("%s · changed while you were elsewhere; it builds when you arrive" % where)
	elif status == "applied" or status == "conflict":
		say("%s rebuilt: %s" % [where, detail])
	elif status == "requires_reload":
		say("%s · needs a reload (%s)" % [where, reason])
	else:
		say("refused: %s — %s" % [reason, detail.left(90)])


func _floor_of(a: Dictionary, ops: Array) -> String:
	for op_v in ops:
		var oid: String = String((op_v as Dictionary).get("object_id", ""))
		var parts: PackedStringArray = oid.split("/")
		if parts.size() >= 2:
			return parts[1]
	var d: String = String(a.get("detail", ""))
	var i: int = d.find("floor ")
	if i >= 0:
		var rest: String = d.substr(i + 6)
		var n: String = ""
		for ch in rest:
			if ch.is_valid_int():
				n += ch
			else:
				break
		if n != "":
			return n
	return "?"


func _on_spawn_result(r: Dictionary) -> void:
	var rid: String = String(r.get("revision_id", "")).right(13)
	if bool(r.get("ok", false)):
		if bool(r.get("removed", false)):
			say("removed %s · saved as %s" % [String(r.get("id", "")), rid])
		elif bool(r.get("moved", false)):
			say("moved %s · saved as %s" % [String(r.get("id", "")), rid])
		else:
			say("spawned %s · saved as %s" % [String(r.get("id", "")), rid])
	else:
		say("not saved: %s" % String(r.get("error", "?")).left(90))
