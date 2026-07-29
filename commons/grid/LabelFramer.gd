# LabelFramer.gd — TEXT WANTS A BODY TOO (the artifact_readout_screen truth,
# applied systemically). Palle: all hanging Label3D must become 2D-in-3D
# boards or plates INTEGRATED in the wrapper or artifact.
#
# 945 billboarded Label3D sites across 557 scripts make per-file migration
# the wrong shape — so, like Wang tiles and the em-square, we standardize
# the MEETING POINT: at spawn, GridInteractablesComponent walks the artifact
# and every HANGING label (billboard enabled = the hanging signal) is framed
# in place — billboard off, a readout-style bezel + panel added behind the
# glyphs. The Label3D node itself survives untouched in the tree, so artifact
# scripts that live-update `.text` keep working.
#
# NOT touched: non-billboard labels (they lie on bodies — axis ticks,
# engraved values — already integrated); empty labels; labels inside an
# artifact that opts out (config framed_labels:false -> meta).
# Safe to call repeatedly (per-label meta marker).
#
# ── 2026-07-29: ONE PLATE PER STACK, AND THE OUTLINE STOPS INFLATING IT ──
#
# Two faults, one cause: the frame was sized and placed PER LABEL, so an
# artifact with a title, a caption and a value became three separate slabs
# floating at three widths — and each slab was 0.10 m bigger than its text
# needed, so the three shingled into each other.
#
# THE OUTLINE. embodied_prop._billboard_label sets outline_size = 10 at the
# default pixel_size 0.005, and Label3D.get_aabb() INCLUDES the outline glyph
# quads — 0.05 m of it on every side, so +0.10 m on both width and height of
# every panel. Nine artifacts were then hand-tuned against the smaller figure
# they assumed, and their stacks still overlapped. The outline is there to keep
# glyphs legible against an unknown background; the moment this framer puts an
# opaque panel behind them, that job is done and the outline is only inflating
# the thing it is drawn on. So framing now ZEROES the outline and measures
# after — smaller plates, better contrast, and the per-artifact spacing numbers
# become true instead of 0.10 m optimistic.
#
# THE STACK. Labels that share a parent, a facing and a column are one caption
# block, not three captions. They now get ONE panel and ONE bezel spanning the
# whole group, so the artifact reads as a single object carrying a nameplate
# rather than a body orbited by loose cards. A lone label still gets its own
# plate parented to the label itself, so live repositioning keeps working.
extends RefCounted

const PANEL := Color(0.12, 0.12, 0.135)      # Rams anthracite (readout screen_bg)
const BEZEL := Color(0.70, 0.68, 0.64)       # worn painted metal (readout frame)
const PAD_W := 0.05
const PAD_H := 0.035
const MIN_W := 0.18
const MIN_H := 0.09

## Two labels belong to one plate when their columns line up within this much
## (metres) and the vertical space between them is no wider than MERGE_GAP.
## Deliberately tight: this merges a caption stack, never two labels that happen
## to sit on opposite ends of the same instrument.
const MERGE_ALIGN := 0.18
const MERGE_GAP := 0.16
## Quantisation for the grouping key. Labels facing different ways, or standing
## in different columns, are different blocks.
const KEY_Q := 0.05


static func frame_labels(root: Node) -> int:
	if not is_instance_valid(root):
		return 0
	if root is Node3D and root.has_meta("config_framed_labels") \
			and str(root.get_meta("config_framed_labels")).to_lower() in ["false", "0", "off"]:
		return 0

	var found: Array[Label3D] = []
	var stack: Array = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is Label3D and _framable(cur as Label3D):
			found.append(cur as Label3D)
		for c in cur.get_children():
			stack.append(c)
	if found.is_empty():
		return 0

	# Measure as we prepare, and NEVER re-measure afterwards. Label3D rebuilds its
	# mesh lazily, so get_aabb() called after outline_size is changed returns the
	# OLD mesh's extents — the first version of this did exactly that and every
	# plate collapsed onto the MIN_W x MIN_H floor. The outline is removed
	# arithmetically instead, which is exact and synchronous.
	var metrics: Array = []
	for l in found:
		metrics.append(_prepare(l))

	for group in _group(metrics):
		if group.size() == 1:
			_plate_single(group[0])
		else:
			_plate_group(group)
	return found.size()


