extends SceneTree
## Bench for commons/void/fit_strategies.gd (strip a work's own floor / walls / ceiling) and commons/void/slab_extension.gd
## (the side slab). Run headless; prints PASS/FAIL and quits with the failure count.
const Fit = preload("res://commons/void/fit_strategies.gd")
var fails := 0
func check(label: String, ok: bool) -> void:
	if not ok: fails += 1
	print("%s %s" % ["PASS" if ok else "FAIL", label])

func body_box(parent: Node3D, n: String, size: Vector3, at: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new(); b.name = n; b.position = at; parent.add_child(b)
	var m := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; m.mesh = bm; m.name = n + "Mesh"; b.add_child(m)
	var c := CollisionShape3D.new(); var s := BoxShape3D.new(); s.size = size; c.shape = s; b.add_child(c)
	return b

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var floor_root := Node3D.new(); root.add_child(floor_root); floor_root.position.y = -84
	var mount := Node3D.new(); floor_root.add_child(mount)
	var art := Node3D.new(); mount.add_child(art)
	var ground := body_box(art, "Ground", Vector3(19, .016, 14), Vector3(0, .008, 0))
	var back := body_box(art, "Backdrop", Vector3(19, 6, .12), Vector3(0, 3, -6.94))
	var lid := body_box(art, "Lid", Vector3(19, .1, 14), Vector3(0, 6, 0))
	var sofa := body_box(art, "Receiver", Vector3(1.8, 1.8, 1.8), Vector3(0, .9, 0))
	var label := body_box(art, "Plate", Vector3(3, .02, 2), Vector3(4, .01, 3))   # flat but small: not a floor
	await process_frame
	var none := Fit.strip(mount, art, {})
	check("no strip settings: nothing touched", none.is_empty() and ground.get_child(0).layers != 0)
	var done := Fit.strip(mount, art, {"strip": ["floor", "walls"]})
	await physics_frame
	check("floor found by shape and hidden (%s)" % str(done), ground.get_child(0).layers == 0 and done.values().has("floor"))
	check("its collision is off", (ground.get_child(1) as CollisionShape3D).disabled)
	check("the perimeter wall is stripped", back.get_child(0).layers == 0)
	check("the ceiling is kept when not asked", lid.get_child(0).layers != 0)
	check("the receiver in the middle is kept", sofa.get_child(0).layers != 0 and not (sofa.get_child(1) as CollisionShape3D).disabled)
	check("a small flat plate is not a floor", label.get_child(0).layers != 0)
	var named := Fit.strip(mount, art, {"strip_parts": ["Lid*"]})
	check("strip by name", lid.get_child(0).layers == 0 and named.size() == 1)
	var kept := Node3D.new(); mount.add_child(kept)
	var g2 := body_box(kept, "Ground", Vector3(19, .016, 14), Vector3(0, .008, 0))
	await process_frame
	Fit.strip(mount, kept, {"strip": ["floor"], "keep_parts": ["Ground*"]})
	check("keep_parts wins over shape", g2.get_child(0).layers != 0)
	# fit.set before the work builds: typed values converted, unknown names reported
	var src := GDScript.new()
	src.source_code = "extends Node3D
@export var num_layers: int = 10
@export var spacing: float = 1.2
@export var on: bool = true
"
	src.reload()
	var work := Node3D.new(); work.set_script(src)
	Fit.before_ready(work, {"set": {"num_layers": "5", "spacing": 1, "on": "false", "nonsense": 3}})
	check("fit.set converts to the property's type (layers %s, spacing %s, on %s)" % [work.get("num_layers"), work.get("spacing"), work.get("on")],
		work.get("num_layers") == 5 and is_equal_approx(work.get("spacing"), 1.0) and work.get("on") == false)
	check("an unknown setting is reported, not silently dropped", work.get_meta("fit_rejected", []) == ["nonsense"])
	work.free()
	# the side slab
	var slab: Node3D = load("res://commons/void/slab_extension.tscn").instantiate()
	slab.set_meta("config_length", 14); slab.set_meta("config_depth", 12); slab.set_meta("config_drop", 6)
	floor_root.add_child(slab); slab.position = Vector3(0, 0, 9)
	await process_frame
	var s: StaticBody3D = slab.get_node("SideSlab/Slab")
	var size: Vector3 = (s.get_child(1) as CollisionShape3D).shape.size
	check("depth is held to 10 m (asked 12): %.2f" % size.z, absf(size.z - 10.05) < .01 and absf(size.x - 14) < .01)
	check("a visitor on it belongs to it", slab.contains_visitor(slab.to_global(Vector3(3, 1, 5))) and not slab.contains_visitor(slab.to_global(Vector3(3, 1, -1))))
	var beams := slab.find_children("Beam*", "MeshInstance3D", true, false)
	var lowest := INF
	for b in beams: lowest = minf(lowest, (b as Node3D).position.y)
	check("tangled beams run down toward the floor below (%d, mid-heights down to %.1f)" % [beams.size(), lowest], beams.size() >= 6 and lowest < -2.0)
	check("beams do not collide", slab.find_children("*", "CollisionShape3D", true, false).size() == 1)
	check("it is walkable outside the tower", slab.is_in_group("void_exterior_walk") and slab.is_in_group("void_floor_extension"))
	print("[fit_strategies_bench] %s" % ("ok" if fails == 0 else "%d FAIL" % fails))
	quit(fails)
