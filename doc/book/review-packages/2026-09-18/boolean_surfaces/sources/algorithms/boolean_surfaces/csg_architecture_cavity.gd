# CSG Architecture Cavity — real-world example: a room is a wall minus a void
#
# A thick wall block with three openings cut through it: a rectangular doorway, a circular
# porthole, and a tall arched window. All three are CSG subtractions from the same wall.
# The player walks around or through the doorway, experiencing architecture as Boolean
# composition.
#
# Sets up an architectural intuition for everything that follows: cavities in solids,
# rooms in buildings, mortise-and-tenon joints, even the way the chamber's ring of
# stations in the postfoundation capstone will be a wall with seven cavities.
#
# @identity
# essence: A thick wall with three openings — doorway, circular porthole, arched window — each a CSG subtraction from the same solid. Architecture as Boolean difference.
# desire: To turn the difference operator into a habitable space the player can walk through, not merely observe.
# critical_parameter: wall_size against the opening sizes — the ratio of solid to void. Too little solid and the wall stops reading as a wall; too little void and it stops being architecture.
# triggers: Automatic — builds the wall, openings, and ground on _ready(). The player walks up to or through the doorway.
# emerges: The bodily understanding that rooms, doors, and windows are all the same operation: solid minus opening.
# needs: Procedural CSG [has], walkable ground [has]. The second wall this line used to name as missing now EXISTS, as the `interior` axis — corner, court and room add one, two and three returning runs and close the void. It is not the default and no map places it yet, so the claim is buildable but still unmet in the game.
# relationships: The applied payoff of csg_difference_demo. Prefigures the postfoundation capstone's ring of seven cavities. The most embodied artifact in the sequence.
# truth: Every architectural cavity is a difference. A room is a wall that has been subtracted from.
# @qfep_term: F — composition algebra applied to architecture.

extends Node3D
class_name CSGArchitectureCavity

# --- DNA (stage 2, promoted 2026-08-11) -------------------------------------
# THE PROBLEM. This artifact's own declared critical_parameter is "wall_size against the
# opening sizes — the ratio of solid to void. Too little solid and the wall stops reading
# as a wall", and it has shipped exactly ONE ratio across eleven placements. Its @identity
# then names what it is missing in so many words: "a second wall to make an enclosed room
# the player can stand inside". So the two things this object argues about were both
# unreachable — one frozen at a single value, the other simply absent. Hence two axes and
# not one, and neither of them is the sibling family's word.
#
# openwork — WHAT A WALL'S HOLES ARE, AND AT WHAT DENSITY MASS STOPS BEING MASS. A ladder
#   in count and kind against a 3.4 x 2.6 m face of 8.84 sq m. Solid fraction, front run:
#     door     the rectangular doorway alone. 1.44 sq m void, 84% solid. The minimum
#              claim — one difference and it is already architecture.
#     sampler  SHIPPED. doorway + porthole + arched window, ~75% solid: three unlike
#              opening types arguing that all three are one operator.
#     arcade   the same arch repeated across the run on even piers and nothing else.
#              5 bays, 3.37 sq m, 62% solid — repetition of a single difference, and
#              the wall becomes rhythm.
#     screen   a 7 x 5 lattice of 0.36 m square subtractions on a 0.486 x 0.52 pitch,
#              leaving 0.126 and 0.16 m mullions. 4.54 sq m, 49% solid — past the
#              tipping point, where the wall reads as a filter rather than mass with
#              holes. It stops there deliberately: thinner mullions read as NO WALL and
#              the verdict would become a fact about the capture.
#   The Label3D follows the rung, because on this artifact the label is part of the claim.
#
# interior — WHETHER THE SUBTRACTION HAS PRODUCED AN INSIDE. One wall demonstrates the
#   operator and never delivers the truth line: a wall has no interior.
#     none    SHIPPED. The single 3.4 m run.
#     corner  two runs meeting at a right angle — shelter, a claim on space, no inside.
#     court   three runs, open at the back — enclosure felt before it is closed.
#     room    four runs, the doorway in the front one: the first rung on which the player
#             is INSIDE and the void is bounded. The sequence's payoff standing up rather
#             than being asserted.
#   The two axes compose — every added run carries the active openwork, so interior=room
#   at openwork=screen is a lantern. ONE rule governs the composition and it is the rule
#   that makes "room" honest: only the FRONT run is entered, so the ground-level doorway
#   appears there and nowhere else. Windows repeat on every run; doors do not.
#
# GEOMETRY THAT DOES NOT MOVE. The returning runs are sized to stand wholly on the shipped
# ground slab (wall_size.x + 2 by wall_size.z + 4 = 5.4 x 4.4) — depth is DERIVED from it,
# not chosen. _build_ground is untouched at every rung. That matters more than it looks:
# the capture AABB counts MeshInstance3D only and every part of this wall is CSG, so the
# slab IS the measured box. Leaving it alone means the framing is one number for all
# sixteen variants instead of one per value.
#
# WHAT IS DECLINED. `strike` — the family word shared character for character by
# fontana_puncture, csg_difference_demo and csg_compose_workbench — is NOT promoted here,
# and the reason is specific rather than borrowed. Those three each have ONE B to place.
# This wall's B is three things at once (a box, a sphere, and a box-union-cylinder), so
# strike would have to pick a favourite: moving any one of them across four named
# positions changes about 2% of the face while announcing itself as the artifact's
# structural axis. That is subtraction_suite's refusal in another key — there the tray had
# no B to place; here there are three and no single one of them is the strike.
# Also declined: an axis directly over the solid-to-void RATIO, this artifact's own
# declared critical_parameter. It is a fraction, a fraction is already legible as a number,
# and csg_compose_workbench declined an axis over preset_spacing for exactly that reason.
# openwork moves the same ratio as a CONSEQUENCE of changing what the holes ARE, which is
# the thing a vocabulary is actually needed for.
const OPENWORKS: PackedStringArray = ["door", "sampler", "arcade", "screen"]
const INTERIORS: PackedStringArray = ["none", "corner", "court", "room"]

