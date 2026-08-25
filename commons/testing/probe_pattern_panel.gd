extends SceneTree
## THE PANEL RE-DRESSES THE ROOM (2026-08-25, Palle: "can we put a panel on the
## wall where i can change the whole room?"). Builds a hall that declares a
## pattern, finds its panel, and cycles it — then asks the multimeshes whether
## the room actually changed, which is the only question that matters.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_pattern_panel.gd

const OUT := "res://ada_run/pattern_panel.txt"


func _initialize() -> void:
	call_deferred("_run")


## a fingerprint of what the hall's big surfaces are wearing
func _skin(seg: Node3D) -> Dictionary:
	var out: Dictionary = {}
	for mm_v in seg.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := mm_v as MultiMeshInstance3D
		var m: Material = mmi.material_override
		if m == null and mmi.multimesh != null and mmi.multimesh.mesh != null:
			m = mmi.multimesh.mesh.surface_get_material(0)
		if not (m is StandardMaterial3D):
			continue
		var t: Texture2D = (m as StandardMaterial3D).albedo_texture
		if t == null or t.get_width() != 192:
			continue
		var n: int = mmi.multimesh.instance_count if mmi.multimesh != null else 0
		out[mmi.get_path()] = {"tex": t.get_instance_id(), "n": n}
	return out


func _run() -> void:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_pp_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("start_chapter", "color")
	inst.set("start_map", "Symmetry_Seventeen")
	var ctl := FileAccess.open("res://ada_run/_trial_pp_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "color", "first_map": "Symmetry_Seventeen",
		"dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.5).timeout
	inst.call("flush_stamps")
	await create_timer(1.5).timeout

	var rep := "THE ROOM'S PANEL\n"
	var panels: Array = inst.get("_pattern_panels")
	rep += "  panels built: %d\n" % panels.size()
	if panels.is_empty():
		rep += "  FAIL no panel — does the hall declare museum.pattern?\n"
	else:
		var pr: Dictionary = panels[0]
		var plate: Node3D = pr.get("plate")
		var lab: Label3D = pr.get("label")
		var seg: Node3D = pr.get("seg")
		rep += "  the plate stands at %s\n" % str(plate.position)
		rep += "  it reads: \"%s\"\n" % String(lab.text).replace("\n", " / ")
		var before: Dictionary = _skin(seg)
		var boxes := 0
		for k in before:
			boxes += int((before[k] as Dictionary)["n"])
		rep += "  the room wears %d patterned surface group(s), %d boxes\n" % [before.size(), boxes]
		inst.call("_pattern_cycle", pr)
		await create_timer(0.6).timeout
		var after: Dictionary = _skin(seg)
		var changed := 0
		for k in after:
			if before.has(k) and int((after[k] as Dictionary)["tex"]) != int((before[k] as Dictionary)["tex"]):
				changed += int((after[k] as Dictionary)["n"])
		rep += "  after one click it reads: \"%s\"\n" % String(lab.text).replace("\n", " / ")
		rep += "  boxes whose texture changed: %d\n" % changed
		rep += "  %s\n" % ("PASS the panel re-dresses the room" if changed >= 100
			else "FAIL only %d boxes changed" % changed)
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
