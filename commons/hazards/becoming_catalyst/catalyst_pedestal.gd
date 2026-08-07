# @identity
# essence: wireframe_cube(1m) -> display_case(catalyst) -- a glowing cage that presents the crystal
# desire: to be noticed, approached, and opened — the first thing the player reaches for
# critical_parameter: cage_color / crystal_hover_height -- the wireframe must say "pick me up"
# triggers: player enters lab; catalyst not yet absorbed; visual beacon draws the eye
# emerges: the moment before transformation — the tool exists, waiting to be claimed
# needs: BecomingCatalyst scene [spawns]; wireframe rendering [has]; slow rotation [has]
# relationships: contains becoming_catalyst; inspired by cube_lines aesthetic; lives in lab spawn area
# truth: the cage doesn't protect the crystal — it frames the invitation.

# CatalystPedestal.gd
# A one-meter wireframe cube display case with the Becoming Catalyst floating
# inside. Place this in lab maps instead of a raw becoming_catalyst. The player
# walks up, sees the glowing crystal rotating inside the wireframe cage, and
# grabs it — at which point the crystal absorbs into their hand and the cage
# fades away.
#
# Visual: 12 glowing cyan edges (like cube_lines) + catalyst crystal hovering
# at center + gentle bob + slow rotation + point light.
#
# ── WHAT THE EDGE IS MADE OF (finish pass, 2026-08-07) ───────────────────────
# The wireframe used to be twelve unshaded cylinders: one flat cyan, one alpha,
# one roughness value that nothing ever read. SHADING_MODE_UNSHADED writes
# ALBEDO and drops EMISSION on the floor, so the "glow" was never a glow — it
# was a flat decal of a cage, and the emission_energy_multiplier the fade
# animates was animating nothing. That is the flat-plastic tell in its purest
# form, and it is now gone.
#
# The cage is a built object with two materials and a story about how it was
# made, and both of them are the same at every value of the offer axis:
#
#   · the EDGES are side-emitting acrylic light guide. A dielectric — metallic
#     0, because a light pipe is not metal — with a clear coat for the extruded
#     skin, a micro-grain roughness map so the highlight running the length of a
#     rod is a broken field instead of one mirror line, a Fresnel rim so a 12 mm
#     rod still separates from a dark room, and the shipped cyan on EMISSION
#     actually reaching the frame for the first time — retuned to 1.35, because
#     the shipped 2.0 was only ever a number in a field nothing sampled, and it
#     clips the blue channel to white the moment it is real. See EDGE_EMISSION.
#
#   · the JOINTS are machined aluminium ferrules. Real metal: metallic 1.0, a
#     measured albedo, its own tighter grain and a touch of anisotropy. One
#     ferrule sits at every unique edge endpoint, which is also why the rods no
#     longer need end caps — the ferrule covers the open tube. Twelve sticks
#     that happened to touch became one welded frame, and the corners of the
#     cube stopped being the place where the geometry admits it is fake.
#
# Two more surfaces belong to one value each, and only because that value asked
# for them: the vitrine is glazed for real (see _glaze_vitrine) and the shrine
# has a lamp (see _light_shrine). The docstring below used to claim this artifact
# owned exactly one material language. It owns three now, and says so.
#
# Everything is procedural, built in _ready(), and cheap enough for a Quest:
# no _process shader work, no reflection probes, no imported textures. The one
# extra light in the file is the shrine's, and it casts no shadow.

extends Node3D
class_name CatalystPedestal

const MK = preload("res://commons/render/mesh_kit.gd")
const PK = preload("res://commons/render/pbr_kit.gd")

const CAGE_SIZE := 1.0          # 1 meter cube
const EDGE_THICKNESS := 0.006   # Thin wireframe lines
const CAGE_COLOR := Color(0.3, 0.65, 1.0, 0.8)  # Cyan like cube_lines
const CRYSTAL_BOB_SPEED := 1.2  # Gentle vertical bob
const CRYSTAL_BOB_AMOUNT := 0.04
const CRYSTAL_SPIN_SPEED := 0.4  # Slow Y rotation (rad/s)
const CAGE_FADE_TIME := 1.5     # Seconds to fade cage after pickup

# ── Finish constants ─────────────────────────────────────────────────────────
# EDGE_SEGMENTS 8 with open ends is 16 triangles a rod, two-thirds of what the
# shipped 6-sided capped CylinderMesh cost, so the ferrules are paid for before
# they are built. A 12 mm rod does not need 24 sides; it needs smooth normals
# and a roughness map, and it now has both.
const EDGE_SEGMENTS := 8
## The one shipped number this pass changed, and only because it was fiction.
## SHADING_MODE_UNSHADED never read EMISSION, so the shipped 2.0 lit nothing; the
## fade animated it from 2.0 to 0 in front of an audience of no one. Now that the
## rod is shaded, 2.0 puts the blue channel at 2.0 and FILMIC clips it to white —
## a white line where a cyan one was, which is the rubric's colour-discipline
## failure and the loss of the artifact's own hue. 1.35 sits just past the
## tonemap knee: bright enough to bloom in any rig that has glow, low enough that
## red/green/blue land near 0.40 / 0.72 / 0.88 and the cage is still CYAN.
const EDGE_EMISSION := 1.35
## Triplanar noise is authored in LOCAL space at ~5 tiles/metre, which across a
## 12 mm rod is a quarter of one tile — i.e. flat colour, the trap PbrKit's rule 1
## warns about. 5x lands the grain at ~4 cm along the rod and just under one tile
## around its circumference, so the highlight breaks both ways.
const EDGE_DETAIL_SCALE := 5.0

