# @identity
# essence: costume(t) = composed_torso + 2 driven arms + 4 following limbs + what the walk has given
# desire: to be a body with more parts than expected, and to carry its history where it can be seen
# critical_parameter: stage -- the garment grows with the walk, and nothing it gains is ever taken back
# triggers: the headset and two controllers move it; a finished sequence grows it and pins a trophy
# emerges: a silhouette that is a record -- you can read how far someone has walked by looking at them
# needs: an XROrigin3D [found]; a torso [INFERRED, never tracked]; trophies [pinned by the wardrobe]
# relationships: wears PlayerCustomization's features; borrows head_crab's plant-and-settle for its limbs
# truth: the body is not given, it is composed -- and in three-point tracking that is not a metaphor.

extends Node3D
class_name QueerCostume

## THE COSTUME (2026-08-27, Palle: "can the VR player get a super queer costume
## that used inverse kinematics for moving part of the human queer body and
## attach beautiful thing to it as we go along the sequences" — then, of the two
## forks: trophies hung on a growing garment, and extra limbs beyond the arms).
##
## WHAT WAS ALREADY HERE, and why this is small. commons/player/
## PlayerCustomization.gd is a finished unlockable-feature system with colours
## and save/load; commons/body/ik_arms/ holds a real IK arm rig and a
## TorsoEstimator that composes a torso out of a headset and two controllers.
## Across the whole repository nothing ever called unlock_feature. The wardrobe
## was built and had no door. This adds the parts it did not have: limbs beyond
## the two you drive, a garment that grows, and slots to pin things to.
##
## THE EXTRA LIMBS REACH THE WAY THE SPIDER'S LEGS DO. They are not animated;
## they are SOLVED. Each is a chain of fixed-length segments run through FABRIK
## toward a target that trails the torso — and when the torso pulls the target
## too far, the limb re-plants and settles, which is head_crab's plant-and-step
## with the walking taken out. That is why they read as alive rather than as
## cloth: the lag is a physical consequence, not a curve somebody drew.

signal stage_changed(stage: int)
signal trophy_pinned(slot: String, what: String)

## The places a trophy can hang, measured DOWN FROM THE NECK — the torso's origin
## sits 0.15 m under the headset, so these are the proportions of a standing adult
## and not a guess. The first pass put the shoulder line 0.17 m below the eyes,
## which is the wearer's chin; in a headset that is a collar worn through the jaw.
const SLOTS := {
	"throat":   Vector3(0.00, -0.07, -0.08),
	"ear_left": Vector3(-0.11, 0.09, -0.01),
	"ear_right": Vector3(0.11, 0.09, -0.01),
	"shoulder_left": Vector3(-0.20, -0.13, 0.00),
	"shoulder_right": Vector3(0.20, -0.13, 0.00),
	"spine":    Vector3(0.00, -0.34, 0.07),
	"hip_left": Vector3(-0.15, -0.58, 0.00),
	"hip_right": Vector3(0.15, -0.58, 0.00),
}

@export_group("Extra limbs")
## Four beyond the two you drive. They hang off the shoulder line and the hips.
@export var limb_count: int = 4
@export var limb_segments: int = 4
@export var limb_length: float = 0.22       ## metres per segment
@export var limb_lag: float = 0.16          ## how slowly a target follows
@export var limb_reach: float = 0.30        ## how far it drifts before re-planting
## A LIMB THAT REACHES ITS MAXIMUM HAS NO KNEE LEFT. Measured on the first pass:
## walking three metres pulled every tip to 1.200 m of a 1.20 m reach — fully
## straight, four segments in a line, dragging behind the walker like a streamer.
## Every gate was green, because a straight chain still holds its segment lengths
## perfectly. So the target is held inside this fraction of the reach, which is
## the difference between a limb and a rope.
@export var limb_bend_keep: float = 0.82
## how hard the elbow is pushed toward the arc. 0 gives plain FABRIK, and plain
## FABRIK gives hairpins — see _solve.
@export var limb_pole: float = 0.35
@export var limb_settle: float = 3.2        ## how quickly a re-plant eases in
@export var limb_radius: float = 0.018

@export_group("Look")
@export var cloth: Color = Color(0.18, 0.06, 0.28)      ## deep violet
@export var edge: Color = Color(0.98, 0.44, 0.72)       ## the bright hem
@export var limb_base: Color = Color(0.10, 0.05, 0.16)
@export var limb_tip: Color = Color(0.86, 0.52, 0.95)
@export var joint_glow: float = 0.9

