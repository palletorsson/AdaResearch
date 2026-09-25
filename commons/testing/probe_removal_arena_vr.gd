extends SceneTree
## Gate for random_removal_arena's player test (2026-09-24). In the museum's headset
## branch the museum never builds its desktop walker, so `_player` stays null and the
## shipped arena compared every body against null: in VR the floor removed nothing.
##
##   V  headset body       -> a PlayerBody (group player_body, layer 20) standing in the
##                            arena, under a museum whose _player is null, starts the
##                            removals; negative control: the shipped script does not
##   D  desktop unchanged  -> with a walker set, the walker starts them (new and shipped)
##   S  no stranger        -> with a walker set, another player_body does not
##   R  readout visible    -> the readout's backing plate sits behind the label, not in
##                            front of it; negative control: the shipped plate hid it
##
## usage: godot --headless --path . --xr-mode off --script res://commons/testing/probe_removal_arena_vr.gd
##
## Godot 4.6 segfaults while tearing this probe down (exit 139), after the RESULT line.
## Read the RESULT line, not the exit code, until that is traced.

const ARENA := "res://commons/artifacts/randomness_space/removal_arena.gd"
const BEFORE := "res://doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Remove/removal_arena.gd.before.txt"

var _fails := 0
var _keep: Array = []   # runtime scripts outlive their instances, or teardown crashes

func _initialize() -> void:
	_run.call_deferred()

func _check(label: String, ok: bool, detail: String) -> void:
	if not ok:
		_fails += 1
	print("%s %s — %s" % ["PASS" if ok else "FAIL", label, detail])

func _script_from(src: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = src
	assert(s.reload() == OK)
	_keep.append(s)
	return s

## A stand-in museum: the arena finds its museum as the ancestor with _basin_burned.
func _museum(with_walker: bool) -> Node3D:
	var m := Node3D.new()
	m.set_script(_script_from("extends Node3D\nvar _player = null\nfunc _basin_burned() -> void:\n\tpass\n"))
	root.add_child(m)
	if with_walker:
		var w := _body("Walker", "")
		w.position = Vector3(40, 0.9, 40)   # outside the arena unless a trial moves it in
		m.add_child(w)
		m.set("_player", w)
	return m

func _body(n: String, group: String) -> CharacterBody3D:
	var b := CharacterBody3D.new()
	b.name = n
	if group != "":
		b.add_to_group(group)
	b.collision_layer = 524288
	var c := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	c.shape = cap
	b.add_child(c)
	b.position = Vector3(0, 0.9, 0)
	return b

## Build an arena under a museum, put `who` in it, and report whether a removal began.
func _trial(script_path: String, with_walker: bool, who: String) -> bool:
	var m := _museum(with_walker)
	var a := Node3D.new()
	if script_path == BEFORE:
		a.set_script(_script_from(FileAccess.get_file_as_string(BEFORE)))
	else:
		a.set_script(load(script_path))
	m.add_child(a)
	var body: Node3D
	if who == "walker":
		body = m.get("_player")
		body.position = Vector3(0, 0.9, 0)
	else:
		body = _body("PlayerBody", "player_body")
		m.add_child(body)
	for i in 12:
		await physics_frame
	var began: bool = bool(a.get("entered"))
	m.queue_free()
	await process_frame
	return began

## Distance from the readout label to its backing plate's front face, along the
## label's facing (-z, yaw PI): positive = plate behind the text, negative = hides it.
func _plate_gap(script_path: String) -> float:
	var m := _museum(false)
	var a := Node3D.new()
	if script_path == BEFORE:
		a.set_script(_script_from(FileAccess.get_file_as_string(BEFORE)))
	else:
		a.set_script(load(script_path))
	m.add_child(a)
	var lab: Label3D = a.get("readout")
	var gap := -INF
	for c in a.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh 				and ((c as MeshInstance3D).mesh as BoxMesh).size.is_equal_approx(Vector3(1.55, 0.25, 0.035)):
			gap = ((c as MeshInstance3D).position.z - 0.0175) - lab.position.z
	m.free()
	return gap

func _run() -> void:
	var v_new := await _trial(ARENA, false, "player_body")
	var v_old := await _trial(BEFORE, false, "player_body")
	_check("V a headset PlayerBody starts the removals", v_new and not v_old,
		"new=%s; shipped=%s (the shipped arena ignored it)" % [str(v_new), str(v_old)])
	var d_new := await _trial(ARENA, true, "walker")
	var d_old := await _trial(BEFORE, true, "walker")
	_check("D the desktop walker still starts them", d_new and d_old, "new=%s shipped=%s" % [str(d_new), str(d_old)])
	var s_new := await _trial(ARENA, true, "player_body")
	_check("S with a walker present, another player_body does not", not s_new, "new=%s" % str(s_new))
	var r_new := _plate_gap(ARENA)
	var r_old := _plate_gap(BEFORE)
	_check("R the readout plate sits behind its label", r_new > 0.0 and r_old < 0.0,
		"plate front face %.4f m behind the label (shipped: %.4f, i.e. in front)" % [r_new, r_old])
	print("RESULT %s (%d failed)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	# let the freed stand-in museums (runtime scripts) go before the engine tears down
	for i in 3:
		await process_frame
	quit(0 if _fails == 0 else 1)
