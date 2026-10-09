extends Node
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "Fractal_Synthesis"
const OUT := "res://ada_run/synthesis-review-2026-09-14/Fractal_Synthesis/"
const MAP_CELL := Vector2i(5, 2)
const SPOT := Vector3(9.5, 0.0, 5.2)    # the visitor's spot: before the instrument, which the
                                        # token's 180 turns toward the hall's north door
const EYE_H := 1.6

func _ready() -> void: run.call_deferred()

func _live() -> bool:
	return str(get_script().resource_path).ends_with("_live.gd")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[pair-review] ", "PASS " if ok else "FAIL ", message)

func note(message: String) -> void:
	print("[pair-review] note: ", message)

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() == "headless":
		check(false, "PNG capture requires a rendered window; omit --headless, or omit --capture for logic only")
		_finish(); return
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/synthesis-review-2026-09-14/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	em.set("_plan_path", "res://ada_run/synthesis-review-2026-09-14/review-plan.json")
	em.set("_hand_path", "res://ada_run/synthesis-review-2026-09-14/necklace_hand.json")   # the REAL hand, on purpose
	em.set("start_chapter", "fractals"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "fractals", "dollhouse": 0, "grid_pack": 1})); f.close()
	get_tree().root.add_child(em); get_tree().current_scene = em
	await get_tree().create_timer(1.0).timeout
	em.set_process(false); em.set_physics_process(false); em.call("flush_stamps")
	var player: Node = em.get("_player")
	if player != null: player.set_process(false); player.set_physics_process(false)
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == MAP: seg = rec.node; break
	check(seg != null, "the hall exists in the active museum")
	if seg == null:
		_finish(); return
	for i in range(30): await get_tree().process_frame
	var vest: int = int(em.get("VESTIBULE_H"))
	var capture: bool = "--capture" in OS.get_cmdline_user_args()
	var cam: Camera3D
	if capture:
		var wc: Camera3D = em.get("_cam")
		if wc != null and is_instance_valid(wc):
			for c in wc.get_children():
				if c is Timer: (c as Timer).stop()
		cam = Camera3D.new(); em.add_child(cam); cam.fov = 62
	measurements["captures"] = {}

	var records: Array = []
	var works: Dictionary = {}
	for rec: Dictionary in em.get("_edit_records"):
		var candidate = rec.get("node")
		if not is_instance_valid(candidate): continue
		var n: Node3D = candidate as Node3D
		if n == null or not seg.is_ancestor_of(n): continue
		var token: String = str(rec.get("token", ""))
		if token not in ["fractal_recursion_1", "koch_curve", "sierpinski_triangle", "recursive_tree", "cantor_set", "fractal_clouds", "dark_sphere", "strange_attractors", "romanesco", "fibonacci_sequences"]: continue
		works[token] = n
		var meshes: Array = []
		for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh and mi.is_visible_in_tree():
				var box: AABB = seg.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()
				meshes.append({"name": str(mi.name), "position": [box.position.x,box.position.y,box.position.z-vest], "size": [box.size.x,box.size.y,box.size.z]})
		records.append({"token":token,"position":str(seg.to_local(n.global_position)),"meshes":meshes})
	measurements["inventory"] = records

	check(works.size()==10,"all ten authored works exist")
	await review_works(works,seg,em,cam,vest)
	await shot(cam, seg.to_global(Vector3(9.5,24,20+vest)), seg.to_global(Vector3(9.49,2,15+vest)), "overview", 72)
	_finish()

func shot(cam: Camera3D, at: Vector3, target: Vector3, name_: String, field_of_view: float=68) -> void:
	cam.global_position=at;cam.look_at(target);cam.fov=field_of_view
	for i in range(16): cam.make_current();await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+name_+".png")

func _finish() -> void:
	var f:=FileAccess.open(OUT+"probe_ca_edge_live.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"map":MAP,"checks":checks,"failures":failures,"measurements":measurements,"headset_verified":false},"  "));f.close()
	print("Pair review: ",checks," checks; failures: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func review_works(works: Dictionary,seg: Node3D,em: Node3D,cam: Camera3D,vest: int) -> void:
	await shot(cam,seg.to_global(Vector3(9.5,1.65,1.5+vest)),seg.to_global(Vector3(9.5,1.6,10+vest)),"entrance",83)
	for token in works:
		var n: Node3D=works[token]
		em.get("_player").global_position=n.global_position+Vector3(0,0,-3)
		em.set("_wake_until_ms",0)
		for i in range(3):em.call("_cull_artifacts");await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		await shot(cam,n.global_position+Vector3(0,2,-6),n.global_position+Vector3(0,1.2,0),token,80)
