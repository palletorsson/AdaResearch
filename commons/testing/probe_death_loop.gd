extends SceneTree
## THE DEATH, AND THEN AGAIN (2026-08-25, Palle: "can you test the death effect
## and loop works?"). One death proves the effect; three prove the LOOP — that
## the museum tears the end scene down as cleanly as it puts it up, that the
## walker can die in the same pool twice, and that nothing accumulates.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_death_loop.gd

const OUT := "res://ada_run/death_loop.txt"
var rep := "THE DEATH LOOP\n"
var _inst: Node3D = null
var _player: Node3D = null


func _initialize() -> void:
	call_deferred("_run")


## the end scene, sampled: what is on the glass right now
func _state() -> Dictionary:
	var layer: Variant = _inst.get("_death_layer")
	var splat: Variant = _inst.get("_death_splat")
	var veil: Variant = _inst.get("_death_veil")
	var line: Variant = _inst.get("_death_line")
	var pr: Variant = (splat as Object).get("progress") if splat != null else null
	return {
		"built": layer != null,
		"visible": (layer as CanvasLayer).visible if layer != null else false,
		"splat": float(pr) if pr is float else -1.0,
		"veil": (veil as ColorRect).color.a if veil != null else -1.0,
		"line": (line as Label).modulate.a if line != null else -1.0,
		"words": String((line as Label).text) if line != null else "",
		"dying": bool(_inst.get("_dying")),
		"deaths": int(_inst.get("_deaths")),
		"y": _player.position.y}


func _row(t: float) -> String:
	var s: Dictionary = _state()
	return "    %4.1fs  splat %.2f  veil %.2f  line %.2f  dying=%-5s  y %6.2f" % [
		t, s["splat"], s["veil"], s["line"], str(s["dying"]), s["y"]]


## one death, sampled from the touch to the far side of the fade
func _die(label: String, how: Callable) -> void:
	rep += "  %s\n" % label
	how.call()
	var t := 0.0
	var peak_splat := 0.0
	var peak_veil := 0.0
	var said: Array = []
	while t < 4.2:
		await create_timer(0.3).timeout
		t += 0.3
		var s: Dictionary = _state()
		peak_splat = maxf(peak_splat, float(s["splat"]))
		peak_veil = maxf(peak_veil, float(s["veil"]))
		if String(s["words"]) != "" and not said.has(String(s["words"])):
			said.append(String(s["words"]))
		if is_equal_approx(fmod(t, 0.9), 0.0) or t < 0.7:
			rep += _row(t) + "\n"
	var e: Dictionary = _state()
	rep += "    peak splatter %.2f, peak black %.2f, said \"%s\"\n" % [peak_splat, peak_veil,
		"/".join(said)]
	rep += "    ended: visible=%s dying=%s deaths=%d standing at y %.2f\n" % [
		str(e["visible"]), str(e["dying"]), int(e["deaths"]), float(e["y"])]
	var ok: bool = peak_splat > 0.9 and peak_veil > 0.9 and not bool(e["dying"]) \
		and not bool(e["visible"]) and absf(float(e["y"])) < 0.6
	rep += "    %s\n" % ("PASS" if ok else "FAIL (splatter, black, tear-down or footing)")


func _run() -> void:
	_inst = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	_inst.set("EM_CONTROL", "res://ada_run/_trial_dl_control.json")
	_inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	_inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	_inst.set("start_chapter", "transformation")
	_inst.set("start_map", "Trans_Introduction")
	var ctl := FileAccess.open("res://ada_run/_trial_dl_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "transformation",
		"first_map": "Trans_Introduction", "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(_inst)
	await create_timer(3.0).timeout
	_inst.call("flush_stamps")
	await create_timer(2.0).timeout
	_player = _inst.get("_player") as Node3D

	# where the fire is, so the walker can be dropped in it twice
	var seg: Node3D = null
	for s_v in _inst.get("_segments"):
		var sd: Dictionary = s_v
		if String(sd.get("pearl", "")) == "trans introduction":
			seg = sd.get("node")
	var pool := Vector3.ZERO
	var fires: Array = seg.find_children("BasinFire", "Area3D", true, false) if seg != null else []
	if not fires.is_empty():
		for c in (fires[0] as Area3D).get_children():
			if c is CollisionShape3D:
				pool = (c as CollisionShape3D).global_position
				break
	rep += "  the pool's fire sits at %s\n" % str(pool)
	rep += "  save point: %s\n\n" % str(_inst.call("_save_point_now"))

	await _die("DEATH 1 — walked into the fire", func() -> void:
		_player.position = pool + Vector3(0.0, 0.3, 0.0))
	rep += "\n"
	# THE LOOP: the same pool, a second time. If the end scene did not tear
	# itself down, or body_entered never fires again, this is where it shows.
	await _die("DEATH 2 — the same pool again (the loop)", func() -> void:
		_player.position = pool + Vector3(0.0, 0.3, 0.0))
	rep += "\n"
	await _die("DEATH 3 — the beam", func() -> void:
		_inst.call("on_lethal_touch", "laser", pool))

	# nothing may accumulate: one layer, one splatter, one veil, whatever the
	# death count — a leak here is invisible until the twentieth death
	var layers := 0
	for n in _inst.find_children("DeathScene", "CanvasLayer", true, false):
		layers += 1
	rep += "\n  end scenes in the tree: %d (must be 1)\n" % layers
	rep += "  deaths counted: %d (must be 3)\n" % int(_inst.get("_deaths"))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
