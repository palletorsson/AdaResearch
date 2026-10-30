class_name GrabHint
extends Node3D
## DISTANCE GRAB, MADE EXPLICIT (Palle, 2026-10-30: "can we make distance grab more explicit"). XR Tools lets a
## hand grab a pickable up to `ranged_distance` away in a narrow cone, but shows nothing until the grip closes
## and the thing flies in. This node on the rig draws, for each hand, what that hand WOULD grab: a thin line
## from the hand to the pickup's `closest_object` and a ring on it, only while the thing is out of the near
## grab zone (within arm's reach the hand touches it, nothing to explain). The ring is the hand's colour so two
## hands' targets read apart. em_layout rig.grab_hint false removes it.

const LAYOUT := "res://commons/data/em_layout.json"
const COLOURS := {"LeftHand": Color("7fd0ff"), "RightHand": Color("ffb36b")}

var enabled := true
var _hands: Array = []     # [{ctrl, pickup, line: MeshInstance3D, ring: MeshInstance3D}]

func _ready() -> void:
	var cfg := _rig_config();enabled = bool(cfg.get("grab_hint", true))
	if not enabled:set_process(false);return
	for name in ["LeftHand", "RightHand"]:
		var ctrl: Node3D = get_parent().get_node_or_null(name)
		if ctrl == null:continue
		var pk: Node = XRToolsFunctionPickup.find_instance(ctrl) if ctrl is XRController3D else null
		if pk == null:continue
		var col: Color = COLOURS.get(name, Color.WHITE)
		var line := MeshInstance3D.new();line.name = "GrabLine";line.mesh = ImmediateMesh.new();line.top_level = true
		var lm := StandardMaterial3D.new();lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;lm.albedo_color = Color(col, .6);lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;line.material_override = lm
		add_child(line);line.hide()
		var ring := MeshInstance3D.new();ring.name = "GrabRing";var t := TorusMesh.new();t.inner_radius = .05;t.outer_radius = .062;t.rings = 24;t.ring_segments = 8;ring.mesh = t;ring.top_level = true
		var rm := StandardMaterial3D.new();rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;rm.albedo_color = Color(col, .85);rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;ring.material_override = rm
		add_child(ring);ring.hide()
		_hands.append({"ctrl": ctrl, "pickup": pk, "line": line, "ring": ring})

func _rig_config() -> Dictionary:
	if not FileAccess.file_exists(LAYOUT):return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	return parsed["rig"] if parsed is Dictionary and parsed.get("rig") is Dictionary else {}

## The hand's would-be grab, or null: the pickup's closest object when it is beyond the near zone and not held.
func target_of(ctrl: Node3D) -> Node3D:
	for h in _hands:
		if h.ctrl != ctrl:continue
		var pk: Node = h.pickup
		if is_instance_valid(pk.get("picked_up_object")):return null
		var o: Node3D = pk.get("closest_object")
		# XR Tools recomputes its closest object only when a body enters or leaves the ranged area, so a hand
		# that turns onto a thing already inside it sees nothing until it moves: the hint reads the area itself,
		# by the same rule (the nearest to the hand's forward within ranged_angle, pickable now)
		if o == null or not is_instance_valid(o):
			var best_dp: float = cos(deg_to_rad(float(pk.get("ranged_angle"))));var fwd: Vector3 = -ctrl.global_basis.z
			for c in (pk.get("_object_in_ranged_area") as Array):
				if not is_instance_valid(c) or not c.has_method("can_pick_up") or not c.can_pick_up(pk):continue
				var dp: float = fwd.dot(((c as Node3D).global_position - ctrl.global_position).normalized())
				if dp > best_dp:best_dp = dp;o = c
		if o == null or not is_instance_valid(o):return null
		if (o.global_position - ctrl.global_position).length() <= float(pk.get("grab_distance")) + .05:return null
		return o
	return null

## Is the hint drawn for this hand now?
func showing_for(ctrl: Node3D) -> bool:
	for h in _hands:
		if h.ctrl == ctrl:return (h.line as MeshInstance3D).visible and (h.ring as MeshInstance3D).visible
	return false

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	for h in _hands:
		var o: Node3D = target_of(h.ctrl);var line: MeshInstance3D = h.line;var ring: MeshInstance3D = h.ring
		if o == null:line.hide();ring.hide();continue
		line.global_transform = Transform3D.IDENTITY
		var im: ImmediateMesh = line.mesh;im.clear_surfaces();im.surface_begin(Mesh.PRIMITIVE_LINES)
		im.surface_add_vertex(h.ctrl.global_position);im.surface_add_vertex(o.global_position);im.surface_end();line.show()
		# the ring faces the eye, round the thing
		var look: Vector3 = (cam.global_position - o.global_position).normalized() if cam != null else Vector3.UP
		ring.global_transform = Transform3D(Basis.looking_at(look, Vector3.UP if absf(look.dot(Vector3.UP)) < .95 else Vector3.FORWARD) * Basis(Vector3.RIGHT, PI / 2), o.global_position);ring.show()