const FERRULE_RADIUS := EDGE_THICKNESS * 1.55   # 3.3 mm proud of the rod
const FERRULE_SEGMENTS := 8
const FERRULE_RINGS := 3
const FERRULE_DETAIL_SCALE := 9.0               # ~1 / 0.018 m, PbrKit rule 1

const GLASS_THICKNESS := 0.006
const GLASS_OPACITY := 0.14
const GLASS_GAP := 0.0015       # clearance from the mullions — no z-fighting

const CONTACT_STRENGTH := 0.42
const SHRINE_LIGHT_COLOR := Color(1.0, 0.88, 0.68)
const SHRINE_LIGHT_ENERGY := 2.4

# ── DNA ──────────────────────────────────────────────────────────────────────
## AXIS — ON WHAT TERMS THE CRYSTAL IS OFFERED. The word is [[catalyst_pickup]]'s,
## adopted because the question is identical — this pedestal IS the offer side of
## the catalyst system, and the thing a still can hold about it is the institution
## standing around the reward. The values overlap where this artifact's body can
## build them: catalyst_pickup stages its offers in painted metal and glass, this
## pedestal draws every institution in EDGES, through the same _build_edge()
## pipeline, and therefore fades on pickup, hides on lease, returns on
## re-materialize and answers #cage_color: exactly as the shipped cage does.
## `chute` (vended) is the one catalyst_pickup value honestly refused: a dispenser
## cabinet with a dark delivery slot cannot be said in open wireframe, and a wire
## hopper would be a menu entry, not an argument.
##
##   cage     the shipped presentation — a 1 m wireframe cube, the display case
##            whose truth line is "the cage doesn't protect the crystal — it
##            frames the invitation".
##   plinth   the bare offer — no case at all. A low open wireframe dais under the
##            crystal and nothing between you and it; catalyst_pickup's own reading:
##            take it.
##   vitrine  the case glazed shut — every face of the cube gains glazing bars (a
##            vertical and a horizontal mullion per side, a cross over the top),
##            and behind the bars, real glass: an exhibit at the last moment.
##   clamp    held by the machine — the cube is gone; four edges rise from the base
##            square and pinch to an apex above the crystal, a single finger
##            reaching down at it. Not offered: GRIPPED.
##   shrine   venerated — the cube keeps its shape and gains two stepped ground
##            squares at its foot and a four-hip wireframe roof with a finial,
##            and one warm lamp hung from that finial. Approach, don't grab.
##
## The offer decides GEOMETRY, and nothing else. Two values now also carry one
## surface each — the vitrine its panes, the shrine its lamp — because glazing
## bars with no glass and a roof with no light are both a drawing of an argument
## rather than the argument. Neither moved a single edge.
##
## Appearance only (R5): nothing here touches the crystal spawn, the pickup signal,
## the sequence binding, the lease clock or the forwarded config keys.
@export_enum("cage", "plinth", "vitrine", "clamp", "shrine") var offer: String = "cage"
const OFFERS: PackedStringArray = ["cage", "plinth", "vitrine", "clamp", "shrine"]

var _cage: Node3D = null
var _crystal: Node3D = null       # The BecomingCatalyst instance
var _cage_light: OmniLight3D = null
var _cage_edges: Array[MeshInstance3D] = []
var _edge_materials: Array[StandardMaterial3D] = []
var _crystal_base_y: float = 0.0
var _fading: bool = false
var _fade_progress: float = 0.0

# The finish pass's own state. All of it is rebuilt by _build_cage and cleared by
# _rebuild_cage, and all of it is null/empty on CatalystPrompterBox, which extends
# this script and never builds a cage at all.
var _rod_mat: StandardMaterial3D = null       # shared by every edge
var _trim_mat: StandardMaterial3D = null      # shared by every ferrule
var _trim_base: Color = Color(1.0, 1.0, 1.0, 1.0)
var _trim_materials: Array[StandardMaterial3D] = []
var _glass_materials: Array[StandardMaterial3D] = []
var _joints: Array[Vector3] = []
var _joint_seen: Dictionary = {}
var _ground_decal: Decal = null
var _ground_mix_rest: float = 0.0
var _offer_light: SpotLight3D = null
var _offer_energy_rest: float = 0.0
# Rest values, snapshotted so the fade knows what each surface came from.
var _fade_mats: Array[StandardMaterial3D] = []
var _fade_a0: PackedFloat32Array = PackedFloat32Array()
var _fade_e0: PackedFloat32Array = PackedFloat32Array()

# Timed lease — when lease_s > 0 the pedestal survives the pickup: the
# cage fades and hides instead of queue_free, and re-materializes with a
# fresh crystal once the lease (plus a grace beat) has run out. The
# crystal's dissolve is driven by CatalystCapabilityManager's clock; this
# countdown is the pedestal's own, started at pickup, so the return works
# even though the crystal may dissolve in a different map.
const RETURN_GRACE := 1.5       # seconds after lease end before the cage returns
var _lease_s: float = 0.0
var _leased_out: bool = false
var _return_left: float = 0.0
var _last_crystal_cfg: Dictionary = {}   # re-applied to the respawned crystal

