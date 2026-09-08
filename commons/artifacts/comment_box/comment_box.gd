extends Node3D
class_name CommentBox

## THE COMMENT BOX (2026-09-05, Palle: "make a comment artifact that we can add
## and that has a comment box for input"). A lectern with a screen on its slant:
## click the text, type - the physical keyboard on desktop, the keys on the
## screen by laser in VR, and the same keys under the crosshair - press SEND, and
## the comment lands in ada_run/desktop_feedback.md, the file the Desktop-AI
## bridge already reads, under a `## <time> | <Map>` header with
## `- Source: comment_box` and `- Box: <id>` so the next agent knows where it
## was said. The writer is FeedbackWriter (commons/bridge), one implementation
## shared with the desktop overlays' format.
##
## ON THE DESKTOP. In a headset the sentence above is FALSE, and this file said
## it for two days (measured 2026-09-07). res:// is inside the .pck in an export
## and is read-only, so FeedbackWriter.save() is refused and falls back to
## user://desktop_feedback/ — which on a Quest is /data/data/<pkg>/files/, private
## to the device. vr_link.gd had already written this down on 2026-08-31: "every
## other bridge in this project (em_control.json, mapsim_control.json,
## desktop_feedback.md) is a FILE poll that cannot cross to a headset at all".
## The box shipped into Point_One — the museum lobby — five days later anyway.
## Until the box learns to send over vr_link, `python tools/pull_vr_feedback.py`
## is the wire: it reads that private file over adb and merges it here, and it is
## the only thing that lets a comment typed in VR reach the bridge or stage 6 of
## the pipeline scorer.
##
## Map token: comment_box:<rot>#label:Leave a comment#box:west_wall
## (the museum keeps only the FIRST #key). Config keys: label, box, prompt, out
## (a path override for probes - a test must never write into ada_run).
##
## Built for the three visitors this project has: the desktop crosshair
## (DesktopInteractionPointer walks up to the viewport body's pointer_event), the
## VR laser (layers 21 + 23), and the museum walker's DesktopHand. The screen is a
## Viewport2Din3D, which the grid's chrome pass leaves alone (it hides
## CanvasLayers only), and it stands on layers 21 + 23 only, so it is not a wall.
##
## While the text has focus the box stands in group `ada_typing`, which
## DesktopPlayer and the museum read to stop walking on letters. Focus is
## released by SEND, by LEAVE, by Escape, or by walking more than 2.5 m away.
## Nothing here touches Input.mouse_mode, and nothing writes before a real SEND.

signal activated
signal comment_sent(map_name: String, box_id: String, text: String, landed_at: String)