@export_group("Growth")
## 0 is a bare rig. Every finished sequence raises it by one and nothing lowers
## it: the garment is a record, and a record that can shrink is not one.
@export var stage: int = 0
@export var max_stage: int = 22

var _origin: Node3D = null
var _head: Node3D = null
var _hand_l: Node3D = null
var _hand_r: Node3D = null

var _torso: Node3D = null
var _limbs: Array = []          # each: {chain, target, home, planted, ease, draw}
var _garment: Node3D = null
var _slots: Dictionary = {}     # slot name -> Node3D
var _pins: Dictionary = {}      # slot name -> what is hanging there
var _built := false


func _ready() -> void:
	set_process(true)
	call_deferred("_build")


## Point it at the rig. Called by the wardrobe, or found on its own.
func attach_to(origin: Node3D) -> void:
	_origin = origin
	if _built:
		return
	_build()


func _find_rig() -> void:
	if _origin == null:
		var n: Node = self
		while n != null and not (n is XROrigin3D):
			n = n.get_parent()
		_origin = n as Node3D
	if _origin == null:
		var tree := get_tree()
		if tree != null:
			for c in tree.root.find_children("*", "XROrigin3D", true, false):
				_origin = c as Node3D
				break
	if _origin == null:
		return
	_head = _origin.get_node_or_null("XRCamera3D") as Node3D
	_hand_l = _origin.get_node_or_null("LeftHand") as Node3D
	_hand_r = _origin.get_node_or_null("RightHand") as Node3D


func _build() -> void:
	if _built:
		return
	_built = true
	_find_rig()

	_torso = Node3D.new()
	_torso.name = "ComposedTorso"
	add_child(_torso)

	for k in SLOTS.keys():
		var s := Node3D.new()
		s.name = "Slot_" + String(k)
		s.position = SLOTS[k]
		_torso.add_child(s)
		_slots[k] = s

	_harness()
	_garment = Node3D.new()
	_garment.name = "Garment"
	_torso.add_child(_garment)
	_dress(stage)

	for i in range(limb_count):
		_limbs.append(_make_limb(i))
	print("[costume] %d extra limb(s), %d slot(s), stage %d" % [_limbs.size(), _slots.size(), stage])


# ── the torso, composed ─────────────────────────────────────────────────────

## THE TORSO IS NEVER TRACKED. Three-point VR gives a head and two hands and
## nothing between them, so the chest is INFERRED: placed under the head, and
## turned to face the average of where the hands are, which is what a body
## actually does. commons/body/ik_arms/torso_estimator.gd says the same thing at
## more length; this keeps the costume standing when that node is not present.
func _compose_torso(delta: float) -> void:
	if _head == null or not is_instance_valid(_head):
		return
	var neck: Vector3 = _head.global_position + Vector3(0, -0.15, 0)
	_torso.global_position = _torso.global_position.lerp(neck, 1.0 - exp(-12.0 * delta))
	var face: Vector3 = -_head.global_transform.basis.z
	if _hand_l != null and _hand_r != null and is_instance_valid(_hand_l) and is_instance_valid(_hand_r):
		# the shoulder line is across the hands; the chest faces its normal, so
		# reaching across the body turns the torso the way a torso turns
		var across: Vector3 = _hand_r.global_position - _hand_l.global_position
		across.y = 0.0
		if across.length() > 0.15:
			var from_hands := Vector3(across.z, 0.0, -across.x).normalized()
			face = (face * 0.65 + from_hands * 0.35).normalized()
	face.y = 0.0
	if face.length() > 0.01:
		var want: float = atan2(-face.x, -face.z)
		_torso.rotation.y = lerp_angle(_torso.rotation.y, want, 1.0 - exp(-8.0 * delta))


# ── the extra limbs ─────────────────────────────────────────────────────────

