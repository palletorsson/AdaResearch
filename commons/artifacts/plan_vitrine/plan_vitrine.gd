# plan_vitrine.gd
# A glass room around the walkable plan, and a pen in each hand once you are inside.

extends Node3D
class_name PlanVitrine

# @identity
# essence: enter(area) -> both controllers carry a draw_dot; exit(area) -> they give them back
# desire: the visitor stops reading the plan and starts drawing on it, with two incompatible pens at once
# critical_parameter: door_side — where the glass opens, which decides which way the time axis unrolls
# triggers: a visitor standing inside the box, polled at 10 Hz; not a signal, so an exit cannot be missed
# emerges: the difference between drawing IN space and drawing space AGAINST time, felt in two hands at the same moment
# needs: a live OpenXR rig for the pens [absent on desktop and in the museum, where the glass still builds and the hands stay empty]
# relationships: wraps simulation_grid, whose numbered rows become the amplitude ruler; arms draw_dot and draw_dot_time_domain, editing neither
# truth: two hands given different instruments will discover the difference faster than a label can state it

## 2026-09-09, Palle: "For the simulation_grid add a glass box around that we can
## enter and inside make both hand paint in the air with the two different
## versions of draw_dot. This is an area so when you enter add the draw_dots to
## the hand and when exit remove them."

# ── THE PENS ARE BUILT, NOT INSTANCED, AND THAT IS THE WHOLE TRICK ───────────
#
# The obvious build is `preload("draw_dot.tscn").instantiate()` onto a controller.
# It is wrong, and it fails in a way that would have been hard to read from
# inside a headset.
#
# draw_dot.tscn ships a child named GrabPoint which is an instance of
# grab_sphere_point.tscn — an XRToolsPickable rigid body. Mount that inside a
# collision hand and you have parented an obstacle to the thing that collides
# with it, and the OTHER hand's pickup function can reach over and take it off
# the first, welding a stray collider to the rig for the life of the session.
#
# So each pen is assembled here instead: a bare Node3D wearing draw_dot.gd, with
# a plain Marker3D named "GrabPoint" at the fingertip. That name is not decorative
# — draw_dot.gd:15 and :20 both default their NodePaths to "GrabPoint", and :412
# refuses to run unless both resolve.
#
# A Marker3D is exactly the right wrong shape, three times over:
#   * draw_dot.gd:442 gates recording on `_grab_point.has_method("is_picked_up")`.
#     A Marker3D has no such method, so the condition is false and the pen records
#     unconditionally. A pen strapped to your hand should not wait to be grabbed.
#   * draw_dot.gd:425 wires the `dropped` signal only `if has_signal("dropped")`.
#     A Marker3D has none, so nothing is ever appended to the TraceData autoload.
#   * It carries no collider, so there is nothing for a hand to fight or steal.
# `_draw_sphere` is declared Node3D at :103 and only ever read for
# `global_position` at :421 and :440, so a Marker3D serves it exactly.
#
# The result: neither draw_dot.gd nor draw_dot_time_domain.gd is edited.

# ── WHICH PEN GOES IN WHICH HAND, AND WHY IT IS NOT ARBITRARY ────────────────
#
# The time-domain pen does not paint in the air. It throws the hand's z away and
# stamps every sample on one frozen plane (draw_dot_time_domain.gd:69), then
# pushes the whole trail along world +Z (:47). That is an oscilloscope tape, and
# a tape is only legible from the SIDE — run it away from the reader and the
# history disappears into the vanishing point.
#
# Entering by the -x door the visitor faces +x, so their RIGHT hand points to
# world +Z. The tape unrolls across their view, which is the reading an
# oscilloscope wants, and into the half of the box the other hand is not using.
# On the left it would crawl straight through the free hand's sculpture.
#
# Which also, finally, gives the plan a job: its numbered columns become the
# amplitude ruler and +z becomes time. The left hand draws IN the space; the
# right hand draws the space AGAINST time.

const PLAN_SCENE := preload("res://commons/artifacts/simulation_grid/simulation_grid.tscn")
const SCRIPT_FREE := preload("res://commons/primitives/point/draw_dot.gd")
const SCRIPT_TAPE := preload("res://commons/primitives/point/draw_dot_time_domain.gd")

## The grid player's body sits on physics layer 20; the museum's Walker on layer
## 1. Masking only one is how an artifact ends up invisible in the other world.
const PLAYER_LAYER := 524288
const WALKER_LAYER := 1
## Occupancy is polled, never signalled — see _process().
const POLL_S := 0.1

