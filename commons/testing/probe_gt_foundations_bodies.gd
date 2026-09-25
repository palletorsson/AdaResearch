extends SceneTree
## Stands the four bodies GT_Foundations places, at the map's scale, and prints
## their world geometry — so a chapter can say where a red platform or a river
## slab is without doing the arithmetic by hand (2026-09-24, edges pilot).
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_gt_foundations_bodies.gd
##
## Everything is placed at the origin; the map cell offsets are added in the
## report so the reader sees hall coordinates (cell (x,z) -> world (x, 0, z)).

const BODIES := [
	{"name": "KonigsbergBridge", "scene": "res://algorithms/graphtheory/graphspace3d/konigsberg3d.tscn", "scale": 0.6, "cell": Vector2i(6, 6)},
	{"name": "graphspace", "scene": "res://algorithms/graphtheory/graphspace/graphspace.tscn", "scale": 0.6, "cell": Vector2i(2, 2)},
	{"name": "graphspace3d", "scene": "res://algorithms/graphtheory/graphspace3d/graphspace3d.tscn", "scale": 1.0, "cell": Vector2i(11, 5)},
	{"name": "two_travelers", "scene": "res://commons/artifacts/two_travelers/two_travelers.tscn", "scale": 1.0, "cell": Vector2i(10, 9)},
	{"name": "synthesis_stand(graphspace hero)", "scene": "res://commons/artifacts/synthesis/synthesis_stand.tscn", "scale": 1.0, "cell": Vector2i(5, 1), "config": {"subject": "graphspace", "mode": "hero"}},
]
const HALL := Rect2(0.5, 0.5, 12.0, 11.0)
const OUT := "C:/Users/palle/AppData/Local/Temp/claude/C--Users-palle-Documents-GitHub-AdaResearch-46/8987ca3e-a19b-46d1-b00a-85888e1b0458/scratchpad/gt_foundations_bodies.txt"
var _lines: PackedStringArray = []  # interior x 0.5..12.5, z 0.5..11.5 (walls at 0 and 12 / 0 and 11)

func _init() -> void:
	await process_frame
	for b in BODIES:
		await _stand(b)
	_say("[probe] done")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_lines))
		f.close()
	quit()

func _say(msg: String) -> void:
	print(msg)
	_lines.append(msg)

func _stand(b: Dictionary) -> void:
	var packed: PackedScene = load(b["scene"])
	if packed == null:
		_say("[probe] %s: NO SCENE" % b["name"])
		return
	var inst: Node3D = packed.instantiate()
	inst.scale = Vector3.ONE * float(b["scale"])
	var cell: Vector2i = b["cell"]
	inst.position = Vector3(cell.x, 0.0, cell.y)
	if b.has("config") and inst.has_method("apply_grid_config"):
		inst.apply_grid_config(b["config"])  # the museum configures before _ready
	root.add_child(inst)
	await create_timer(0.6).timeout
	var meshes: Array = []
	var labels: Array = []
	_collect(inst, meshes, labels)
	var merged: AABB
	var first := true
	for m in meshes:
		var mi: VisualInstance3D = m
		var wa: AABB = mi.global_transform * mi.get_aabb()
		if wa.size.length() < 0.001:
			continue
		merged = wa if first else merged.merge(wa)
		first = false
	_say("\n[probe] ===== %s at cell %s scale %.2f: %d meshes, %d Label3D" % [b["name"], str(cell), b["scale"], meshes.size(), labels.size()])
	if not first:
		_say("[probe]   merged AABB x %.1f..%.1f  y %.1f..%.1f  z %.1f..%.1f  (hall interior x 0.5..12.5, z 0.5..11.5, floor y 0)" % [
			merged.position.x, merged.end.x, merged.position.y, merged.end.y, merged.position.z, merged.end.z])
		var inside := 0
		var outside := 0
		for m in meshes:
			var mi: VisualInstance3D = m
			var wa: AABB = mi.global_transform * mi.get_aabb()
			if wa.size.length() < 0.001:
				continue
			var c := Vector2(wa.get_center().x, wa.get_center().z)
			if HALL.has_point(c):
				inside += 1
			else:
				outside += 1
		_say("[probe]   mesh centres inside the hall footprint: %d, outside: %d" % [inside, outside])
	if b["name"] == "KonigsbergBridge":
		for m in meshes:
			var mi: VisualInstance3D = m
			var pname := mi.name.to_lower() + " < " + (mi.get_parent().name.to_lower() if mi.get_parent() else "") + (" [csg collision]" if (mi is CSGShape3D and mi.use_collision) else "")
			var wa: AABB = mi.global_transform * mi.get_aabb()
			var big: bool = wa.size.x > 2.0 or wa.size.z > 2.0
			if big or "river" in pname or "platform" in pname or "land" in pname or "bridge" in pname or "arch" in pname:
				_say("[probe]   %-42s x %6.1f..%6.1f  y %5.2f..%5.2f  z %6.1f..%6.1f" % [pname.left(42), wa.position.x, wa.end.x, wa.position.y, wa.end.y, wa.position.z, wa.end.z])
		for l in labels:
			var lb: Label3D = l
			var p := lb.global_position
			_say("[probe]   label %-34s at (%.1f, %.2f, %.1f) font %d billboard %d" % [lb.text.split("\n")[0].left(34), p.x, p.y, p.z, lb.font_size, lb.billboard])
	if b["name"] == "two_travelers":
		for l in labels:
			var lb: Label3D = l
			var p := lb.global_position
			_say("[probe]   label %-34s at (%.1f, %.2f, %.1f)" % [lb.text.split("\n")[0].left(34), p.x, p.y, p.z])
	var static_bodies := _count_static(inst)
	_say("[probe]   StaticBody3D/CollisionShape3D under the body: %d" % static_bodies)
	# every solid thing whose centre falls inside the hall (or one metre outside its walls)
	var solids: Array = []
	_collect_solids(inst, solids)
	var wide := HALL.grow(1.0)
	for s in solids:
		var n: Node3D = s
		var wa: AABB
		if n is VisualInstance3D:
			wa = n.global_transform * (n as VisualInstance3D).get_aabb()
		elif n is CollisionShape3D and (n as CollisionShape3D).shape != null:
			wa = n.global_transform * (n as CollisionShape3D).shape.get_debug_mesh().get_aabb()
		else:
			continue
		var c := Vector2(wa.get_center().x, wa.get_center().z)
		if wide.has_point(c):
			_say("[probe]   SOLID in/at the hall: %-30s x %5.1f..%5.1f  y %5.2f..%5.2f  z %5.1f..%5.1f -> cells x %d..%d z %d..%d" % [
				(n.get_parent().name + "/" + n.name).left(30), wa.position.x, wa.end.x, wa.position.y, wa.end.y, wa.position.z, wa.end.z,
				roundi(wa.position.x), roundi(wa.end.x), roundi(wa.position.z), roundi(wa.end.z)])
	inst.queue_free()
	await process_frame

func _collect(n: Node, meshes: Array, labels: Array) -> void:
	if n is Label3D:
		labels.append(n)
	elif n is VisualInstance3D:
		meshes.append(n)
	for c in n.get_children():
		_collect(c, meshes, labels)

func _collect_solids(n: Node, acc: Array) -> void:
	if (n is CSGShape3D and (n as CSGShape3D).use_collision) or n is CollisionShape3D:
		acc.append(n)
	for c in n.get_children():
		_collect_solids(c, acc)

func _count_static(n: Node) -> int:
	var k := 0
	if n is StaticBody3D or n is CollisionShape3D:
		k += 1
	for c in n.get_children():
		k += _count_static(c)
	return k

