# @identity
# essence: a framed picture, standing on a low plinth, whose subject is the room it is
#   standing in — a gallery wall, a frame in that wall, and inside that frame the same
#   wall again, four deep, each level turned a little further as it recedes. At the dead
#   centre, where the levels would have to meet and cannot, a small chased silver seal
#   sits proud of the board. Under the seal the board is not painted dark. It is GONE:
#   the aperture is open geometry, and a visitor with an eye to it looks through the
#   artwork into whatever the hall has put behind it.
# desire: that the learner finds the gap by finding the signature first — that the mark
#   is read as craftsmanship, admired, and only then understood as the place where the
#   picture gave up. The order matters. A hole found first is damage; a hole found under
#   a maker's mark is a confession.
# critical_parameter: spiral — the twist per level and the shrink per level, moved
#   together because they are one decision. At "escher" they are the print's own ratio
#   and the centre becomes unreadable, which is the fact the artifact is about.
# triggers: none. _ready() builds it and nothing moves afterwards; `lid` is a build-time
#   position, not an animation, because the evidence for this object is a still and a
#   lid that opens only while you watch is a lid that is closed in every photograph.
# emerges: from the front, a tunnel of gilt frames turning clockwise into a silver dot.
#   From two steps to the side, the tunnel shortens and the seal slides off-axis — the
#   recursion has a viewpoint, and standing anywhere else breaks it. That is Escher's
#   too: Print Gallery only works from where he drew it from.
# needs: a lit hall [the room provides it]; something BEHIND it worth seeing through —
#   a blank wall behind reads as a plugged hole and says nothing, a doorway or a lit
#   depth behind reads as an outside and says everything. Placement is doing half the
#   argument here, and a placer who backs this against a wall has silenced it.
# relationships: stands with escher_room (local consistency, global impossibility, at
#   room scale) and godel_sentence_machine (the same claim stated rather than shown);
#   argues with the_frame_you_were_given, which says the last cut still lies — this says
#   there is a place no cut reaches at all. Kin to incompleteness_tower in claim and to
#   none of them in method: they say it, this one fails to draw it and signs the failure.
# truth: a construction that cannot close itself has two honest endings — hide the gap,
#   or sign it. Escher signed his, and the monogram over the blank centre of Print
#   Gallery is not a lapse in the drawing; it is the drawing's only true sentence about
#   itself. Incompleteness is not the hole. It is the signature on the lid.

extends Node3D
class_name PrintGalleryRecursion

const PBR := preload("res://commons/render/pbr_kit.gd")

## THE THREE SPIRALS, and why the default is not the historical one.
##
## Lenstra and de Smit (Leiden, 2003) reconstructed the centre Escher left blank and
## found the print repeats at a magnification of 256 per full turn — a quarter turn is
## a factor of four. "escher" is that ratio exactly: twist 90, shrink 0.25.
##
## It is not the default, and the arithmetic is the reason — worked in Python before the
## build, which is the only reason the next fact is in this comment rather than in a
## screenshot nobody could explain. At shrink 0.25 the FOURTH aperture would be 1/256 of
## the first: 4.7 mm on a 1.20 m picture. That is under MIN_APERTURE_M, so the build
## truncates and "escher" comes out with THREE levels, not four — an 18.8 mm innermost
## aperture and a 25 mm seal. The print's own ratio runs out of picture before it runs
## out of levels, at this size, which is exactly the difficulty Escher was in and is
## worth having reachable. The default "wide" runs 0.55: four levels, a 110 mm aperture
## and a 147 mm seal, hand-sized and legible in one still.
##
## Those are ARITHMETIC, not renders — the engine was not this session's to run — so
## treat them as ratios, not as measurements of what a camera sees.
##
## "none" is the control. Twist 0 is a plain mise-en-abyme: nested frames, no rotation,
## no spiral. It is here because the difference between "none" and "wide" is the entire
## claim that this object is about Escher and not about two mirrors facing each other.
const SPIRALS := {
	"wide": {"twist": 30.0, "shrink": 0.55},
	"escher": {"twist": 90.0, "shrink": 0.25},
	"none": {"twist": 0.0, "shrink": 0.55},
}