## Build simulation_grid inside the box. False leaves the floor to the map.
@export var wrap_plan: bool = true
## Outer face to outer face, metres. simulation_grid's walkable collider is 5 x 5.
@export var span_m: float = 5.0
@export var height_m: float = 2.8
@export var pane_m: float = 0.012
## A ceiling pane. Off, because standing inside is already two glass layers on every level sight line.
@export var lid: bool = false
## Which face opens. The door is an invitation, not a gate: no pane has a collider, so every face is walk-through.
@export_enum("-x", "+x", "-z", "+z", "none") var door_side: String = "-x"
@export var tint: Color = Color(0.72, 0.84, 0.87, 0.12)
@export var edge_color: Color = Color(0.55, 0.85, 1.0)
@export var edge_glow: float = 1.4
@export var edge_m: float = 0.018
## Ink names, not colours — draw_dot.gd:70 declares ink as an enum of STRINGS, and a Color here would be refused in silence.
@export var left_ink: String = "cyan"
@export var right_ink: String = "amber"
## Seconds the marks hang in the air after the visitor steps out. 0 clears them with the hands.
@export var linger_s: float = 6.0
@export var tape_speed: float = 0.6
@export var tape_fade_s: float = 8.0
## Where the nib sits relative to the controller. The aim pose looks down -Z.
@export var nib_offset: Vector3 = Vector3(0.0, -0.012, -0.09)

## ONE ARTIFACT OWNS A CONTROLLER AT A TIME, across the whole process.
##
## The in-place map reload does not free ordinary interactables, so a second copy
## of this artifact can be built on top of the first while the first still holds
## the hands. Without this the second would mount its pens over the first's and
## the originals would leak for the life of the session. Keyed by controller
## instance id, valued by owning artifact instance id.
static var _claims: Dictionary = {}

var _area: Area3D
var _hold: Node3D
var _left_pen: Node3D
var _right_pen: Node3D
var _armed: bool = false
var _poll: float = 0.0
var _linger: float = 0.0


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["span_m", "height_m", "pane_m", "edge_m", "edge_glow", "linger_s",
			"tape_speed", "tape_fade_s"]:
		if config_data.has(key):
			set(key, float(config_data[key]))
	for key in ["wrap_plan", "lid"]:
		if config_data.has(key):
			set(key, bool(config_data[key]))
	if config_data.has("door"):
		var d := String(config_data["door"])
		if d in ["-x", "+x", "-z", "+z", "none"]:
			door_side = d
	if config_data.has("left_ink"):
		left_ink = String(config_data["left_ink"])
	if config_data.has("right_ink"):
		right_ink = String(config_data["right_ink"])
	for key in ["tint", "edge_color"]:
		if config_data.has(key):
			var c: Variant = config_data[key]
			if c is Color:
				set(key, c)
			elif typeof(c) == TYPE_STRING and Color.html_is_valid(str(c)):
				set(key, Color.html(str(c)))
	if is_inside_tree():
		_disarm()
		_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_left_pen = null
	_right_pen = null
	_armed = false

	if wrap_plan:
		var plan := PLAN_SCENE.instantiate()
		plan.name = "Plan"
		add_child(plan)

	_hold = Node3D.new()
	_hold.name = "Hold"          # where the pens live between visits
	_hold.visible = false
	add_child(_hold)

	_build_glass()
	_build_edges()
	_build_sensor()


## GLASS THAT DOES NOT BLOCK ANYONE.
##
## Every pane here is a MeshInstance3D and nothing else. There is no
## StaticBody3D, no CollisionShape3D and no CSG anywhere in this function, so the
## visitor walks through any face at engine level. The pathfinder is untouched
## too: it reads the structure layer and wall edges for blocking and never treats
## the interactables layer as occupancy. The doorway only says where the front is.
##
## Four separate meshes, not one box with CULL_DISABLED: transparency sorts PER
## OBJECT, so a single enclosing box pops inside out as you turn around in it.
func _build_glass() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.04
	mat.metallic = 0.15
	# Mandatory. Back-face culling makes the box vanish the moment you step in.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(tint.r, tint.g, tint.b)
	mat.emission_energy_multiplier = 0.25
	# NOT depth_draw_opaque_only: at alpha 0.12 no pixel is opaque, so it would
	# write no depth and buy nothing.

	var half := span_m * 0.5
	var c := half - pane_m * 0.5              # pane CENTRES, so outer faces land on +-half
	var inner := span_m - pane_m * 2.0        # the z panes butt inside the x panes

	_pane(mat, Vector3(pane_m, height_m, span_m), Vector3(-c, height_m * 0.5, 0.0), "-x")
	_pane(mat, Vector3(pane_m, height_m, span_m), Vector3(c, height_m * 0.5, 0.0), "+x")
	_pane(mat, Vector3(inner, height_m, pane_m), Vector3(0.0, height_m * 0.5, -c), "-z")
	_pane(mat, Vector3(inner, height_m, pane_m), Vector3(0.0, height_m * 0.5, c), "+z")

	if lid:
		var l := MeshInstance3D.new()
		l.name = "Lid"
		var lm := BoxMesh.new()
		lm.size = Vector3(inner, pane_m, inner)
		l.mesh = lm
		l.position = Vector3(0.0, height_m - pane_m * 0.5, 0.0)
		l.material_override = mat
		l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(l)


