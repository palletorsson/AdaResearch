extends SceneTree
## WHAT THE SPIDER IS MADE OF (2026-08-26, Palle: "trace the spider form back to
## point and line via force and composition and weaving").
##
## A file-read tells you what the code MEANS to build. This boots the deployed
## artifact and counts what is actually STANDING: every mesh by primitive class,
## every radius and height, the chain of one leg, and then eight seconds of the
## four foot positions sampled at 20 Hz — because whether the animal WEAVES is
## not a question about the source, it is a question about whether the traces
## its feet leave on the floor cross each other.
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const OUT := "res://ada_run/spider_census.json"
const TXT := "res://ada_run/spider_census.txt"
const HZ := 0.05
const SECONDS := 8.0

var _r := {}
var _lines: Array = []

func _initialize() -> void: call_deferred("_run")

func _say(s: String) -> void:
	_lines.append(s)
	print(s)

## every node under n, with its class and — for anything that draws — the
## primitive it draws and the numbers that size it
func _walk(n: Node, depth: int, acc: Dictionary) -> void:
	var cls := n.get_class()
	acc["classes"][cls] = int(acc["classes"].get(cls, 0)) + 1
	if n is MeshInstance3D:
		var m: Mesh = (n as MeshInstance3D).mesh
		if m != null:
			var mc := m.get_class()
			acc["meshes"][mc] = int(acc["meshes"].get(mc, 0)) + 1
			var d := {"node": n.name, "mesh": mc}
			if m is SphereMesh:
				d["radius"] = (m as SphereMesh).radius
				d["height"] = (m as SphereMesh).height
			elif m is CylinderMesh:
				d["top"] = (m as CylinderMesh).top_radius
				d["bottom"] = (m as CylinderMesh).bottom_radius
				d["height"] = (m as CylinderMesh).height
			elif m is BoxMesh:
				d["size"] = str((m as BoxMesh).size)
			elif m is CapsuleMesh:
				d["radius"] = (m as CapsuleMesh).radius
				d["height"] = (m as CapsuleMesh).height
			acc["parts"].append(d)
	elif cls.begins_with("CSG"):
		acc["csg"][cls] = int(acc["csg"].get(cls, 0)) + 1
		var d2 := {"node": n.name, "csg": cls}
		if n.get("radius") != null: d2["radius"] = n.get("radius")
		if n.get("height") != null: d2["height"] = n.get("height")
		acc["parts"].append(d2)
	for c in n.get_children():
		_walk(c, depth + 1, acc)

func _chain(n: Node, out: Array, depth: int) -> void:
	out.append("  ".repeat(depth) + n.name + "  [" + n.get_class() + "]")
	for c in n.get_children():
		if out.size() > 60: return
		_chain(c, out, depth + 1)