## Bays in an arcade across the shipped 3.4 m run; scaled by length on shorter runs.
const ARCADE_BAYS: int = 5
## The lattice on the shipped run. Rows are fixed (the wall's height never varies with the
## run); columns scale with length so the pitch, not the count, is what wraps the room.
const SCREEN_COLS: int = 7
const SCREEN_ROWS: int = 5
const SCREEN_CUT: float = 0.36
## Clearance left between the outer face of the back run and the edge of the ground slab.
const GROUND_MARGIN: float = 0.1

@export_category("Wall Settings")
## What the holes ARE. See the DNA note. sampler is the shipped wall, and its branch is a
## short-circuit: the same three subtractions, in the same order, from the same literals.
@export_enum("door", "sampler", "arcade", "screen") var openwork: String = "sampler"
## Whether the subtraction has produced an inside. none is the shipped single run and adds
## nothing; the other three add returning runs sized to the existing ground slab.
@export_enum("none", "corner", "court", "room") var interior: String = "none"
@export var wall_color: Color = Color(0.8, 0.76, 0.7, 1.0)
@export var wall_size: Vector3 = Vector3(3.4, 2.6, 0.4)
## The shipped doorway. A placement that names these directly still WINS over openwork —
## the named axis chooses WHICH subtractions exist, never how big they are.
@export var door_size: Vector3 = Vector3(0.8, 1.8, 0.6)
@export var door_offset_x: float = -0.9
@export var porthole_radius: float = 0.32
@export var porthole_offset: Vector3 = Vector3(0.0, 1.4, 0.0)
@export var arch_size: Vector3 = Vector3(0.55, 1.0, 0.6)
@export var arch_top_radius: float = 0.28
@export var arch_offset_x: float = 1.1

var _root_csg: CSGCombiner3D
var _built: bool = false
## Only nodes THIS script added, so a rebuild frees its own work and nothing else's.
var _owned: Array[Node] = []


func _ready() -> void:
	_read_metadata_overrides()
	_build()


## Guarded. The old body assigned wall_color and did nothing else — a knob with no rebuild
## behind it, and since the grid delivers config with call_deferred (i.e. AFTER _ready) it
## could never take effect at all. It now rebuilds when, and only when, a value the build
## actually reads has changed. Of the eleven placements, nine pass no keys and two pass
## {"emissive": false}, which no build path reads — so the signature is unchanged for every
## one of them and none is even torn down.
func apply_grid_config(config_data: Dictionary) -> void:
	var before: String = _config_signature()
	for k in config_data.keys():
		var sk: String = str(k).replace(":", "_").replace(",", "_").replace(" ", "_").replace("-", "_")
		if sk.is_valid_identifier():
			set_meta("config_%s" % sk, config_data[k])
	_read_metadata_overrides()
	if not _built:
		return
	if _config_signature() == before:
		return
	for n in _owned:
		if is_instance_valid(n):
			n.queue_free()
	_owned.clear()
	_root_csg = null
	_built = false
	_build()