func _make_limb(i: int) -> Dictionary:
	# two off the shoulders, two off the hips, alternating sides
	var side: float = -1.0 if (i % 2) == 0 else 1.0
	var high: bool = i < 2
	var root := Vector3(0.20 * side, (-0.13 if high else -0.56), 0.06)

	var holder := Node3D.new()
	holder.name = "Limb_%d" % i
	holder.position = root
	_torso.add_child(holder)

	var chain: Array = []
	for s in range(limb_segments + 1):
		chain.append(Vector3(0, -limb_length * float(s), 0))

	var draw: Array = []
	for s in range(limb_segments):
		var seg := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var t: float = float(s) / float(maxi(1, limb_segments - 1))
		cm.top_radius = limb_radius * (1.0 - t * 0.62)
		cm.bottom_radius = limb_radius * (1.0 - t * 0.45)
		cm.height = 1.0
		cm.radial_segments = 8
		seg.mesh = cm
		seg.material_override = _mat(limb_base.lerp(limb_tip, t), 0.35, 0.25, joint_glow * t)
		holder.add_child(seg)
		var hub := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = limb_radius * 1.7 * (1.0 - t * 0.5)
		sm.height = sm.radius * 2.0
		sm.radial_segments = 10
		sm.rings = 6
		hub.mesh = sm
		hub.material_override = _mat(limb_tip, 0.22, 0.6, joint_glow)
		holder.add_child(hub)
		draw.append({"seg": seg, "hub": hub})

	return {
		"holder": holder, "chain": chain, "draw": draw,
		# up and OUT on its own side — all four sharing one pole makes four limbs
		# that arc identically, which reads as a machine rather than a body
		"pole": Vector3(side * 0.40, 1.0, -0.15).normalized(),
		"target": Vector3.ZERO, "planted": Vector3.ZERO,
		"ease": 1.0, "primed": false, "steps": 0,
	}


## FABRIK, over an array of points. Backward from the tip to the target, then
## forward from the root, holding every segment at its own length — the same rule
## the corpus's `line` obeys: a shaft whose height IS the distance between two
## points.
##
## THE POLE IS NOT A DETAIL. Plain FABRIK has no preferred plane, so a chain that
## can reach its target a hundred ways picks whichever one it drifted into — and
## the first render of this costume came back with two limbs folded into hairpins
## standing straight up past the wearer's head. Every gate was green: the tips
## were on target, the segments were exact, the plants were counted. A solver
## with no opinion about its elbow will find one for you, and you will not like
## it. So the forward pass leans each interior joint toward `pole`, which is up
## and outward from the body — the arachnid arc, chosen deliberately.
func _solve(chain: Array, root: Vector3, target: Vector3, pole: Vector3 = Vector3.ZERO) -> void:
	var n: int = chain.size()
	if n < 2:
		return
	var reach: float = limb_length * float(n - 1)
	var to: Vector3 = target - root
	if to.length() > reach:
		# further than it can reach: straighten toward it and stop
		var dir: Vector3 = to.normalized()
		for i in range(n):
			chain[i] = root + dir * (limb_length * float(i))
		return
	var bias: float = clampf(limb_pole, 0.0, 1.0)
	for pass_i in range(4):
		chain[n - 1] = target
		for i in range(n - 2, -1, -1):
			var d: Vector3 = (chain[i] as Vector3) - (chain[i + 1] as Vector3)
			if d.length() < 0.0001: d = Vector3.DOWN
			chain[i] = (chain[i + 1] as Vector3) + d.normalized() * limb_length
		chain[0] = root
		for i in range(1, n):
			var d2: Vector3 = (chain[i] as Vector3) - (chain[i - 1] as Vector3)
			if d2.length() < 0.0001: d2 = Vector3.DOWN
			d2 = d2.normalized()
			# the interior joints lean toward the pole; the tip never does, or it
			# would be pulled off the target it exists to reach
			if i < n - 1 and bias > 0.0 and pole.length() > 0.001:
				var w: float = bias * (1.0 - float(i - 1) / float(maxi(1, n - 2)))
				d2 = (d2 + pole.normalized() * w).normalized()
			chain[i] = (chain[i - 1] as Vector3) + d2 * limb_length