## Metres of recession per level, before scale_factor.
const STEP_M := 0.09
## Stop nesting when the next aperture would be narrower than this. A sixth level at
## Escher's ratio is 0.3 mm wide: geometry the renderer keeps and nobody can see, and a
## derived seal small enough to vanish under its own chamfer. The build truncates and
## says so once, rather than shipping invisible triangles.
const MIN_APERTURE_M := 0.012
## THE LID DOES NOT SWING, AND THE REASON IS MEASURED.
##
## The first build hinged it: a pivot at the left edge, 118 degrees, swinging out toward
## the viewer like a locket. It cannot work, and the numbers say so before any render
## does. The seal is derived to cover the innermost aperture's corners, which at the
## shipped defaults makes it 146.8 mm across — against an innermost bay that is 199.7 x
## 149.8 mm and 90 mm deep. There is no room BESIDE it (147 of a 150 mm plate) and none
## in FRONT of it: at every angle tried, -75, -100, -118, the swung disc reaches z = -85
## to -97 mm, well past the next frame's plane at -180, and its Y half-extent of 73.4 mm
## exceeds that frame's 63.9 mm optical half-height. Gilt moulding with steel poking
## through it. A hinge here is not a mechanism, it is a clipping bug with a story.
##
## So "open" SETS THE SEAL ASIDE: unscrewed, and seated flat on the widest wall band the
## picture has, out at the first level where there is actually room for it. That is
## honest about the object (a plate this size comes off, it does not fold) and it says
## the better thing anyway. Off its hole the signature is only an ornament, and without
## its signature the hole is only a hole. Each was carrying the other.
const LID_ASIDE_Y := -0.22

@export_category("The picture")
## The opening of the outermost frame — the first level's wall, and the object's width.
@export var picture_width: float = 1.20
@export var picture_height: float = 0.90
## Bench height, not gallery-plinth height, and chosen from where the seal lands rather
## than from what looks like furniture. A picture standing on the floor puts its own
## centre at half its height, which for a 1 m picture is 0.5 m — you would be looking
## DOWN into the hole. At 0.62 the seal sits at 1.145 m: just under an adult's eye line,
## the height you meet a peephole at, and the plinth top is somewhere to rest a hand
## while you lean in.
@export var plinth_height: float = 0.62
## How many nested levels. Reachable from a map as `#rings:` or `#count:` — NOT as
## `#levels:`; see apply_grid_config.
@export_range(2, 6) var levels: int = 4
## "wide" (default, legible) | "escher" (the print's own 256-per-turn ratio) | "none"
## (no twist — the control). See SPIRALS.
@export_enum("wide", "escher", "none") var spiral: String = "wide"
## "closed" (default) | "open" | "gone". Closed is the argument: the gap is signed, not
## hidden. "gone" exists so a later ruling can take the seal off without a code change —
## and taking it off is a different artifact making a different claim, which is exactly
## why it is a knob and not a decision made here.
@export_enum("closed", "open", "gone") var lid: String = "closed"
## Multiplies every dimension. Reachable as `#scale:` or `#size:`.
@export var scale_factor: float = 1.0

@export_category("The finish")
## Gallery plaster inside the picture. Pale on purpose: the aperture has to read as
## darker-or-otherwise than the wall around it from across the room, and pale plaster
## against whatever the hall puts behind the hole is the widest contrast available
## without knowing the hall.
@export var wall_colour: Color = Color(0.735, 0.715, 0.675)
## Antique gilt for every frame in the picture, including the picture's own.
@export var gild_colour: Color = Color(0.660, 0.540, 0.290)
## The case around it — dark stained wood. Never 0,0,0: a pure black albedo has no
## diffuse response left to shade with and reads as a hole cut in the room, which is a
## thing this artifact already has one of and does not need two.
@export var case_colour: Color = Color(0.125, 0.092, 0.072)