## One wall, cut into two jambs and a header if it is the door side.
func _pane(mat: StandardMaterial3D, size: Vector3, at: Vector3, side: String) -> void:
	if side != door_side:
		_glass_mesh(mat, size, at, "Pane" + side)
		return

	# The opening. 1.2 m wide and 2.1 m high, centred on the face.
	var open_w: float = 1.2
	var open_h: float = 2.1
	var along: int = 2 if (side == "-x" or side == "+x") else 0   # z for an x wall
	var run: float = size[along]
	if run <= open_w:
		_glass_mesh(mat, size, at, "Pane" + side)
		return
	var jamb: float = (run - open_w) * 0.5

	for s in [-1.0, 1.0]:
		var js := size
		js[along] = jamb
		var ja := at
		ja[along] += s * (open_w + jamb) * 0.5
		_glass_mesh(mat, js, ja, "Jamb" + side + ("A" if s < 0.0 else "B"))

	var hs := size
	hs[along] = open_w
	hs.y = height_m - open_h
	var ha := at
	ha.y = open_h + (height_m - open_h) * 0.5
	_glass_mesh(mat, hs, ha, "Header" + side)


func _glass_mesh(mat: StandardMaterial3D, size: Vector3, at: Vector3, node_name: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = at
	mi.material_override = mat
	# The floor is the one surface the visitor is always looking at.
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## LIT EDGES, because a glass box without them is a tinted ghost with no corners
## and the visitor cannot see where the room is, let alone where it opens.
func _build_edges() -> void:
	var em := StandardMaterial3D.new()
	em.albedo_color = edge_color
	em.emission_enabled = true
	em.emission = edge_color
	em.emission_energy_multiplier = edge_glow
	em.roughness = 0.3

	var half := span_m * 0.5 - edge_m * 0.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_edge(em, Vector3(edge_m, height_m, edge_m),
					Vector3(sx * half, height_m * 0.5, sz * half), "Post")
	for sz in [-1.0, 1.0]:
		_edge(em, Vector3(span_m, edge_m, edge_m),
				Vector3(0.0, height_m - edge_m * 0.5, sz * half), "RailTopX")
		_edge(em, Vector3(edge_m, edge_m, span_m),
				Vector3(sz * half, height_m - edge_m * 0.5, 0.0), "RailTopZ")

	# A lit frame around the opening — this is what reads as "come in here".
	if door_side == "none":
		return
	var open_w: float = 1.2
	var open_h: float = 2.1
	var along: int = 2 if (door_side == "-x" or door_side == "+x") else 0
	var sign_v: float = -1.0 if door_side.begins_with("-") else 1.0
	var face: int = 0 if along == 2 else 2

	for s in [-1.0, 1.0]:
		var p := Vector3.ZERO
		p[face] = sign_v * half
		p[along] = s * open_w * 0.5
		p.y = open_h * 0.5
		var sz2 := Vector3(edge_m, open_h, edge_m)
		_edge(em, sz2, p, "DoorPost")
	var lp := Vector3.ZERO
	lp[face] = sign_v * half
	lp.y = open_h
	var ls := Vector3(edge_m, edge_m, edge_m)
	ls[along] = open_w
	_edge(em, ls, lp, "Lintel")


func _edge(mat: StandardMaterial3D, size: Vector3, at: Vector3, node_name: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = at
	mi.material_override = mat
	add_child(mi)


## The sensor. An Area on nobody's layer, monitoring both worlds' bodies.
func _build_sensor() -> void:
	_area = Area3D.new()
	_area.name = "Inside"
	_area.collision_layer = 0                     # nothing can collide with it
	_area.collision_mask = PLAYER_LAYER | WALKER_LAYER
	_area.monitorable = false
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(span_m - pane_m * 2.0, height_m, span_m - pane_m * 2.0)
	col.shape = box
	col.position.y = height_m * 0.5
	_area.add_child(col)
	add_child(_area)


## OCCUPANCY IS A POLL, NOT A SIGNAL, and that is deliberate.
##
## body_entered/body_exited can be missed: an Area publishes a frame late, a
## rebuild re-enters with a stale list, and a body freed inside the box never
## emits its exit at all. Any of those leaves the pens welded to the hands after
## the visitor has walked away. A poll cannot miss an exit — the worst it can be
## is 0.1 s late, which nobody can feel. A 12 Hz poll of the same kind already
## ships to the Quest elsewhere in the corpus, so the budget is proven.
func _process(delta: float) -> void:
	if _linger > 0.0:
		_linger -= delta
		if _linger <= 0.0:
			_clear_pens()

	_poll -= delta
	if _poll > 0.0:
		return
	_poll = POLL_S

	var occupied := false
	if _area != null and is_instance_valid(_area):
		for b in _area.get_overlapping_bodies():
			if _is_visitor(b):
				occupied = true
				break

	if occupied and not _armed:
		_arm()
	elif not occupied and _armed:
		_disarm()


## A VISITOR, not merely a body. Shared verbatim with health_cross, approach_wall,
## approach_scale and carve_grid. Never `body is CharacterBody3D`: every hazard
## creature extends that class and sits on layer 1, and that fallback was measured
## letting a head crab trip a pad meant for the player.
func _is_visitor(b: Node) -> bool:
	if b == null or is_ancestor_of(b):
		return false
	if b.is_in_group("em_walker") or b.is_in_group("player_body") \
		or b.is_in_group("player") or b.is_in_group("vr_player"):
		return true
	var n: Node = b.get_parent()
	while n != null:
		if n is XROrigin3D:
			return true
		n = n.get_parent()
	return false


## Is there a real headset, as opposed to a scene with controller nodes parked in
## it? grid.tscn carries two idle controllers even under --xr-mode off, and
## mounting on those paints a permanent rail into every headless capture.
func _xr_live() -> bool:
	if has_meta("force_arm"):
		return true
	var i := XRServer.find_interface("OpenXR")
	return i != null and i.is_initialized()


## The live rig, not a parked one. Two rigs can bind the same trackers.
func _rig() -> XROrigin3D:
	var found: XROrigin3D = null
	var pending: Array[Node] = [get_tree().get_root()]
	while not pending.is_empty():
		var n: Node = pending.pop_back()
		if n is XROrigin3D:
			if n.current:
				return n
			found = n
		for c in n.get_children():
			pending.append(c)
	return found


func _controller(origin: XROrigin3D, tracker: StringName) -> XRController3D:
	# By TRACKER, never by name: "LeftHand" names both a controller and a hand
	# mesh on the same branch.
	for n in origin.find_children("*", "XRController3D", true, false):
		if n is XRController3D and n.tracker == tracker:
			return n
	return null


func _arm() -> void:
	if not _xr_live():
		return
	var origin := _rig()
	if origin == null:
		return
	var left := _controller(origin, &"left_hand")
	var right := _controller(origin, &"right_hand")
	if left == null or right == null:
		return
	# Both or neither; a half-armed pair is worse than none. The probe hook skips
	# this too, because a headless tree has controller NODES but no live tracker
	# to make either of them active, and the mount path is the thing under test.
	if not has_meta("force_arm") and not (left.get_is_active() and right.get_is_active()):
		return

	var me := get_instance_id()
	for ctrl in [left, right]:
		var key: int = ctrl.get_instance_id()
		if _claims.has(key):
			var owner_id: int = _claims[key]
			if owner_id != me and is_instance_valid(instance_from_id(owner_id)):
				return          # another vitrine holds the hands; yield to it
	for ctrl in [left, right]:
		_claims[ctrl.get_instance_id()] = me

	if _left_pen == null or not is_instance_valid(_left_pen):
		_left_pen = _make_pen(SCRIPT_FREE, left_ink, false)
		_left_pen.name = "PlanPen_L"
		_hold.add_child(_left_pen)
	if _right_pen == null or not is_instance_valid(_right_pen):
		_right_pen = _make_pen(SCRIPT_TAPE, right_ink, true)
		_right_pen.name = "PlanPen_R"
		_hold.add_child(_right_pen)

	_mount(_left_pen, left)
	_mount(_right_pen, right)

	# Aim the tape's writing plane at the low-z face, in WORLD space so it
	# survives a rotated token. With ~4.8 m of run at 0.6 m/s the trace fades
	# exactly as it reaches the far pane instead of escaping the box.
	if is_instance_valid(_right_pen) and _right_pen.has_method("_set_time_origin"):
		var p := global_position
		p.z -= (span_m * 0.5 - 0.1)
		_right_pen.call("_set_time_origin", p)

	_linger = 0.0
	_armed = true


func _mount(pen: Node3D, ctrl: Node3D) -> void:
	if not is_instance_valid(pen) or not is_instance_valid(ctrl):
		return
	if pen.get_parent() == ctrl:
		return                                  # idempotent: no double-add
	if pen.get_parent() != null:
		pen.get_parent().remove_child(pen)
	ctrl.add_child(pen)
	pen.transform = Transform3D.IDENTITY
	pen.visible = true
	pen.set_process(true)
	if pen.has_method("clear_trail"):
		pen.call("clear_trail")


## Build one pen. See the header for why this is not an instantiated scene.
func _make_pen(script: Script, ink_name: String, is_tape: bool) -> Node3D:
	var pen := Node3D.new()
	pen.set_script(script)

	# The nib. Named GrabPoint because draw_dot.gd resolves both of its NodePaths
	# to that name and refuses to run if either is missing. A Marker3D satisfies
	# the lookup and none of the pickable behaviour.
	var nib := Marker3D.new()
	nib.name = "GrabPoint"
	nib.position = nib_offset
	pen.add_child(nib)                          # before the pen enters any tree

	var dot := MeshInstance3D.new()
	dot.name = "Nib"
	var sm := SphereMesh.new()
	sm.radius = 0.012
	sm.height = 0.024
	dot.mesh = sm
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = edge_color
	dot.material_override = dm
	nib.add_child(dot)                          # mesh only, never a collider

	# Exports, all set before the pen enters the tree: draw_dot.gd reads its ink
	# config before it builds the trail.
	pen.set("record_only_when_grabbed", false)  # a pen strapped to a hand does not wait
	pen.set("show_data_table", false)
	pen.set("show_reference_frame", false)
	pen.set("auto_clear_on_drop", false)
	pen.set("ink", ink_name)                    # a STRING enum, not a Color
	pen.set("trigger_tag", "")                  # no unlock await to resume on a freed pen
	pen.set("retention", "none")
	if is_tape:
		pen.set("fade_trail", true)
		pen.set("fade_duration", tape_fade_s)
		pen.set("sample_interval", 0.04)
		pen.set("time_axis_speed", tape_speed)
		pen.set("trail_max_points", 4096)
		pen.set("lock_origin_on_ready", false)  # we set the origin ourselves, in world space
	else:
		pen.set("fade_trail", false)
		pen.set("min_segment_distance", 0.006)
		pen.set("trail_max_points", 2048)
	return pen


## Give the hands back. Nothing is freed: the pens are parked and reused, so a
## second entry costs no instantiation.
func _disarm() -> void:
	for pen in [_left_pen, _right_pen]:
		if pen == null or not is_instance_valid(pen):
			continue
		pen.set_process(false)
		if pen.get_parent() != null:
			pen.get_parent().remove_child(pen)
		if _hold != null and is_instance_valid(_hold):
			_hold.add_child(pen)
			pen.position = Vector3.ZERO
	_release_claims()
	_armed = false
	# The trail mesh is top-level, so the marks hang in world space. Let them.
	_linger = linger_s
	if linger_s <= 0.0:
		_clear_pens()


func _clear_pens() -> void:
	_linger = 0.0
	for pen in [_left_pen, _right_pen]:
		if pen != null and is_instance_valid(pen) and pen.has_method("clear_trail"):
			pen.call("clear_trail")


func _release_claims() -> void:
	var me := get_instance_id()
	for key in _claims.keys():
		if _claims[key] == me:
			_claims.erase(key)


## THE PENS LIVE OUTSIDE THIS ARTIFACT'S SUBTREE BY CONSTRUCTION — they are
## parented to controllers on the XR rig, which is a sibling of the map, not a
## descendant. So freeing the artifact cannot reach them and this teardown is not
## optional. Every step is validity-guarded because on a full tree teardown the
## controller may already be gone.
func _exit_tree() -> void:
	_release_claims()
	for pen in [_left_pen, _right_pen]:
		if pen == null or not is_instance_valid(pen):
			continue
		if pen.get_parent() != null:
			pen.get_parent().remove_child(pen)
		pen.queue_free()
	_left_pen = null
	_right_pen = null
	_armed = false


## For a probe.
func is_armed() -> bool:
	return _armed