## EVERY POSITION HERE IS WORLD-SPACE, and that is the whole point. A limb whose
## target lives in the torso's own frame rides along rigidly with the body and
## reads as a stick taped to a coat. The tip has to be a fact about the ROOM:
## it stays where it is while the wearer walks away from it, and only then does
## it let go and re-plant. That is head_crab's foot, and it is why these read as
## limbs rather than as decoration.
func _drive_limbs(delta: float) -> void:
	for i in range(_limbs.size()):
		var L: Dictionary = _limbs[i]
		var holder: Node3D = L["holder"]
		var root: Vector3 = holder.global_position

		# where it WANTS to trail: below and behind its own root, expressed in the
		# torso's frame but immediately taken into the world, so the resting place
		# swings when the body turns and holds still when it does not
		var rest: Vector3 = holder.global_transform * Vector3(
			0.0, -limb_length * float(limb_segments) * 0.62, 0.34)
		if not bool(L["primed"]):
			L["planted"] = rest
			L["target"] = rest
			for s in range(L["chain"].size()):
				(L["chain"] as Array)[s] = root + Vector3.DOWN * (limb_length * float(s))
			L["primed"] = true
			L["steps"] = 0

		# IT PLANTS AND SETTLES, which is head_crab's gait with the walking taken
		# out: the tip holds its place in the room until the body has dragged the
		# rest-point too far, then it re-reaches ONCE and eases in, instead of
		# sliding the whole way like something being pulled.
		var planted: Vector3 = L["planted"]
		if planted.distance_to(rest) > limb_reach:
			L["planted"] = rest
			L["ease"] = 0.0
			L["steps"] = int(L["steps"]) + 1
		var ease: float = minf(1.0, float(L["ease"]) + delta * limb_settle)
		L["ease"] = ease
		var smooth: float = ease * ease * (3.0 - 2.0 * ease)
		var want: Vector3 = (L["target"] as Vector3).lerp(L["planted"] as Vector3, smooth)
		var tgt: Vector3 = (L["target"] as Vector3).lerp(want, 1.0 - exp(-delta / maxf(0.01, limb_lag)))
		# hold it inside the reach so the chain keeps a bend
		var span: Vector3 = tgt - root
		var keep: float = limb_length * float(limb_segments) * clampf(limb_bend_keep, 0.1, 0.99)
		if span.length() > keep:
			tgt = root + span.normalized() * keep
		L["target"] = tgt

		# taken into the world each frame, so the arc survives the body turning
		var pole: Vector3 = (holder.global_transform.basis * (L["pole"] as Vector3)).normalized()
		var chain: Array = L["chain"]
		_solve(chain, root, L["target"], pole)
		_draw(L, holder)
		_limbs[i] = L


## The chain is solved in the room and drawn on the body, so every point comes
## back through to_local — the one conversion that has to happen exactly once.
func _draw(L: Dictionary, holder: Node3D) -> void:
	var chain: Array = L["chain"]
	var draw: Array = L["draw"]
	for s in range(draw.size()):
		var a: Vector3 = holder.to_local(chain[s])
		var b: Vector3 = holder.to_local(chain[s + 1])
		var d: Dictionary = draw[s]
		var seg: MeshInstance3D = d["seg"]
		var hub: MeshInstance3D = d["hub"]
		var mid: Vector3 = (a + b) * 0.5
		var v: Vector3 = b - a
		var h: float = v.length()
		if h < 0.0001:
			continue
		seg.position = mid
		var axis: Vector3 = v / h
		var dot: float = Vector3.UP.dot(axis)
		var rot: Basis = Basis()
		if dot > 0.9999:
			rot = Basis()
		elif dot < -0.9999:
			rot = Basis(Vector3.RIGHT, PI)
		else:
			rot = Basis(Vector3.UP.cross(axis).normalized(), acos(clampf(dot, -1.0, 1.0)))
		# BASIS CARRIES SCALE, SO IT MUST BE WRITTEN LAST AND CARRY IT. Setting
		# `scale` and then `basis` silently discards the scale — which drew every
		# segment at the cylinder's authored 1.0 m instead of its real 0.22 m, and
		# turned four limbs into sixteen metre-long rods crossing the body. The
		# probe never saw it: the CHAIN was right to five decimals, and only the
		# drawing was wrong. That is the whole argument for looking at the picture.
		seg.basis = rot * Basis.from_scale(Vector3(1.0, h, 1.0))
		hub.position = a


# ── the garment, which only ever grows ──────────────────────────────────────

## Raise the stage. Never lowers: a garment that can shrink is not a record.
func grow(to_stage: int = -1) -> void:
	var want: int = (stage + 1) if to_stage < 0 else to_stage
	want = clampi(want, stage, max_stage)
	if want == stage:
		return
	stage = want
	_dress(stage)
	emit_signal("stage_changed", stage)


