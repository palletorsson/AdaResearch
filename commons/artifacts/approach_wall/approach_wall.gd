extends Node3D
class_name ApproachWall

# @identity
# essence: a wall of slats that stands shut and makes way exactly where your body arrives
# desire: to answer a person instead of admitting one, so the hole is the shape of the approach and not the shape of a door
# critical_parameter: aperture_m — how much of the wall your body is worth
# triggers: any player body or museum walker inside the field; continuous, and it shuts again behind you
# emerges: a passage that exists only while somebody is there to need it
# needs: nothing but a visitor — with no visitor in the scene it stands closed, which is its resting state
# relationships: sibling to carve_grid, which you cut a tunnel through, and to the scaling room, which shrinks around you; this one gives way
# truth: a door decides where you go, this wall lets your body decide
#
## 2026-09-08, Palle: "On the same theme a wall mech that is closed but open when
## we approach."
##
## THE VISITOR'S BODY IS THE TRANSFORMATION. Everywhere else in this chapter a cube
## is translated, turned or scaled while you stand and watch it happen. Here the
## operator is you and the operand is the room. It is the chapter's standing ruling
## (Palle, 2026-09-05: "transformation creates empty space. The holes are the
## pathway up/down/to the side") carried one step further, because this hole is not
## authored into the map's structure layer. You make it by arriving and it is gone
## when you leave.
##
## It is not a door. A door has one hinge and one place it opens and it opens the
## same way for everybody who comes. This wall reads each slat's own distance to
## your body, so what opens is your width, your approach and nothing else. Walk
## along the face and the hole walks with you.
##
## THE DETECTOR AND THE BLOCKER ARE ON DIFFERENT LAYERS, AND THAT IS THE FACT THAT
## COST THE MOST.
##
## Three visitors have to be both seen and stopped, and they do not share a layer.
## The VR rig arrives as xr-tools' PlayerBody: collision layer 20 (524288), mask
## 1023. The desktop grid player is a plain CharacterBody3D left on the DEFAULT
## layer 1. The endless museum's walker is another bare CharacterBody3D, named
## Walker, layer 1, mask 1, in group em_walker and nothing else — no XROrigin3D
## ancestor, no grid player group. So the sensing Area3D masks 1 | 524288, which is
## health_cross's rule and the reason force_pad quietly does nothing in the museum.
## But the slats themselves must LIVE on layer 1, not 20: the walker masks 1 and
## the VR body masks 1023, and nothing in this project masks layer 20 at all, so a
## slat put there would be a wall that stops nobody while looking perfectly solid.
## One number to see with, a different one to be solid with.
##
## THE PRICE OF BEING SOLID ON LAYER 1 IS THAT THE SENSOR SEES THE BUILDING. The
## field is wide enough to cover the whole wall, and every floor slab, hall wall and
## podium in the grid is a StaticBody3D on layer 1 — as are this wall's own slats.
## Left unfiltered they arrive as visitors standing inside the wall and it hangs
## open forever. So a body counts only if it is a VISITOR: one of the four visitor
## groups, or an XROrigin3D somewhere above it, and never a descendant of this
## node. Not "any CharacterBody3D" — hazard_creature_base extends CharacterBody3D,
## and a silhouette drifting along the far side would hold the wall open until the
## visitor arrived to find it was never shut.
##
## THE COLLISION FOLLOWS THE MESH BECAUSE IT HAS NO WAY NOT TO. The worst failure
## this artifact can have is looking open and stopping you — a hole you can see
## through and walk into. So there is no second copy of the motion to drift: the
## shape and the mesh are both children of the one AnimatableBody3D that moves and
## they ride its transform. AnimatableBody3D and not StaticBody3D, because a
## StaticBody moved by script carries no platform velocity and shoves a standing
## visitor through whatever is behind them.

const PLAYER_LAYER := 524288          # physics layer 20 — the xr-tools PlayerBody
const WALKER_LAYER := 1               # physics layer 1  — museum Walker and desktop player
const MODE_SWING := 0
const MODE_SLIDE_Y := 1
const MODE_SLIDE_X := 2
## A crowd is bounded so the per-frame work is bounded. Nine people at one wall is
## a party, not a museum.
const MAX_VISITORS := 8
## The sensor is signal-driven, but a body freed mid-overlap never sends its exit
## and would hold the wall open. Twice a second the list is rebuilt from scratch.
const RESYNC_S := 0.5
const OPEN_EDGE := 0.05
const SLIDE_SPAN := 1.6               # slide_x moves a slat this many of its own widths
## The one place the mode names are written down, so the export hint, the config
## reader and the index cannot drift apart.
const MODE_NAMES := ["swing", "slide_y", "slide_x"]