const V2D := preload("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
const UI := preload("res://commons/artifacts/comment_box/comment_box_ui.tscn")
# preloaded, not by class_name: a new global class is unknown to the class cache until the editor rebuilds it
const Feedback := preload("res://commons/bridge/feedback_writer.gd")
const POINTABLE_LAYERS := (1 << 20) | (1 << 22)   # 21 + 23: the pointers, not the player's feet
const SCREEN_M := Vector2(0.52, 0.36)
const SCREEN_PX := Vector2(624, 432)
const WALK_AWAY_M := 2.5
const TILT_DEG := 35.0

@export var label: String = "Leave a comment"
@export var box: String = ""
@export var prompt: String = "click here, then type"
@export var out: String = ""      # "" = the bridge's file; probes point this at user://

const WOOD := Color(0.36, 0.26, 0.18)
const SLATE := Color(0.16, 0.17, 0.19)
const BRASS := Color(0.72, 0.56, 0.26)
const PAPER := Color(1.0, 0.996, 0.988)

var _built := false
var _v2d: Node3D = null
var _ui: Node = null
var _typing := false
var _title_label: Label3D = null
var _plate_label: Label3D = null
var _walk_timer: Timer = null
var _focus_from: Vector3 = Vector3.INF   # where the visitor stood when the text took focus


func _ready() -> void:
	_read_meta()
	_build()


## The grid calls this deferred, after _ready; the museum calls it before
## add_child. Either way the box re-titles; it never rebuilds its screen.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("label"):
		label = str(config["label"])
	if config.has("box"):
		box = str(config["box"])
	if config.has("prompt"):
		prompt = str(config["prompt"])
	if config.has("out"):
		out = str(config["out"])
	if _built:
		_retitle()


func _read_meta() -> void:
	# both placers stamp config_<key> meta before add_child
	if has_meta("config_label"):
		label = str(get_meta("config_label"))
	if has_meta("config_box"):
		box = str(get_meta("config_box"))
	if has_meta("config_prompt"):
		prompt = str(get_meta("config_prompt"))
	if has_meta("config_out"):
		out = str(get_meta("config_out"))


func get_ui() -> Node:
	return _ui


# ---- the body ------------------------------------------------------------------

func _matte(c: Color, rough: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _box(size: Vector3, at: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)
	return mi


func _build() -> void:
	var wood := _matte(WOOD)
	var slate := _matte(SLATE, 0.6)
	var brass := _matte(BRASS, 0.35)

	# the lectern: a foot, a column, a tilted top
	_box(Vector3(0.46, 0.04, 0.46), Vector3(0, 0.02, 0), wood, self)
	# the column stops under the slant's front: taller, its top pokes up through
	# the tilted slab and lies across the keys (the first capture showed it)
	_box(Vector3(0.26, 0.84, 0.26), Vector3(0, 0.46, 0), wood, self)
	var top := Node3D.new()
	top.name = "Top"
	top.position = Vector3(0, 1.00, 0.0)
	top.rotation_degrees = Vector3(TILT_DEG, 0, 0)
	add_child(top)
	# a wedge under the slab fills the gap the tilt opens at the back
	_box(Vector3(0.24, 0.18, 0.20), Vector3(0, -0.09, 0), wood, top)
	_box(Vector3(0.62, 0.04, 0.46), Vector3.ZERO, slate, top)
	# a thin lip at the near edge, flush with the slant: raised, it hid the bottom
	# row of keys from any eye above the visitor's (the capture showed it)
	_box(Vector3(0.62, 0.02, 0.02), Vector3(0, 0.02, 0.235), brass, top)

	# the screen, flat on the slant: its +Z becomes the top's +Y
	_v2d = V2D.instantiate()
	_v2d.name = "Screen"
	_v2d.set("screen_size", SCREEN_M)
	_v2d.set("viewport_size", SCREEN_PX)
	_v2d.set("scene", UI)
	_v2d.set("unshaded", true)
	_v2d.set("transparent", 0)
	_v2d.set("update_mode", 2)       # throttled
	_v2d.set("throttle_fps", 20.0)
	_v2d.set("collision_layer", POINTABLE_LAYERS)
	# the box forwards the keyboard itself (see _input), so the order in which
	# _input reaches the two nodes cannot type a letter twice or not at all
	_v2d.set("input_keyboard", false)
	_v2d.position = Vector3(0, 0.021, -0.01)
	_v2d.rotation_degrees = Vector3(-90, 0, 0)
	top.add_child(_v2d)

	# the title above, facing the visitor
	_title_label = Label3D.new()
	_title_label.font_size = 56
	_title_label.pixel_size = 0.0025   # ~1.2 m for the default title; 0.004 spilled two cells
	_title_label.outline_size = 10
	_title_label.modulate = PAPER
	_title_label.outline_modulate = Color(0.1, 0.1, 0.12, 0.9)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED   # readable from every side, never mirrored
	_title_label.position = Vector3(0, 1.62, 0.05)
	add_child(_title_label)

	# the brass plate with the box's id on the column's front
	_box(Vector3(0.24, 0.06, 0.008), Vector3(0, 0.70, 0.134), brass, self)
	_plate_label = Label3D.new()
	_plate_label.font_size = 28
	_plate_label.pixel_size = 0.0011   # "comment box" fits the 0.24 m plate
	_plate_label.modulate = Color(0.12, 0.09, 0.05)
	_plate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plate_label.position = Vector3(0, 0.70, 0.139)
	add_child(_plate_label)

	_walk_timer = Timer.new()
	_walk_timer.wait_time = 0.5
	_walk_timer.autostart = true
	_walk_timer.timeout.connect(_on_walk_tick)
	add_child(_walk_timer)

	_built = true
	_retitle()
	_bind_ui.call_deferred()


func _retitle() -> void:
	if _title_label:
		_title_label.text = label
	if _plate_label:
		_plate_label.text = ("box · " + box) if not box.is_empty() else "comment box"
	if _ui:
		_ui.call("set_title", label)
		_ui.call("set_prompt", prompt)
		_ui.call("set_context", _context_line())
		_refresh_recent()


## The viewport instantiates its scene in its own _ready; bind once it exists,
## with one retry a frame later, as push_button_2d3d does.
func _bind_ui() -> void:
	if _v2d == null:
		return
	_ui = _v2d.call("get_scene_instance")
	if _ui == null:
		await get_tree().process_frame
		_ui = _v2d.call("get_scene_instance")
	if _ui == null:
		push_warning("comment_box: the screen has no UI")
		return
	_ui.connect("comment_submitted", _on_comment)
	_ui.connect("typing_changed", _on_typing)
	_retitle()


# ---- where we are ----------------------------------------------------------------

func _grid() -> Node:
	return get_tree().get_first_node_in_group("grid_system") if is_inside_tree() else null


func _map_name() -> String:
	var g := _grid()
	if g and "map_name" in g:
		var m := str(g.map_name)
		if not m.is_empty():
			return m
	# the museum: the hall the walker stands in, by the bridge's own reading
	var link := get_node_or_null("/root/VRLink")
	if link and link.has_method("_hall"):
		var hall = link.call("_hall")
		if hall is Dictionary and not str(hall.get("map", "")).is_empty():
			return str(hall.get("map"))
	var gm := get_node_or_null("/root/GameManager")
	if gm and "current_map_name" in gm and not str(gm.current_map_name).is_empty():
		return str(gm.current_map_name)
	var scene := get_tree().current_scene if is_inside_tree() else null
	return scene.name if scene else ""


func _sequence_name() -> String:
	var g := _grid()
	if g and g.has_meta("current_sequence"):
		var seq = g.get_meta("current_sequence")
		if seq is Dictionary:
			return str(seq.get("sequence_name", ""))
	return ""


func _context_line() -> String:
	var m := _map_name()
	var parts: Array[String] = []
	if not m.is_empty():
		parts.append("in " + m)
	if not box.is_empty():
		parts.append("box " + box)
	parts.append("what you say here reaches the next agent")
	return " · ".join(parts)


func _out_path() -> String:
	return out if not out.is_empty() else Feedback.MARKDOWN_PATH


# ---- the comment -----------------------------------------------------------------

func _on_comment(text: String) -> void:
	var m := _map_name()
	var p := global_position
	var extra := {
		"source": "comment_box",
		"box": box,
		"position": [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)],
	}
	var entry := Feedback.make_entry(text, m, _sequence_name(), extra)
	var landed := Feedback.save(entry, _out_path())
	if landed.is_empty():
		if _ui:
			_ui.call("sent_fail")
		return
	if _ui:
		_ui.call("sent_ok", landed)
	_refresh_recent()
	comment_sent.emit(m, box, text, landed)
	activated.emit()


func _refresh_recent() -> void:
	if _ui == null:
		return
	var path := _out_path()
	var blocks := Feedback.read_blocks(path)
	if blocks.is_empty() and path.begins_with("res://"):
		blocks = Feedback.read_blocks("%s/%s" % [Feedback.FALLBACK_DIR, path.get_file()])
	var mine: Array[String] = []
	var tag := "- Box: `%s`" % box if not box.is_empty() else "- Source: `comment_box`"
	var m := _map_name()
	for b in blocks:
		if b.find(tag) < 0:
			continue
		if not m.is_empty() and b.find("- Map: `%s`" % m) < 0:
			continue
		mine.append(b)
	var last := ""
	if not mine.is_empty():
		# the block: header line, bullets, blank, the comment, blank, ---
		var lines := mine[mine.size() - 1].split("\n")
		var seen_blank := false
		for l in lines:
			if l.is_empty():
				seen_blank = true
				continue
			if seen_blank and l != "---":
				last = l.substr(0, 90)
				break
	_ui.call("set_recent", mine.size(), last)


# ---- typing -------------------------------------------------------------------------

func _on_typing(t: bool) -> void:
	_typing = t
	if t:
		add_to_group("ada_typing")
		var v := _visitor()
		_focus_from = v.global_position if v else Vector3.INF
	elif is_in_group("ada_typing"):
		remove_from_group("ada_typing")


## WHILE THE TEXT HAS FOCUS, EVERY KEY IS ITS. The key goes into the screen's
## viewport here and is marked handled, so the scene's hotkeys never see it:
## M/N/C on the map switcher, E on the player, the museum's letters. The
## review that found this (2026-09-05) traced each of those to a typed letter.
func _input(event: InputEvent) -> void:
	if not _typing or _v2d == null:
		return
	if event is InputEventKey or event is InputEventShortcut:
		var vp := _v2d.get_node_or_null("Viewport")
		if vp:
			vp.push_input(event)
		get_viewport().set_input_as_handled()


func _visitor() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var p := tree.get_first_node_in_group("player_body")
	if p == null:
		p = tree.get_first_node_in_group("em_walker")
	if p == null:
		var gm := get_node_or_null("/root/GameManager")
		if gm and gm.has_method("get_player"):
			p = gm.call("get_player")
	return p as Node3D


## Walking away lets go of the text: measured from where the visitor stood when
## it took focus (a click from four metres is a click, not a walk), and from the
## box itself when nobody stood anywhere we could see.
func _on_walk_tick() -> void:
	if not _typing or _ui == null:
		return
	var v := _visitor()
	if v == null:
		return
	var origin := _focus_from if _focus_from != Vector3.INF else global_position
	var limit := WALK_AWAY_M if _focus_from != Vector3.INF else WALK_AWAY_M * 2.0
	if v.global_position.distance_to(origin) > limit:
		_ui.call("release")
