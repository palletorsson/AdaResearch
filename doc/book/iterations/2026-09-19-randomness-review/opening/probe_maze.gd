extends SceneTree
var checks: Array = []
func _initialize() -> void: call_deferred("run")
func check(label: String, passed: bool, details = null) -> void:
	checks.append({"label":label,"passed":passed,"details":details})
func raster_matches(maze: Node3D) -> bool:
	for z in maze.grid_depth:
		for x in maze.grid_width:
			var mesh: MeshInstance3D = maze.wall_nodes[z * maze.grid_width + x].get_child(0)
			var slope: Vector3 = mesh.basis.z
			var rises := slope.y * slope.z > 0
			for i in maze.nav_grid_scale:
				var yy: int = i if rises else maze.nav_grid_scale - 1 - i
				var other: int = maze.nav_grid_scale - 1 - yy
				if maze.nav_grid[z * maze.nav_grid_scale + yy][x * maze.nav_grid_scale + i] != 1: return false
				if other != yy and maze.nav_grid[z * maze.nav_grid_scale + other][x * maze.nav_grid_scale + i] != 0: return false
	return true
func run() -> void:
	var source := OS.get_environment("PROBE_SOURCE")
	var maze = load(source).new()
	maze.grid_width = 2; maze.grid_depth = 2; maze.animate = false
	maze.maze = [[0,1],[1,0]]
	maze.build_navigation_grid(); maze.create_3d_maze()
	check("both initial diagonal orientations match their navigation raster", raster_matches(maze))
	var original: Array = maze.maze.duplicate(true)
	var old_grid: Array = maze.nav_grid.duplicate(true)
	maze.ant_nav_pos = Vector2i(1,1)
	maze.ant_path = [Vector2i(0,0),Vector2i(1,1)]
	maze.visited = {Vector2i(0,0):true,Vector2i(1,1):true}
	seed(123)
	maze._on_wall_timer_timeout()
	var changed := 0
	for z in maze.grid_depth:
		for x in maze.grid_width:
			if maze.maze[z][x] != original[z][x]: changed += 1
	check("one visual replacement updates exactly one stored orientation",changed == 1,changed)
	check("navigation raster is rebuilt after replacement",maze.nav_grid != old_grid)
	check("replacement geometry and navigation agree",raster_matches(maze))
	check("old search exclusions are released for the changed topology",maze.visited.size()==1 and maze.visited.has(maze.ant_nav_pos))
	check("new search begins at current ant rather than teleporting to entrance",maze.ant_path.size()==1 and maze.ant_path[0]==Vector2i(1,1) and maze.ant_nav_pos==Vector2i(1,1))
	var moves: Array = maze.get_possible_moves()
	var expected: Array = []
	for direction in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
		var next: Vector2i = maze.ant_nav_pos + direction
		if next.x >= 0 and next.x < 4 and next.y >= 0 and next.y < 4 and maze.nav_grid[next.y][next.x] == 0:
			expected.append(next)
	check("next search admits exactly the unblocked neighbours in the refreshed raster",moves==expected,{"actual":str(moves),"expected":str(expected)})
	for k in 12:
		maze._on_wall_timer_timeout()
		check("raster remains aligned after repeated replacement %d" % k,raster_matches(maze))
	maze.free()
	# Stand up the actual shipped stroke scene at its full10x10 size, without
	# allowing unrelated elapsed-time draws to intervene in this bounded check.
	var packed_maze = load("res://algorithms/randomness/generative/tenprintantmaze/ten_print_maze_3d.tscn")
	var placed = packed_maze.instantiate()
	placed.set_script(load(source))
	placed.maze_seed = 1982
	root.add_child(placed)
	placed.set_process(false); placed.wall_timer.stop()
	check("shipped scene retains100stroke cells",placed.wall_nodes.size()==100 and placed.impression=="stroke")
	check("shipped timer remains0.08seconds",is_equal_approx(placed.wall_timer.wait_time,.08))
	check("shipped scene initial raster matches its rendered strokes",raster_matches(placed))
	var ant_before: Vector2i = placed.ant_nav_pos
	placed._on_wall_timer_timeout()
	check("shipped scene replacement agrees with navigation",raster_matches(placed))
	check("shipped scene ant stays in place during topology change",placed.ant_nav_pos==ant_before)
	placed.queue_free(); await process_frame
	var replay = load("res://algorithms/randomness/seed_replay/seed_replay_demo.gd").new()
	replay.comparison = "replicas"; replay._columns = [{},{}]
	var left: PackedFloat32Array = replay.raw_prefix(0,25)
	check("seed comparison replays the same raw stream",left==replay.raw_prefix(1,25))
	replay._extra_on = true
	var right: PackedFloat32Array = replay.raw_prefix(1,24)
	check("extra draw shifts the same stream by exactly one position",right==left.slice(1))
	check("inspection does not consume the replay stream",right==replay.raw_prefix(1,24))
	check("configured64cubes consume192colour draws",replay.draws_per_grid()==192)
	replay.free()
	var meter = load("res://commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd").new()
	meter._draw_contrast_sample()
	var counts: Array[int] = []; counts.resize(meter.num_symbols); counts.fill(0)
	for symbol in meter._sample_contrast: counts[symbol] += 1
	var h := 0.0
	for count in counts:
		if count > 0:
			var p: float = float(count)/meter.sequence_length
			h -= p * log(p)/log(2.0)
	check("concentrated sample retains200draws and first-symbol109",meter._sample_contrast.size()==200 and counts[0]==109,counts)
	check("concentrated sample has four absent symbols",counts.count(0)==4)
	check("concentrated sample empirical entropy rounds to1.82bits",absf(h-1.82)<.005,h)
	meter.free()
	var packed = load("res://algorithms/nature_system/demo/nature_system_demo.tscn")
	check("Nature System standalone scene loads",packed is PackedScene)
	if packed is PackedScene:
		var demo = packed.instantiate()
		check("Nature System instantiated without starting its population",demo != null)
		check("Nature System is a standalone48specimen layout",demo.grid_rows*demo.grid_cols*4 == 48, {"rows":demo.grid_rows,"columns":demo.grid_cols,"spacing":demo.grid_spacing,"auto_populate":demo.auto_populate})
		demo.free()
	var failed := checks.filter(func(v):return not v.passed)
	var file := FileAccess.open(OS.get_environment("PROBE_OUTPUT"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"source":source,"checks":checks,"failed":failed.size()},"  ")); file.close()
	print("RANDOM_MAZE ",checks.size()," checks; ",failed.size()," failed")
	quit(0 if failed.is_empty() else 1)