## How many slats the wall is cut into. More slats means the hole can follow you
## more finely; the wall is no more open at ten than at forty, only smoother.
@export var slats: int = 15
## The wall's span, metres. Its plane is local XY and its face looks down local -Z.
@export var width_m: float = 4.4
## How tall it stands. The bottom sits on the floor at y = 0.
@export var height_m: float = 3.0
## How deep each slat is, front to back.
@export var thickness_m: float = 0.12
## How wide the hole your body opens is. Half a metre is a wall that grudges you a
## gap; two metres is a wall that steps aside for anyone in the room.
@export var aperture_m: float = 1.3
## How near you have to be before anything begins to move. Measured straight out
## from the wall's face, either side.
@export var reach_m: float = 2.6
## Seconds for a slat to cover most of the distance to where it should be. This is
## the difference between a wall that breathes and a wall that snaps.
@export_range(0.01, 3.0, 0.01) var ease_s: float = 0.22
## Which way the wall spends its openness. swing: each slat turns out of the plane
## about its inner edge. slide_y: slats sink into the floor. slide_x: slats part
## sideways and bunch. A String rather than an int so a registry sweep can set it
## by name — Object.set() of an int onto a typed String property is refused in
## silence, and the other way round too.
@export_enum("swing", "slide_y", "slide_x") var open_by: String = "swing"
## How far a slat turns when it is fully open, degrees. Past ninety it tucks back
## against its neighbour instead of standing in the doorway.
@export var swing_deg: float = 95.0
## The shoulder width is_passable() is asked about. A gap narrower than this is a
## view, not a way through.
@export var pass_width_m: float = 0.55
## Seconds a visitor may stand in front of a wall that never moves before it says
## so out loud.
@export var seal_report_s: float = 4.0
@export var slat_color: Color = Color(0.62, 0.63, 0.66)

## The wall has just given way. The fraction is how far the widest slat had got at
## that moment. Sent on the rising edge and again whenever the opening grows
## noticeably wider, never every frame: a signal per frame on a Quest is an
## argument array per frame.
signal opened(fraction: float)
## Shut again, and standing as it was found.
signal closed()
## Somebody stood inside the field, in front of the wall's own span, for
## seal_report_s, and not one slat moved past three percent. Said out loud once,
## because a wall that silently refuses is indistinguishable from a wall that is
## simply a wall. It catches the rotation mistake — the plane is local XY facing
## -Z, so a wall turned a quarter turn in a map reads your approach as travel along
## its face and never sees you coming — and it catches aperture_m set to nothing.
## It cannot catch a wrong collision mask, because the mask is also what tells it
## somebody is standing there; that failure is prevented by construction instead.
signal sealed(why: String)

var _field: Area3D
var _slats: Array[AnimatableBody3D] = []
var _visitors: Array[Node3D] = []

var _cx := PackedFloat32Array()       # each slat's centre, wall-local x
var _hx := PackedFloat32Array()       # each slat's hinge, wall-local x
var _off := PackedFloat32Array()      # centre minus hinge — the slat's own arm
var _open := PackedFloat32Array()     # where each slat actually is, 0 shut
var _side := PackedFloat32Array()     # latched: which side of the plane the visitor was on
var _push := PackedFloat32Array()     # latched: which way along x to get out of the way
var _vx := PackedFloat32Array()
var _vz := PackedFloat32Array()

var _mode := MODE_SWING
var _slat_w := 0.0
var _vn := 0
var _resync := 0.0
var _widest := 0.0
var _peak := 0.0
var _near_s := 0.0
var _covered := false
var _is_open := false
var _reported := 0.0
var _sealed_said := false


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("slats"):
		slats = int(config_data["slats"])
	if config_data.has("width"):
		width_m = float(config_data["width"])
	if config_data.has("height"):
		height_m = float(config_data["height"])
	if config_data.has("thickness"):
		thickness_m = float(config_data["thickness"])
	if config_data.has("aperture"):
		aperture_m = float(config_data["aperture"])
	if config_data.has("reach"):
		reach_m = float(config_data["reach"])
	if config_data.has("ease"):
		ease_s = float(config_data["ease"])
	if config_data.has("swing"):
		swing_deg = float(config_data["swing"])
	if config_data.has("pass_width"):
		pass_width_m = float(config_data["pass_width"])
	# open_by arrives either as its name or as its index, because a map token and a
	# registry sweep do not agree about which one a value is.
	if config_data.has("open_by"):
		_take_mode(config_data["open_by"])
	elif config_data.has("mode"):
		_take_mode(config_data["mode"])
	if config_data.has("color"):
		var c: Variant = config_data["color"]
		if c is Color:
			slat_color = c
		elif typeof(c) == TYPE_STRING and Color.html_is_valid(str(c)):
			slat_color = Color.html(str(c))
	if is_inside_tree():
		_build()


