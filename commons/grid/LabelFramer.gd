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
extends RefCounted

const PANEL := Color(0.12, 0.12, 0.135)      # Rams anthracite (readout screen_bg)
const BEZEL := Color(0.70, 0.68, 0.64)       # worn painted metal (readout frame)
const PAD_W := 0.05
const PAD_H := 0.035
const MIN_W := 0.18
const MIN_H := 0.09


static func frame_labels(root: Node) -> int:
	if not is_instance_valid(root):
		return 0
	if root is Node3D and root.has_meta("config_framed_labels") \
			and str(root.get_meta("config_framed_labels")).to_lower() in ["false", "0", "off"]:
		return 0
	var framed := 0
	var stack: Array = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is Label3D:
			if _frame_one(cur):
				framed += 1
		for c in cur.get_children():
			stack.append(c)
	return framed


static func _frame_one(label: Label3D) -> bool:
	if label.has_meta("label_framed"):
		return false
	if label.billboard == BaseMaterial3D.BILLBOARD_DISABLED:
		return false                     # lies on a body — already integrated
	if str(label.text).strip_edges() == "":
		return false
	label.set_meta("label_framed", true)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# hanging labels hover just off their body — the panel behind the glyphs
	# would embed into it. Nudge the whole assembly forward along its facing.
	label.position += label.transform.basis.z * 0.035
	var aabb := label.get_aabb()
	var w: float = maxf(aabb.size.x + PAD_W * 2.0, MIN_W)
	var h: float = maxf(aabb.size.y + PAD_H * 2.0, MIN_H)
	var cx: float = aabb.position.x + aabb.size.x * 0.5
	var cy: float = aabb.position.y + aabb.size.y * 0.5
	# the body: panel just behind the glyphs, bezel just behind the panel —
	# children of the label so they follow any live repositioning.
	label.add_child(_plate(Vector3(w, h, 0.012), Vector3(cx, cy, -0.010), PANEL))
	label.add_child(_plate(Vector3(w + 0.03, h + 0.03, 0.010),
			Vector3(cx, cy, -0.018), BEZEL))
	return true


static func _plate(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.55
	mi.material_override = m
	mi.position = pos
	return mi