## How many levels actually got built after MIN_APERTURE_M truncation. Read by probes;
## do not set.
var built_levels: int = 0

var _warned_truncation: bool = false


func _ready() -> void:
	_build()


# ──────────────────────────────────────────────────────────────────────
#  BUILD
# ──────────────────────────────────────────────────────────────────────

func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

	var s: float = maxf(0.05, scale_factor)
	var preset: Dictionary = SPIRALS.get(spiral, SPIRALS["wide"])
	var twist: float = float(preset["twist"])
	var shrink: float = clampf(float(preset["shrink"]), 0.05, 0.92)

	var pw: float = picture_width * s
	var ph: float = picture_height * s
	var plinth_h: float = plinth_height * s
	var step: float = STEP_M * s
	var plate_t: float = 0.018 * s

	# ── the levels, sized before anything is built, because the case depth, the
	#    plinth depth and the seal radius are all derived from where the last one
	#    lands. outer[i+1] == inner[i] exactly: the reveal skirt spans the depth
	#    step and the twist between them, so no level has to over-cover the one in
	#    front of it. Over-covering was the first design and it eats the shrink — a
	#    rectangle rotated 30 degrees needs its cover 1.53x oversize on the short
	#    axis, which at shrink 0.55 leaves an effective 0.84 per level and no
	#    visible recursion at all.
	var outer_w: PackedFloat32Array = PackedFloat32Array()
	var outer_h: PackedFloat32Array = PackedFloat32Array()
	var inner_w: PackedFloat32Array = PackedFloat32Array()
	var inner_h: PackedFloat32Array = PackedFloat32Array()
	var ow: float = pw
	var oh: float = ph
	for i in clampi(levels, 2, 6):
		var iw: float = ow * shrink
		var ih: float = oh * shrink
		if iw < MIN_APERTURE_M * s and i > 1:
			if not _warned_truncation:
				_warned_truncation = true
				push_warning("print_gallery_recursion: spiral '%s' would put level %d under the %.0f mm floor (%.1f mm) — stopping at %d levels." % [spiral, i, MIN_APERTURE_M * 1000.0, iw * 1000.0, i])
			break
		outer_w.append(ow)
		outer_h.append(oh)
		inner_w.append(iw)
		inner_h.append(ih)
		ow = iw
		oh = ih
	built_levels = outer_w.size()

	var tunnel: float = float(built_levels - 1) * step
	var case_wall: float = 0.075 * s
	var case_front: float = 0.04 * s
	var case_d: float = maxf(0.36 * s, tunnel + 0.10 * s)
	var case_zc: float = case_front - case_d * 0.5
	var case_ow: float = pw + 2.0 * case_wall
	var case_oh: float = ph + 2.0 * case_wall

	var wall_mat: StandardMaterial3D = PBR.concrete(wall_colour, 0.18)
	var gild_mat: StandardMaterial3D = PBR.worn_metal(gild_colour, 0.30)
	var wood_mat: StandardMaterial3D = PBR.painted_metal(case_colour, 0.28, 0.0, 0.56)
	var stone_mat: StandardMaterial3D = PBR.concrete(Color(0.300, 0.295, 0.285), 0.34)

	# ── plinth. Origin is the BASE: y runs 0 .. plinth_h, so the artifact stands on
	#    the node origin and survives a map token that carries an explicit y and skips
	#    auto-grounding.
	var plinth_d: float = case_d + 0.14 * s
	var plinth_w: float = case_ow + 0.07 * s
	add_child(PBR.box(Vector3(0.0, plinth_h * 0.5, case_zc), Vector3(plinth_w, plinth_h, plinth_d), stone_mat, -1.0, 0.20))

	# ── the picture. Its origin is the centre of the outermost opening; every level,
	#    skirt and the seal are children of it, so the whole recursion moves as one.
	var picture := Node3D.new()
	picture.name = "Picture"
	picture.position = Vector3(0.0, plinth_h + case_oh * 0.5, 0.0)
	add_child(picture)

	# the case: a rectangular tube around the opening, closing the sides so the tunnel
	# machinery is not visible from an oblique angle. Without it the object reads as a
	# stack of receding boards, which is true and destroys the picture.
	var case_node := Node3D.new()
	case_node.name = "Case"
	case_node.position = Vector3(0.0, 0.0, case_zc)
	picture.add_child(case_node)
	_annulus(case_node, case_ow, case_oh, pw, ph, case_d, wood_mat, 0.22)

	# the picture's own gilt lip, over the case mouth. The three numbers are hoisted
	# because _build_colliders needs the same ones — the lip is the frontmost touchable
	# surface in the object and gets shapes of its own, and two copies of 0.055 is
	# exactly how a collider stops matching its mesh six months later.
	var lip_mw: float = 0.050 * s
	var lip_d: float = 0.055 * s
	var lip_zc: float = case_front + 0.0275 * s
	var lip := Node3D.new()
	lip.name = "Lip"
	picture.add_child(lip)
	_moulding(lip, pw, ph, lip_mw, lip_d, lip_zc, gild_mat)

	# ── the nested levels
	for i in built_levels:
		var z: float = -float(i) * step
		var rot: float = float(i) * twist
		var lvl := Node3D.new()
		lvl.name = "Level%d" % i
		lvl.position = Vector3(0.0, 0.0, z)
		lvl.rotation_degrees = Vector3(0.0, 0.0, rot)
		picture.add_child(lvl)

		# the depicted gallery wall at this level: an annulus, so the centre of every
		# level is a genuine opening and the hole at the end is a hole all the way.
		_annulus(lvl, outer_w[i], outer_h[i], inner_w[i], inner_h[i], plate_t, wall_mat, 0.0)

		# the frame hanging on that wall — a rebate lip, half over the opening edge, so
		# it reads as a moulding with a rebate and not as a decal on a board.
		var mw: float = minf(0.030 * s, inner_w[i] * 0.11)
		if inner_h[i] > mw * 1.6:
			_moulding(lvl, inner_w[i], inner_h[i], mw, 0.020 * s, 0.014 * s, gild_mat)

		# the reveal: wall carried back and round from this opening to the next level's
		# edge. Same size at both ends, so with twist 0 it is a plain tube and with
		# twist 30 it is a band that turns — which is the entire visual difference
		# between a mise-en-abyme and a Droste spiral.
		if i + 1 < built_levels:
			var ring_a: PackedVector3Array = _ring_points(inner_w[i], inner_h[i], z, rot, 3)
			var ring_b: PackedVector3Array = _ring_points(outer_w[i + 1], outer_h[i + 1], z - step, rot + twist, 3)
			var skirt: MeshInstance3D = _bridge(ring_a, ring_b, wall_mat)
			if skirt != null:
				skirt.name = "Reveal%d" % i
				picture.add_child(skirt)

	# ── the seal
	var last: int = built_levels - 1
	var lid_r: float = 0.5 * sqrt(inner_w[last] * inner_w[last] + inner_h[last] * inner_h[last]) * 1.07
	var lid_t: float = maxf(0.009 * s, lid_r * 0.11)
	if lid != "gone":
		var mount := Node3D.new()
		mount.name = "LidMount"
		if lid == "open":
			# set aside on the outermost wall band — the only surface in the picture
			# wide enough to take it. Band centre is midway between that level's
			# opening and its outer edge, so this follows `spiral` instead of being a
			# hand-placed number that goes wrong the moment somebody changes shrink.
			mount.position = Vector3(
				(inner_w[0] + outer_w[0]) * 0.25,
				inner_h[0] * LID_ASIDE_Y,
				plate_t * 0.5 + lid_t * 0.5 + 0.004 * s)
		else:
			# on its seat: proud of the innermost plate by enough to clear that level's
			# gilt moulding, so it reads as applied afterwards rather than inlaid.
			mount.position = Vector3(0.0, 0.0, -float(last) * step + 0.036 * s)
		picture.add_child(mount)
		mount.add_child(_seal(lid_r, lid_t))

	var body: StaticBody3D = _build_colliders(plinth_w, plinth_h, plinth_d, case_ow, case_oh, case_wall, case_d, case_zc)

	# THE LIP HAD NO SHAPE, and it is the frontmost thing a hand meets. Computed at the
	# shipped defaults: the four gilt bars stand 55 mm proud of the case mouth (z 0.040 ..
	# 0.095) while the case shell's collision stops dead at 0.040, and the band runs from
	# y 0.670 to 1.620 — straight through the height a visitor leans in at. 55 mm of ghost
	# across the most touchable surface on the object, which is the pink_gun fault in a
	# milder key.
	#
	# Four shapes matching the four bars exactly, and the argument survives intact. The
	# side bars occupy |x| 0.575 .. 0.625 over the opening's height, the top and bottom
	# |y| 0.425 .. 0.475 over its width: a 25 mm rebate rim on an opening 1.15 x 0.85 m,
	# while the hole that carries the claim is 270 mm further back, 110 mm across, and
	# still has no collider within a quarter of a metre of it.
	var lip_y: float = plinth_h + case_oh * 0.5
	_box_shape(body, Vector3(0.0, lip_y + ph * 0.5, lip_zc), Vector3(pw + lip_mw, lip_mw, lip_d))
	_box_shape(body, Vector3(0.0, lip_y - ph * 0.5, lip_zc), Vector3(pw + lip_mw, lip_mw, lip_d))
	_box_shape(body, Vector3(pw * 0.5, lip_y, lip_zc), Vector3(lip_mw, ph - lip_mw, lip_d))
	_box_shape(body, Vector3(-pw * 0.5, lip_y, lip_zc), Vector3(lip_mw, ph - lip_mw, lip_d))


