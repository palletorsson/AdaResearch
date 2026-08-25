extends SceneTree
## THE DEATH, END TO END (2026-08-24, Palle: "if the player falls into the pool
## reset to the last save point ... the laser should also kill you ... splatter
## animation on screen, to the endscene, back to the last save point").
## Three questions: does the fire kill, does the laser kill, and does the end
## scene actually exist on screen while it happens.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_museum_death.gd

const OUT := "res://ada_run/museum_death.txt"
var rep := "MUSEUM DEATH\n"


func _initialize() -> void:
	call_deferred("_run")


## the end scene, read defensively: every one of these is null until the
## first death builds the layer, and float(null) is not a float
func _scene_state(inst: Node) -> String:
	var layer: Variant = inst.get("_death_layer")
	var splat: Variant = inst.get("_death_splat")
	var line: Variant = inst.get("_death_line")
	var pr: Variant = (splat as Object).get("progress") if splat != null else null
	var kd: Variant = (splat as Object).get("kind") if splat != null else null
	return "end scene built=%s visible=%s kind=%s progress=%s line=\"%s\"" % [
		layer != null,
		str((layer as CanvasLayer).visible) if layer != null else "-",
		str(kd) if kd != null else "-",
		("%.2f" % float(pr)) if pr is float else "-",
		String((line as Label).text) if line != null else "-"]


func _run() -> void:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_md_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_md_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_md_hand.json")
	inst.set("start_chapter", "transformation")
	inst.set("start_map", "Trans_Introduction")
	var ctl := FileAccess.open("res://ada_run/_trial_md_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "transformation",
		"first_map": "Trans_Introduction", "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(2.5).timeout
	inst.call("flush_stamps")
	await create_timer(1.5).timeout

	var player: Node3D = inst.get("_player") as Node3D
	rep += "  in the lethal group: %d node(s)\n" % get_nodes_in_group("em_lethal").size()

	# ── the fire ─────────────────────────────────────────────────────────
	var seg: Node3D = null
	for s_v in inst.get("_segments"):
		var sd: Dictionary = s_v
		if String(sd.get("pearl", "")) == "trans introduction":
			seg = sd.get("node")
	var fires: Array = seg.find_children("BasinFire", "Area3D", true, false) if seg != null else []
	if fires.is_empty() or player == null:
		rep += "  FAIL no fire to fall into\n"
	else:
		var sh: CollisionShape3D = null
		for c in (fires[0] as Area3D).get_children():
			if c is CollisionShape3D:
				sh = c as CollisionShape3D
				break
		var pool: Vector3 = sh.global_position
		player.position = pool + Vector3(0.0, 0.3, 0.0)
		await create_timer(0.4).timeout
		var layer: Node = inst.get("_death_layer")
		var splat: Node = inst.get("_death_splat")
		rep += "  FIRE: end scene built=%s  visible=%s  kind=%s  progress=%.2f\n" % [
			layer != null, (layer as CanvasLayer).visible if layer != null else false,
			str(splat.get("kind")) if splat != null else "-",
			float(splat.get("progress")) if splat != null else -1.0]
		# the whole sequence is about 3 s of splatter, black, and back
		await create_timer(4.5).timeout
		rep += "  FIRE: walker at %s (%.1f m from the pool), dying=%s\n" % [str(player.position),
			player.position.distance_to(pool), str(inst.get("_dying"))]
		rep += "  FIRE: %s\n" % ("BURNED and returned" if player.position.distance_to(pool) > 2.0 else "FAIL still in the pool")

	# ── the laser ────────────────────────────────────────────────────────
	# no laser stands in this hall, so ask the artifact itself: does a beam
	# that hits the player reach the museum's death at all
	var lm: Node3D = (load("res://commons/primitives/laser_measure/grab_laser_measure.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(lm)
	await create_timer(0.4).timeout
	# THE SCRIPT IS NOT ON THE ROOT — walk down, the way the museum now does
	var armed := 0
	var holder: Node = null
	for c in lm.find_children("*", "Node3D", true, false):
		if "lethal" in c:
			c.set("lethal", true)
			holder = c
			armed += 1
	rep += "  LASER: armed %d node(s) under the root; root itself has lethal=%s
" % [
		armed, str("lethal" in lm)]
	if holder != null:
		rep += "  LASER: %s carries it, lethal=%s min_distance=%s
" % [holder.name,
			str(holder.get("lethal")), str(holder.get("lethal_min_distance"))]
	var before: Vector3 = player.position
	inst.call("on_lethal_touch", "laser", lm.global_position)
	await create_timer(0.5).timeout
	rep += "  LASER: %s
" % _scene_state(inst)
	await create_timer(4.5).timeout
	rep += "  LASER: walker moved %.1f m, deaths=%d
" % [player.position.distance_to(before), int(inst.get("_deaths"))]

	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
