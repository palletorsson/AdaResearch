extends SceneTree
## Run headlessly; all saves are isolated from the visitor's cloth and wardrobe.
const Cloth = preload("res://commons/artifacts/garment_cutting_table/cloth_record.gd")
const PrintRecord = preload("res://commons/artifacts/ten_print_textile/print_record.gd")
const Wardrobe = preload("res://commons/player/costume_wardrobe.gd")
const OUT := "user://cloth_record_regression/"
var failures := 0
var checks := 0

class ProgressStub extends Node:
	signal sequence_completed(sequence: String)
	func is_sequence_completed(_name: String) -> bool: return false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ", title)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	create_timer(60).timeout.connect(func(): quit(98))
	var printed := PrintRecord.make(435)
	printed.mark = 2
	printed.palette = 1
	printed.repeat = 3
	var woven := Cloth.sample("tartan")
	var unmarked := printed.duplicate(true)
	unmarked.erase("kind")
	var incomplete := printed.duplicate(true)
	incomplete.erase("samples")
	var broken_weave := woven.duplicate(true)
	broken_weave.picks[0].erase("bits")
	var invalid: Array[Dictionary] = [{}, {"version":1}, unmarked, incomplete, broken_weave]
	for i in range(invalid.size()):
		var data: Dictionary = invalid[i]
		check(not Cloth.valid(data), "Invalid record %d rejected by validation" % i)
		check(Cloth.image(data) == null, "Invalid record %d produces no image" % i)
		check(Cloth.material(data) == null, "Invalid record %d produces no material" % i)

	for data in [woven, printed]:
		var path: String = OUT + ("print.json" if data == printed else "weave.json")
		check(Cloth.save_record(data, path) and Cloth.load_record(path) == data,
			"Cloth save/load preserves the complete record: " + path.get_file())
		check(Cloth.image(data).get_width() == (336 if data == printed else 576),
			"Renderer selects the correct format: " + path.get_file())
	check(Cloth.material(printed).uv1_scale == Vector3(3,3,1), "Print repeat survives material creation")

	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var manager := ProgressStub.new()
	world.add_child(manager)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.make_current()
	var wardrobe := Wardrobe.new()
	wardrobe.mount_path = world.get_path()
	wardrobe.head_path = camera.get_path()
	wardrobe.manager_path = manager.get_path()
	wardrobe.appearance_save_path = OUT + "wardrobe.cfg"
	world.add_child(wardrobe)
	await process_frame
	await process_frame
	# Load interactive scenes after autoload startup (the button depends on XRTools).
	var table_script = load("res://commons/artifacts/garment_cutting_table/garment_cutting_table.gd")
	var table: Node3D = table_script.new()
	table.cloth_path = OUT + "print.json"
	world.add_child(table)
	table.set_process(false)
	check(table.record == printed and table.suit.record == printed,
		"Cutting table and fitting load saved printed cloth without loom picks")
	check("STORED DRAWS" in table.source_label.text, "Table identifies the print record")
	for data in [woven, printed]:
		check(table.set_record(data) and table.select_style("gown"), "Table accepts cloth and gown cut")
		table.act("CUT")
		table.advance(20.0)
		table.act("ASSEMBLE")
		table.advance(20.0)
		check(table.phase == "ready" and table.suit.record == data, "Cut and assemble preserve the fabric record")
		check(table.wear() and wardrobe.suit_cloth == data and wardrobe.costume.tailored_suit.record == data,
			"Completed gown transfers to the actual wearer")
		check(not table.set_record({}) and table.record == data,
			"Invalid replacement leaves the current table cloth intact")
		check(not wardrobe.set_tailored_suit({}) and wardrobe.suit_cloth == data,
			"Invalid replacement leaves the worn cloth intact")
	var saved := ConfigFile.new()
	check(saved.load(wardrobe.appearance_save_path) == OK and saved.get_value("appearance", "suit_cloth") == printed,
		"Wardrobe persists print samples, seed and design")
	wardrobe.queue_free()
	await process_frame
	var restored := Wardrobe.new()
	restored.mount_path = world.get_path()
	restored.head_path = camera.get_path()
	restored.manager_path = manager.get_path()
	restored.appearance_save_path = OUT + "wardrobe.cfg"
	world.add_child(restored)
	await process_frame
	await process_frame
	check(restored.suit_cloth == printed and restored.costume.tailored_suit.record == printed,
		"Fresh wardrobe restores the saved printed gown onto its meshes")
	check(restored.suit_style == "gown", "Restored dress keeps its shape")
	var file := FileAccess.open(OUT + "invalid.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(unmarked))
	file.close()
	check(Cloth.load_record(OUT + "invalid.json").is_empty(), "Malformed saved print is refused")
	var fallback: Node3D = table_script.new()
	fallback.cloth_path = OUT + "invalid.json"
	world.add_child(fallback)
	fallback.set_process(false)
	check(fallback.record == woven and fallback.suit.record == woven,
		"Table with malformed save starts with its standard tartan cloth")
	world.queue_free()
	await process_frame
	await process_frame
	print("CLOTH RECORD: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
