extends SceneTree
var checks: Array = []
var failures: Array = []
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name": label, "passed": ok}); print("HORDE ", "PASS " if ok else "FAIL ", label)
	if not ok: failures.append(label)
func run() -> void:
	var Model = load("res://commons/artifacts/listening_horde/horde.gd")
	var m = Model.new()
	check("20 resting bodies start at distinct homes", m.counts() == [20,0,0] and m.positions[0] != m.positions[19])
	var saved: Array = m.positions.duplicate()
	for i in range(120): m.step(1.0/60)
	check("Silence leaves bodies at rest", m.positions == saved)
	check("Out-of-court pulse is rejected", m.pulse(Vector3(-20,1.4,0)) == 0 and m.pulses == 0)
	check("Partition cannot be a sound destination", not m.valid_source(Vector3(0,1.4,3)))
	check("Near pulse reaches whole court", m.pulse(Vector3(-2.1,1.4,-1.6)) == 20)
	check("Pulse enters investigate and records fixed position", m.counts() == [0,20,0] and m.memories[0] == Vector2(-2.1,-1.6))
	var safe := true; var speeds := true; var finite := true; var crossed := false; var returning := false
	for step in range(7200):
		m.step(1.0/60)
		for i in range(m.COUNT):
			var p: Vector2 = m.positions[i]
			finite = finite and p.is_finite() and m.velocities[i].is_finite()
			safe = safe and absf(p.x) <= m.LIMIT.x + .001 and absf(p.y) <= m.LIMIT.y + .001 and not (absf(p.x) < m.WALL_MARGIN - .001 and absf(p.y) > m.GAP)
			speeds = speeds and m.velocities[i].length() <= m.SPEED + .001
			crossed = crossed or p.x < -.5
			returning = returning or m.states[i] == m.State.RETURNING
	check("Bodies actually cross into the pulse side", crossed)
	check("Crowd never crosses partition or outer boundary", safe)
	check("All velocity updates stay finite and capped", speeds and finite)
	check("Investigating bodies eventually switch to return", returning)
	check("Whole crowd returns to its original resting places", m.counts() == [20,0,0] and m.positions == m.homes)
	if m.counts() != [20,0,0]: print("UNSETTLED ",m.counts()," ",m.positions)
	# Independent range case: a farther source leaves some bodies untouched.
	m = Model.new(); var heard: int = m.pulse(Vector3(-4.2,1.4,-3.3))
	check("Eight-metre hearing radius excludes distant listeners", heard > 0 and heard < 20)
	m = Model.new(); m.pulse(Vector3(-2,1.4,0)); m.step(.05)
	m.pulse(Vector3(1,1.4,0))
	check("A later audible pulse replaces the earlier record", m.memories[0] == Vector2(1,0) and m.dwell[0] == 0 and m.pulses == 2)
	m = Model.new(); m.positions[0]=Vector2(.4,3); m.pulse(Vector3(-.4,1.4,3)); m.step(.05)
	check("Arrival cannot be claimed through the partition",m.dwell[0]==0 and m.states[0]==m.State.INVESTIGATING)
	var scene = load("res://commons/artifacts/listening_horde/listening_horde.tscn")
	var room := Node3D.new(); root.add_child(room); room.position=Vector3(31,4,-20); room.rotation.y=.7
	var h = scene.instantiate(); room.add_child(h); await process_frame; h.playing=false
	check("Runtime creates twenty full-size listeners", h.bodies.size()==20 and is_equal_approx(h.heads[0].position.y,1.45))
	check("Sphere reuses the carried PointBody",h.point.has_method("pick_up") and h.point.get_script().resource_path.ends_with("particle_swarm_walk/point_body.gd"))
	h.point.action()
	check("Unheld trigger cannot send a pulse",h.model.pulses==0)
	var pointer:=Node3D.new();root.add_child(pointer);h.point.on_desktop_grab(pointer)
	h.point.global_position=h.to_global(Vector3(-2.1,1.4,-1.6));h.point.action()
	check("Real held action records transformed local coordinates",h.model.pulses==1 and h.model.memories[0].is_equal_approx(Vector2(-2.1,-1.6)))
	var record:Vector3=h.recorded_position;var memory:Vector2=h.model.memories[0]
	h.point.global_position=h.to_global(Vector3(-1,1.4,2));h._physics_process(.1)
	check("Moving the hand never moves the remembered destination",h.recorded_position==record and h.model.memories[0]==memory)
	h.point.action();check("Rapid repeat is debounced",h.model.pulses==1)
	h.point.on_desktop_drop(pointer);h._physics_process(2)
	check("Dropped sphere returns without clearing agent memory",h.point.global_position.is_equal_approx(h.to_global(h.HOME)) and h.model.memories[0]==memory)
	check("Memory marker remains at the original pulse",h.marker.position.is_equal_approx(Vector3(record.x,0,record.z)))
	check("State has glyph and colour, not colour alone",h.glyphs[0].text=="?" and h.heads[0].material_override.albedo_color==h.COLOURS[1])
	FileAccess.open("res://ada_run/listening_horde_checks.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Production state/movement model plus real scene and synthetic desktop pickup/action. No headset claim."},"  "))
	quit(0 if failures.is_empty() else 1)