## Every value any build path reads. Anything absent here is a knob that could change the
## picture without the guard noticing.
func _config_signature() -> String:
	return "|".join(PackedStringArray([
		openwork, interior, str(wall_color), str(wall_size),
		str(door_size), str(door_offset_x),
		str(porthole_radius), str(porthole_offset),
		str(arch_size), str(arch_top_radius), str(arch_offset_x)]))


func _read_metadata_overrides() -> void:
	if has_meta("config_openwork"):
		var o: String = str(get_meta("config_openwork")).strip_edges().to_lower()
		if OPENWORKS.has(o):
			openwork = o
	if has_meta("config_interior"):
		var i: String = str(get_meta("config_interior")).strip_edges().to_lower()
		if INTERIORS.has(i):
			interior = i
	if has_meta("config_wall_color"):
		var c = get_meta("config_wall_color")
		if c is Color:
			wall_color = c
		else:
			wall_color = _parse_color(str(c), wall_color)
	if has_meta("config_wall_size"):
		wall_size = _parse_vec3(get_meta("config_wall_size"), wall_size)
	if has_meta("config_door_size"):
		door_size = _parse_vec3(get_meta("config_door_size"), door_size)
	if has_meta("config_arch_size"):
		arch_size = _parse_vec3(get_meta("config_arch_size"), arch_size)
	if has_meta("config_porthole_offset"):
		porthole_offset = _parse_vec3(get_meta("config_porthole_offset"), porthole_offset)
	if has_meta("config_door_offset_x"):
		door_offset_x = float(str(get_meta("config_door_offset_x")))
	if has_meta("config_porthole_radius"):
		porthole_radius = float(str(get_meta("config_porthole_radius")))
	if has_meta("config_arch_top_radius"):
		arch_top_radius = float(str(get_meta("config_arch_top_radius")))
	if has_meta("config_arch_offset_x"):
		arch_offset_x = float(str(get_meta("config_arch_offset_x")))


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts: PackedStringArray = raw.split(",")
	if parts.size() >= 3:
		var a: float = 1.0
		if parts.size() > 3:
			a = float(parts[3])
		return Color(float(parts[0]), float(parts[1]), float(parts[2]), a)
	return fallback


func _parse_vec3(raw, fallback: Vector3) -> Vector3:
	if raw is Vector3:
		return raw
	var parts: PackedStringArray = str(raw).split(",")
	if parts.size() >= 3:
		return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

## Child order is WallRoot, [extra runs], Label3D, Ground. At interior=none there are no
## extra runs, so the order and the node count are exactly what shipped.
func _build() -> void:
	_built = true
	_build_wall_with_openings()
	_build_interior_runs()
	_build_label()
	_build_ground()


func _own(n: Node) -> void:
	_owned.append(n)
	add_child(n)


## The shipped run: origin, no yaw, full wall_size.x, and it is the FRONT — the only run
## the doorway is ever cut into.
func _build_wall_with_openings() -> void:
	_root_csg = _make_run("WallRoot", wall_size.x, true)
	_own(_root_csg)


