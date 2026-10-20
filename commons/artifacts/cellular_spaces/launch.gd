extends Node3D
## F6 opens the pair in the real museum; keep resume and edits in their own folder.
const ROOT := "res://commons/artifacts/cellular_spaces/"
const RUN := "user://cellular-spaces/"
@export_enum("womb", "commons") var first_space := "womb"
var museum: Node3D

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--cellular-form=commons": first_space="commons"
	var first_map := "Noise_Cellular_Womb" if first_space=="womb" else "Noise_Cellular_Commons"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RUN))
	var xr := XRServer.find_interface("OpenXR")
	var args := OS.get_cmdline_args()
	var disabled := false
	for i in range(args.size()-1):
		if args[i]=="--xr-mode" and args[i+1]=="off": disabled=true
	if not disabled and xr!=null and not xr.is_initialized(): xr.initialize()
	if xr!=null and xr.is_initialized():
		get_viewport().use_xr=true
		add_child(load("res://commons/scenes/base.tscn").instantiate())
	# Follow the project's isolated museum-launch pattern. Snapshot current logic,
	# redirect only evidence/control paths, and retain the actual museum renderer.
	var source := FileAccess.get_file_as_string("res://commons/scenes/endless_museum.gd")
	var paths := RegEx.new()
	paths.compile('res://ada_run/[A-Za-z0-9_\\-]+\\.(?:json|txt)')
	var redirected: Dictionary={}
	for found in paths.search_all(source):
		var original := found.get_string()
		if redirected.has(original): continue
		redirected[original]=true
		var destination := RUN+original.get_file()
		if FileAccess.file_exists(original):
			FileAccess.open(destination,FileAccess.WRITE).store_string(FileAccess.get_file_as_string(original))
		source=source.replace(original,destination)
	var bake := "res://commons/data/museum/em_bake.json"
	FileAccess.open(RUN+"em_bake.json",FileAccess.WRITE).store_string(FileAccess.get_file_as_string(bake))
	source=source.replace(bake,RUN+"em_bake.json")
	FileAccess.open(RUN+"museum_snapshot.gd",FileAccess.WRITE).store_string(source)
	FileAccess.open(RUN+"overrides.json",FileAccess.WRITE).store_string("{}")
	FileAccess.open(RUN+"control.json",FileAccess.WRITE).store_string(JSON.stringify({"first_chapter":"noise","first_map":first_map,"dollhouse":0}))
	museum=Node3D.new()
	museum.set_script(load(RUN+"museum_snapshot.gd"))
	museum.name="Museum"
	museum.set("EM_CONTROL",RUN+"control.json")
	museum.set("_hand_path",RUN+"necklace_hand.json")
	museum.set("_overrides_path",RUN+"overrides.json")
	museum.set("start_chapter","noise")
	museum.set("start_map",first_map)
	museum.set("plan_file",ROOT+"museum_plan.json")
	add_child(museum)
