extends SceneTree
var checks: Array = []
var failures: Array = []
const STEPS := ["01-colour", "02-seed", "03-grid", "04-pair", "05-unused-draw", "06-channel-roles"]
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: failures.append(label)
	print("PASS " if ok else "FAIL ",label)
func colours(cubes: Array[MeshInstance3D]) -> PackedColorArray:
	var out := PackedColorArray()
	for cube in cubes: out.append(cube.material_override.albedo_color)
	return out
func expected(s: int, count: int, skip: int = 0) -> PackedColorArray:
	var source := RandomNumberGenerator.new()
	source.seed=s
	for i in range(skip): source.randf()
	var out := PackedColorArray()
	for i in range(count): out.append(Color(source.randf(),source.randf(),source.randf()))
	return out
func scene(script: Script) -> Node3D:
	var node: Node3D = load("res://study.tscn").instantiate()
	node.set_script(script)
	root.add_child(node)
	return node
func run() -> void:
	for i in range(STEPS.size()):
		var lesson := scene(load("res://steps/"+STEPS[i]+".gd"))
		await process_frame
		var display := lesson.get_node("Display")
		var count := 1 if i<2 else 16
		check(STEPS[i]+" display size",display.left.size()==count and display.right.size()==(16 if i>=3 else 0))
		var original := colours(display.left)
		var start_state: int = lesson.rng.state
		await create_timer(0.1).timeout
		check(STEPS[i]+" waiting consumes no draw",lesson.rng.state==start_state)
		display.replay_button.pressed.emit()
		if i==0:
			var continued := RandomNumberGenerator.new()
			continued.state=start_state
			check("unseeded replay continues stream",colours(display.left)[0]==Color(continued.randf(),continued.randf(),continued.randf()))
		else:
			check(STEPS[i]+" replay recovers colours",colours(display.left)==original)
			for s in [0,1,42,137,999,-3]:
				lesson.seed_value=s
				lesson.replay()
				check(STEPS[i]+" left assignments seed "+str(s),colours(display.left)==expected(s,count))
				if i>=3:
					var wanted := expected(s,16,1 if i==4 else 0)
					if i==5:
						for cell in range(wanted.size()): wanted[cell]=Color(wanted[cell].b,wanted[cell].g,wanted[cell].r)
					check(STEPS[i]+" right assignments seed "+str(s),colours(display.right)==wanted)
			lesson.seed_value=42
			lesson.replay()
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://"+STEPS[i]+".png")
		lesson.queue_free()
		await process_frame
	var edit := GDScript.new()
	edit.source_code=FileAccess.get_file_as_string("res://steps/03-grid.gd").replace("\r\n", "\n").replace("\trng.seed = seed_value\n\tfor cube in $Display.left:","\tfor cube in $Display.left:\n\t\trng.seed = seed_value")
	check("seed-in-loop edit compiles",edit.reload()==OK)
	var changed := scene(edit)
	var repeated := colours(changed.get_node("Display").left)
	check("per-cube reset repeats one colour",repeated.size()==16 and Array(repeated).all(func(c): return c==repeated[0]))
	changed.queue_free()
	await process_frame
	edit=GDScript.new()
	edit.source_code=FileAccess.get_file_as_string("res://steps/06-channel-roles.gd").replace("Color(c, b, a)","Color(a, a, a)")
	check("grey assignment edit compiles",edit.reload()==OK)
	changed=scene(edit)
	var neutral := colours(changed.get_node("Display").right)
	var baseline := expected(42,16)
	var matches := true
	for i in range(16): matches=matches and neutral[i]==Color(baseline[i].r,baseline[i].r,baseline[i].r)
	check("grey assignment retains draw positions",matches)
	changed.queue_free()
	await process_frame
	FileAccess.open("res://verification.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"engine":Engine.get_version_info(),"scope":"Complete portable scripts, actual replay signal, six seeds, two learner edits; no learner or headset trial."},"\t"))
	quit(0 if failures.is_empty() else 1)