## The returning runs. interior=none returns before any of this exists.
##
## DEPTH IS DERIVED FROM THE GROUND, not chosen: _build_ground lays a slab of
## wall_size.z + 4.0 in Z centred on the origin, so the back run's outer face has to clear
## -(wall_size.z + 4.0) * 0.5 by GROUND_MARGIN. Keeping every run over the slab is what
## holds the measured AABB — which is the slab, since the wall is entirely CSG — identical
## at all four rungs, so one dna.framing serves the whole sweep.
func _build_interior_runs() -> void:
	if interior == "none" or not INTERIORS.has(interior):
		return
	var half_t: float = wall_size.z * 0.5
	var depth: float = (wall_size.z + 4.0) * 0.5 - half_t - GROUND_MARGIN
	var side_x: float = wall_size.x * 0.5 - half_t
	# THE RETURNING RUNS BUTT AGAINST THE FRONT WALL'S BACK FACE, they do not run
	# through it. They used to: side_len was depth + wall_size.z and side_z was
	# -depth * 0.5, which put each run's near end at +half_t — the front wall's own
	# FRONT plane. Two consequences, both wrong. The two solids are separate
	# CSGCombiner3D roots rather than one, so coplanar front faces z-fight — in the
	# sequence whose sibling artifact exists specifically to exhibit that failure. And
	# the run occupied the full z-thickness of the wall at each end, plugging the end
	# bay at openwork=arcade and the end columns at openwork=screen, so the openings
	# were cut and then filled in from behind.
	var side_len: float = depth
	var side_z: float = -(depth * 0.5) - half_t

	# THE RUN NEAREST THE CAMERA IS BUILT FIRST, and that is not an aesthetic choice.
	# It was +X second, so `corner` raised the run on -X: the side the canonical
	# standpoint (yaw 0.62, pitch -0.26 — camera at +X/+Y/+Z) cannot see, because it
	# falls inside the front wall's own silhouette and behind it. A reviewer predicted
	# from that geometry alone that corner would measure identical to none and court
	# identical to room, before any frame existed. The sweep then reported exactly
	# those two pairs as twins, at 5.33% and 4.22%. The axis was not half-dead; half of
	# it was built where this pipeline does not stand. Same disease as the anamorphic
	# audit, one layer further in — there the camera missed a face, here it missed a
	# whole wall.
	var near: CSGCombiner3D = _make_run("WallRunRight", side_len, false)
	near.position = Vector3(side_x, near.position.y, side_z)
	near.rotation.y = PI * 0.5
	_own(near)
	if interior == "corner":
		return

	var far: CSGCombiner3D = _make_run("WallRunLeft", side_len, false)
	far.position = Vector3(-side_x, far.position.y, side_z)
	far.rotation.y = PI * 0.5
	_own(far)
	if interior == "court":
		return

	var back: CSGCombiner3D = _make_run("WallRunBack", wall_size.x, false)
	back.position = Vector3(0.0, back.position.y, -depth)
	_own(back)


## One run of wall with the active openwork cut out of it. `front` is true for the shipped
## run only, and is what keeps a room from having four doorways.
func _make_run(node_name: String, run_len: float, front: bool) -> CSGCombiner3D:
	var root := CSGCombiner3D.new()
	root.name = node_name
	root.position.y = wall_size.y * 0.5
	# Solid wall.
	var wall := CSGBox3D.new()
	wall.size = Vector3(run_len, wall_size.y, wall_size.z) if run_len != wall_size.x else wall_size
	wall.operation = CSGShape3D.OPERATION_UNION
	root.add_child(wall)
	_build_openings(root, run_len, front)
	# Material on the wall root.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = wall_color
	mat.roughness = 0.85
	mat.metallic = 0.05
	root.material_override = mat
	return root


## THE SHORT-CIRCUIT LIVES HERE. openwork=sampler on the front run — which is what all
## eleven placements build — falls into the `_:` branch's `front` arm, which is the shipped
## body verbatim: door, porthole, arch, in that order, from those literals, with no
## scaling, no counting and no layout arithmetic anywhere in the path.
func _build_openings(root: CSGCombiner3D, run_len: float, front: bool) -> void:
	match openwork:
		"door":
			# Only the front run is entered, so a returning run at this rung is blank mass.
			if front:
				_sub_door(root)
		"arcade":
			_sub_arcade(root, run_len)
		"screen":
			_sub_screen(root, run_len)
		_:
			# sampler, and the fallthrough for any value the sweep sets that this code
			# does not know — which renders the shipped wall rather than nothing.
			if front:
				_sub_door(root)
				_sub_porthole(root, porthole_offset)
				_sub_arch(root, arch_offset_x)
			else:
				var s: float = run_len / wall_size.x if wall_size.x != 0.0 else 1.0
				_sub_porthole(root, Vector3(
					porthole_offset.x * s, porthole_offset.y, porthole_offset.z))
				_sub_arch(root, arch_offset_x * s)


## Doorway (rectangular subtraction).
func _sub_door(root: CSGCombiner3D) -> void:
	var door := CSGBox3D.new()
	door.size = door_size
	door.position = Vector3(door_offset_x, -wall_size.y * 0.5 + door_size.y * 0.5, 0.0)
	door.operation = CSGShape3D.OPERATION_SUBTRACTION
	root.add_child(door)


## Porthole (sphere subtraction).
##
## PRE-EXISTING ODDITY, PRESERVED ON PURPOSE. porthole_offset.y is 1.4 against a wall
## half-height of 1.3, so the sphere centre sits 0.1 m ABOVE the wall top and the shipped
## "porthole" is really a scallop bitten out of the top edge — a circular segment of about
## 0.098 sq m, not a 0.32 m disc through the wall. Defaults are sacred, so this is left
## exactly as it is; a placement that wants a true porthole names porthole_offset and wins.
func _sub_porthole(root: CSGCombiner3D, at: Vector3) -> void:
	var porthole := CSGSphere3D.new()
	porthole.radius = porthole_radius
	porthole.position = at
	porthole.operation = CSGShape3D.OPERATION_SUBTRACTION
	root.add_child(porthole)