# ──────────────────────────────────────────────────────────────────────
#  PARTS
# ──────────────────────────────────────────────────────────────────────

## A rectangular annulus from four boxes: top and bottom span the full width, left and
## right fill the remaining height. They meet edge to edge with no overlap, so a
## translucent or vertex-coloured material would not double up along the joins.
func _annulus(parent: Node3D, ow: float, oh: float, iw: float, ih: float,
		t: float, mat: Material, wear: float) -> void:
	var ry: float = (oh - ih) * 0.5
	var rx: float = (ow - iw) * 0.5
	if ry > 0.0008:
		parent.add_child(PBR.box(Vector3(0.0, (ih + ry) * 0.5, 0.0), Vector3(ow, ry, t), mat, -1.0, wear))
		parent.add_child(PBR.box(Vector3(0.0, -(ih + ry) * 0.5, 0.0), Vector3(ow, ry, t), mat, -1.0, wear))
	if rx > 0.0008:
		parent.add_child(PBR.box(Vector3((iw + rx) * 0.5, 0.0, 0.0), Vector3(rx, ih, t), mat, -1.0, wear))
		parent.add_child(PBR.box(Vector3(-(iw + rx) * 0.5, 0.0, 0.0), Vector3(rx, ih, t), mat, -1.0, wear))