signal catalyst_taken()
signal catalyst_returned()

func _ready() -> void:
	_build_cage()
	_build_light()
	_spawn_crystal()

func _process(delta: float) -> void:
	# Crystal hover and spin
	if is_instance_valid(_crystal) and not _fading:
		var bob := sin(Time.get_ticks_msec() / 1000.0 * CRYSTAL_BOB_SPEED) * CRYSTAL_BOB_AMOUNT
		_crystal.position.y = _crystal_base_y + bob
		_crystal.rotation.y += CRYSTAL_SPIN_SPEED * delta

	# Light pulse
	if _cage_light and not _fading:
		var pulse := 1.5 + sin(Time.get_ticks_msec() / 800.0) * 0.4
		_cage_light.light_energy = pulse

	# Cage fade after crystal is taken
	if _fading:
		_fade_progress += delta / CAGE_FADE_TIME
		if _fade_progress >= 1.0:
			if _lease_s > 0.0:
				# Leased crystal: the pedestal stays, hidden, awaiting return.
				_fading = false
				_leased_out = true
				if _cage:
					_cage.visible = false
				if _cage_light:
					_cage_light.visible = false
			else:
				queue_free()
			return
		var alpha: float = 1.0 - _fade_progress
		_apply_fade(alpha)
		if _cage_light:
			_cage_light.light_energy = alpha * 1.5

	# Timed-lease return countdown (ticks through fade + hidden states).
	if _return_left > 0.0:
		_return_left -= delta
		if _return_left <= 0.0:
			_rematerialize()


# ═══════════════════════════════════════════════════════════════════════════
# CAGE — 12 wireframe edges of a 1m cube
# ═══════════════════════════════════════════════════════════════════════════

func _build_cage() -> void:
	_cage = Node3D.new()
	_cage.name = "Cage"
	add_child(_cage)

	_joints.clear()
	_joint_seen.clear()
	_rod_mat = _make_rod_material()
	_edge_materials.append(_rod_mat)

	var half := CAGE_SIZE * 0.5

	# plinth and clamp REPLACE the cube; cage, vitrine and shrine all start from
	# the shipped cube, built in exactly the legacy order so offer=cage keeps
	# every edge index and name byte for byte.
	match offer:
		"plinth":
			_edges_plinth(half)
		"clamp":
			_edges_clamp(half)
		_:
			# 8 vertices of the cube, centered at origin, base at y=0
			var v := [
				Vector3(-half, 0.0,  -half),  # 0: bottom-back-left
				Vector3( half, 0.0,  -half),  # 1: bottom-back-right
				Vector3( half, 0.0,   half),  # 2: bottom-front-right
				Vector3(-half, 0.0,   half),  # 3: bottom-front-left
				Vector3(-half, CAGE_SIZE, -half),  # 4: top-back-left
				Vector3( half, CAGE_SIZE, -half),  # 5: top-back-right
				Vector3( half, CAGE_SIZE,  half),  # 6: top-front-right
				Vector3(-half, CAGE_SIZE,  half),  # 7: top-front-left
			]

			# 12 edges
			var edges := [
				[v[0], v[1]], [v[1], v[2]], [v[2], v[3]], [v[3], v[0]],  # bottom
				[v[4], v[5]], [v[5], v[6]], [v[6], v[7]], [v[7], v[4]],  # top
				[v[0], v[4]], [v[1], v[5]], [v[2], v[6]], [v[3], v[7]],  # verticals
			]

			for i in edges.size():
				var edge: Array = edges[i]
				var start: Vector3 = edge[0]
				var end_pos: Vector3 = edge[1]
				_build_edge(start, end_pos, i)

	# OFFER dressing, appended AFTER the cube so offer=cage adds nothing at all;
	# plinth and clamp already said everything above.
	match offer:
		"vitrine":
			_edges_vitrine(half)
		"shrine":
			_edges_shrine(half)
		_:
			pass

	# FINISH, in this order and after every edge exists: the ferrules need the
	# full joint list, the contact pool needs the footprint the joints imply, and
	# the fade snapshot needs every material that ended up in the frame.
	_build_joints()
	_glaze_or_light(half)
	_build_contact_shadow()
	_snapshot_rest()


## PLINTH — the bare offer. A low open wireframe dais (two squares and four
## stubs) under the crystal, and nothing between you and it.
func _edges_plinth(half: float) -> void:
	var r: float = half * 0.84
	var h: float = 0.14
	var b := [
		Vector3(-r, 0.0, -r), Vector3(r, 0.0, -r),
		Vector3(r, 0.0, r), Vector3(-r, 0.0, r),
	]
	var t := [
		Vector3(-r, h, -r), Vector3(r, h, -r),
		Vector3(r, h, r), Vector3(-r, h, r),
	]
	var idx: int = 0
	for i in range(4):
		_build_edge(b[i], b[(i + 1) % 4], idx)
		idx += 1
	for i in range(4):
		_build_edge(t[i], t[(i + 1) % 4], idx)
		idx += 1
	for i in range(4):
		_build_edge(b[i], t[i], idx)
		idx += 1