static func _framable(label: Label3D) -> bool:
	if label.has_meta("label_framed"):
		return false
	if label.billboard == BaseMaterial3D.BILLBOARD_DISABLED:
		return false                     # lies on a body — already integrated
	return str(label.text).strip_edges() != ""


## Mark, unbillboard, measure, drop the now-redundant outline, lift off the body.
##
## Returns the label's extents with the outline REMOVED, in both label space (for
## a lone plate, which parents to the label) and parent space (for a shared one).
## Measuring here and passing the numbers on is not tidiness — it is the only way
## to get them right, because the AABB stops being trustworthy the moment we
## touch outline_size.
static func _prepare(label: Label3D) -> Dictionary:
	label.set_meta("label_framed", true)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# TEXT WITH A BODY OCCLUDES LIKE A BODY. embodied_prop._billboard_label sets
	# no_depth_test = true — correct for a see-through caption that must stay readable
	# through the object it names, and wrong the moment this framer hands it an opaque
	# panel. Left alone the assembly is incoherent: the panel depth-tests and is hidden
	# behind intervening geometry while its own glyphs draw on top of everything,
	# so the words float free of the plate they are printed on. Only labels THIS
	# function frames are touched; the 646 unframed call sites keep their own choice.
	label.no_depth_test = false

	# DO NOT USE get_aabb() HERE. A billboarded Label3D reports a CUBE — the text's
	# diagonal on all three axes, so it never culls whichever way it spins — and the
	# value is still cached from before the line above turned billboarding off.
	# Measured live: "MICROSTATE COUNTER" returns (1.56, 1.56, 1.56) for a string
	# about 1.5 m wide and 0.14 m tall. Sizing a panel from that is why framed plates
	# came out as slabs that swallowed the artifact behind them — the occlusion was
	# never inherent to framing, it was this. Ask the font instead: exact, synchronous,
	# and indifferent to when the mesh happens to rebuild.
	var f: Font = label.font
	if f == null:
		f = ThemeDB.fallback_font
	var px: Vector2 = f.get_multiline_string_size(
		label.text, label.horizontal_alignment, label.width, label.font_size)
	var lw: float = px.x * label.pixel_size
	var lh: float = px.y * label.pixel_size

	# The panel behind the glyphs is the contrast now; keeping the outline as
	# well would only widen the thing it is drawn on — see the header.
	label.outline_size = 0
	# hanging labels hover just off their body — the panel behind the glyphs
	# would embed into it. Nudge the whole assembly forward along its facing.
	label.position += label.transform.basis.z * 0.035

	# Label3D centres its text block on its own origin (offset defaults to zero and
	# both alignments default to centre), so the box is centred at the node.
	var lcx: float = label.offset.x * label.pixel_size
	var lcy: float = label.offset.y * label.pixel_size
	return {
		"label": label,
		# label space, for the single-label plate
		"lw": lw, "lh": lh, "lcx": lcx, "lcy": lcy,
		# parent space, for a shared plate
		"left": label.position.x + lcx - lw * 0.5,
		"right": label.position.x + lcx + lw * 0.5,
		"bottom": label.position.y + lcy - lh * 0.5,
		"top": label.position.y + lcy + lh * 0.5,
		"z": label.position.z,
	}