func _take_mode(v: Variant) -> void:
	if typeof(v) == TYPE_STRING or typeof(v) == TYPE_STRING_NAME:
		var s := str(v).to_lower()
		if MODE_NAMES.has(s):
			open_by = s
		return
	var i: int = clampi(int(v), 0, MODE_NAMES.size() - 1)
	open_by = str(MODE_NAMES[i])


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_slats.clear()
	_visitors.clear()
	_vn = 0
	_widest = 0.0
	_peak = 0.0
	_near_s = 0.0
	_covered = false
	_is_open = false
	_reported = 0.0
	_sealed_said = false
	_resync = 0.0

	# A map is allowed to ask for something silly. The ceiling is what a Quest can
	# carry as moving colliders without the frame budget noticing.
	var n: int = clampi(slats, 1, 96)
	width_m = maxf(width_m, 0.1)
	height_m = maxf(height_m, 0.1)
	thickness_m = maxf(thickness_m, 0.01)
	_slat_w = width_m / float(n)
	_mode = _mode_index()

	_cx.resize(n)
	_hx.resize(n)
	_off.resize(n)
	_open.resize(n)
	_side.resize(n)
	_push.resize(n)
	_vx.resize(MAX_VISITORS)
	_vz.resize(MAX_VISITORS)

	# Two materials shared between all the slats, alternating, so the row reads as
	# separate boards without cutting a hairline gap between them. A visible gap
	# would be a place where the mesh and the collision disagree, which is the one
	# thing this wall must never do.
	var mats: Array[StandardMaterial3D] = []
	for k in 2:
		var m := StandardMaterial3D.new()
		m.albedo_color = slat_color.darkened(0.0 if k == 0 else 0.13)
		m.roughness = 0.62
		m.metallic = 0.08
		mats.append(m)

	var size := Vector3(_slat_w, height_m, thickness_m)
	for i in n:
		var cx: float = -width_m * 0.5 + (float(i) + 0.5) * _slat_w
		# The hinge is the slat's edge nearer the wall's middle, so a hole opened at
		# the centre parts like two shutters and one opened at an end swings a
		# single board clear.
		var s: float = 1.0 if cx >= 0.0 else -1.0
		_cx[i] = cx
		_hx[i] = cx - s * _slat_w * 0.5
		_off[i] = s * _slat_w * 0.5
		_open[i] = 0.0
		_side[i] = 1.0
		_push[i] = s

		var body := AnimatableBody3D.new()
		body.name = "Slat%02d" % i
		# Solid on layer 1: that is what the walker, the desktop player and the VR
		# body all actually collide against. It masks nothing — a wall has no
		# business detecting anything, the field does that.
		body.collision_layer = WALKER_LAYER
		body.collision_mask = 0
		# Moved from _physics_process, so it carries a platform velocity and pushes
		# a visitor out of the way instead of teleporting through them.
		body.sync_to_physics = true
		body.position = Vector3(_hx[i], 0.0, 0.0)
		add_child(body)

		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mesh.mesh = bm
		mesh.material_override = mats[i % 2]
		mesh.position = Vector3(_off[i], height_m * 0.5, 0.0)
		body.add_child(mesh)

		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		col.position = mesh.position
		body.add_child(col)

		_slats.append(body)

	# THE FIELD. One area for the whole wall rather than one per slat: the slats
	# want continuous positions, not enter and exit events, and eight overlap tests
	# a frame is cheaper than sixty.
	_field = Area3D.new()
	_field.name = "Field"
	_field.collision_layer = 0
	_field.collision_mask = PLAYER_LAYER | WALKER_LAYER
	# Nothing watches for areas here, and a monitorable area is reported to every
	# force field, danger zone and trigger volume in the hall for no reason.
	_field.monitorable = false
	# THE SENSOR IS NOT A BODY, AND THE MUSEUM CANNOT TELL THEM APART.
	# endless_museum._extent_of walks every descendant and merges the AABB of any
	# MeshInstance3D or any CollisionShape3D it finds. A sensing volume hung on a
	# CollisionShape3D child is therefore measured as this artifact's own extent:
	# measured 41 sealed cells for a wall 4.40 m wide and 0.12 m thick.
	# Sealing a reach as if it were solid is an over-seal of the walk map, and the
	# ledgered footprint is the distance at which the artifact NOTICES you rather
	# than the space it occupies. So the shape goes straight onto the Area3D
	# through the shape-owner API, which builds no node for _extent_of to find.
	# Overlap detection is unchanged: shape owners are how CollisionObject3D holds
	# shapes either way.
	var fbox := BoxShape3D.new()
	# Wider than the wall by an aperture, so a slat at the very end still feels
	# somebody standing just past the corner, and half a metre proud top and bottom
	# so it does not depend on where a given rig keeps its origin.
	fbox.size = Vector3(width_m + aperture_m * 2.0, height_m + 1.0, reach_m * 2.0)
	var _oid: int = _field.create_shape_owner(_field)
	_field.shape_owner_add_shape(_oid, fbox)
	_field.shape_owner_set_transform(_oid, Transform3D(Basis.IDENTITY, Vector3(0.0, height_m * 0.5, 0.0)))
	add_child(_field)
	_field.body_entered.connect(_on_body_entered)
	_field.body_exited.connect(_on_body_exited)


