extends SceneTree
## Actual shipped scenes, physics overlap and state/readout checks.
## Room placement, human reading distance and learner interpretation are separate checks.
var failures: Array[String] = []
var checks: int = 0
var observations: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func run() -> void:
	var row: Node3D = (load("res://algorithms/arrays/row_3_x.tscn") as PackedScene).instantiate()
	root.add_child(row)
	var row_before: Array = row.get("array_data").duplicate(true)
	row.get_node("Cube_2").call("collect")
	await create_timer(0.3).timeout
	check(row.get("array_data") == [[1,1,0,1]], "Row: collection changes exactly slot 2")
	check(row.get_node("BinaryTableDisplay/Cell_0_2").text == "0", "Row: visible value agrees with collected slot")
	check(row.get_node_or_null("Cube_2") == null, "Row: collected occupant is removed")
	check(row.get_node_or_null("Cube_3") != null, "Row: later occupant keeps index 3")
	observations.append({"case":"row default", "before":row_before, "after":row.get("array_data").duplicate(true), "address_rule":"cube-attached label leaves with occupant"})
	row.queue_free()
	await process_frame
	for config in [{"cols":4,"rows":4,"notation":"plate"},{"cols":3,"rows":2,"notation":"plate"},{"cols":4,"rows":4,"notation":"label"}]:
		var grid: Node3D = (load("res://algorithms/arrays/grid_2d_4x4.tscn") as PackedScene).instantiate()
		grid.call("apply_grid_config", config)
		root.add_child(grid)
		var x: int = int(config["cols"])-1
		var z: int = 1
		var target := "Cube_%d_%d" % [x,z]
		var address := "[%d, %d]" % [x,z]
		var before: Array = grid.get("grid_data").duplicate(true)
		grid.get_node(target).call("collect")
		await create_timer(0.3).timeout
		var expected: Array = before.duplicate(true)
		expected[x][z] = 0
		check(grid.get("grid_data") == expected, "Grid %s: only requested address becomes zero" % str(config))
		var table: Node3D = grid.get_node("BinaryTableDisplay")
		check(table.get("rows") == int(config["cols"]) and table.get("cols") == int(config["rows"]), "Grid %s: visible table dimensions match [x][z] data" % str(config))
		var label: Label3D = table.get_node_or_null("Cell_%d_%d" % [x,z])
		check(label != null and label.text == "0", "Grid %s: visible zero exists at requested address" % str(config))
		var address_remains := false
		for child in grid.get_children():
			if child is Label3D and child.text == address: address_remains = true
		check(address_remains == (config["notation"] == "plate"), "Grid %s: notation retains address only for slot plates" % str(config))
		observations.append({"case":"grid", "config":config,"removed_address":[x,z],"before":before,"after":grid.get("grid_data").duplicate(true),"address_remains":address_remains})
		grid.queue_free()
		await process_frame
	var pickup: Node3D = (load("res://commons/scenes/mapobjects/pick_up_cube.tscn") as PackedScene).instantiate()
	pickup.position = Vector3(20,0,0)
	root.add_child(pickup)
	var body := CharacterBody3D.new()
	body.name = "EncounterBody"
	body.collision_layer = 524288
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.25,0.25,0.25)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(22,0.5,0)
	root.add_child(body)
	await create_timer(0.2).timeout
	check(not pickup.get("has_been_collected"), "Single: waiting outside does not collect")
	body.global_position = pickup.get_node("DetectionArea/CollisionShape3D").global_position
	await create_timer(0.15).timeout
	check(is_instance_valid(pickup) and not pickup.get("has_been_collected"), "Single: non-player overlap does not collect")
	body.position = Vector3(22,0.5,0)
	await create_timer(0.1).timeout
	body.add_to_group("player")
	var manager: Node = root.get_node("GameManager")
	var score_before: int = manager.get("player_score")
	body.global_position = pickup.get_node("DetectionArea/CollisionShape3D").global_position
	await physics_frame
	await physics_frame
	await physics_frame
	check(is_instance_valid(pickup) and pickup.get("has_been_collected"), "Single: real physics entry triggers collection before direct repeat calls")
	if is_instance_valid(pickup):
		pickup.call("_on_detection_area_body_entered", body)
		pickup.call("_on_detection_area_body_entered", body)
	await create_timer(0.3).timeout
	check(not is_instance_valid(pickup), "Single: eligible physics overlap removes pickup")
	check(int(manager.get("player_score"))-score_before == 1, "Single: repeated contact counts once")
	observations.append({"case":"single pickup", "outside_wait":"no collection", "non_player_overlap":"no collection", "score_delta":int(manager.get("player_score"))-score_before, "scope":"physics overlap plus repeated handler calls; no controller or reachability claim"})
	body.queue_free()
	var output := "res://doc/book/iterations/2026-09-08-encounter-pilot/array-runtime.json"
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty(),"observations":observations}, "\t"))
	file.close()
	print("ARRAY ENCOUNTERS ",checks," checks; ",failures)
	quit(0 if failures.is_empty() else 1)
