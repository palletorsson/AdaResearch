extends SceneTree
## DOES THE BLANKET ACTUALLY SEPARATE, AND DOES IT ACTUALLY FAIL?
##
## markov_blanket_room claims that its interior is sealed by a lattice shell and
## that removing enough of the shell opens a path out. Both halves have to be
## tested. A version that always reported SEPARATED would look identical from the
## canonical camera angle and would be arguing nothing -- this corpus has already
## published a finished-looking experiment that answered nothing exactly once.
##
## The claim is read from the model, not the pixels: is_separated() and
## escape_path_length() exist on the artifact so this does not have to measure a
## render to find out what the search concluded.
##
## It also checks the two things that keep an artifact placeable at all, because
## the artifact this one is kin to fails both: no camera, no WorldEnvironment.

const SCENE := "res://commons/artifacts/markov_blanket_room/markov_blanket_room.tscn"


func _build(leak: String, shell: String) -> Node:
	var inst = load(SCENE).instantiate()
	inst.set("leak", leak)
	inst.set("shell", shell)
	get_root().add_child(inst)
	return inst


func _count(n: Node, cls: String) -> int:
	var k := 0
	if n.get_class() == cls:
		k += 1
	for c in n.get_children():
		k += _count(c, cls)
	return k


func _init() -> void:
	var fails := 0

	# 1. SEALED MUST SEPARATE
	var a = _build("sealed", "shell")
	await process_frame
	var sealed_ok: bool = a.is_separated()
	print("1  sealed/shell    -> separated = %s   (must be true)" % sealed_ok)
	if not sealed_ok:
		print("   FAIL the shell has a hole in it at rest; check inner_cells vs blanket_cells")
		fails += 1

	# 2. AND IT MUST BE SEALED BY THE BLANKET, NOT BY THE LATTICE EDGE
	#    If the search simply never reaches the rim, "separated" is meaningless.
	var dissolved = _build("dissolved", "shell")
	await process_frame
	var escaped: bool = not dissolved.is_separated()
	print("2  dissolved/shell -> escaped   = %s   (must be true)" % escaped)
	if not escaped:
		print("   FAIL nothing gets out even with the blanket gone -- the search")
		print("   is not reaching the rim, so test 1 proved nothing")
		fails += 1
	else:
		var n: int = dissolved.escape_path_length()
		print("     escape path crosses %d cells" % n)
		if n <= 0:
			print("   FAIL escaped but drew no path")
			fails += 1

	# 3. shell = none MUST ESCAPE -- there is no blanket left to stop anything
	var none_shell = _build("sealed", "none")
	await process_frame
	var none_escaped: bool = not none_shell.is_separated()
	print("3  sealed/none     -> escaped   = %s   (must be true)" % none_escaped)
	if not none_escaped:
		print("   FAIL the blanket was removed and the interior is still sealed")
		fails += 1

	# 4. DETERMINISM. Same seed, same verdict, or every reading of this artifact
	#    is a reading of the dice.
	var p1 = _build("breach", "patchy")
	await process_frame
	var v1: Array = [p1.is_separated(), p1.escape_path_length()]
	var p2 = _build("breach", "patchy")
	await process_frame
	var v2: Array = [p2.is_separated(), p2.escape_path_length()]
	var same: bool = v1 == v2
	print("4  breach/patchy twice -> identical = %s   (must be true)  %s vs %s"
		% [same, v1, v2])
	if not same:
		print("   FAIL unseeded randomness somewhere -- find the second RNG")
		fails += 1

	# 5. IT MUST NOT STEAL THE ROOM. puls_markov adds a Camera3D with
	#    current = true, a WorldEnvironment and a light, which is why it stands
	#    in no sequence.
	var cams := _count(a, "Camera3D")
	var envs := _count(a, "WorldEnvironment")
	var lights := _count(a, "DirectionalLight3D")
	print("5  cameras=%d environments=%d directional lights=%d   (all must be 0)"
		% [cams, envs, lights])
	if cams + envs + lights > 0:
		print("   FAIL dropped into a map this takes the player's eyes or relights the hall")
		fails += 1

	print("\nprobe_markov_blanket: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)
