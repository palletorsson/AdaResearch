extends SceneTree
## Actual pickup scene and detector physics. Teleported test capsules establish
## eligibility, not museum approach, collision clearance, controller use or learning.

var failures: Array[String] = []
var observations: Array = []
var entered: Array = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var output: String = OS.get_cmdline_user_args()[0]
	var cases: Array = [
		{"name":"unrelated_layer1", "layer":1, "group":"", "collects":false, "hold":"collect"},
		{"name":"museum_walker_layer1", "layer":1, "group":"em_walker", "collects":true, "hold":"collect"},
		{"name":"xr_player_layer20", "layer":524288, "group":"player_body", "collects":true, "hold":"collect"},
		{"name":"museum_demo_stays", "layer":1, "group":"em_walker", "collects":false, "hold":"demo"}
	]
	for spec in cases:
		await test_case(spec)
	var report := {"scope":"Actual pickup packed scene; genuine Area3D body_entered overlap from teleported capsules. No collect/handler forcing. Test body uses the museum capsule dimensions but does not prove approach or exit.", "cases":observations,"failures":failures,"passed":failures.is_empty()}
	var file := FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("PICKUP ENCOUNTER ", "PASS" if failures.is_empty() else "FAIL", " ", failures)
	quit(0 if failures.is_empty() else 1)

func test_case(spec: Dictionary) -> void:
	entered.clear()
	var pickup: Node3D = (load("res://commons/scenes/mapobjects/pick_up_cube.tscn") as PackedScene).instantiate()
	pickup.position = Vector3(20,0,0)
	pickup.set("hold",spec["hold"])
	root.add_child(pickup)
	var area: Area3D = pickup.get_node("DetectionArea")
	var detector_mask: int = area.collision_mask
	area.body_entered.connect(func(body: Node3D): entered.append(str(body.name)))
	var body := CharacterBody3D.new()
	body.name = "Walker" if spec["group"] == "em_walker" else "NeutralTestBody"
	body.collision_layer = int(spec["layer"])
	body.collision_mask = 0
	if str(spec["group"]) != "":
		body.add_to_group(str(spec["group"]))
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.5
	shape.shape = capsule
	shape.position.y = 0.75
	body.add_child(shape)
	body.position = Vector3(22,0,0)
	root.add_child(body)
	await create_timer(0.2).timeout
	var outside_unchanged: bool = is_instance_valid(pickup) and not bool(pickup.get("has_been_collected"))
	var recognised: bool = bool(pickup.call("_is_player",body))
	var manager: Node = root.get_node("GameManager")
	var score_before: int = int(manager.get("player_score"))
	body.global_position = Vector3(20,0,0)
	await create_timer(0.35).timeout
	var removed: bool = not is_instance_valid(pickup)
	var score_delta: int = int(manager.get("player_score"))-score_before
	var entered_detector: bool = not entered.is_empty()
	var expected_collection: bool = bool(spec["collects"])
	var expects_detection: bool = str(spec["hold"]) != "demo"
	var passed: bool = outside_unchanged and removed == expected_collection and score_delta == (1 if expected_collection else 0) and entered_detector == expects_detection
	if not passed:
		failures.append(str(spec["name"]))
	observations.append({"case":spec["name"],"body_layer":spec["layer"],"body_group":spec["group"],"detector_mask":detector_mask,"identity_recognised":recognised,"outside_unchanged":outside_unchanged,"detector_entered":entered_detector,"removed":removed,"score_delta":score_delta,"expected_collection":expected_collection,"passed":passed})
	if is_instance_valid(pickup):
		pickup.queue_free()
	body.queue_free()
	await process_frame
