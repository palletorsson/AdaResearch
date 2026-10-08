extends SceneTree
## IS THE SPECIMEN PINNED?
##
## radiolaria draws from 84 rand* call sites and called `randomize()` in _ready
## until 2026-09-07, so two placements of one token were two different organisms.
## Every DNA verdict over such an artifact is a fact about the dice — CLAUDE.md
## lists it in the trap table as "strong confident bite on a generative artifact".
##
## This measures determinism where it lives — in the GEOMETRY, not in the pixels.
## A capture would answer the same question more slowly and would also be
## measuring the particle system, the rotation and the tonemapper.
##
## Three builds: seed 7, seed 7 again, seed 8. Same seed must give a byte-equal
## signature; a different seed must not. Both halves matter — a signature that is
## equal for 7 and 8 as well would mean the seed reaches nothing and the artifact
## merely stopped moving.

const SCENE := "res://algorithms/computationalbiology/radiolaria2/radiolaria.tscn"


## Every mesh in the tree, by name and position, folded to one string. Positions
## are where the randomness actually lands: spines, pores, ring angles.
func _sig(n: Node) -> String:
	var parts: Array[String] = []
	_walk(n, parts)
	parts.sort()
	return "|".join(parts)


func _walk(n: Node, parts: Array[String]) -> void:
	if n is Node3D and (n is MeshInstance3D or n is CSGShape3D):
		var p: Vector3 = (n as Node3D).position
		# POSITIONS ONLY, NOT NAMES. The first pass folded n.name into the
		# signature and reported seed 7 twice as DIFFERENT — but Godot uniquifies
		# duplicate node names with a counter that is global to the process and
		# monotonic across builds, so the second organism was named differently
		# while being geometrically identical. That was a fault in the instrument,
		# not in the artifact.
		parts.append("%.4f,%.4f,%.4f" % [p.x, p.y, p.z])
	for c in n.get_children():
		_walk(c, parts)


func _build(sd: int) -> String:
	var ps: PackedScene = load(SCENE)
	var inst = ps.instantiate()
	# BEFORE add_child: _ready seeds and builds in one pass, so a value set
	# afterwards is a value the organism was not grown with.
	inst.set("generation_seed", sd)
	inst.set("enable_rotation", false)
	inst.set("show_particle_effects", false)
	get_root().add_child(inst)
	await process_frame
	await process_frame
	var sig := _sig(inst)
	inst.queue_free()
	await process_frame
	return sig


func _init() -> void:
	var fails := 0

	var a := await _build(7)
	var b := await _build(7)
	var c := await _build(8)

	print("meshes in a seed-7 build: %d" % (a.split("|").size()))

	var same: bool = (a == b)
	print("1  seed 7 twice  -> identical = %s   (must be true)" % same)
	if not same:
		print("   FAIL something outside the seed still moves — find the second RNG")
		fails += 1

	var differs: bool = (a != c)
	print("2  seed 7 vs 8   -> different = %s   (must be true)" % differs)
	if not differs:
		print("   FAIL the seed reaches nothing; the organism just stopped re-rolling")
		fails += 1

	print("\nprobe_radiolaria_seed: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)
