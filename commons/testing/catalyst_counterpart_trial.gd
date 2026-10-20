extends Node3D
## F6 launches the real museum and XR rig with an optional counterpart experiment.
## Generated museum snapshot only redirects output files; the scene logic is current.
const RUN := "user://catalyst-counterpart-trial/"
@export var trial_sequence := "transformation"
@export var trial_map := "Trans_Pre"
@export var trial_plan := "res://commons/data/museum/em_plan.json"
@export var run_directory := RUN
var trial: Node3D

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(run_directory))
	var xr := XRServer.find_interface("OpenXR")
	var args := OS.get_cmdline_args()
	var disabled := false
	for i in range(args.size() - 1):
		if args[i] == "--xr-mode" and args[i + 1] == "off": disabled = true
	if not disabled and xr != null and not xr.is_initialized(): xr.initialize()
	if xr != null and xr.is_initialized():
		get_viewport().use_xr = true
		add_child(load("res://commons/scenes/base.tscn").instantiate())
	# Isolate the museum's resume, edits and evidence outputs from the main walk.
	var source := FileAccess.get_file_as_string("res://commons/scenes/endless_museum.gd")
	var paths := RegEx.new()
	paths.compile('res://ada_run/[A-Za-z0-9_\\-]+\\.(?:json|txt)')
	var redirected: Dictionary = {}
	for match_result in paths.search_all(source):
		var original := match_result.get_string()
		if redirected.has(original): continue
		redirected[original] = true
		var destination := run_directory + original.get_file()
		if FileAccess.file_exists(original):
			FileAccess.open(destination, FileAccess.WRITE).store_string(FileAccess.get_file_as_string(original))
		source = source.replace(original, destination)
	var bake := "res://commons/data/museum/em_bake.json"
	FileAccess.open(run_directory + "em_bake.json", FileAccess.WRITE).store_string(FileAccess.get_file_as_string(bake))
	source = source.replace(bake, run_directory + "em_bake.json")
	FileAccess.open(run_directory + "museum_snapshot.gd", FileAccess.WRITE).store_string(source)
	var overrides := "res://commons/data/museum/em_overrides.json"
	FileAccess.open(run_directory + "overrides.json", FileAccess.WRITE).store_string(FileAccess.get_file_as_string(overrides) if FileAccess.file_exists(overrides) else "{}")
	FileAccess.open(run_directory + "control.json", FileAccess.WRITE).store_string(JSON.stringify({"first_chapter":trial_sequence, "first_map":trial_map, "dollhouse":0}))
	var museum := Node3D.new()
	museum.set_script(load(run_directory + "museum_snapshot.gd"))
	museum.name = "Museum"
	museum.set("EM_CONTROL", run_directory + "control.json")
	museum.set("_hand_path", run_directory + "necklace_hand.json")
	museum.set("_overrides_path", run_directory + "overrides.json")
	museum.set("start_chapter", trial_sequence)
	museum.set("start_map", trial_map)
	museum.set("plan_file", trial_plan)
	add_child(museum)
	var began := Time.get_ticks_msec()
	while not bool(museum.get("_museum_core_ready")) and Time.get_ticks_msec() - began < 60000:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	museum.flush_stamps()
	await get_tree().physics_frame
	for child in museum.get_children():
		if child is Node3D and str(child.get_meta("em_map", "")) == trial_map:
			if trial_map == "Catalyst_Opening_Progression":
				trial = load("res://commons/hazards/catalyst_counterpart/opening_progression.gd").mount_progression(child)
			elif trial_map == "Catalyst_Test_Arena":
				trial = load("res://commons/hazards/catalyst_counterpart/test_arena.gd").mount_arena(child)
			elif trial_map == "Catalyst_First_Abilities":
				trial = load("res://commons/hazards/catalyst_counterpart/proving_ground.gd").mount_test(child)
			elif trial_map == "Primitives_Melencolia":
				for node in child.find_children("*", "Node3D", true, false):
					if node.get_script() != null and str(node.get_script().resource_path).ends_with("/EngravingScene.gd"):
						trial = load("res://commons/hazards/catalyst_counterpart/tableau_preview.gd").mount(node)
						break
			else:
				trial = load("res://commons/hazards/catalyst_counterpart/counterpart_trial.gd").mount(museum, child)
			break
	if trial == null: push_error("Counterpart trial could not mount in " + trial_map)
	else: print("[counterpart] Ready in ", trial_map)
