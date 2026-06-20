# Runtime verification harness for the poke/dent native-SoftBody3D artifacts.
# Instances each artifact into a live physics world, steps physics frames, and checks:
#   1. _build()/_ready() ran without throwing,
#   2. a SoftBody3D child exists and is PLAYER-pokable (collision_mask == 1|524288),
#   3. the soft body SIMULATED — its rendered verts moved from the authored rest mesh after stepping,
#   4. apply_grid_config({"emissive": true}) rebuilds cleanly.
# Run: godot --path . --xr-mode off --no-window --script res://commons/testing/_verify_poke_dent.gd
extends SceneTree

const TARGETS := [
	"res://commons/artifacts/poke_dough_toy/poke_dough_toy.gd",
	"res://commons/artifacts/pressure_balloon/pressure_balloon.gd",
	"res://commons/artifacts/poke_pillar_room/poke_pillar_room.gd",
	"res://commons/artifacts/squish_press/squish_press.gd",
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var all_ok := true
	for path in TARGETS:
		if not await _check(path):
			all_ok = false
	print("================================================")
	if all_ok:
		print("VERIFY RESULT: ALL PASS")
	else:
		print("VERIFY RESULT: FAILURE")
	quit(0 if all_ok else 1)


func _check(path: String) -> bool:
	print("------------------------------------------------")
	print("[verify] ", path)
	var scr: Script = load(path)
	if scr == null:
		push_error("could not load script: " + path)
		return false
	var inst = scr.new()
	if inst == null or not (inst is Node3D):
		push_error("instance is not a Node3D: " + path)
		return false

	var holder := Node3D.new()
	root.add_child(holder)
	holder.add_child(inst)   # triggers _ready -> _build

	# Let the deferred _apply_pins()/_snapshot_rest() run.
	await process_frame
	await process_frame

	var bodies: Array = _find_all_soft(inst)
	if bodies.is_empty():
		push_error("no SoftBody3D child found: " + path)
		holder.queue_free()
		return false
	var sb: SoftBody3D = bodies[0]

	var layer_ok: bool = sb.collision_mask == (1 | 524288)
	if not layer_ok:
		push_error("SoftBody3D collision_mask not PLAYER-pokable (got %d): %s"
			% [sb.collision_mask, path])

	# Snapshot rest verts, then step physics so gravity/pins/pressure/press deform the body.
	var rest := _mesh_verts(sb)
	for _i in range(40):
		await physics_frame
	var moved := _max_vertex_drift(sb, rest)
	print("    soft bodies: %d   first body verts: %d   max drift after 40 ticks: %.4f m"
		% [bodies.size(), rest.size(), moved])

	var deformed_ok: bool = moved > 0.002    # any real soft motion at all
	if not deformed_ok:
		push_error("SoftBody3D did not deform (max drift %.5f) — may be rigid/over-pinned: %s"
			% [moved, path])

	# If the artifact has a live readout (squish_press), confirm _process ran and printed strain.
	var readout = inst.get("_readout") if "_readout" in inst else null
	if readout != null and is_instance_valid(readout):
		print("    readout: \"%s\"" % readout.text)

	# Rebuild via apply_grid_config to make sure the config path doesn't throw.
	var cfg_ok := true
	if inst.has_method("apply_grid_config"):
		inst.apply_grid_config({"emissive": true})
		await process_frame
		var after: Array = _find_all_soft(inst)
		if after.is_empty():
			push_error("apply_grid_config rebuild lost the SoftBody3D: " + path)
			cfg_ok = false
		else:
			print("    apply_grid_config(emissive=true): rebuilt OK (%d soft bodies)" % after.size())
	else:
		push_error("missing apply_grid_config: " + path)
		cfg_ok = false

	holder.queue_free()
	await process_frame

	var ok: bool = layer_ok and deformed_ok and cfg_ok
	print("    -> ", "PASS" if ok else "FAIL")
	return ok


func _find_all_soft(n: Node) -> Array:
	var out: Array = []
	if n is SoftBody3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_all_soft(c))
	return out


func _mesh_verts(sb: SoftBody3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	if sb.mesh == null:
		return out
	var arrays: Array = sb.mesh.surface_get_arrays(0)
	if arrays.size() > Mesh.ARRAY_VERTEX:
		out = arrays[Mesh.ARRAY_VERTEX]
	return out


func _max_vertex_drift(sb: SoftBody3D, rest: PackedVector3Array) -> float:
	var live := _mesh_verts(sb)
	if live.size() != rest.size() or live.is_empty():
		return 0.0
	var m := 0.0
	for i in range(live.size()):
		var d: float = live[i].distance_to(rest[i])
		if d > m:
			m = d
	return m