## A SHIFT THAT LENGTHENS AND FILLS, INSIDE A BOUNDED BODY. The first version
## added a fixed 0.11 m tier per stage and let the total run: at the end of the
## walk that is a 2.2 m cone half a metre wide, standing through the floor with
## the wearer inside it. It measured perfectly — twenty-two stages, twenty-two
## tiers — and the photograph showed a lampshade. So the hem descends toward a
## LIMIT and the tiers divide whatever length it has reached: more sequences
## make the garment longer, fuller and finer, never taller than a person.
func _dress(n: int) -> void:
	if _garment == null:
		return
	for c in _garment.get_children():
		c.queue_free()
	if n <= 0:
		return
	var tiers: int = mini(n, max_stage)
	var far: float = float(tiers) / float(maxi(1, max_stage))     # 0 at the start, 1 walked
	var waist: float = -0.42
	var hem: float = lerp(-0.58, -1.15, far)                       # knee-length by the end
	var span: float = waist - hem
	var h: float = span / float(tiers)
	for i in range(tiers):
		var t: float = float(i) / float(maxi(1, tiers - 1)) if tiers > 1 else 1.0
		var ring := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.145 + t * (0.045 + 0.10 * far)
		cm.bottom_radius = 0.150 + (t + 1.0 / float(tiers)) * (0.055 + 0.14 * far)
		cm.height = h * 1.06                                       # a little overlap, no gaps
		cm.radial_segments = 24
		cm.rings = 1
		# NO CAPS. Godot caps a CylinderMesh by default, so twenty-two tiers are
		# twenty-two closed buckets — which is why the first photograph showed a
		# lid across the waist and read as a lampshade rather than as cloth.
		cm.cap_top = false
		cm.cap_bottom = false
		ring.mesh = cm
		# the hem is the bright edge; the body of it stays deep
		var rm: StandardMaterial3D = _mat(cloth.lerp(edge, t * 0.6), 0.55, 0.05,
			0.0 if i < tiers - 1 else 0.7)
		rm.cull_mode = BaseMaterial3D.CULL_DISABLED    # the wearer sees the inside
		ring.material_override = rm
		ring.position = Vector3(0, waist - h * (float(i) + 0.5), 0)
		_garment.add_child(ring)


## SOMETHING FOR THE TROPHIES TO SIT ON. Without it the slots hang in empty air
## beside a floating skirt, which is what the first photograph showed: a
## lampshade with confetti around it. A yoke across the shoulders, a line down
## the spine and a band at the waist is the least that reads as worn.
func _harness() -> void:
	var yoke := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.155
	tm.outer_radius = 0.190
	tm.rings = 28
	tm.ring_segments = 8
	yoke.mesh = tm
	yoke.material_override = _mat(cloth.lerp(edge, 0.25), 0.42, 0.55, 0.25)
	yoke.position = Vector3(0, -0.13, 0.0)
	yoke.scale = Vector3(1.0, 1.0, 0.72)                 # a body is not a circle
	_torso.add_child(yoke)

	var band := MeshInstance3D.new()
	var bm := TorusMesh.new()
	bm.inner_radius = 0.125
	bm.outer_radius = 0.150
	bm.rings = 24
	bm.ring_segments = 8
	band.mesh = bm
	band.material_override = _mat(edge, 0.35, 0.6, 0.55)
	band.position = Vector3(0, -0.42, 0.0)
	band.scale = Vector3(1.0, 1.0, 0.74)
	_torso.add_child(band)

	for side in [-1.0, 1.0]:
		var strap := MeshInstance3D.new()
		var cm2 := CylinderMesh.new()
		cm2.top_radius = 0.011
		cm2.bottom_radius = 0.013
		cm2.height = 0.24
		cm2.radial_segments = 8
		strap.mesh = cm2
		strap.material_override = _mat(cloth.lerp(edge, 0.35), 0.5, 0.3, 0.2)
		strap.position = Vector3(0.095 * side, -0.28, 0.050)
		strap.rotation_degrees = Vector3(9, 0, 5.0 * side)
		_torso.add_child(strap)

	# a bodice between the two, open at both ends so the wearer is not inside a
	# closed tube looking at a lid
	var chest := MeshInstance3D.new()
	var chm := CylinderMesh.new()
	chm.top_radius = 0.150
	chm.bottom_radius = 0.128
	chm.height = 0.30
	chm.radial_segments = 24
	chm.cap_top = false
	chm.cap_bottom = false
	chest.mesh = chm
	chest.material_override = _mat(cloth, 0.6, 0.1, 0.0)
	chest.position = Vector3(0, -0.27, 0.0)
	chest.scale = Vector3(1.0, 1.0, 0.76)
	_torso.add_child(chest)


