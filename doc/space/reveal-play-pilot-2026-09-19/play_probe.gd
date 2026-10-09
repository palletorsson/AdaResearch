extends SceneTree
## Synthetic desktop input in the actual museum. No headset or learner claim.
const BASE := "res://ada_run/encounter_pilot/CA_SoftRules/"
const OUT := "res://doc/space/reveal-play-pilot-2026-09-19/after/"
var failures: Array[String] = []
var checks: Array[Dictionary] = []
var states: Array[Dictionary] = []
var study: Variant
var driver: Variant
var camera: Camera3D
var standing: Vector3

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks.append({"passed": ok, "message": message})
	if not ok: failures.append(message)
	print("REVEAL ", "PASS " if ok else "FAIL ", message)

func titles() -> Array:
	return [study.get_node("FieldTitle_0").text, study.get_node("FieldTitle_1").text]

func remember(tag: String) -> void:
	states.append({"stage": tag, "readback": study.readback(), "titles": titles(), "readout": study.reading.text})

func press(index: int) -> void:
	driver.cam.make_current()
	var control: Node3D = study.console.find_child("Btn_%d" % index, true, false).get_node("InteractableAreaButton")
	var result: Dictionary = await driver.press(control, standing)
	check(str(result.get("hover", "")).contains("InteractableAreaButton"), "pointer reaches button %d" % index)

func photograph(tag: String) -> void:
	if DisplayServer.get_name() == "headless": return
	camera.global_position = study.to_global(Vector3(-0.5, 1.65, -4.8))
	camera.look_at(study.to_global(Vector3(0, 1.85, 3)))
	camera.make_current()
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + tag + ".png"))

func run() -> void:
	var museum: Node3D = load(BASE + "museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL", BASE + "control.json")
	museum.set("_hand_path", BASE + "necklace_hand.json")
	museum.set("_overrides_path", BASE + "em_overrides.json")
	museum.set("start_chapter", "cellularautomata")
	museum.set("start_map", "CA_SoftRules")
	museum.set("plan_file", BASE + "plan.json")
	root.add_child(museum)
	var started := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - started < 60000:
		await process_frame
	museum.set("_lazy_pending", 0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	study = museum.find_child("ExchangeStudy", true, false)
	check(study != null, "exchange study exists in the built museum")
	if study == null:
		finish(); return
	var player: Node = museum.get("_player")
	if is_instance_valid(player):
		player.set_process(false); player.set_physics_process(false)
	driver = load("res://commons/testing/wcn_desktop_driver.gd").new()
	museum.add_child(driver)
	standing = study.to_global(Vector3(-4.5, 0, -3.15))
	driver.spawn(standing, museum)
	camera = Camera3D.new(); root.add_child(camera); camera.fov = 70
	await physics_frame
	check(titles() == ["A", "B"] and not study.reading.text.contains("EXCHANGE"), "arrival withholds the exchange setting")
	check(study.left.v == study.right.v and study.left.u == study.right.u, "both fields begin with identical values")
	remember("arrival"); await photograph("arrival")
	await press(0)
	check(study.left.ticks == 1 and is_equal_approx(study.left.v[study.WITNESS], 0.02) and study.right.v[study.WITNESS] == 0.0, "STEP exposes the independently calculated first difference at W")
	check(titles() == ["A", "B"], "a first step leaves interpretation open")
	await press(3)
	started = Time.get_ticks_msec()
	while study.running and Time.get_ticks_msec() - started < 12000: await process_frame
	check(study.left.ticks == 101 and study.right.ticks == 101 and not study.running, "+100 completes exactly one hundred further updates")
	check(titles() == ["A", "B"] and not study.reading.text.contains("EXCHANGE"), "observation time does not trigger an automatic answer")
	remember("observed"); await photograph("observed")
	var values: PackedFloat32Array = study.left.v.duplicate()
	await press(6); await press(7)
	check(study.show_u and not study.coating and study.left.v == values and study.left.ticks == 101, "VIEW and COAT change the display without changing the field or clock")
	await press(6); await press(7)
	await press(5)
	check(study.injections == 1 and study.left.ticks == 101, "INJECT adds a matched intervention without advancing time")
	await press(2)
	check(study.left.ticks == 0 and study.injections == 0 and titles() == ["A", "B"], "REPLAY before comparison restores an unlabelled beginning")
	await press(4)
	check(study.right.exchange and study.left.ticks == 0 and titles() == ["A / EXCHANGE ON", "B / EXCHANGE ON"], "changing EXCHANGE B reveals both current settings and resets the comparison")
	remember("revealed"); await photograph("revealed")
	await press(0)
	check(study.left.v == study.right.v and study.left.u == study.right.u, "matched exchange produces matching full fields after STEP")
	await press(4); await press(0)
	check(titles()[1] == "B / EXCHANGE OFF" and study.left.v[study.WITNESS] > study.right.v[study.WITNESS], "switching back updates the label and restores the difference")
	await press(2)
	check(titles()[1] == "B / EXCHANGE OFF" and study.left.ticks == 0, "REPLAY preserves the explanation already revealed")
	await press(1)
	check(study.running, "RUN starts the live clock")
	await create_timer(0.25).timeout
	await press(1)
	check(not study.running and study.left.ticks > 0, "RUN can hold the clock again")
	remember("replayed")
	finish()

func finish() -> void:
	var f := FileAccess.open(OUT + "checks.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"scope": "Built museum with synthetic mouse input through the real desktop interaction pointer; museum movement logic paused. No learner or headset verification.", "checks": checks, "failures": failures, "stages": states, "pointer": driver.log if driver != null else []}, "\t"))
	f.close()
	quit(0 if failures.is_empty() else 1)
