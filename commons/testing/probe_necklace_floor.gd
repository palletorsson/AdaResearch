extends SceneTree
## probe_necklace_floor.gd — WHERE ARE THE CAPTIONS?
##
## The beads hang BELOW the string (STRING_Y 1.52, plate at local y -0.80, the
## token caption at -1.62 and the subtitle at -1.98). That puts both captions
## near or under y = 0, and the stage lays a 140 x 0.12 x 26 m floor slab there.
## This measures it: every Label3D's global Y against the floor slab's real AABB,
## and a segment test from the camera to each label against that AABB.
##
## Nothing is asserted from arithmetic — the transforms are read off the live tree.

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const TRIAL_OPS := "user://_audit4_necklace_ops.json"


func _initialize() -> void:
	_run()


func _run() -> void:
	var report := ProjectSettings.globalize_path("user://probe_necklace_floor.json")
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--report="):
			report = str(a).split("=", true, 1)[1]

	var ps := load(SCENE) as PackedScene
	var n: Node = ps.instantiate()
	n.set("ops_path", TRIAL_OPS)
	root.add_child(n)
	await process_frame
	await process_frame

	var cam: Camera3D = null
	var slabs: Array = []
	for c in n.get_children():
		if c is Camera3D:
			cam = c as Camera3D
		elif c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh:
			var mi := c as MeshInstance3D
			var sz: Vector3 = (mi.mesh as BoxMesh).size
			if sz.x > 50.0:      # the stage slabs, not a bead part
				slabs.append({"node": mi, "aabb": mi.global_transform * mi.get_aabb(),
					"size": [sz.x, sz.y, sz.z],
					"pos": [mi.global_position.x, mi.global_position.y, mi.global_position.z]})

	var floor_aabb: AABB = AABB()
	var floor_desc: Dictionary = {}
	for s in slabs:
		var sd: Dictionary = s
		var ab: AABB = sd["aabb"]
		if ab.size.y < 1.0 and ab.position.y < 1.0:     # the ground, not the backdrop
			floor_aabb = ab
			floor_desc = {"size": sd["size"], "pos": sd["pos"],
				"aabb_min": [ab.position.x, ab.position.y, ab.position.z],
				"aabb_max": [ab.end.x, ab.end.y, ab.end.z]}

	var rows: Array = []
	var buried := 0
	var occluded := 0
	var total := 0
	for i in range(0, 10):
		var anchor: Node3D = null
		for c in n.get_children():
			if c is Node3D and str(c.name).begins_with("bead_%d_" % i):
				anchor = c as Node3D
				break
		if anchor == null:
			continue
		var parts: Array = []
		for g in anchor.get_children():
			var label := ""
			if g is Label3D:
				label = "Label3D:" + str((g as Label3D).text).replace("\n", " ").substr(0, 24)
			elif g is Sprite3D:
				label = "Sprite3D(tile)"
			elif g is MeshInstance3D:
				var m := (g as MeshInstance3D).mesh
				label = "Mesh:" + (m.get_class() if m != null else "?")
			else:
				continue
			var g3 := g as Node3D
			var p: Vector3 = g3.global_position
			var below: bool = p.y < floor_aabb.end.y
			var hit: bool = _seg_hits(cam.global_position, p, floor_aabb)
			total += 1
			if below:
				buried += 1
			if hit:
				occluded += 1
			parts.append({
				"part": label, "world_y": snappedf(p.y, 0.01),
				"below_floor_top": below, "floor_between_camera_and_it": hit,
				"visible_flag": g3.visible,
			})
		rows.append({"bead": i, "lookup": str(n.call("lookup_at", i)),
			"anchor_y": snappedf(anchor.global_position.y, 0.01), "parts": parts})

	var doc := {
		"floor": floor_desc,
		"stage_slabs": slabs.size(),
		"camera_y": cam.global_position.y,
		"parts_tested": total,
		"parts_below_the_floor_surface": buried,
		"parts_the_floor_stands_in_front_of": occluded,
		"pass": occluded == 0,
		"beads": rows,
	}
	var f := FileAccess.open(report, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(doc, "  ", false))
		f.close()
	quit(0)


## Does the segment a→b cross the box? Slab method, no physics needed.
func _seg_hits(a: Vector3, b: Vector3, box: AABB) -> bool:
	var d: Vector3 = b - a
	var t0 := 0.0
	var t1 := 1.0
	for axis in 3:
		var o: float = a[axis]
		var dd: float = d[axis]
		var lo: float = box.position[axis]
		var hi: float = box.end[axis]
		if absf(dd) < 1.0e-9:
			if o < lo or o > hi:
				return false
			continue
		var ta: float = (lo - o) / dd
		var tb: float = (hi - o) / dd
		if ta > tb:
			var sw := ta
			ta = tb
			tb = sw
		t0 = maxf(t0, ta)
		t1 = minf(t1, tb)
		if t0 > t1:
			return false
	return true
