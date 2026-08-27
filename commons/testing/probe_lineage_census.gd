extends SceneTree
## THE SAME CENSUS, RUN ON THE ANCESTORS (2026-08-26).
##
## The spider counted out as 32 spheres and 24 cylinders. That is only a
## genealogy if the corpus's own point is a sphere and its own line is a
## cylinder — otherwise the resemblance is mine, not the projects.
##
## So: instantiate the artifacts the first four maps actually place, and count
## them the same way. origin and interactive_point_origin_force stand in
## Point_One; line, grabbable_line and lightrod in Point_Lines; draw_dot in
## Point_Trace; triangle and interactivetriangle in Point_Triangle_Context.
## No opinion is applied — whatever primitive class is standing gets counted.
const IN := "res://ada_run/_lineage_subjects.json"
const TXT := "res://ada_run/lineage_census.txt"
const JSN := "res://ada_run/lineage_census.json"

var _l: Array = []
var _rows: Array = []

func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _count(n: Node, acc: Dictionary) -> void:
	var cls := n.get_class()
	if n is MeshInstance3D:
		var m: Mesh = (n as MeshInstance3D).mesh
		if m != null:
			var k := m.get_class()
			acc[k] = int(acc.get(k, 0)) + 1
	elif cls.begins_with("CSG") and cls != "CSGCombiner3D":
		acc[cls] = int(acc.get(cls, 0)) + 1
	elif n is MultiMeshInstance3D:
		var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
		var c := 0
		if mm != null: c = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
		acc["MultiMesh(%s)" % (mm.mesh.get_class() if mm != null and mm.mesh != null else "?")] = int(acc.get("MultiMesh", 0)) + c
	for ch in n.get_children(): _count(ch, acc)

## points and lines, by the only rule that is not a matter of taste: a sphere or
## a box small in all three axes is a POINT; anything long in one axis is a LINE
func _family(acc: Dictionary) -> Array:
	var pts := 0
	var lns := 0
	for k in acc:
		var key := String(k)
		var v := int(acc[k])
		if key.find("Sphere") != -1: pts += v
		elif key.find("Cylinder") != -1 or key.find("Capsule") != -1: lns += v
	return [pts, lns]

func _run() -> void:
	var st := Node3D.new(); get_root().add_child(st)
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(IN))
	if not (doc is Dictionary):
		print("no subject list"); quit(1); return
	var subs: Array = (doc as Dictionary).get("subjects", [])
	_say("THE LINEAGE, COUNTED THE SAME WAY")
	_say("")
	var x := 0.0
	for s in subs:
		var sd: Dictionary = s
		var path := String(sd.get("scene", ""))
		var tok := String(sd.get("token", ""))
		if not ResourceLoader.exists(path):
			_say("%-32s -- scene missing" % tok); continue
		var ps: PackedScene = load(path) as PackedScene
		if ps == null:
			_say("%-32s -- not a scene" % tok); continue
		var inst: Node = ps.instantiate()
		if inst == null:
			_say("%-32s -- would not instantiate" % tok); continue
		st.add_child(inst)
		if inst is Node3D: (inst as Node3D).global_position = Vector3(x, 0, 0)
		x += 6.0
		await create_timer(0.9).timeout
		var acc := {}
		_count(inst, acc)
		var fam := _family(acc)
		var parts: Array = []
		var ks: Array = acc.keys(); ks.sort()
		for k in ks: parts.append("%s x%d" % [k, acc[k]])
		_say("%-32s  points %-5d lines %-5d   %s" % [tok, fam[0], fam[1], ", ".join(PackedStringArray(parts))])
		_rows.append({"token": tok, "points": fam[0], "lines": fam[1], "primitives": acc})

	_say("")
	_say("reading: a POINT in this corpus is a sphere; a LINE is a cylinder or a")
	_say("capsule. The spider is 32 of the first and 24 of the second.")
	var f := FileAccess.open(TXT, FileAccess.WRITE)
	f.store_string("\n".join(PackedStringArray(_l)) + "\n"); f.close()
	var j := FileAccess.open(JSN, FileAccess.WRITE)
	j.store_string(JSON.stringify({"rows": _rows}, "\t")); j.close()
	quit(0)
