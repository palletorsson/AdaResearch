extends SceneTree

## DOES THE THRESHOLD ACTUALLY FIRE, AND DOES IT ALWAYS LET GO?
##
## 2026-08-31. wireframe_threshold changes one global piece of state — the
## viewport's debug_draw — so its failure mode is not "it does nothing", it is
## "the whole game is left undressed and only a restart fixes it". A compile
## check says nothing about either. This walks a body in and out and reads the
## viewport back after each step.
##
## Every case has a way to fail that is not the same as another case's:
##
##   1 enter          a CharacterBody3D standing in it undresses the room
##   2 exit           leaving dresses it again, back to the value from before
##   3 floor          a StaticBody3D does NOT count as an occupant. This is the
##                    one the mask forces: the museum walker sits on the default
##                    layer 1 with the static world, so the area has to watch
##                    layer 1, so the floor and the walls arrive here too.
##   4 two bodies     the first to leave must not dress the room while the second
##                    is still standing there
##   5 freed          the artifact deleted with someone inside still hands the
##                    viewport back — the case that would otherwise strand the
##                    game. NOTE, measured: this passes with _exit_tree gutted,
##                    because Godot 4.6 emits body_exited when the Area3D is
##                    freed. So it is a REGRESSION GUARD on the outcome, not
##                    evidence that _exit_tree is load-bearing. Mutating
##                    _is_occupant turns 3b and 3c red; mutating _exit_tree
##                    turns nothing red, and that is worth knowing.
##   6 blink          blink_seconds dresses the room again on its own, without
##                    anybody stepping out
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_wireframe_threshold.gd

const SCENE := "res://commons/artifacts/wireframe_threshold/wireframe_threshold.tscn"

var _root: Window
var _fails: int = 0
var _ran: int = 0
var _arrivals: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	_root = get_root()
	print("")
	print("WIREFRAME THRESHOLD PROBE")
	print("")

	var normal: int = Viewport.DEBUG_DRAW_DISABLED
	_root.debug_draw = normal

	# ---- 1 & 2: in, then out -------------------------------------------
	var th: Node3D = _place()
	var body: CharacterBody3D = _body(Vector3(0.0, 0.5, 6.0))
	await _tick(4)
	_check("0 quiet", _root.debug_draw, normal)

	body.position = Vector3(0.0, 0.5, 0.0)
	await _tick(6)
	_check("1 enter", _root.debug_draw, Viewport.DEBUG_DRAW_WIREFRAME)

	body.position = Vector3(0.0, 0.5, 6.0)
	await _tick(6)
	_check("2 exit", _root.debug_draw, normal)

	# ---- 3: a threshold placed INTO a room that already has a floor -------
	#
	# The two earlier versions of this case are the finding. v1 read debug_draw
	# after adding a floor and PASSED with the occupant filter mutated away, so it
	# was not testing anything. v2 asserted the floor reached the Area3D and showed
	# it never did, not in 68 physics ticks: a StaticBody3D added after an area
	# exists never moves, so the broadphase has no event and body_entered is never
	# emitted. That is the wrong order for this artifact — a threshold is PLACED
	# INTO a room that already has a floor, and built that way round the floor
	# arrives at once. This is that order.
	var floor_body := StaticBody3D.new()
	var fc := CollisionShape3D.new()
	var fb := BoxShape3D.new()
	fb.size = Vector3(4.0, 0.2, 4.0)
	fc.shape = fb
	floor_body.add_child(fc)
	_root.add_child(floor_body)
	floor_body.position = Vector3(6.0, 0.1, 6.0)
	await _tick(4)

	_arrivals.clear()
	var th_floor: Node3D = _place()
	th_floor.position = Vector3(6.0, 0.0, 6.0)
	await _tick(8)
	# The mask watches layer 1 so the museum walker reaches it, which means the
	# floor reaches it too. If this line goes red, 3b stops testing anything —
	# nothing would be arriving for the filter to reject.
	_check_true("3a floor reaches the area", _arrivals.has("StaticBody3D"),
		"arrivals: " + str(_arrivals))
	var occupants: Dictionary = th_floor.get("_inside")
	_check_true("3b floor is not an occupant", occupants.is_empty(),
		"occupants: " + str(occupants.size()))
	_check("3c room stays dressed", _root.debug_draw, normal)
	th_floor.free()
	await _tick(2)

	# ---- 4: two occupants, one leaves ------------------------------------
	var b2: CharacterBody3D = _body(Vector3(0.0, 0.5, 0.0))
	body.position = Vector3(0.2, 0.5, 0.0)
	await _tick(6)
	_check("4a both in", _root.debug_draw, Viewport.DEBUG_DRAW_WIREFRAME)
	b2.position = Vector3(0.0, 0.5, 6.0)
	await _tick(6)
	_check("4b one left, one stays", _root.debug_draw, Viewport.DEBUG_DRAW_WIREFRAME)
	body.position = Vector3(0.0, 0.5, -6.0)
	await _tick(6)
	_check("4c both left", _root.debug_draw, normal)

	# ---- 5: freed with someone inside ------------------------------------
	body.position = Vector3(0.0, 0.5, 0.0)
	await _tick(6)
	_check("5a inside", _root.debug_draw, Viewport.DEBUG_DRAW_WIREFRAME)
	th.free()
	await _tick(4)
	_check("5b artifact freed while occupied", _root.debug_draw, normal)

	# ---- 6: blink lets go on its own -------------------------------------
	var th2: Node3D = _place()
	th2.set("blink_seconds", 0.25)
	body.position = Vector3(0.0, 0.5, 6.0)
	await _tick(4)
	body.position = Vector3(0.0, 0.5, 0.0)
	await _tick(6)
	_check("6a blink took", _root.debug_draw, Viewport.DEBUG_DRAW_WIREFRAME)
	await _tick(40)                             # ~0.66 s at 60 Hz, still standing in it
	_check("6b blink let go while still inside", _root.debug_draw, normal)

	print("")
	print("  %d checked, %d FAILED" % [_ran, _fails])
	quit(1 if _fails > 0 else 0)