## CLAMP — held by the machine. Four edges rise off the base square and pinch to
## an apex above the crystal, and a single finger reaches down at it. The claw
## silhouette against the cube is the whole argument: not offered, gripped.
func _edges_clamp(half: float) -> void:
	var apex := Vector3(0.0, CAGE_SIZE * 1.32, 0.0)
	var b := [
		Vector3(-half, 0.0, -half), Vector3(half, 0.0, -half),
		Vector3(half, 0.0, half), Vector3(-half, 0.0, half),
	]
	var idx: int = 0
	for i in range(4):
		_build_edge(b[i], b[(i + 1) % 4], idx)
		idx += 1
	for i in range(4):
		_build_edge(b[i], apex, idx)
		idx += 1
	# the finger: from the pinch point down toward the crystal, stopping short
	_build_edge(apex, Vector3(0.0, 0.92, 0.0), idx)


## VITRINE — the case glazed shut. Each side face gains a vertical and a
## horizontal glazing bar, the top face a cross: the same cube read as panes.
func _edges_vitrine(half: float) -> void:
	var idx: int = 12
	for face in range(4):
		var ang: float = TAU * float(face) / 4.0
		var n := Vector3(cos(ang), 0.0, sin(ang))
		var t := Vector3(-sin(ang), 0.0, cos(ang))
		var c: Vector3 = n * half
		var mid_y := Vector3(0.0, CAGE_SIZE * 0.5, 0.0)
		_build_edge(c + t * -half + mid_y, c + t * half + mid_y, idx)
		idx += 1
		_build_edge(c, c + Vector3(0.0, CAGE_SIZE, 0.0), idx)
		idx += 1
	_build_edge(Vector3(-half, CAGE_SIZE, 0.0), Vector3(half, CAGE_SIZE, 0.0), idx)
	idx += 1
	_build_edge(Vector3(0.0, CAGE_SIZE, -half), Vector3(0.0, CAGE_SIZE, half), idx)


## SHRINE — venerated. Two stepped ground squares widen the foot, four hips rise
## to an apex over the cube and a finial tops it: approach, don't grab.
func _edges_shrine(half: float) -> void:
	var idx: int = 12
	for r in [half * 1.24, half * 1.44]:
		var rf: float = r
		var q := [
			Vector3(-rf, 0.0, -rf), Vector3(rf, 0.0, -rf),
			Vector3(rf, 0.0, rf), Vector3(-rf, 0.0, rf),
		]
		for i in range(4):
			_build_edge(q[i], q[(i + 1) % 4], idx)
			idx += 1
	var apex := Vector3(0.0, CAGE_SIZE * 1.42, 0.0)
	var tv := [
		Vector3(-half, CAGE_SIZE, -half), Vector3(half, CAGE_SIZE, -half),
		Vector3(half, CAGE_SIZE, half), Vector3(-half, CAGE_SIZE, half),
	]
	for i in range(4):
		_build_edge(tv[i], apex, idx)
		idx += 1
	_build_edge(apex, apex + Vector3(0.0, 0.16, 0.0), idx)


## One edge: a length of light guide between two joints. Same signature, same
## node name, same midpoint-and-align transform as the shipped version — every
## _edges_* builder above calls it unchanged. What differs is underneath: a
## MeshKit barrel with smooth normals and tangents instead of a 6-sided
## CylinderMesh, no end caps (a ferrule covers each end), and ONE shared
## material instead of a fresh flat one per edge.
func _build_edge(start: Vector3, end_pos: Vector3, idx: int) -> void:
	_note_joint(start)
	_note_joint(end_pos)

	var mid := (start + end_pos) * 0.5
	var length := start.distance_to(end_pos)
	var dir := (end_pos - start).normalized()

	if _rod_mat == null:
		_rod_mat = _make_rod_material()
		_edge_materials.append(_rod_mat)

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Edge%d" % idx
	# caps = false: the tube is open at both ends and a ferrule sits over each.
	# Building the caps anyway would be 16 triangles a rod nobody ever sees.
	mesh_inst.mesh = MK.cylinder(EDGE_THICKNESS, length, EDGE_SEGMENTS, 0.0, 1, false)
	mesh_inst.material_override = _rod_mat

	_cage.add_child(mesh_inst)
	_cage_edges.append(mesh_inst)

	# Position at midpoint and rotate to align cylinder with edge direction
	mesh_inst.position = mid
	# Cylinder default axis is Y. Rotate to align with edge direction.
	if dir.is_equal_approx(Vector3.UP) or dir.is_equal_approx(Vector3.DOWN):
		pass  # Already aligned
	else:
		var up := Vector3.UP
		var axis := up.cross(dir).normalized()
		var angle := up.angle_to(dir)
		if axis.length() > 0.001:
			mesh_inst.transform.basis = Basis(axis, angle)
			mesh_inst.position = mid


## Remember an edge endpoint, once. Quantised to the millimetre because two
## builders arriving at the same corner from different arithmetic must agree it
## is one corner, or the frame grows a second ferrule inside the first.
func _note_joint(p: Vector3) -> void:
	var key: String = "%.3f|%.3f|%.3f" % [p.x, p.y, p.z]
	if _joint_seen.has(key):
		return
	_joint_seen[key] = true
	_joints.append(p)


