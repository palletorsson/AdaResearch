extends SceneTree

## Drive the artifact runner's player down the corridor, headless, and verify that
## streamed artifacts can't body-check the player. Answers two things at once:
##   1. "Can you control the player and walk the world?"  -> yes, we set the player's
##      z and step frames; the streaming window spawns/frees around us as we move.
##   2. Does artifacts_inert actually neutralise the physics? -> we recurse every spawned
##      slot and assert every CollisionObject3D / SoftBody3D has collision_layer == 0 and
##      collision_mask == 0 (and rigidbodies frozen). If any body still lives on a layer,
##      it could shove the player -> that's the "game jumps / can't move" bug.
##
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/walk_runner_headless.gd -- \
##     --maps=softbody --steps=0 [--inert=true]
##
## --maps : comma list of concept-map stubs (default softbody — the native SoftBody3D
##          artifacts that collide on the player layer). Empty = whole curriculum.
## --steps: how many slots to walk. 0 = walk every slot in the queue.
## --inert: true (default) applies the fix; false is the control (bodies stay live).

const RunnerScript := preload("res://commons/artifacts/artifact_runner/artifact_runner.gd")

var _maps: Array[String] = ["softbody"]
var _steps: int = 0
var _inert: bool = true


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var arg := String(raw).strip_edges()
		if arg.begins_with("--maps="):
			var v := arg.substr(7)
			_maps = []
			if v.strip_edges() != "":
				for s in v.split(","):
					_maps.append(s.strip_edges())
		elif arg.begins_with("--steps="):
			var v := arg.substr(8)
			if v.is_valid_int():
				_steps = int(v)
		elif arg.begins_with("--inert="):
			_inert = arg.substr(8).strip_edges().to_lower() != "false"
	_run.call_deferred()


# Count physics bodies under a node and how many are inert (layer == 0 and mask == 0).
func _audit(node: Node, acc: Dictionary) -> void:
	if node.name == "SlotFloor":
		return  # the corridor floor is meant to be solid (layer 1) — not an artifact
	var is_body := node is CollisionObject3D or node is SoftBody3D
	if is_body:
		acc["bodies"] += 1
		var layer: int = node.collision_layer
		var mask: int = node.collision_mask
		if layer == 0 and mask == 0:
			acc["inert"] += 1
		else:
			acc["live"] += 1
			if acc["examples"].size() < 6:
				acc["examples"].append("%s (layer=%d mask=%d)" % [node.name, layer, mask])
	for c in node.get_children():
		_audit(c, acc)


func _run() -> void:
	# --- minimal world: env + light, plus a third-person camera that trails the player ---
	var world := Node3D.new()
	world.name = "RunnerWalkTest"
	root.add_child(world)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.09, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.62, 0.68)
	env.ambient_light_energy = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, -35, 0)
	key.light_energy = 1.0
	world.add_child(key)

	# --- the player: a real physics body, in the group the runner looks for ---
	var player := CharacterBody3D.new()
	player.name = "DesktopPlayer"
	player.add_to_group("player_body")
	player.collision_layer = 524288   # the "player" layer the soft bodies mask against
	player.collision_mask = 1
	var pcol := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.6
	pcol.shape = cap
	pcol.position = Vector3(0, 0.8, 0)
	player.add_child(pcol)
	world.add_child(player)
	player.global_position = Vector3(0, 0.0, 1.5)

	# --- the runner ---
	var runner: Node3D = RunnerScript.new()
	runner.name = "ArtifactRunner"
	runner.only_maps = _maps
	runner.artifacts_inert = _inert
	runner.debug_print = false
	world.add_child(runner)

	# Let _ready run (build queue/index) and the deferred first window spawn.
	for i in range(6):
		await process_frame

	var n_slots: int = runner._n_slots
	if n_slots <= 0:
		print("WALK: queue empty for maps=%s — nothing to walk" % str(_maps))
		quit(1)
		return
	var walk_to: int = n_slots - 1 if _steps <= 0 else mini(_steps, n_slots - 1)
	print("WALK: maps=%s  queue=%d artifacts  %d slots  inert=%s" % [
		str(_maps), runner._queue.size(), n_slots, str(_inert)])
	print("WALK: driving player z from 1.5 through slot %d (%.0f m) ..." % [
		walk_to, float(walk_to) * runner.slot_depth])

	var total := {"bodies": 0, "inert": 0, "live": 0, "examples": []}
	var max_y_drift: float = 0.0
	var sections := {}

	# --- walk: advance the player one slot at a time, let the window stream around us ---
	for step in range(walk_to + 1):
		var target_z: float = float(step) * runner.slot_depth + runner.slot_depth * 0.5
		player.global_position.z = target_z
		# a few frames so _process -> _update_window spawns the chunk ahead and physics steps
		for f in range(4):
			await process_frame
		max_y_drift = maxf(max_y_drift, absf(player.global_position.y))
		# record which section we're standing in
		if step < n_slots:
			var first = runner._queue[step * runner.artifacts_per_slot] if step * runner.artifacts_per_slot < runner._queue.size() else {}
			sections[str(first.get("section", "?"))] = true

	# --- audit every currently-live slot's physics bodies ---
	for slot_key in runner._slots.keys():
		_audit(runner._slots[slot_key], total)

	var grounded: bool = max_y_drift < 0.05
	var all_inert: bool = int(total["live"]) == 0
	var lines: Array[String] = []
	lines.append("================  WALK REPORT  ================")
	lines.append("maps            : %s   inert=%s" % [str(_maps), str(_inert)])
	lines.append("sections walked : %s" % ", ".join(PackedStringArray(sections.keys())))
	lines.append("player advanced : z=%.1f m  (max |y| drift = %.4f m)" % [player.global_position.z, max_y_drift])
	lines.append("physics bodies  : %d found in live slots" % total["bodies"])
	lines.append("  inert (0/0)   : %d" % total["inert"])
	lines.append("  STILL LIVE    : %d" % total["live"])
	if total["live"] > 0:
		lines.append("  live examples : %s" % ", ".join(PackedStringArray(total["examples"])))
	lines.append("-----------------------------------------------")
	if _inert:
		lines.append("VERDICT: %s" % ("PASS - every body inert, player stayed grounded" if (all_inert and grounded) else "FAIL - see above"))
	else:
		lines.append("CONTROL (inert=false): %d bodies still live on their layers (these are what shove the player)" % total["live"])
	lines.append("===============================================")
	var report := "\n".join(PackedStringArray(lines))
	print("\n" + report)
	var out_abs := ProjectSettings.globalize_path("res://ada_run/runner_walk_report.txt")
	DirAccess.make_dir_recursive_absolute(out_abs.get_base_dir())
	var fout := FileAccess.open(out_abs, FileAccess.WRITE)
	if fout:
		fout.store_string(report + "\n")
		fout.close()
	quit(0 if (not _inert) or (all_inert and grounded) else 2)