## Bucket by parent + facing + column, then split each bucket wherever the
## vertical run breaks. Returns a list of groups, each at least one label.
static func _group(metrics: Array) -> Array:
	var buckets: Dictionary = {}
	for m in metrics:
		var l: Label3D = m["label"]
		var p: Node = l.get_parent()
		var pid: int = p.get_instance_id() if p != null else 0
		var b: Basis = l.transform.basis
		var key: String = "%d|%.2f_%.2f_%.2f|%d|%d" % [
			pid, b.z.x, b.z.y, b.z.z,
			int(round(l.position.x / KEY_Q)), int(round(l.position.z / KEY_Q))]
		if not buckets.has(key):
			buckets[key] = []
		(buckets[key] as Array).append(m)

	var groups: Array = []
	for key in buckets.keys():
		var members: Array = buckets[key]
		if members.size() == 1:
			groups.append(members)
			continue
		# Top-down, so a run reads the way it is written.
		members.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["top"]) > float(b["top"]))
		var run: Array = [members[0]]
		for i in range(1, members.size()):
			var prev: Dictionary = run[run.size() - 1]
			var next: Dictionary = members[i]
			# Columns must line up AND the gap must be a caption gap, not a
			# span across the artifact.
			var prev_cx: float = (float(prev["left"]) + float(prev["right"])) * 0.5
			var next_cx: float = (float(next["left"]) + float(next["right"])) * 0.5
			var aligned: bool = absf(next_cx - prev_cx) <= MERGE_ALIGN
			var gap: float = float(prev["bottom"]) - float(next["top"])
			if aligned and gap <= MERGE_GAP:
				run.append(next)
			else:
				groups.append(run)
				run = [next]
		groups.append(run)
	return groups


## A lone label keeps the original shape: plates parented to the label itself,
## in LABEL space, so a script that moves the label carries its frame along.
static func _plate_single(m: Dictionary) -> void:
	var label: Label3D = m["label"]
	var w: float = maxf(float(m["lw"]) + PAD_W * 2.0, MIN_W)
	var h: float = maxf(float(m["lh"]) + PAD_H * 2.0, MIN_H)
	var cx: float = float(m["lcx"])
	var cy: float = float(m["lcy"])
	# the body: panel just behind the glyphs, bezel just behind the panel —
	# children of the label so they follow any live repositioning.
	label.add_child(_plate(Vector3(w, h, 0.012), Vector3(cx, cy, -0.010), PANEL))
	label.add_child(_plate(Vector3(w + 0.03, h + 0.03, 0.010),
			Vector3(cx, cy, -0.018), BEZEL))


## A stack gets ONE plate spanning all of it, parented to the shared parent so
## the block is a single piece of the artifact rather than one card per line.
static func _plate_group(group: Array) -> void:
	var first: Label3D = group[0]["label"]
	var parent: Node = first.get_parent()
	if parent == null or not (parent is Node3D):
		# Nothing to hang a shared plate on — fall back to one each.
		for m in group:
			_plate_single(m)
		return

	var left: float = INF
	var right: float = -INF
	var top: float = -INF
	var bottom: float = INF
	var z_back: float = INF
	for item in group:
		var m: Dictionary = item
		left = minf(left, float(m["left"]))
		right = maxf(right, float(m["right"]))
		bottom = minf(bottom, float(m["bottom"]))
		top = maxf(top, float(m["top"]))
		z_back = minf(z_back, float(m["z"]))

	var w: float = maxf(right - left + PAD_W * 2.0, MIN_W)
	var h: float = maxf(top - bottom + PAD_H * 2.0, MIN_H)
	var cx: float = (left + right) * 0.5
	var cy: float = (bottom + top) * 0.5

	var panel := _plate(Vector3(w, h, 0.012), Vector3(cx, cy, z_back - 0.010), PANEL)
	var bezel := _plate(Vector3(w + 0.03, h + 0.03, 0.010),
			Vector3(cx, cy, z_back - 0.018), BEZEL)
	# Carry the group's facing, which the bucket key already proved is shared.
	panel.basis = first.transform.basis
	bezel.basis = first.transform.basis
	(parent as Node3D).add_child(panel)
	(parent as Node3D).add_child(bezel)


static func _plate(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	# Marked so tooling can tell the caption furniture from the artifact's own
	# body — probe_label_placement uses it to find plates that cross the thing
	# they are captioning.
	mi.set_meta("label_plate", true)
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.55
	mi.material_override = m
	mi.position = pos
	return mi