## Resolved once at build so the hot loop never touches a string.
func _mode_index() -> int:
	if open_by == "slide_y":
		return MODE_SLIDE_Y
	if open_by == "slide_x":
		return MODE_SLIDE_X
	return MODE_SWING


func _physics_process(delta: float) -> void:
	if _slats.is_empty():
		return
	_sense(delta)

	# Frame-rate independent approach: the same fraction of the remaining distance
	# per second whatever the headset is managing. Nothing here allocates.
	var k: float = 1.0 - exp(-delta / maxf(ease_s, 0.01))
	var widest := 0.0
	for i in _slats.size():
		var target: float = _target_for(i)
		# The latch is taken on the way up only. A visitor who walks through the
		# plane flips the sign of their own z, and without this the slat would swing
		# back through the body it just made room for.
		if target > 0.02 and _open[i] <= 0.02:
			_latch(i)
		var o: float = lerpf(_open[i], target, k)
		if target <= 0.0 and o < 0.0008:
			o = 0.0                      # the closed state is a real rest, not an asymptote
		_open[i] = o
		_drive(i, o)
		if o > widest:
			widest = o
	_widest = widest
	if widest > _peak:
		_peak = widest

	if widest >= OPEN_EDGE:
		if not _is_open:
			_is_open = true
			_reported = widest
			opened.emit(widest)
		elif widest - _reported > 0.15:
			_reported = widest
			opened.emit(widest)
	elif _is_open:
		_is_open = false
		_reported = 0.0
		closed.emit()

	if not _sealed_said:
		if _covered:
			_near_s += delta
			if _near_s >= seal_report_s and _peak < 0.03:
				_sealed_said = true
				var why := ("a visitor stood in front of the wall for %.0f s and no slat"
					+ " opened past 3%% — check the wall's rotation (its plane is local XY,"
					+ " its face is local -Z) and aperture_m=%.2f") % [_near_s, aperture_m]
				push_warning("approach_wall: " + why)
				sealed.emit(why)
		else:
			_near_s = 0.0


## Positions, in the wall's own frame, of everybody who might open it.
##
## The transform is inverted once and reused, because to_local() inverts it again
## for every body it is asked about.
func _sense(delta: float) -> void:
	_resync -= delta
	if _resync <= 0.0:
		_resync = RESYNC_S
		_visitors.clear()
		if _field != null and is_instance_valid(_field):
			for b in _field.get_overlapping_bodies():
				if _is_visitor(b):
					_visitors.append(b)

	var inv := global_transform.affine_inverse()
	var half_x: float = width_m * 0.5 + aperture_m
	_vn = 0
	_covered = false
	for b in _visitors:
		if _vn >= MAX_VISITORS:
			break
		if not is_instance_valid(b):
			continue
		var p: Vector3 = inv * b.global_position
		_vx[_vn] = p.x
		_vz[_vn] = p.z
		_vn += 1
		# In front of the wall's own span, not merely somewhere in the room. A
		# person walking past the far end is not evidence of anything.
		if absf(p.z) < reach_m and absf(p.x) < half_x:
			_covered = true