## THE JOINTS — machined aluminium ferrules, one at every unique endpoint.
##
## This is rubric item 3 and it is the cheapest honest geometry in the file. A
## corner where three thin cylinders end flat is a corner where the object admits
## it was assembled out of primitives: three ellipse-shaped holes and a notch you
## can see through. A ball 3.3 mm proud of the rod closes all of it, gives the
## frame a second, real material to answer the light with, and terminates the
## clamp's finger and the shrine's finial with a tip instead of an open tube.
##
## Cost: 64 triangles each at 8 x 3, against the 8 saved per rod by dropping the
## caps. Counted per value against the shipped build — cage 704 vs 288 (2.4x),
## plinth the same, clamp 528 vs 216 (2.4x), shrine 1552 vs 600 (2.6x), and the
## heaviest, vitrine with 20 joints and five panes, 1852 vs 528 (3.5x). All of it
## inside R2's ~4x ceiling, and the absolute number is under 2k on a 1 m object.
func _build_joints() -> void:
	if _cage == null or _joints.is_empty():
		return
	_trim_mat = _make_trim_material()
	_trim_materials.append(_trim_mat)

	# One mesh, many instances: the material lives on material_override, so
	# sharing the SphereMesh costs nothing and cannot leak a material between them.
	var sphere := SphereMesh.new()
	sphere.radius = FERRULE_RADIUS
	sphere.height = FERRULE_RADIUS * 2.0
	sphere.radial_segments = FERRULE_SEGMENTS
	sphere.rings = FERRULE_RINGS

	for i in _joints.size():
		var p: Vector3 = _joints[i]
		var mi := MeshInstance3D.new()
		mi.name = "Ferrule%d" % i
		mi.mesh = sphere
		mi.material_override = _trim_mat
		mi.position = p
		_cage.add_child(mi)
		_cage_edges.append(mi)


## The two values that own a surface of their own. Called after the edges so it
## can never move one.
func _glaze_or_light(half: float) -> void:
	if offer == "vitrine":
		_glaze_vitrine(half)
	elif offer == "shrine":
		_light_shrine()


## VITRINE — the glass the mullions were asking for.
##
## Five panes, 6 mm thick, set 1.5 mm inside the bars the way real glazing sits
## behind its beads — near enough to read as one assembly, far enough that
## nothing z-fights. No pane on the floor face: a vitrine's base is its plinth.
##
## Deliberately faint. At 0.14 opacity the glass is almost invisible head-on and
## announces itself only at a grazing angle, which is exactly when a real case
## gives itself away, and it means the crystal is never seen through a grey and
## the WIREFRAME still carries the argument. render_priority -1 draws the panes
## before the rods so the frame always wins the sort — the safer failure, since
## the frame is the thing being said.
##
## VR: one glass layer per sight line is PbrKit's rule; looking through a closed
## box is two, which is the cost of a vitrine being a vitrine. No refraction
## (desktop-only, and left off), no second pane, no interior glazing.
func _glaze_vitrine(half: float) -> void:
	if _cage == null:
		return
	var mat: StandardMaterial3D = _make_glass_material()
	_glass_materials.append(mat)

	var inset: float = EDGE_THICKNESS + GLASS_THICKNESS * 0.5 + GLASS_GAP
	var span: float = CAGE_SIZE - EDGE_THICKNESS * 4.0
	var pane_mesh: ArrayMesh = MK.bevel_box(
		Vector3(span, span, GLASS_THICKNESS), 0.0015)

	for face in range(4):
		var ang: float = TAU * float(face) / 4.0
		var n := Vector3(cos(ang), 0.0, sin(ang))
		var pane := MeshInstance3D.new()
		pane.name = "Pane%d" % face
		pane.mesh = pane_mesh
		pane.material_override = mat
		pane.position = n * (half - inset) + Vector3(0.0, CAGE_SIZE * 0.5, 0.0)
		# rounded/bevelled boxes are thin in Z; turn local +Z to face outward.
		pane.rotation.y = PI * 0.5 - ang
		_cage.add_child(pane)

	var top := MeshInstance3D.new()
	top.name = "PaneTop"
	top.mesh = pane_mesh
	top.material_override = mat
	top.position = Vector3(0.0, CAGE_SIZE - inset, 0.0)
	top.rotation.x = PI * 0.5
	_cage.add_child(top)


## SHRINE — light with intent.
##
## One warm lamp hung from the finial and aimed straight down the axis at the
## crystal. Not more brightness: a DIFFERENT light, warm against the cage's cyan,
## narrow enough that it lands on the object and not the room, so the shrine's
## claim (approach, don't grab) is made by the lighting and not only by the roof.
##
## Shadows off — a spot shadow map is a per-frame cost on a Quest and this cone
## has one thing under it. Range stops just past the floor. It is a child of Cage,
## so it fades with the cage, hides with the lease and returns with it, and it is
## the ONLY extra light any offer adds: R2 allows three, this file spends one.
func _light_shrine() -> void:
	if _cage == null:
		return
	var apex_y: float = CAGE_SIZE * 1.42
	_offer_light = SpotLight3D.new()
	_offer_light.name = "ShrineLamp"
	_offer_light.light_color = SHRINE_LIGHT_COLOR
	_offer_light.light_energy = SHRINE_LIGHT_ENERGY
	_offer_light.light_specular = 0.7
	_offer_light.spot_range = apex_y + 0.25
	_offer_light.spot_angle = 26.0
	_offer_light.spot_angle_attenuation = 1.2
	_offer_light.spot_attenuation = 1.35
	_offer_light.shadow_enabled = false
	_offer_light.position = Vector3(0.0, apex_y - 0.06, 0.0)
	_offer_light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_cage.add_child(_offer_light)
	_offer_energy_rest = SHRINE_LIGHT_ENERGY