func _run() -> void:
	var st := Node3D.new(); get_root().add_child(st)
	var fb := StaticBody3D.new()
	var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(120, 0.4, 120); cs.shape = bx; cs.position = Vector3(0, -0.2, 0)
	fb.add_child(cs); st.add_child(fb)
	var w := CharacterBody3D.new(); w.name = "Walker"; w.add_to_group("em_walker")
	st.add_child(w); w.global_position = Vector3(0, 0, -9)
	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	st.add_child(c); c.global_position = Vector3.ZERO
	await create_timer(1.4).timeout

	# ── THE CENSUS ─────────────────────────────────────────────────────────
	var acc := {"classes": {}, "meshes": {}, "csg": {}, "parts": []}
	_walk(c, 0, acc)
	_say("SPIDER CENSUS — the deployed head_crab at its shipped defaults")
	_say("")
	_say("nodes by class:")
	var ck: Array = acc["classes"].keys(); ck.sort()
	for k in ck: _say("  %-28s %d" % [k, acc["classes"][k]])
	_say("")
	_say("mesh primitives actually standing:")
	var mk: Array = acc["meshes"].keys(); mk.sort()
	for k in mk: _say("  %-28s %d" % [k, acc["meshes"][k]])
	if not acc["csg"].is_empty():
		_say("CSG primitives:")
		var gk: Array = acc["csg"].keys(); gk.sort()
		for k in gk: _say("  %-28s %d" % [k, acc["csg"][k]])
	_say("")
	# the distinct sizes — a point family and a line family have few distinct values
	var sph := {}; var cyl := {}
	for p in acc["parts"]:
		var pd: Dictionary = p
		if String(pd.get("mesh", pd.get("csg", ""))).find("Sphere") != -1:
			var key := "%.4f" % float(pd.get("radius", -1.0))
			sph[key] = int(sph.get(key, 0)) + 1
		elif String(pd.get("mesh", pd.get("csg", ""))).find("Cylinder") != -1:
			var key2 := "r%.4f h%.4f" % [float(pd.get("bottom", pd.get("radius", -1.0))), float(pd.get("height", -1.0))]
			cyl[key2] = int(cyl.get(key2, 0)) + 1
	_say("spheres by radius (the POINTS):")
	for k in sph: _say("  r=%s  x%d" % [k, sph[k]])
	_say("cylinders by radius+height (the LINES):")
	for k in cyl: _say("  %s  x%d" % [k, cyl[k]])
	_say("")

	# ── ONE LEG, AS A CHAIN ────────────────────────────────────────────────
	var body: Node = c.get("_body")
	if body != null and is_instance_valid(body):
		var arm: Node = body.get_node_or_null("SpringArm3D_0")
		if arm != null:
			var ch: Array = []
			_chain(arm, ch, 0)
			_say("ONE LEG as a chain (SpringArm3D_0):")
			for l in ch: _say("  " + l)
			_say("")

	# ── EIGHT SECONDS OF FOOT TRACES ───────────────────────────────────────
	var feet: Array = c.get("_feet")
	var traces: Array = [[], [], [], []]
	var body_trace: Array = []
	var t := 0.0
	while t < SECONDS:
		await create_timer(HZ).timeout
		t += HZ
		for i in range(min(4, feet.size())):
			var f = feet[i]
			if f != null and is_instance_valid(f):
				var gp: Vector3 = (f as Node3D).global_position
				traces[i].append(Vector2(gp.x, gp.z))
		body_trace.append(Vector2(c.global_position.x, c.global_position.z))

	# how many DISTINCT plants did each foot make? a planted foot does not move
	var plants := []
	for i in range(4):
		var tr: Array = traces[i]
		var n := 0
		for j in range(1, tr.size()):
			if (tr[j] as Vector2).distance_to(tr[j - 1] as Vector2) > 0.004: n += 1
		plants.append(n)
	# do the traces CROSS? segment-vs-segment in the floor plane, all six pairs
	var crossings := {}
	for a in range(4):
		for b in range(a + 1, 4):
			var hits := 0
			var ta: Array = traces[a]; var tb: Array = traces[b]
			for i in range(1, ta.size()):
				for j in range(1, tb.size()):
					var r = Geometry2D.segment_intersects_segment(ta[i - 1], ta[i], tb[j - 1], tb[j])
					if r != null: hits += 1
			crossings["%d-%d" % [a, b]] = hits
	var span := 0.0
	if body_trace.size() > 1:
		span = (body_trace[0] as Vector2).distance_to(body_trace[body_trace.size() - 1] as Vector2)
	_say("EIGHT SECONDS OF WALKING — %.2f m travelled" % span)
	_say("  samples per foot: %d at %d Hz" % [traces[0].size(), int(1.0 / HZ)])
	_say("  moving samples per foot (a planted foot is still): %s" % str(plants))
	_say("  trace crossings in the floor plane, per pair:")
	for k in crossings: _say("    feet %s : %d crossing segment(s)" % [k, crossings[k]])
	var total := 0
	for k in crossings: total += int(crossings[k])
	_say("  TOTAL crossings: %d" % total)
	_say("")
	_say("  reading: %s" % ("the four traces CROSS — the floor pattern is a braid" if total > 0 else "the four traces DO NOT cross — four parallel dotted lines, no braid"))

	_r = {
		"classes": acc["classes"], "meshes": acc["meshes"], "csg": acc["csg"],
		"spheres_by_radius": sph, "cylinders_by_size": cyl,
		"part_count": acc["parts"].size(),
		"foot_moving_samples": plants, "crossings": crossings, "total_crossings": total,
		"travelled_m": span,
	}
	var jf := FileAccess.open(OUT, FileAccess.WRITE)
	jf.store_string(JSON.stringify(_r, "\t")); jf.close()
	var tf := FileAccess.open(TXT, FileAccess.WRITE)
	tf.store_string("\n".join(PackedStringArray(_lines)) + "\n"); tf.close()
	quit(0)
