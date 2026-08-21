extends SceneTree
## THE TRANSPLANT, photographed: the point hall in grid-pack mode from the
## plan view at noon — the grid map's own constellation standing on the
## museum's floor. (windowed — a screenshot needs a renderer)

const CTL := "res://ada_run/_doll_trial_control.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "",
		"dollhouse": 1, "grid_pack": 1}, " "))
	f.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", "res://ada_run/_doll_trial_overrides.json")
	get_root().add_child(inst)
	await create_timer(2.0).timeout
	var pl: CharacterBody3D = inst.get("_player")
	if pl != null:
		pl.position = Vector3(7.0, 0.0, 18.0)   # the tile's centre — the ruler's word, not a theory's
	inst.set("_doll_zoom", 13.0)
	inst.set("_doll_top", true)
	inst.set("_doll_yaw", 0.0)                    # square to the grid, like the map editor
	await create_timer(5.0).timeout
	var img := get_root().get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://ada_run/gridpack_plan.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	print("GRIDPACK SHOT saved")
	quit(0)