## GROUNDING (rubric item 4). A wireframe has almost no underside, so nothing in
## the scene says it is standing on the floor rather than hovering a centimetre
## over it — and the pedestal's own omni light, pointing outward from the middle
## of the cage, actively washes out the one place a contact would have shown.
##
## One Decal fixes it. It conforms to whatever it lands on (a floor, a step, a
## plinth top) instead of z-fighting like a flat quad, it is not a light so it
## costs nothing against R2's budget, and its radius is measured from the joints
## THIS build produced — so plinth gets a small pool, cage a square-ish one and
## shrine's two stepped ground squares a wide one, with no per-value table.
func _build_contact_shadow() -> void:
	if _cage == null or _joints.is_empty():
		return
	var reach: float = 0.0
	for i in _joints.size():
		var p: Vector3 = _joints[i]
		reach = maxf(reach, maxf(absf(p.x), absf(p.z)))
	if reach < 0.01:
		return
	_ground_decal = PK.ground_shadow(reach * 1.15, CONTACT_STRENGTH, 0.10)
	_ground_mix_rest = _ground_decal.albedo_mix
	_cage.add_child(_ground_decal)


# ═══════════════════════════════════════════════════════════════════════════
# MATERIALS — three surfaces, each one physically committed
# ═══════════════════════════════════════════════════════════════════════════

## The edge: side-emitting acrylic light guide. metallic 0 because a light pipe is
## a dielectric; a clear coat because it was extruded, not painted; a roughness
## texture so the lengthwise highlight is a field rather than a mirror line; a
## Fresnel rim because a 12 mm rod against a dark lab needs its silhouette back.
##
## albedo_color and emission are set LAST and verbatim from CAGE_COLOR, because
## those two are exactly what an #cage_color: token overwrites and what the fade
## animates. Everything the finish added lives in the other channels, so a
## recoloured cage keeps its whole surface and only changes hue.
func _make_rod_material() -> StandardMaterial3D:
	var rgb := Color(CAGE_COLOR.r, CAGE_COLOR.g, CAGE_COLOR.b)
	var m: StandardMaterial3D = PK.hard_plastic(rgb, 0.74, 0.03)
	m.albedo_color = CAGE_COLOR
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = rgb
	m.emission_energy_multiplier = EDGE_EMISSION
	PK.edge_light(m, 0.46, 0.55)
	PK.scale_detail(m, EDGE_DETAIL_SCALE)
	return m


## The joint: machined aluminium. The one true metal in the artifact — metallic
## 1.0, a measured albedo, a tight machined grain and a little anisotropy, so it
## answers the cage's own cyan light with a coloured specular instead of glowing.
## Alpha-blended at a rest alpha of 1.0 purely so the pickup fade can reach it;
## without that the rods would dissolve and leave a constellation of metal balls.
func _make_trim_material() -> StandardMaterial3D:
	var m: StandardMaterial3D = PK.machined_metal(PK.ALUMINIUM, 0.26, 0.12)
	var a: Color = m.albedo_color
	_trim_base = Color(a.r, a.g, a.b, 1.0)
	m.albedo_color = _trim_base
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	PK.edge_light(m, 0.22, 0.20)
	PK.scale_detail(m, FERRULE_DETAIL_SCALE)
	return m


## The pane: glass, tinted a pale version of whatever the cage is lit in, so the
## case belongs to the frame rather than sitting in front of it.
func _make_glass_material() -> StandardMaterial3D:
	var tint: Color = Color(CAGE_COLOR.r, CAGE_COLOR.g, CAGE_COLOR.b).lightened(0.45)
	var m: StandardMaterial3D = PK.glass(tint, 0.05, GLASS_OPACITY)
	m.render_priority = -1
	return m


# ═══════════════════════════════════════════════════════════════════════════
# FADE — one curve, every surface, from its own rest value
# ═══════════════════════════════════════════════════════════════════════════

## Record what each surface looks like at rest, so the fade can scale it rather
## than assume it. The shipped code hard-coded 0.8 and 2.0, which was true of the
## only material that existed then and wrong for the aluminium (rest alpha 1.0)
## and the glass (rest alpha 0.14) — and quietly wrong for any #cage_color: token
## that carried an alpha of its own.
func _snapshot_rest() -> void:
	_fade_mats.clear()
	_fade_a0 = PackedFloat32Array()
	_fade_e0 = PackedFloat32Array()
	for m in _edge_materials:
		_remember_rest(m)
	for tm in _trim_materials:
		_remember_rest(tm)
	for gm in _glass_materials:
		_remember_rest(gm)


func _remember_rest(m: StandardMaterial3D) -> void:
	if m == null:
		return
	var e: float = 0.0
	if m.emission_enabled:
		e = m.emission_energy_multiplier
	_fade_mats.append(m)
	_fade_a0.append(m.albedo_color.a)
	_fade_e0.append(e)


