extends SceneTree

const OUT := "res://doc/book/iterations/2026-09-20-machinelearning-review/"
var checks: Array = []
var evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks.append({"ok": ok, "message": message})

func mount(path: String) -> Node:
	var scene: PackedScene = load("res://" + path)
	var node: Node = scene.instantiate()
	root.add_child(node)
	node.set_process(false)
	return node

func baseline(path: String) -> Node:
	var script := GDScript.new()
	var source := FileAccess.get_file_as_string(OUT + "before/" + path)
	var re := RegEx.new()
	re.compile("(?m)^class_name .*\\n")
	script.source_code = re.sub(source, "", true)
	check(script.reload() == OK, "baseline compiles: " + path)
	var node: Node = script.new()
	root.add_child(node)
	node.set_process(false)
	return node

func positions(node: Node) -> Array:
	var result: Array = []
	for p in node.data_points: result.append(p.position)
	return result

func run() -> void:
	var loss_path := "algorithms/machinelearning/loss_function_comparator/loss_function_comparator"
	var old := baseline(loss_path + ".gd")
	var sample: Array = old._data_y.duplicate()
	old._on_reset_pressed()
	check(sample != old._data_y, "reproduced old RESET redrawing observations")
	old.free()
	var loss := mount(loss_path + ".tscn")
	loss._on_outlier_changed(0.0)
	var clean: Array = loss._data_y.duplicate()
	var previous: Array = clean.duplicate()
	var nested := true
	var counts: Array = []
	for fraction in [0.1, 0.25, 0.5, 0.8, 1.0]:
		loss._on_outlier_changed(fraction)
		var count := 0
		for i in clean.size():
			if previous[i] != clean[i]: nested = nested and loss._data_y[i] == previous[i]
			if loss._data_y[i] != clean[i]: count += 1
		counts.append(count)
		previous = loss._data_y.duplicate()
	check(nested and counts[-1] > counts[0], "higher outlier setting retains existing alternates and adds more")
	evidence.outlier_counts = counts
	loss._on_outlier_changed(0.25)
	var fixed: Array = loss._data_y.duplicate()
	loss._gradient_step(0)
	loss._step_timer = 0.07
	loss._on_reset_pressed()
	check(fixed == loss._data_y, "RESET keeps selected observations")
	check(loss._step_timer == 0 and loss._ball_positions == [Vector2(1.5,1),Vector2(1.5,1),Vector2(1.5,1)], "RESET repeats all three starts and timer")
	loss._on_outlier_changed(1.0)
	loss._on_outlier_changed(0.25)
	check(fixed == loss._data_y, "returning slider to a setting repeats the sample")
	loss.tail = "none"
	loss._regenerate()
	check(clean == loss._data_y, "NONE and slider zero share the same clean baseline")
	var shared: Array = loss._data_y.duplicate()
	var scores: Array = []
	for i in 3: scores.append(loss._eval_loss(i, 0.3, 0.2))
	check(shared == loss._data_y and scores[0] != scores[2], "three losses score the same candidate without changing the data")
	loss.free()

	var km := mount("algorithms/machinelearning/kmeansclustering/enhanced_kmeans.tscn")
	check(km.natural_cluster_count == 4, "standalone scene default preserved")
	km.apply_grid_config({"natural_cluster_count":3,"lesson_controls":"on"})
	check(km.natural_cluster_count == 3 and km.cluster_count == 4, "museum override gives three blobs and four centres")
	check(not km.ui_container.visible and km._lesson_controls.get_child_count() == 9, "spatial controls replace desktop overlay in lesson")
	var points := positions(km)
	km._lesson_controls.get_node("STEP/InteractableAreaButton").button_pressed.emit(null)
	check(km._lesson_label.text.contains("Total distance:") and km.iteration == 1 and km.is_paused and points == positions(km), "STEP changes assignments/centres while points stay fixed")
	for expected in ["rings", "block", "blobs"]:
		km._lesson_controls.get_node("DATASET/InteractableAreaButton").button_pressed.emit(null)
		check(km.cohort == expected and km.cluster_count == 4 and km.is_paused and km.iteration == 0, "DATASET selects " + expected + " with K fixed and a paused start")
	check(points == positions(km), "return to BLOBS repeats the data")
	km._lesson_controls.get_node("PAUSE_RUN/InteractableAreaButton").button_pressed.emit(null)
	check(not km.is_paused, "RUN resumes the lesson")
	km._lesson_controls.get_node("RESET/InteractableAreaButton").button_pressed.emit(null)
	check(km.is_paused and km.iteration == 0 and points == positions(km), "RESET repeats the selected lesson without a redraw")
	km.apply_grid_config({"lesson_controls":"on"})
	check(km.find_children("LessonControls", "Node3D", false, false).size() == 1, "reapplying lesson configuration does not duplicate controls")
	km.free()
	# The museum can configure an instance before it enters the scene tree.
	km = load("res://algorithms/machinelearning/kmeansclustering/enhanced_kmeans.tscn").instantiate()
	km.apply_grid_config({"natural_cluster_count":3,"lesson_controls":"on"})
	root.add_child(km)
	km.set_process(false)
	var hidden := true
	for child in km.get_children():
		if child is CanvasLayer: hidden = hidden and not child.visible
	check(hidden and is_instance_valid(km._lesson_controls), "pre-ready configuration hides all k-means overlays and builds controls")
	km.free()
	for path in ["supportvectormachine/svm_visualization", "pca/pca_visualization", "randomforest/random_forest_visualization"]:
		var support: Node = load("res://algorithms/machinelearning/" + path + ".tscn").instantiate()
		support.apply_grid_config({"desktop_ui":"off"})
		root.add_child(support)
		support.set_process(false)
		check(not support.ui_display.visible, path + ": pre-ready museum setting hides overlay")
		check(support.ui_display.has_node("Panel/VBoxContainer/info_label_0"), path + ": stable UI paths remain valid")
		support.apply_grid_config({"desktop_ui":"on"})
		check(support.ui_display.visible, path + ": desktop UI can be restored in place")
		support.free()

	var gan_path := "algorithms/machinelearning/generative_adversarial_networks_GANs/GenerativeAdversarialNetworksGANs_VR"
	old = baseline(gan_path + ".gd")
	check(old.real_data_particles.is_empty() and old.fake_data_particles.is_empty(), "reproduced missing example particles in old diagram")
	old.free()
	var gan := mount(gan_path + ".tscn")
	check(gan.real_data_particles.size() == 10 and gan.fake_data_particles.size() == 10, "diagram creates ten reference and ten candidate particles")
	gan.position = Vector3(12, 0, 12)
	gan.scale = Vector3.ONE * 0.8
	gan._process(1.0)
	check(gan._metrics_label.text.contains("Scripted loss") and gan._metrics_label.text.contains("No models trained") and gan._metrics_label.text.contains("0.93"), "visible metrics update and declare diagram status")
	var item: Dictionary = gan.fake_data_particles[0]
	var target: Vector3 = gan.to_global(Vector3(gan.room_separation,2,0))
	item.progress = 0.999
	gan._animate_data_flow(0.0)
	check(item.node.global_position.distance_to(target) < 0.05, "candidate reaches discriminator in a transformed museum placement")
	gan.reset_training()
	check(gan._metrics_label.text.contains("1.00") and gan.generation_quality == 0.0, "diagram reset resets displayed script state")
	gan.free()

	var memory := mount("algorithms/machinelearning/LSTMs/LSTMs_VR.tscn")
	var explicit := false
	for label in memory.find_children("*", "Label3D", true, false):
		explicit = explicit or label.text.contains("No sequence is learned here")
	check(explicit and memory.memory_particles.size() == 20, "memory diagram declares scope and retains its animated stream")
	memory.free()
	var failed := checks.filter(func(c): return not c.ok)
	var f := FileAccess.open(OUT + "model-checks.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failed,"evidence":evidence,"scope":"Controlled model and wired-signal checks, not tracked-hand interaction"}, "  "))
	f.close()
	print("ML_MODELS ", checks.size(), " checks, failures: ", failed)
	quit(0 if failed.is_empty() else 1)
