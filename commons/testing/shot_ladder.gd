extends SceneTree
## THE LADDER, photographed twice: the plan view (camera at noon over the
## point hall), then the spine strip open over it. Windowed — a screenshot
## needs a renderer.

const CTL := "res://ada_run/_doll_trial_control.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "", "dollhouse": 1}, " "))
	f.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", "res://ada_run/_doll_trial_overrides.json")
	get_root().add_child(inst)
	await create_timer(2.0).timeout
	var pl: CharacterBody3D = inst.get("_player")
	if pl != null:
		pl.position = Vector3(7.0, 0.0, 13.0)
	inst.set("_doll_zoom", 17.0)
	inst.set("_doll_top", true)           # straight to the plan
	await create_timer(5.0).timeout       # wake ramp, recut, the climb's butter
	var img := get_root().get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://ada_run/ladder_plan.png"))
	inst.call("_spine_toggle")            # the strip over the plan
	await create_timer(1.0).timeout
	var img2 := get_root().get_viewport().get_texture().get_image()
	img2.save_png(ProjectSettings.globalize_path("res://ada_run/ladder_strip.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	print("LADDER SHOTS saved")
	quit(0)