## alpha 1.0 is fully present, 0.0 is gone. Same curve as the shipped fade — each
## surface's rest alpha and rest emission energy, scaled linearly — so an
## #cage_color: cage still dissolves over CAGE_FADE_TIME exactly as it always did,
## and the lease's re-materialize is just _apply_fade(1.0).
func _apply_fade(alpha: float) -> void:
	for i in _fade_mats.size():
		var m: StandardMaterial3D = _fade_mats[i]
		m.albedo_color.a = _fade_a0[i] * alpha
		if m.emission_enabled:
			m.emission_energy_multiplier = _fade_e0[i] * alpha
	if _ground_decal != null:
		_ground_decal.albedo_mix = _ground_mix_rest * alpha
	if _offer_light != null:
		_offer_light.light_energy = _offer_energy_rest * alpha


# ═══════════════════════════════════════════════════════════════════════════
# LIGHT — soft glow from the center
# ═══════════════════════════════════════════════════════════════════════════

func _build_light() -> void:
	_cage_light = OmniLight3D.new()
	_cage_light.name = "CageLight"
	_cage_light.light_color = Color(0.4, 0.7, 1.0)
	_cage_light.light_energy = 1.5
	_cage_light.omni_range = 2.0
	_cage_light.omni_attenuation = 1.5
	_cage_light.position = Vector3(0, CAGE_SIZE * 0.5, 0)
	add_child(_cage_light)


# ═══════════════════════════════════════════════════════════════════════════
# CRYSTAL — spawn the catalyst inside the cage
# ═══════════════════════════════════════════════════════════════════════════

func _spawn_crystal() -> void:
	var catalyst_scene := load("res://commons/hazards/becoming_catalyst/becoming_catalyst.tscn")
	if catalyst_scene == null:
		push_error("[CatalystPedestal] Failed to load becoming_catalyst.tscn")
		return

	_crystal = catalyst_scene.instantiate()
	_crystal.name = "CatalystCrystal"

	# Position at center of the cage
	_crystal_base_y = CAGE_SIZE * 0.5
	_crystal.position = Vector3(0, _crystal_base_y, 0)

	add_child(_crystal)

	# Connect to the catalyst's picked_up signal to know when player takes it
	if _crystal.has_signal("picked_up"):
		_crystal.picked_up.connect(_on_crystal_taken)

	# If apply_grid_config landed before _ready, forward the stashed
	# crystal config now that the crystal exists.
	if not _pending_crystal_cfg.is_empty() and _crystal.has_method("apply_grid_config"):
		_crystal.call_deferred("apply_grid_config", _pending_crystal_cfg)
		_pending_crystal_cfg = {}

	print("[CatalystPedestal] Crystal spawned at center of cage")


func _on_crystal_taken(_pickable) -> void:
	# Crystal has been grabbed — fade the cage away
	_fading = true
	_fade_progress = 0.0
	catalyst_taken.emit()
	if _lease_s > 0.0:
		# Start the return countdown. The crystal dissolves on the
		# manager's clock (~lease_s after absorb); the cage returns a
		# grace beat later so the two never overlap.
		_return_left = _lease_s + RETURN_GRACE
		print("[CatalystPedestal] Crystal taken on a %.0fs lease — return countdown started" % _lease_s)
	else:
		print("[CatalystPedestal] Crystal taken — fading cage")


## Lease over: restore the cage and grow a fresh crystal with the same
## config the original had (sequence binding, lease, mode seeds).
func _rematerialize() -> void:
	_return_left = 0.0
	_leased_out = false
	_fading = false
	_fade_progress = 0.0
	if _cage:
		_cage.visible = true
	# Every surface back to its own rest value — light guides, aluminium, glass,
	# the contact pool and the shrine lamp, in one call.
	_apply_fade(1.0)
	if _cage_light:
		_cage_light.visible = true
		_cage_light.light_energy = 1.5
	_pending_crystal_cfg = _last_crystal_cfg.duplicate()
	_spawn_crystal()
	catalyst_returned.emit()
	print("[CatalystPedestal] Lease over — cage re-materialized, crystal returned")


# ═══════════════════════════════════════════════════════════════════════════
# GRID INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════

# Stash for crystal config when apply_grid_config arrives before _ready.
var _pending_crystal_cfg: Dictionary = {}

# Token grammar: catalyst_pedestal:0:0#key:value#key:value...
# Forwarded keys (handled by becoming_catalyst.configure):
#   all_modes      — unlock every mode (debug)
#   start_mode     — unlock one specific mode
#   unlock_to      — unlock all modes up to a given order
#   shooting_only  — unlock only order >= 1 (skip voxel/wedge placement)
#   active_mode    — set current_mode_index to point at this mode_id
#   sequence       — bind the crystal to a sequence (name or "auto"); arms
#                    the native mode via catalyst_sequence_binding.gd
#   lease_s        — timed lease: crystal dissolves after N seconds and the
#                    pedestal re-materializes it (also pedestal-handled)
# Pedestal-handled keys:
#   cage_color     — RGBA wireframe tint
#   clear_modes    — call CatalystCapabilityManager.reset_progression() first
const _CATALYST_FORWARD_KEYS = [
	"all_modes", "start_mode", "unlock_to",
	"shooting_only", "active_mode", "sequence", "lease_s",
]