## A moulding centred ON the opening edge, so half of it overhangs into the opening.
## Top and bottom run long, left and right are shortened by one moulding width — they
## meet exactly, no mitre and no gap.
func _moulding(parent: Node3D, iw: float, ih: float, mw: float, d: float,
		zc: float, mat: Material) -> void:
	if mw <= 0.0008 or ih <= mw * 1.2:
		return
	parent.add_child(PBR.box(Vector3(0.0, ih * 0.5, zc), Vector3(iw + mw, mw, d), mat))
	parent.add_child(PBR.box(Vector3(0.0, -ih * 0.5, zc), Vector3(iw + mw, mw, d), mat))
	parent.add_child(PBR.box(Vector3(iw * 0.5, 0.0, zc), Vector3(mw, ih - mw, d), mat))
	parent.add_child(PBR.box(Vector3(-iw * 0.5, 0.0, zc), Vector3(mw, ih - mw, d), mat))


## Points around a rectangle in the picture plane, rotated about Z, in COUNTER-clockwise
## order seen from +Z. The order is load-bearing: _bridge derives its normals from it,
## and reversing it turns the reveal inside out.
func _ring_points(w: float, h: float, z: float, rot_deg: float, per_side: int) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var hw: float = w * 0.5
	var hh: float = h * 0.5
	var corners: Array[Vector2] = [
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	]
	var a: float = deg_to_rad(rot_deg)
	var ca: float = cos(a)
	var sa: float = sin(a)
	for si in 4:
		var p0: Vector2 = corners[si]
		var p1: Vector2 = corners[(si + 1) % 4]
		for k in per_side:
			var q: Vector2 = p0.lerp(p1, float(k) / float(per_side))
			pts.append(Vector3(q.x * ca - q.y * sa, q.x * sa + q.y * ca, z))
	return pts


