extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(0.8).timeout
	if map_id == "Noise_Voxel": await voxel_checks()
	elif map_id == "Noise_One": await ring_checks()

func state(bench: Node3D) -> Array:
	return [bench.threshold, bench.noise_scale, bench._noise.seed, bench._rebuilds, bench._cell, bench._cut]

func press(bench: Node3D, key: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = key
	bench._input(event)

func button(bench: Node3D, id: int) -> void:
	var area: Node = bench.get_node("LatticeStand/Panel").find_child("Btn_"+str(id), true, false).get_node("InteractableAreaButton")
	area.button_pressed.emit(area)

func voxel_checks() -> void:
	var bench := find_scene("/perlin_terrain_sculptor.gd")
	var volume := find_scene("/voxelnoise.gd")
	check("paired model and volume loaded", bench != null and volume != null)
	if bench == null or volume == null: return
	check("museum placement disables keyboard shortcuts", not bench.keyboard_shortcuts)
	var before := state(bench)
	var occupancy: Dictionary = bench.occupancy_report()
	for key in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_R, KEY_N]:
		press(bench, key)
		check("walking key leaves model unchanged: "+OS.get_keycode_string(key), state(bench) == before)
	check("all shortcuts leave occupancy unchanged", bench.occupancy_report() == occupancy)
	var legacy: Node = load("res://commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.gd").new()
	check("standalone instances retain keyboard default", legacy.keyboard_shortcuts)
	legacy.free()
	bench.apply_grid_config({"keyboard":"on"})
	var frequency: float = bench.noise_scale
	press(bench, KEY_RIGHT)
	check("opted-in shortcut still changes frequency", is_equal_approx(bench.noise_scale,frequency+0.5))
	bench.noise_scale = frequency
	bench.apply_grid_config({"keyboard":"off"})
	await create_timer(0.8).timeout
	check("explicit opt-out restored", not bench.keyboard_shortcuts)
	check("pair still shares orientation", bench.global_basis.z.normalized().is_equal_approx(volume.global_basis.z.normalized()))
	check("full volume retains one-metre cells and flight enclosure", is_equal_approx(volume.voxel_scale,1.0) and volume.has_node("FlightBox"))
	var flight_id: int = volume.get_node("FlightBox").get_instance_id()
	check("piece count is on the bench", "pieces" in bench._lattice_readout.text)
	var stage_labels: Array = volume.get_node("VolumeStage").find_children("*","Label3D",true,false)
	var captions: Array = []
	for label in stage_labels: captions.append(label.text)
	check("volume keeps front and back dimension captions", stage_labels.size() == 2 and "times the spacing" in stage_labels[0].text and stage_labels[0].position.z * stage_labels[1].position.z < 0)
	check("volume keeps twenty-five times the model spacing", is_equal_approx(volume.voxel_scale/bench.voxel_size,25.0))
	await snapshot("bench-controls", bench.to_global(Vector3(0.15,0.30,2.5)), bench.to_global(Vector3(0,-0.15,0.10)), 54)
	button(bench,0)
	await create_timer(1.0).timeout
	check("physical THRESHOLD button still changes model", is_equal_approx(bench.threshold,0.1))
	check("THRESHOLD reaches large volume", is_equal_approx(volume.iso_level,bench.threshold))
	check("higher threshold removes cells at the same seed", bench._noise.seed == before[2] and bench.occupancy_report().occupied < occupancy.occupied)
	check("model and volume occupancy agree", bench.occupancy_report().occupied == volume._occupied_cells.size())
	button(bench,1)
	await create_timer(0.3).timeout
	check("physical CELL button updates volume marker", bench._cell != before[4] and volume._selected_cell == bench._cell)
	button(bench,3)
	check("physical CUT button still opens model", bench._cut != before[5])
	button(bench,3)
	check("CUT can be closed again", bench._cut == before[5])
	button(bench,2)
	await create_timer(0.8).timeout
	check("physical SEED button remains connected", bench._noise.seed != before[2] and volume.noise_seed == bench._noise.seed)
	check("console updates preserve the flight enclosure", volume.get_node("FlightBox").get_instance_id() == flight_id)
	observations = {"initial":occupancy, "button_threshold":0.1, "captions":captions, "scope":"Real museum: supplied keyboard callbacks and actual console button signals. No physical controller, headset or flight-route acceptance."}

func ring_checks() -> void:
	var pair := find_scene("/noisetorus.gd")
	check("upright pair loaded", pair != null and pair.stand == "pair")
	if pair == null: return
	check("two distinct receiving surfaces retained", pair._rings.size() == 2)
	var posts: Array = []
	for ring in pair._rings:
		var post: MeshInstance3D = pair._pair_root.get_node("Post_"+ring.kind)
		var top: float = post.position.y+post.mesh.size.y*0.5
		var bottom: float = post.position.y-post.mesh.size.y*0.5
		check("support starts at bench: "+ring.kind, is_equal_approx(bottom,pair.PAIR_BENCH_H))
		check("support meets maximum inward relief: "+ring.kind, top >= pair.PAIR_H-pair.PAIR_OUTER+pair.PAIR_AMPS.back()-0.0001)
		check("ring remains upright: "+ring.kind, is_equal_approx(absf(ring.holder.rotation.x),PI/2.0))
		posts.append({"kind":ring.kind,"base":bottom,"top":top})
	await snapshot("upright-pair", pair.to_global(Vector3(0,1.65,2.5)), pair.to_global(Vector3(0,1.1,0)), 60)
	observations={"posts":posts,"scope":"Native geometry and museum photograph. Existing repair retained; no new ring geometry in this pass."}

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Real museum, supplied input events and support checks; no headset or learner acceptance."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("NOISE REVIEW ",map_id," ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