func apply_grid_config(config_data: Dictionary) -> void:
	# offer: which institution stands around the crystal (appearance only). Read
	# FIRST, and normalised against OFFERS so a typo keeps the shipped cage; a
	# cage_color in the same token then recolours the rebuilt edges below.
	if config_data.has("offer"):
		var o: String = str(config_data["offer"]).strip_edges().to_lower()
		if OFFERS.has(o) and o != offer:
			offer = o
			if _cage != null and not _fading and not _leased_out:
				_rebuild_cage()

	if config_data.has("cage_color"):
		var c: Color = Color(config_data["cage_color"])
		for mat in _edge_materials:
			mat.albedo_color = c
			mat.emission = c
		# The ferrules are aluminium and stay aluminium. A tint, not a repaint:
		# the frame keeps one true metal in it whatever colour the light is, which
		# is the whole reason there are two materials instead of one.
		for tm in _trim_materials:
			var tinted: Color = _trim_base.lerp(Color(c.r, c.g, c.b), 0.22)
			tm.albedo_color = Color(tinted.r, tinted.g, tinted.b, _trim_base.a)
		# The glass follows the light it is glazing, pale and at its own opacity.
		for gm in _glass_materials:
			var pane: Color = Color(c.r, c.g, c.b).lightened(0.45)
			gm.albedo_color = Color(pane.r, pane.g, pane.b, GLASS_OPACITY)
		# Re-read the rest values so a later fade scales from the NEW colour.
		# Not while fading: mid-fade values are not anybody's rest state.
		if not _fading:
			_snapshot_rest()

	# clear_modes: only free GHOST catalysts (auto-absorbed onto an
	# XRController by the manager from save state). Don't touch the
	# pedestal's own crystal or the bracelet. Most maps will only have
	# our pedestal's crystal in the scene, so this is a no-op there.
	if _is_truthy(config_data.get("clear_modes", false)):
		var freed: int = 0
		for cat in get_tree().get_nodes_in_group("catalyst"):
			# Skip our pedestal's own crystal (and any descendant of it).
			if cat == _crystal or self.is_ancestor_of(cat):
				continue
			# Only free if parented to an XRController3D — that's what
			# auto_absorb does. Anything else (pedestals in other maps,
			# sibling catalysts, etc.) leave alone.
			var p := cat.get_parent()
			if p and p.get_class() == "XRController3D":
				cat.queue_free()
				freed += 1

		var cap_mgr := get_tree().root.get_node_or_null("CatalystCapabilityManager")
		if cap_mgr == null:
			cap_mgr = get_tree().root.get_node_or_null("CatalystCapability")
		if cap_mgr and "_catalyst_modes" in cap_mgr:
			cap_mgr._catalyst_modes.clear()
			if cap_mgr.has_method("save_state"):
				cap_mgr.call("save_state")
		print("[CatalystPedestal] clear_modes ran — freed %d ghost catalysts; bracelet preserved" % freed)

	# lease_s: the pedestal needs it too (return countdown + survive fade).
	if config_data.has("lease_s"):
		_lease_s = float(str(config_data["lease_s"]))

	# Forward catalyst-related keys to the spawned crystal.
	var crystal_cfg: Dictionary = {}
	for k in _CATALYST_FORWARD_KEYS:
		if config_data.has(k):
			crystal_cfg[k] = config_data[k]
	if crystal_cfg.is_empty():
		return
	# Remember for lease respawns — the returned crystal gets the same
	# sequence binding / lease / mode seeds the original had.
	_last_crystal_cfg = crystal_cfg.duplicate()
	if is_instance_valid(_crystal) and _crystal.has_method("apply_grid_config"):
		_crystal.call("apply_grid_config", crystal_cfg)
		_pending_crystal_cfg = {}
	else:
		# Crystal not yet spawned — defer until _spawn_crystal runs.
		_pending_crystal_cfg = crystal_cfg


## Rebuild only the wireframe housing (an #offer: token arriving after _ready).
## The light, the crystal, the lease clock and every signal are untouched — this
## frees the Cage node alone and builds the newly chosen institution through the
## same _build_edge pipeline, so fade, lease hide/return and #cage_color: keep
## working at every value. Everything the finish pass added lives under Cage too
## (ferrules, panes, the shrine lamp, the contact pool), so one queue_free still
## clears the whole institution and the arrays below are the only bookkeeping.
func _rebuild_cage() -> void:
	if _cage != null:
		_cage.queue_free()
	_cage = null
	_cage_edges.clear()
	_edge_materials.clear()
	_trim_materials.clear()
	_glass_materials.clear()
	_fade_mats.clear()
	_fade_a0 = PackedFloat32Array()
	_fade_e0 = PackedFloat32Array()
	_rod_mat = null
	_trim_mat = null
	_ground_decal = null
	_ground_mix_rest = 0.0
	_offer_light = null
	_offer_energy_rest = 0.0
	_joints.clear()
	_joint_seen.clear()
	_build_cage()


# Truthy check — accepts native bool, "true"/"yes"/"1" strings, non-zero numbers.
# GDScript has no bool() constructor; tokens arrive as strings via the parser.
func _is_truthy(value) -> bool:
	if typeof(value) == TYPE_BOOL:
		return value
	if typeof(value) == TYPE_STRING:
		return value.to_lower() in ["true", "1", "yes"]
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return value != 0
	return false