## How far this slat should be out of the way, given where everybody is.
##
## Two visitors at one slat take the wider of their two claims rather than the sum:
## a hole is opened by a body, and two bodies do not make a body twice as wide.
func _target_for(i: int) -> float:
	var best := 0.0
	var cx: float = _cx[i]
	var ap: float = maxf(aperture_m, 0.001)
	var rc: float = maxf(reach_m, 0.001)
	for v in _vn:
		var t: float = absf(cx - _vx[v]) / ap
		if t >= 1.0:
			continue
		var d: float = absf(_vz[v]) / rc
		if d >= 1.0:
			continue
		var o: float = (1.0 - t) * (1.0 - d)
		o = o * o * (3.0 - 2.0 * o)      # soft edges, so the hole has a shoulder rather than a step
		if o > best:
			best = o
	return best


## Held from the moment a slat starts to move until it is shut again: which side of
## the plane the visitor came from, and which way along the wall they are.
func _latch(i: int) -> void:
	var best := INF
	var vx := 0.0
	var vz := 1.0
	for v in _vn:
		var dist: float = absf(_cx[i] - _vx[v]) + absf(_vz[v])
		if dist < best:
			best = dist
			vx = _vx[v]
			vz = _vz[v]
	_side[i] = 1.0 if vz >= 0.0 else -1.0
	_push[i] = 1.0 if _cx[i] >= vx else -1.0


## One scalar, spent three ways. The mesh and the shape are both children of the
## body being moved here, so whatever this does to one it has already done to the
## other — there is no second animation to fall out of step.
func _drive(i: int, o: float) -> void:
	var b: AnimatableBody3D = _slats[i]
	if b == null or not is_instance_valid(b):
		return
	var hinge := Vector3(_hx[i], 0.0, 0.0)
	if _mode == MODE_SLIDE_Y:
		b.position = hinge + Vector3(0.0, -o * height_m, 0.0)
		b.rotation = Vector3.ZERO
	elif _mode == MODE_SLIDE_X:
		b.position = hinge + Vector3(o * _slat_w * SLIDE_SPAN * _push[i], 0.0, 0.0)
		b.rotation = Vector3.ZERO
	else:
		# Turning about +Y carries a point at +x toward -z, so the sign of the arm
		# decides which way out of the plane the board goes. Multiplied by the
		# latched side, the wall always opens AWAY from the person, never across
		# them.
		var arm: float = 1.0 if _off[i] >= 0.0 else -1.0
		b.position = hinge
		b.rotation = Vector3(0.0, deg_to_rad(o * swing_deg * _side[i] * arm), 0.0)


## A body counts only if it walks. Everything static in a hall — floors, walls,
## podiums — is on layer 1 too, and so are this wall's own slats, so without this
## the field would report the building as a crowd and the wall would hang open.
##
## AND ONLY IF IT IS A VISITOR. `hazard_creature_base` extends CharacterBody3D, so
## accepting any CharacterBody3D hands the wall to the museum's own traffic: a
## silhouette drifting along the far side holds it open, and the visitor never
## meets a closed wall at all — which is the entire artifact. The desktop player is
## in `player_body`, the museum Walker in `em_walker`, and the VR XRToolsPlayerBody
## in no group whatever, so that one is recognised by the XROrigin3D above it.
## Shared verbatim with carve_grid and approach_scale.
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


func _on_body_entered(body: Node3D) -> void:
	if _is_visitor(body) and not _visitors.has(body):
		_visitors.append(body)


func _on_body_exited(body: Node3D) -> void:
	_visitors.erase(body)


## How far the wall is open at its widest point, 0 shut and 1 a slat entirely out
## of the plane.
func openness() -> float:
	return _widest


## Whether a body could actually get through, which is not the same question.
##
## A run of slats has to be open at once and it has to be wide enough for a pair of
## shoulders; a wall a little bit open everywhere is shut. The threshold differs by
## mode because the modes do not spend openness the same way: a swung slat at 0.75
## has turned 71 degrees and cleared two thirds of its width, while a sunk slat at
## 0.75 still has its top at thigh height and you would have to be a cat.
func is_passable() -> bool:
	if _slats.is_empty() or _slat_w <= 0.0:
		return false
	var need: int = maxi(1, int(ceil(pass_width_m / _slat_w)))
	var thr: float = 0.9 if _mode == MODE_SLIDE_Y else (0.7 if _mode == MODE_SLIDE_X else 0.75)
	var run := 0
	for i in _open.size():
		if _open[i] >= thr:
			run += 1
			if run >= need:
				return true
		else:
			run = 0
	return false


## For a probe: how many bodies the field is currently holding as visitors. Zero
## with nobody in the scene, which is the headless case and is not a fault.
func visitor_count() -> int:
	return _vn
