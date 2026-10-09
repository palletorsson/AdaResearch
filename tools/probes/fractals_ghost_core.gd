extends SceneTree
## Execute the fresh student's verbatim reconstructions, not teacher copies.
const OUT := "res://doc/book/iterations/2026-10-08-fractals-ghost-student/"
const STUDENT := OUT + "attempt/reconstructed/"
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}
var world: Node3D

func _initialize() -> void:
	run.call_deferred()

func check(title: String, ok: bool) -> void:
	checks.append({"name": title, "passed": ok})
	if not ok:
		failures.append(title)
	print("GHOST CORE ", title, " ", ok)

func study(hall: String, file: String):
	var script = load(STUDENT + hall + "/" + file)
	if script == null or not script.can_instantiate():
		check(hall + " script loads", false)
		return null
	var node = script.new()
	world.add_child(node)
	return node

func sound_tree(joint: Node3D) -> bool:
	if not joint.transform.is_finite() or float(joint.get_meta("length")) <= 0:
		return false
	for child in joint.get_children():
		if child.has_meta("length"):
			if not child.position.is_equal_approx(Vector3.UP * float(joint.get_meta("length"))) or not sound_tree(child):
				return false
	return true

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	current_scene = world
	var frames = study("Fractal_Recursion", "frames.gd")
	check("Recursion: three frames drawn as twelve sides", frames != null and frames.sizes.size() == 3 and frames.frames.get_child_count() == 12)
	if frames != null:
		check("Recursion: printed ratio produces decreasing sizes", is_equal_approx(frames.sizes[0], 1.8) and is_equal_approx(frames.sizes[1], 1.17) and is_equal_approx(frames.sizes[2], 0.7605))
		frames.ratio = 0.5
		frames.rebuild()
		check("Recursion: independent half-size exercise", is_equal_approx(frames.sizes[2], 0.45))
		frames.depth = 0
		frames.rebuild()
		check("Recursion: stopping condition draws nothing at zero depth", frames.sizes.is_empty() and frames.frames.get_child_count() == 0)
		frames.free()
	var tree = study("Fractal_RecursiveTrees", "tree.gd")
	check("Trees: fifteen segments, two grips and attached hierarchy", tree != null and tree.segment_count == 15 and tree.points.size() == 2 and sound_tree(tree.tree))
	if tree != null:
		var right: Transform3D = tree.first_forks[1].transform
		var before: Basis = tree.first_forks[0].basis
		tree.turn_fork(0, Vector3(0.4, 1, 0.3))
		check("Trees: local turn leaves other fork unchanged", not tree.first_forks[0].basis.is_equal_approx(before) and tree.first_forks[1].transform.is_equal_approx(right) and sound_tree(tree.tree))
		tree.free()
	var cantor = study("Fractal_CantorSet", "cantor.gd")
	check("Cantor: initial six-metre interval exists", cantor != null and cantor.current == [Vector2(0, 6)])
	if cantor != null:
		var seed: Array = cantor.current.duplicate()
		for i in 5:
			cantor.advance()
		check("Cantor: fifth cut has thirty-two pieces and 64/81 metres", cantor.current.size() == 32 and absf(cantor.kept_length(cantor.current) - 64.0 / 81.0) < 0.00001)
		check("Cantor: original and first history row survive independently", cantor.original == seed and cantor.history[0] == seed and not is_same(cantor.history[0], cantor.original))
		cantor.advance()
		check("Cantor: finite generation budget", cantor.history.size() == 6)
		cantor.show_history = true
		cantor.redraw()
		check("Cantor: history view shows sixty-three bars without changing survivors", cantor.rows.get_child_count() == 63 and cantor.current.size() == 32)
		var given: Array[Vector2] = [Vector2(0, 6)]
		check("Cantor: quarter replacement yields two 1.5-metre ends", cantor.replace_intervals(given, 0.25) == [Vector2(0, 1.5), Vector2(4.5, 1.5)] and given == [Vector2(0, 6)])
		cantor.free()
	var koch = study("Fractal_KochSierpinski", "koch.gd")
	check("Koch: four-metre seed instantiated", koch != null and is_equal_approx(koch.path_length(koch.current), 4.0))
	if koch != null:
		for i in 4:
			koch.advance()
		check("Koch: 256 segments and preserved endpoints", koch.current.size() == 257 and koch.current[0] == Vector3(-2, 0, 0) and koch.current[-1] == Vector3(2, 0, 0))
		check("Koch: longer path is drawn at the declared scale", absf(koch.path_length(koch.current) - 4.0 * pow(4.0 / 3.0, 4)) < 0.0001 and koch.drawing.get_child_count() == 256)
		koch.advance()
		check("Koch: cap retains fourth generation", koch.generation == 4)
		var source_path: Array[Vector3] = [Vector3(-2, 0, 0), Vector3(2, 0, 0)]
		var left: Array = koch.replace_path(source_path, 1.0)
		var right: Array = koch.replace_path(source_path, -1.0)
		check("Koch: reversing the turn preserves length and changes shape", is_equal_approx(koch.path_length(left), koch.path_length(right)) and left[2].y * right[2].y < 0)
		koch.free()
	var menger = study("Fractal_MengerSponge", "menger.gd")
	check("Menger: initial nine-metre seed and point reader", menger != null and is_equal_approx(menger.retained_volume(), 729) and menger.point.has_method("pick_up"))
	if menger != null:
		menger.advance()
		check("Menger: first selection retains twenty 3-metre cubes", menger.current.size() == 20 and is_equal_approx(menger.edge, 3) and is_equal_approx(menger.retained_volume(), 540))
		menger.advance()
		check("Menger: second cut retains four hundred 1-metre cubes", menger.current.size() == 400 and is_equal_approx(menger.edge, 1) and is_equal_approx(menger.retained_volume(), 400))
		check("Menger: miniature scale is distinct from model edge", is_equal_approx(menger.drawing.get_child(0).mesh.size.x, 0.09))
		check("Menger: cell decision distinguishes corner and face centre", menger.keep_cell(Vector3i(1, 1, 1)) and not menger.keep_cell(Vector3i(1, 0, 0)))
		menger.advance()
		check("Menger: cap retains second cut", menger.generation == 2)
		menger.free()
	var golden = study("Fractal_GoldenSpiral", "sum_points.gd")
	check("Golden: last-pair points and 1,1 seed exist", golden != null and golden.points.size() == 2 and golden.values == [1, 1])
	if golden != null:
		for i in 8:
			golden.advance()
		check("Golden: recurrence reaches ten terms ending in 55", golden.values == [1, 1, 2, 3, 5, 8, 13, 21, 34, 55])
		check("Golden: same value has two declared heights", is_equal_approx(golden.height_for(55, true), 2.75) and is_equal_approx(golden.height_for(55, false), 0.5 * log(55.0) + 0.5))
		golden.advance()
		check("Golden: ten-term cap", golden.values.size() == 10)
		var alternate_seed: Array[int] = [1, 2]
		golden.values = alternate_seed
		for i in 8:
			golden.advance()
		check("Golden: independent seed variation reaches 89", golden.values[-1] == 89)
		golden.free()
	var recipe = study("Fractal_Synthesis", "recipe.gd")
	check("Synthesis: independent live and kept recipes each render eight pieces", recipe != null and recipe.live.size() == 8 and recipe.kept.size() == 8 and not is_same(recipe.recipe, recipe.kept_recipe))
	if recipe != null:
		var kept: Array = recipe.kept.duplicate()
		recipe.choose(0)
		check("Synthesis: live quarter edit preserves kept thirds", is_equal_approx(recipe.total(recipe.live), 0.75) and recipe.kept == kept)
		recipe.keep_current()
		recipe.choose(2)
		check("Synthesis: KEEP captures before another live choice", is_equal_approx(recipe.total(recipe.kept), 0.75) and is_equal_approx(recipe.total(recipe.live), 3.072))
		recipe.restore()
		recipe.advance()
		check("Synthesis: RESTORE copies before further edits", recipe.recipe.steps == 4 and recipe.kept_recipe.steps == 3 and not is_same(recipe.recipe, recipe.kept_recipe))
		recipe.reset_live()
		check("Synthesis: RESET changes live only", recipe.recipe.steps == 3 and is_equal_approx(recipe.recipe.fraction, 1.0 / 3.0) and is_equal_approx(recipe.kept_recipe.fraction, 0.25))
		recipe.free()
	await process_frame
	FileAccess.open(OUT + "core-checks.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures, "scope": "Seven studies reconstructed verbatim by the fresh reader. Focused native code and geometry assertions, not complete interaction or headset certification."}, "  "))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
