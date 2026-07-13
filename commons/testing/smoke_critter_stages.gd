extends SceneTree

## Headless smoke test for the evolving pink critter (critter_morphology).
##
## Checks:
##   1. Stage table: order 2 → legacy cube; 4.5 → flying legless mote (pops);
##      6 → serpent (snake-wave); 7 → grounded octapod (8 legs); 9 → wave ×2;
##      10 → grand (bigger)
##   2. A foe seeded critter_stage=4.5 builds a blob (no BoxMesh), flies flag on
##   3. A foe seeded critter_stage=7 grows 8 leg roots
##   4. Pop: a mote foe that lands its contact hit blows up (DEAD, mesh hidden)
##   5. Legacy: critter_stage=2 keeps the grey BoxMesh cube
## Prints PASS/FAIL, quit(0/1).

const FOE_SCENE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const MORPH := preload("res://commons/hazards/catalyst_foe/critter_morphology.gd")


class DamageSink extends Node3D:
	var hits: int = 0
	func apply_health_damage(_amount: float) -> void:
		hits += 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== critter stages smoke test ===")

	# ── 1. Stage table thresholds ──
	var cube: Dictionary = MORPH.stage_for(2.0)
	var mote: Dictionary = MORPH.stage_for(4.5)
	var serpent: Dictionary = MORPH.stage_for(6.0)
	var octo: Dictionary = MORPH.stage_for(7.0)
	var many: Dictionary = MORPH.stage_for(9.0)
	var grand: Dictionary = MORPH.stage_for(10.0)
	var table_ok: bool = (
		String(cube["name"]) == "cube" and not bool(cube["pop"])
		and String(mote["name"]) == "mote" and bool(mote["flying"]) and int(mote["legs"]) == 0 and bool(mote["pop"])
		and String(serpent["name"]) == "serpent" and bool(serpent["wave"]) and bool(serpent["flying"])
		and String(octo["name"]) == "octapod" and not bool(octo["flying"]) and int(octo["legs"]) == 8
		and int(many["wave_mult"]) == 2
		and String(grand["name"]) == "grand" and float(grand["scale"]) > float(octo["scale"])
	)
	print("- stage table: cube/mote/serpent/octapod/many/grand thresholds ok=%s" % table_ok)
	if not table_ok:
		print("FAIL: stage table"); quit(1); return

	var root := Node.new()
	root.name = "CritterTestRoot"
	get_root().add_child(root)
	var player := DamageSink.new()
	player.name = "Player"
	player.add_to_group("player")
	root.add_child(player)

	# ── 2. Mote body: no BoxMesh, flying stage active ──
	var mote_foe: Node = FOE_SCENE.instantiate()
	mote_foe.call("apply_grid_config", {"critter_stage": 4.5})
	root.add_child(mote_foe)
	await process_frame
	var mote_meshes: Array = _mesh_types(mote_foe)
	var has_box: bool = mote_meshes.has("BoxMesh")
	var has_sphere: bool = mote_meshes.has("SphereMesh")
	print("- mote body: sphere=%s box=%s (expect sphere, no box)" % [has_sphere, has_box])
	if has_box or not has_sphere:
		print("FAIL: mote body"); quit(1); return

	# ── 3. Octapod: 8 leg roots ──
	var octo_foe: Node = FOE_SCENE.instantiate()
	octo_foe.call("apply_grid_config", {"critter_stage": 7.0})
	root.add_child(octo_foe)
	await process_frame
	# Legs live under the GaitRig node ("Leg0".."Leg7"), one level down.
	var legs: int = 0
	var mesh_root: Node = octo_foe.get("_mesh_root")
	if mesh_root != null:
		legs = mesh_root.find_children("Leg?", "", true, false).size()
	print("- octapod legs: %d (expect 8)" % legs)
	if legs != 8:
		print("FAIL: octapod legs"); quit(1); return

	# ── 4. Pop on contact hit ──
	var popper: Node = FOE_SCENE.instantiate()
	popper.call("apply_grid_config", {"critter_stage": 4.5, "initial_state": "foe"})
	root.add_child(popper)
	await process_frame
	var landed: bool = bool(popper.call("_try_damage_target", player))
	await process_frame
	var blown: bool = bool(popper.get("_blown_up"))
	var mesh_hidden: bool = mesh_root != null  # placeholder, re-read below
	var pop_root: Node = popper.get("_mesh_root")
	mesh_hidden = pop_root != null and not (pop_root as Node3D).visible
	print("- pop: hit landed=%s (player hits=%d), blown_up=%s, mesh hidden=%s" % [
		landed, player.hits, blown, mesh_hidden])
	if not landed or player.hits != 1 or not blown or not mesh_hidden:
		print("FAIL: pop on contact"); quit(1); return

	# ── 5. Legacy cube below the color threshold ──
	var cube_foe: Node = FOE_SCENE.instantiate()
	cube_foe.call("apply_grid_config", {"critter_stage": 2.0})
	root.add_child(cube_foe)
	await process_frame
	var cube_meshes: Array = _mesh_types(cube_foe)
	print("- legacy: box=%s sphere=%s (expect box only)" % [
		cube_meshes.has("BoxMesh"), cube_meshes.has("SphereMesh")])
	if not cube_meshes.has("BoxMesh") or cube_meshes.has("SphereMesh"):
		print("FAIL: legacy cube"); quit(1); return

	print("PASS: critter table, mote body, octapod legs, pop, legacy cube")
	quit(0)


func _mesh_types(foe: Node) -> Array:
	var out: Array = []
	var mesh_root: Node = foe.get("_mesh_root")
	if mesh_root == null:
		return out
	for child in mesh_root.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh != null:
			var cls: String = (child as MeshInstance3D).mesh.get_class()
			if not out.has(cls):
				out.append(cls)
	return out