func _place() -> Node3D:
	var packed: PackedScene = load(SCENE)
	var n: Node3D = packed.instantiate()
	_root.add_child(n)
	n.position = Vector3.ZERO
	# WHAT THE AREA ACTUALLY SEES. The artifact masks layer 1 so the museum
	# walker reaches it, and the comment in the source says the floor and walls
	# arrive too. That claim is worth nothing unless something reads it back.
	for c in n.get_children():
		if c is Area3D:
			(c as Area3D).body_entered.connect(_note_arrival)
	return n


func _note_arrival(b: Node3D) -> void:
	_arrivals.append(b.get_class())


func _body(at: Vector3) -> CharacterBody3D:
	var b := CharacterBody3D.new()
	var c := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.25
	cap.height = 1.6
	c.shape = cap
	b.add_child(c)
	_root.add_child(b)
	b.position = at
	return b


func _tick(n: int) -> void:
	for i in range(n):
		await physics_frame


func _check_true(what: String, ok: bool, detail: String) -> void:
	_ran += 1
	if not ok:
		_fails += 1
	print("  %-34s %s   %s" % [what, ("ok  " if ok else "FAIL"), detail])


func _check(what: String, got: int, want: int) -> void:
	_ran += 1
	var ok: bool = got == want
	if not ok:
		_fails += 1
	print("  %-34s %s   got %s, wanted %s" % [what, ("ok  " if ok else "FAIL"), _name(got), _name(want)])


func _name(m: int) -> String:
	match m:
		Viewport.DEBUG_DRAW_DISABLED: return "normal"
		Viewport.DEBUG_DRAW_WIREFRAME: return "wireframe"
		Viewport.DEBUG_DRAW_OVERDRAW: return "overdraw"
		Viewport.DEBUG_DRAW_UNSHADED: return "unshaded"
		Viewport.DEBUG_DRAW_NORMAL_BUFFER: return "normals"
	return str(m)
