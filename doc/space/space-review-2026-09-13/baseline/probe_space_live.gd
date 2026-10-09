extends Node
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "Noise_Space_10"
const OUT := "res://ada_run/space-review-2026-09-13/Noise_Space_10/"
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
	print("[space-review] ", "PASS " if ok else "FAIL ", message)

func note(message: String) -> void:
	print("[space-review] note: ", message)

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() == "headless":
		check(false, "PNG capture requires a rendered window; omit --headless, or omit --capture for logic only")
		_finish(); return
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/space-review-2026-09-13/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	em.set("_plan_path", "res://ada_run/space-review-2026-09-13/review-plan.json")
	em.set("_hand_path", "res://ada_run/space-review-2026-09-13/necklace_hand.json")   # the REAL hand, on purpose
	em.set("start_chapter", "noise"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "noise", "dollhouse": 0, "grid_pack": 1})); f.close()
	get_tree().root.add_child(em); get_tree().current_scene = em
	await get_tree().create_timer(1.0).timeout
	em.set_process(false); em.call("flush_stamps")
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
		var n: Node3D = rec.get("node") as Node3D
		if n == null or not seg.is_ancestor_of(n): continue
		var token: String = str(rec.get("token", ""))
		if token not in ["noise_space", "dark_sphere"]: continue
		works[token] = n
		var meshes: Array = []
		for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh and mi.is_visible_in_tree():
				var box: AABB = seg.global_transform.affine_inverse() * mi.global_transform * mi.get_aabb()
				meshes.append({"name": str(mi.name), "position": [box.position.x,box.position.y,box.position.z-vest], "size": [box.size.x,box.size.y,box.size.z]})
		records.append({"token":token,"position":str(seg.to_local(n.global_position)),"meshes":meshes})
	measurements["inventory"] = records
	check(works.size()==2,"both authored works exist")
	await review_works(works,seg,em,cam,vest)
	await shot(cam, seg.to_global(Vector3(6.5,16,6.5+vest)), seg.to_global(Vector3(6.48,0,6.5+vest)), "plan")
	_finish()

func shot(cam: Camera3D, at: Vector3, target: Vector3, name_: String, field_of_view: float=68) -> void:
	cam.global_position=at;cam.look_at(target);cam.fov=field_of_view
	for i in range(16): cam.make_current();await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+name_+".png")

func _finish() -> void:
	var f:=FileAccess.open(OUT+"probe_space_live.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"map":MAP,"checks":checks,"failures":failures,"measurements":measurements,"headset_verified":false},"  "));f.close()
	print("Space review: ",checks," checks; failures: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func review_works(works: Dictionary, seg: Node3D, em: Node3D, cam: Camera3D, vest: int) -> void:
	var ground: Node3D=works.noise_space
	measurements["noise"]={"seed":ground.noise.seed,"basis":ground.noise.noise_type,"fractal":ground.noise.fractal_type,"frequency":ground.noise.frequency,"gain":ground.noise.fractal_gain,"lacunarity":ground.noise.fractal_lacunarity,"octaves":ground.noise.fractal_octaves}
	await shot(cam,ground.to_global(Vector3(0,3.5,-6.0)),ground.to_global(Vector3(0,0,0)),"terrain",90)