# ── trophies ────────────────────────────────────────────────────────────────

## Hang something in a named slot. A slot ACCUMULATES — twenty-two sequences
## against eight slots means the third thing on a shoulder must sit beside the
## first two, not replace them. Each new one takes the next place on a small
## orbit, which is how jewellery actually collects on a body.
func pin(what: Node3D, slot: String) -> bool:
	if what == null or not _slots.has(slot):
		push_warning("costume: no slot named '%s'" % slot)
		return false
	var s: Node3D = _slots[slot]
	var here: Array = _pins.get(slot, [])
	var n: int = here.size()
	s.add_child(what)
	# first one on the spot, the rest on a widening ring around it
	if n == 0:
		what.position = Vector3.ZERO
	else:
		var a: float = float(n) * 2.399963            # the golden angle, so nothing lines up
		var r: float = 0.028 + 0.014 * floorf(float(n - 1) / 5.0)
		what.position = Vector3(cos(a) * r, sin(a) * r * 0.7, -0.012 * float(n % 3))
	here.append(what)
	_pins[slot] = here
	emit_signal("trophy_pinned", slot, what.name)
	return true


func pinned_count() -> int:
	var n := 0
	for k in _pins.keys():
		for w in (_pins[k] as Array):
			if is_instance_valid(w): n += 1
	return n


func pinned_in(slot: String) -> int:
	return (_pins.get(slot, []) as Array).size()


func slot_names() -> Array:
	return SLOTS.keys()


## how many times each extra limb has let go and re-planted — the probe's
## evidence that they are solved rather than carried
func limb_steps() -> Array:
	var out: Array = []
	for L in _limbs:
		out.append(int((L as Dictionary)["steps"]))
	return out


## where limb i's tip is standing, in the room — NOT named limb_tip, which is
## already the colour export; GDScript keeps functions and variables in one
## namespace, so that collision is a parse error rather than a shadowing warning.
func tip_of(i: int) -> Vector3:
	if i < 0 or i >= _limbs.size():
		return Vector3.ZERO
	var chain: Array = (_limbs[i] as Dictionary)["chain"]
	return chain[chain.size() - 1]


## limb i's whole chain, in the room — the probe's way of checking the one
## invariant FABRIK exists to keep: every segment stays its own length.
func chain_of(i: int) -> Array:
	if i < 0 or i >= _limbs.size():
		return []
	return ((_limbs[i] as Dictionary)["chain"] as Array).duplicate()


## THE WORST DISAGREEMENT BETWEEN THE SOLVED CHAIN AND THE DRAWN ONE. This
## exists because the probe was green while the picture was wrong: the chain was
## exact to five decimals and every segment still RENDERED at a full metre,
## because assigning `basis` after `scale` throws the scale away. A probe that
## only reads the model cannot see a fault in the view, so this reads the view.
func drawn_error() -> float:
	var worst := 0.0
	for L in _limbs:
		var d: Dictionary = L
		var chain: Array = d["chain"]
		var draw: Array = d["draw"]
		for s in range(draw.size()):
			var seg: MeshInstance3D = (draw[s] as Dictionary)["seg"]
			var cm: CylinderMesh = seg.mesh as CylinderMesh
			if cm == null:
				continue
			var drawn: float = seg.global_transform.basis.get_scale().y * cm.height
			var want: float = (chain[s] as Vector3).distance_to(chain[s + 1])
			worst = maxf(worst, absf(drawn - want))
	return worst


func limb_root(i: int) -> Vector3:
	if i < 0 or i >= _limbs.size():
		return Vector3.ZERO
	return ((_limbs[i] as Dictionary)["holder"] as Node3D).global_position


func garment_tiers() -> int:
	return _garment.get_child_count() if _garment != null else 0


func _mat(c: Color, rough: float, metal: float, glow: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m


func _process(delta: float) -> void:
	if not _built:
		return
	_compose_torso(delta)
	_drive_limbs(delta)