## Arched window: a box union a cylinder, then subtracted as one.
func _sub_arch(root: CSGCombiner3D, at_x: float) -> void:
	var arch_combiner := CSGCombiner3D.new()
	arch_combiner.position = Vector3(
		at_x, -wall_size.y * 0.5 + arch_size.y * 0.5 + 0.4, 0.0)
	arch_combiner.operation = CSGShape3D.OPERATION_SUBTRACTION
	var arch_box := CSGBox3D.new()
	arch_box.size = arch_size
	arch_box.operation = CSGShape3D.OPERATION_UNION
	arch_combiner.add_child(arch_box)
	var arch_top := CSGCylinder3D.new()
	if arch_top.has_method("set_radius"):
		arch_top.radius = arch_top_radius
	arch_top.height = arch_size.z
	# Cylinder's default axis is Y, rotate around X to lay it sideways.
	arch_top.rotation.x = PI * 0.5
	arch_top.position.y = arch_size.y * 0.5
	arch_top.operation = CSGShape3D.OPERATION_UNION
	arch_combiner.add_child(arch_top)
	root.add_child(arch_combiner)


## openwork = arcade. The same arch repeated on even piers — including at the two ends, so
## the run does not terminate on a 6 cm stub. Bay count scales with run length, which keeps
## the RHYTHM constant around a room rather than the count.
func _sub_arcade(root: CSGCombiner3D, run_len: float) -> void:
	var bay_w: float = maxf(arch_size.x, arch_top_radius * 2.0)
	var n: int = _arcade_bays(run_len)
	while n > 1 and float(n) * bay_w > run_len:
		n -= 1
	var pier: float = (run_len - float(n) * bay_w) / float(n + 1)
	var x0: float = -run_len * 0.5 + pier + bay_w * 0.5
	for i in range(n):
		_sub_arch(root, x0 + float(i) * (bay_w + pier))


## openwork = screen. Past the tipping point: the wall reads as a filter, not as mass with
## holes in it. Columns scale with run length so the pitch, not the count, wraps the room.
func _sub_screen(root: CSGCombiner3D, run_len: float) -> void:
	var cols: int = _screen_cols(run_len)
	var pitch_x: float = run_len / float(cols)
	var pitch_y: float = wall_size.y / float(SCREEN_ROWS)
	var cut: float = minf(SCREEN_CUT, minf(pitch_x, pitch_y) * 0.8)
	var thru: float = wall_size.z + 0.2
	for c in range(cols):
		for r in range(SCREEN_ROWS):
			var hole := CSGBox3D.new()
			hole.size = Vector3(cut, cut, thru)
			hole.position = Vector3(
				(float(c) - float(cols - 1) * 0.5) * pitch_x,
				(float(r) - float(SCREEN_ROWS - 1) * 0.5) * pitch_y,
				0.0)
			hole.operation = CSGShape3D.OPERATION_SUBTRACTION
			root.add_child(hole)


func _arcade_bays(run_len: float) -> int:
	if wall_size.x == 0.0:
		return ARCADE_BAYS
	return maxi(1, int(round(float(ARCADE_BAYS) * run_len / wall_size.x)))


func _screen_cols(run_len: float) -> int:
	if wall_size.x == 0.0:
		return SCREEN_COLS
	return maxi(1, int(round(float(SCREEN_COLS) * run_len / wall_size.x)))


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(wall_size.x + 2.0, 0.04, wall_size.z + 4.0)
	ground.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.4, 0.36, 1.0)
	mat.roughness = 0.9
	ground.material_override = mat
	ground.position.y = -0.02
	_own(ground)


## On this artifact the label is part of the claim, so it follows the rung. The sampler
## branch returns the shipped string character for character, U+2212 minus sign included.
func _build_label() -> void:
	var label := Label3D.new()
	label.text = _label_text()
	label.font_size = 32
	label.outline_size = 8
	label.modulate = Color(0.95, 0.85, 0.55, 1.0)
	label.position = Vector3(0, wall_size.y + 0.35, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_own(label)


func _label_text() -> String:
	match openwork:
		"door":
			return "wall − door = room"
		"arcade":
			return "wall − %d arches = room" % _arcade_bays(wall_size.x)
		"screen":
			return "wall − %d cuts = room" % (_screen_cols(wall_size.x) * SCREEN_ROWS)
		_:
			return "wall − (door + porthole + window) = room"