## Bridge two rings into a band. Quads are non-planar wherever the twist is non-zero,
## which is why each side is sampled three times instead of once — four corner quads
## fold visibly at 30 degrees and the reveal creases.
func _bridge(a: PackedVector3Array, b: PackedVector3Array, mat: Material) -> MeshInstance3D:
	var n: int = a.size()
	if n < 3 or b.size() != n:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in n:
		var j2: int = (j + 1) % n
		var u0: float = float(j) / float(n)
		var u1: float = float(j + 1) / float(n)
		_tri(st, a[j], b[j], a[j2], Vector2(u0, 0.0), Vector2(u0, 1.0), Vector2(u1, 0.0))
		_tri(st, a[j2], b[j], b[j2], Vector2(u1, 0.0), Vector2(u0, 1.0), Vector2(u1, 1.0))
	# UVs are set above and tangents generated here because PbrKit's materials all carry
	# a normal map, and a hand-built surface without tangents ignores it in silence.
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


## Godot winds FRONT faces clockwise as seen from the visible side, so for vertices
## emitted p, q, r the visible-side normal is cross(r - p, q - p) — not the textbook
## cross(q - p, r - p). Checked by hand against a triangle in the XY plane: (0,1,0) ->
## (1,-1,0) -> (-1,-1,0) is clockwise seen from +Z, and cross(r-p, q-p) comes out +Z,
## which is the side it is visible from. With the two swapped, every reveal in this
## artifact renders inside out and the tunnel looks like a solid twisted post.
func _tri(st: SurfaceTool, p: Vector3, q: Vector3, r: Vector3,
		up: Vector2, uq: Vector2, ur: Vector2) -> void:
	var nrm: Vector3 = (r - p).cross(q - p)
	if nrm.length_squared() < 1e-12:
		return
	nrm = nrm.normalized()
	st.set_normal(nrm)
	st.set_uv(up)
	st.add_vertex(p)
	st.set_normal(nrm)
	st.set_uv(uq)
	st.add_vertex(q)
	st.set_normal(nrm)
	st.set_uv(ur)
	st.add_vertex(r)


## THE SEAL. Everything here is doing one job: making the plate read as struck metal
## somebody chose to put there, and never as a patch over damage. Damage is flat, dull
## and the same colour as what it covers. So: a different metal from the gilt frames
## (silver against gold, the giveaway that it was applied later), a turned bead round
## the rim, a field of chased radial flutes, and a raised mark at the middle.
##
## The mark is a square spiral of five bars, each 0.68 of the last, turning inward — and
## it stops, because it has to stop, four turns short of a centre. It is the same figure
## as the picture it is covering, at the same scale relation, failing in the same place.
## An artist who signs the hole in his construction with a smaller copy of the
## construction is not decorating; he is stating the case. That was the whole reason to
## put a mark here rather than a plain milled cap.
func _seal(r: float, t: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Lid"

	var body_mat: StandardMaterial3D = PBR.machined_metal(PBR.STEEL, 0.17, 0.07)
	var mark_mat: StandardMaterial3D = PBR.machined_metal(PBR.CHROME, 0.09, 0.02)

	# plate. chamfer_cylinder lathes about +Y and is centred on its origin; +90 about X
	# stands it up facing +Z, the way the rest of the artifact faces.
	var plate: MeshInstance3D = PBR.chamfer_cylinder(r, t, -1.0, body_mat, 40, 0.05)
	plate.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	root.add_child(plate)

	# turned bead at the rim
	var bead := MeshInstance3D.new()
	bead.name = "Bead"
	var tor := TorusMesh.new()
	tor.inner_radius = r * 0.855
	tor.outer_radius = r
	tor.rings = 40
	tor.ring_segments = 8
	bead.mesh = tor
	bead.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	bead.position = Vector3(0.0, 0.0, t * 0.5)
	bead.material_override = mark_mat
	root.add_child(bead)

	# chased flutes. Long axis along local +X, then rotated about Z, so the box points
	# radially with no trigonometry in the size.
	var flutes: int = 24
	var f_len: float = r * 0.40
	var f_wid: float = maxf(r * 0.055, 0.0012)
	var f_mid: float = r * 0.655
	for k in flutes:
		var ang: float = TAU * float(k) / float(flutes)
		var fl: MeshInstance3D = PBR.box(Vector3.ZERO, Vector3(f_len, f_wid, t * 0.32), body_mat)
		fl.position = Vector3(f_mid * cos(ang), f_mid * sin(ang), t * 0.5 + t * 0.14)
		fl.rotation_degrees = Vector3(0.0, 0.0, rad_to_deg(ang))
		root.add_child(fl)

	# the mark: a square spiral walking inward and stopping
	var arm: float = r * 0.56
	var bw: float = maxf(r * 0.062, 0.0010)
	var pos := Vector2(-arm * 0.5, -arm * 0.5)
	var dir := Vector2(1.0, 0.0)
	var seg: float = arm
	for _turn in 5:
		var mid: Vector2 = pos + dir * (seg * 0.5)
		var size := Vector3(absf(dir.x) * seg + absf(dir.y) * bw,
			absf(dir.y) * seg + absf(dir.x) * bw, t * 0.30)
		var bar: MeshInstance3D = PBR.box(Vector3(mid.x, mid.y, t * 0.5 + t * 0.16), size, mark_mat)
		root.add_child(bar)
		pos += dir * seg
		dir = Vector2(-dir.y, dir.x)
		seg *= 0.68

	# The plate is touchable, so it is grabbable where it LOOKS grabbable. A cylinder
	# shape matched to the plate, not a default sphere at the origin — that mismatch is
	# how pink_gun ended up with a 2 cm target under a 30 cm body.
	var body := StaticBody3D.new()
	body.name = "SealBody"
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = r
	cyl.height = maxf(t * 1.6, 0.008)
	cs.shape = cyl
	cs.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	body.add_child(cs)
	root.add_child(body)

	return root


## THE COLLIDER IS THE FRAME AND THE SEAL, AND DELIBERATELY NOT THE APERTURE.
##
## Returns the body so the caller can add the gilt lip's four shapes, which need the
## moulding's own numbers and would otherwise be a second copy of them here.
##
## A single box round the whole picture would have been one shape instead of five, and
## it would have put an invisible wall across the hole — a hand reaching in would stop
## at nothing, a pointer would land on nothing, and the one claim this object makes
## would be false everywhere except in a photograph. So the case walls and the plinth
## are solid, the recess is open, and with the lid open a laser goes straight through
## the artwork and hits whatever is behind it. That is not a shortcut; it is the
## argument, in physics.
func _build_colliders(plinth_w: float, plinth_h: float, plinth_d: float,
		case_ow: float, case_oh: float, case_wall: float,
		case_d: float, case_zc: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Body"
	add_child(body)

	var py: float = plinth_h + case_oh * 0.5

	_box_shape(body, Vector3(0.0, plinth_h * 0.5, case_zc), Vector3(plinth_w, plinth_h, plinth_d))
	_box_shape(body, Vector3(-(case_ow - case_wall) * 0.5, py, case_zc), Vector3(case_wall, case_oh, case_d))
	_box_shape(body, Vector3((case_ow - case_wall) * 0.5, py, case_zc), Vector3(case_wall, case_oh, case_d))
	_box_shape(body, Vector3(0.0, py + (case_oh - case_wall) * 0.5, case_zc), Vector3(case_ow, case_wall, case_d))
	_box_shape(body, Vector3(0.0, py - (case_oh - case_wall) * 0.5, case_zc), Vector3(case_ow, case_wall, case_d))

	return body


func _box_shape(body: StaticBody3D, centre: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = size
	cs.shape = bx
	cs.position = centre
	body.add_child(cs)


# ──────────────────────────────────────────────────────────────────────
#  GRID CONFIG
# ──────────────────────────────────────────────────────────────────────

## Called by the grid with a map token's `#key:value` pairs. Four keys, and every one of
## them is either a WORD or a name the grid already knows is a parameter:
##
##   #lid:closed | #lid:open | #lid:gone
##   #spiral:wide | #spiral:escher | #spiral:none
##   #rings:<2..6>   (also #count:) — how many nested levels
##   #scale:<0.2..4> (also #size:)
##
## `#levels:4` DOES NOT WORK FROM A MAP and the key is accepted here only for callers
## that set it directly. "levels" is not in GridInteractablesComponent.CONFIG_PARAM_NAMES,
## so the grid reads a number under it as the tutorial's positional shorthand: the map
## would look right, this node's yaw would quietly become four degrees, and the level
## count would stay at its default. Six walking creatures lost a session to exactly that
## in VFM_09_Legs. Use #rings.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("lid"):
		lid = _as_lid(config_data["lid"])
	if config_data.has("spiral"):
		spiral = _as_spiral(config_data["spiral"])
	# A BOOL HERE IS A TOKEN THAT WENT WRONG, AND ACCEPTING IT MAKES IT WORSE. Two paths
	# deliver one: a valueless `#rings`, and `#levels:4` from a map — the shorthand branch
	# stores config_data["levels"] = true and puts the 4 in the yaw. int(true) is 1, which
	# clamps to 2, so before this guard a map reading `#levels:4` built a TWO-level picture
	# and quietly threw away half the recursion. Refusing the bool leaves the default
	# standing, which is a wrong map that still shows the argument rather than one that
	# silently doesn't.
	for k in ["rings", "count", "levels"]:
		if config_data.has(k) and not (config_data[k] is bool):
			levels = clampi(int(config_data[k]), 2, 6)
	for k in ["scale", "size"]:
		if config_data.has(k) and not (config_data[k] is bool):
			scale_factor = clampf(float(config_data[k]), 0.2, 4.0)
	if is_inside_tree():
		_warned_truncation = false
		_build()


## Word-valued, so it survives the shorthand. "0"/"1"/"true" are accepted anyway because
## somebody will write them, and bool("0") is TRUE in GDScript — a plain cast here would
## open every lid that was explicitly asked to stay shut.
func _as_lid(v) -> String:
	var t: String = str(v).strip_edges().to_lower()
	if t in ["closed", "shut", "0", "false", "no"]:
		return "closed"
	if t in ["open", "lifted", "1", "true", "yes"]:
		return "open"
	if t in ["gone", "removed", "none"]:
		return "gone"
	# "on" and "off" are NOT in those lists on purpose: on a lid they read as "open"
	# just as naturally as they read as "in place", and a key that means two opposite
	# things to two readers is worse than a key that refuses.
	push_warning("print_gallery_recursion: unknown lid '%s' — keeping closed." % t)
	return "closed"


func _as_spiral(v) -> String:
	var t: String = str(v).strip_edges().to_lower()
	if SPIRALS.has(t):
		return t
	if t in ["flat", "straight", "off"]:
		return "none"
	push_warning("print_gallery_recursion: unknown spiral '%s' — keeping wide." % t)
	return "wide"
