extends SceneTree
## Independent review probe for B19, the standing 3 x 3 array. claude-edges-pilot, 2026-10-13.
##
## WHAT IT MEASURES, with the game's own bodies and balls, at stages 2 to 4:
##   FORMATION   nine heads on the 3 x 3 grid, nine [row, column] labels, the eight-bar open
##               frame; from the TRUE arrival (the walker where the game puts it, its camera
##               current) every head is visible by ray and inside the camera's frame.
##   RHYTHM      the real loop for 31 game seconds: which heads fire together, at what clock,
##               rows 0-2 then columns 0-2, then the wrap; how many balls and warnings are
##               live at once; how long a ball takes to the entrance.
##   ONE VOLLEY  a standing visitor at the arrival: how many of the three balls of row 0
##               reach the body, and how many hits the arena counts.
##   COVER       9 heads x 8 standing places, one real zigzag ball each: arrival, console,
##               both refuges, the lane, the first pickup, past the array. A straight-ray
##               prediction is kept beside each result.
##   DODGE       the visitor sidesteps 0.8 m and 1.5 m to either side AFTER the ball leaves;
##               hit or miss against the path's last bend; at Colour/Tiling whether the
##               missed ball reaches the floor and paints a tile.
##   FALLS       a real catalyst projectile empties one place; all nine fall through the open
##               frame to the floor; CLEAR; walking through the fallen column; RESET; the
##               vacancy label for a row and a column volley; the pickups behind the array.
##   CAPTURES    (--mode=captures, rendered) arrival views: quiet, row warning, eyes alone,
##               two seconds of flight, row 1 warning over row 0 flight, column warning,
##               the console view, a vacancy, all down; Tiling's 18-tile flash.
##
## Desktop evidence only: the desktop walker, its camera, signal-level calls. No headset.
## Owns nothing under commons/hazards/biome_ladder/. Writes ada_run/biome_ladder_arrays_review/.
## Run (physics, headless):
##   godot --path . --xr-mode off --headless --script res://tools/probes/biome_ladder_arrays_review.gd -- --stages=2,4 --time-scale=4
## Run (captures, rendered, hidden window):
##   godot --path . --xr-mode off --no-window --rendering-method gl_compatibility --resolution 1440x1000 --script res://tools/probes/biome_ladder_arrays_review.gd -- --mode=captures --stages=2,4
## Exit 0 when every check passes; observations are kept as notes whatever they say.

const WORLD := "res://commons/hazards/biome_ladder/ladder_world.tscn"
const OUT := "res://ada_run/biome_ladder_arrays_review/"
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
const MAX_FRAMES := 1500
const TILE_INDEX := 62   # x 2, z 10: the tile at world (-1, 0, 9), beside the arrival
const PLACES := {
	"arrival": Vector3(0, 0.12, 10.5),
	"console": Vector3(2.2, 0.12, 8.6),
	"left_refuge": Vector3(-4.35, 0.12, 7.9),
	"right_refuge": Vector3(4.35, 0.12, 7.9),
	"first_pickup": Vector3(-0.65, 0.12, 6.0),
	"lane_z6": Vector3(0, 0.12, 6.0),
	"lane_z5": Vector3(0, 0.12, 5.0),
	"past_left_cylinder": Vector3(-1.6, 0.12, -0.85),
}

var mode := "physics"
var stages_to_run: Array[int] = [2, 3, 4]
var time_scale := 4.0
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var notes: Array[String] = []
var shots: Array[Dictionary] = []
var rhythm_records: Array[Dictionary] = []
var world: Node3D
var walker: CharacterBody3D
var rendered := false
var done := false

func _initialize() -> void: run.call_deferred()

func _args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="): mode = a.substr(7)
		elif a.begins_with("--stages="):
			stages_to_run.clear()
			for s in a.substr(9).split(","): stages_to_run.append(int(s))
		elif a.begins_with("--time-scale="): time_scale = maxf(0.25, float(a.substr(13)))

func check(label: String, passed: bool, detail: String = "") -> void:
	checks.append({"name": label, "passed": passed, "detail": detail})
	if not passed: failures.append(label + (" (" + detail + ")" if detail != "" else ""))
	print("[arrays-review] ", "PASS " if passed else "FAIL ", label, ("  " + detail) if detail != "" else "")

func note(text: String) -> void:
	notes.append(text); print("[arrays-review] note ", text)

func game_seconds(ticks: int) -> float: return float(ticks) * time_scale / 60.0

func run() -> void:
	_args()
	rendered = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	create_timer(1700).timeout.connect(func(): check("probe completes in time", false); finish())
	var capacity := root.get_node_or_null("CatalystCapabilityManager")
	if capacity != null: capacity.progression_file = OUT + "isolated-capacity.json"
	world = load(WORLD).instantiate(); root.add_child(world); current_scene = world
	for i in range(300):
		if world.is_map_ready(): break
		await process_frame
	check("ladder world ready", world.is_map_ready())
	if not world.is_map_ready(): finish(); return
	walker = world.walker
	walker.set_physics_process(false)
	walker.camera.make_current()
	await process_frame
	note("walker layer %d mask %d groups %s camera %.2f m over the feet; time_scale %.1f; mode %s" % [walker.collision_layer, walker.collision_mask, str(walker.get_groups()), walker.camera.global_position.y - walker.global_position.y, time_scale, mode])
	if mode != "captures": Engine.time_scale = time_scale
	for stage in stages_to_run:
		world.change_stage(stage)
		await physics_frame; await process_frame
		var arena: Node3D = world.arena
		check("stage %d is built" % stage, is_instance_valid(arena) and arena.stage == stage)
		if mode == "captures":
			await captures(stage, arena)
			continue
		if mode == "clutter":
			await clutter(stage, arena)
			continue
		await formation(stage, arena)
		await rhythm(stage, arena)
		await one_volley(stage, arena)
		await cover_matrix(stage, arena)
		await dodge(stage, arena)
		await falls(stage, arena)
	Engine.time_scale = 1.0
	finish()

## ---------------------------------------------------------------- FORMATION
func formation(stage: int, arena: Node3D) -> void:
	var heads: Array = arena.heads
	check("stage %d stands nine heads" % stage, heads.size() == 9, str(heads.size()))
	var grid_ok := heads.size() == 9
	for i in range(heads.size()):
		@warning_ignore("integer_division")
		var row: int = i / 3
		var expect := Vector3((i % 3 - 1) * 2.4, 3.9 - row * 1.3, 3.5)
		if not Vector3(heads[i].home_position).is_equal_approx(expect): grid_ok = false
	check("stage %d: the nine homes form the 3 x 3 grid (x -2.4/0/2.4, y 3.9/2.6/1.3, z 3.5)" % stage, grid_ok)
	var labels: Array = arena.address_labels
	var label_ok := labels.size() == 9
	for i in range(labels.size()):
		@warning_ignore("integer_division")
		var row: int = i / 3
		if str(labels[i].text) != "[%d, %d]" % [row, i % 3]: label_ok = false
	check("stage %d: nine address labels read [row, column] from [0, 0]" % stage, label_ok, str(labels.size()))
	var bars: int = arena.get_children().filter(func(c): return c is MeshInstance3D and c.mesh is BoxMesh and is_equal_approx(c.position.z, 3.27) and (is_equal_approx(c.mesh.size.y, 3.9) or is_equal_approx(c.mesh.size.x, 7.2))).size()
	check("stage %d: the open wire frame has eight bars and no collider" % stage, bars == 8 and arena.get_children().filter(func(c): return c is StaticBody3D and is_equal_approx(c.position.z, 3.27)).size() == 0, "bars %d" % bars)
	await _place(arena.arrival)
	var cam: Camera3D = walker.camera
	var space := arena.get_world_3d().direct_space_state
	var visible := 0; var in_frame := 0
	for head in heads:
		var ray := PhysicsRayQueryParameters3D.create(cam.global_position, head.global_position, 1 | 2)
		var hit := space.intersect_ray(ray)
		if not hit.is_empty() and hit.collider == head: visible += 1
		if cam.is_position_in_frustum(head.global_position): in_frame += 1
	check("stage %d: all nine heads are visible by ray from the true arrival" % stage, visible == 9, "%d/9" % visible)
	check("stage %d: all nine heads are inside the arrival camera's frame" % stage, in_frame == 9, "%d/9, camera fov %.0f" % [in_frame, cam.fov])
	if heads.size() == 9:
		var d_top: float = cam.global_position.distance_to(heads[1].global_position)
		var d_bottom: float = cam.global_position.distance_to(heads[7].global_position)
		var rule_d: float = cam.global_position.distance_to(Vector3(0, 4.64, 3.5))
		note("stage %d from the arrival: top-centre head %.1f m away subtends %.1f deg, bottom-centre %.1f m / %.1f deg; a 0.12 m address label at %.1f m is %.2f deg tall; the 0.057 m rule text at %.1f m is %.2f deg tall; the 1.2 s white eye (0.05 m) is %.2f deg" % [stage, d_top, rad_to_deg(2 * atan(0.3 / d_top)), d_bottom, rad_to_deg(2 * atan(0.3 / d_bottom)), d_top, rad_to_deg(atan(0.12 / d_top)), rule_d, rad_to_deg(atan(0.057 / rule_d)), rad_to_deg(atan(0.05 / d_top))])
		# The stored path from each row to the arrival: length and flight time, from the game's own list.
		var path_script: GDScript = load("res://commons/hazards/biome_ladder/array_path.gd")
		for slot in [1, 4, 7]:
			var head: Node3D = heads[slot]
			var start: Vector3 = head.global_position + head.global_position.direction_to(cam.global_position) * 0.42
			var pts: PackedVector3Array = path_script.positions(start, cam.global_position, 1.0)
			var length := 0.0
			for i in range(1, pts.size()): length += pts[i - 1].distance_to(pts[i])
			note("stage %d: row %d to the arrival: path %.2f m (straight %.2f m), flight %.1f s at 1.8 m/s, so the ball lands %.1f s after the warning begins; the next group's warning begins at 4.8 s" % [stage, slot / 3, length, start.distance_to(cam.global_position), length / 1.8, 1.2 + length / 1.8])

## ---------------------------------------------------------------- RHYTHM (real loop)
func rhythm(stage: int, arena: Node3D) -> void:
	await _place(PLACES.left_refuge)
	for head in arena.heads: head.set_physics_process(true)
	arena.set_physics_process(true)
	var sent: Array = []
	var t0 := [0]
	var callbacks: Array = []
	for head in arena.heads:
		var slot: int = head.slot
		var cb := func(_shot): sent.append({"slot": slot, "tick": Engine.get_physics_frames() - t0[0]})
		head.ball_sent.connect(cb); callbacks.append([head, cb])
	t0[0] = Engine.get_physics_frames() + 1
	arena.start_round()
	var live_max := 0; var warn_max := 0
	var ticks := int(ceil(31.0 * 60.0 / time_scale))
	for i in range(ticks):
		await physics_frame
		var live: int = arena.get_children().filter(func(c): return c.get_script() != null and str(c.get_script().resource_path).ends_with("ladder_ball.gd") and not c.is_queued_for_deletion()).size()
		var warn: int = arena.heads.filter(func(h): return h.state == h.State.TELEGRAPH).size()
		live_max = maxi(live_max, live); warn_max = maxi(warn_max, warn)
	arena.rest()
	for pair in callbacks: pair[0].ball_sent.disconnect(pair[1])
	# Group the events by physics tick.
	var groups: Array = []
	for e in sent:
		if groups.is_empty() or groups[-1].tick != e.tick: groups.append({"tick": e.tick, "slots": []})
		groups[-1].slots.append(e.slot)
	for g in groups: g.slots.sort()
	var expected := [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 1, 2]]
	var order_ok := groups.size() >= 7
	var clock_ok := groups.size() >= 7
	var seq := []
	for k in range(mini(7, groups.size())):
		var at := game_seconds(int(groups[k].tick))
		seq.append("%s@%.2fs" % [str(groups[k].slots), at])
		if groups[k].slots != expected[k]: order_ok = false
		if absf(at - (1.2 + 4.8 * k)) > 0.2: clock_ok = false
	check("stage %d: the real loop fires rows 0, 1, 2 then columns 0, 1, 2 then row 0 again, each group in one physics tick" % stage, order_ok, ", ".join(seq))
	check("stage %d: groups fire 1.2 s after each 4.8 s selection (1.2, 6.0, 10.8, 15.6, 20.4, 25.2, 30.0 s)" % stage, clock_ok, ", ".join(seq))
	note("stage %d, 31 s of the real loop from behind the left refuge: at most %d balls live at once and %d heads warning at once; %d balls sent in %d groups" % [stage, live_max, warn_max, sent.size(), groups.size()])
	rhythm_records.append({"stage": stage, "groups": groups, "live_max": live_max, "warn_max": warn_max})

## ---------------------------------------------------------------- ONE VOLLEY, one visitor
func one_volley(stage: int, arena: Node3D) -> void:
	await _place(arena.arrival)
	for head in arena.heads: head.set_physics_process(true)
	arena.set_physics_process(true)
	var body_hits := [0]
	var arrivals: Array = []
	var t0 := [0]
	var callbacks: Array = []
	for head in arena.heads:
		var cb := func(shot): shot.player_hit.connect(func(_b): body_hits[0] += 1; arrivals.append(Engine.get_physics_frames() - t0[0]))
		head.ball_sent.connect(cb); callbacks.append([head, cb])
	t0[0] = Engine.get_physics_frames() + 1
	arena.start_round()
	var ticks := int(ceil(9.0 * 60.0 / time_scale))
	var settle := -1
	for i in range(ticks):
		await physics_frame
		if body_hits[0] >= 3 and settle < 0: settle = int(ceil(0.5 * 60.0 / time_scale))
		if settle > 0: settle -= 1
		if settle == 0: break
	var counted: int = arena.player_hits
	var readout: String = str(arena.readout.text)
	arena.rest()
	for pair in callbacks: pair[0].ball_sent.disconnect(pair[1])
	var spread := 0.0
	if arrivals.size() >= 2: spread = game_seconds(int(arrivals[-1]) - int(arrivals[0]))
	check("stage %d: a visitor standing still at the arrival is reached by all three balls of row 0" % stage, body_hits[0] == 3, "%d balls reached the body" % body_hits[0])
	check("stage %d: the arena counts the three balls of one row as ONE hit (hit_cooldown 0.75 s)" % stage, body_hits[0] == 3 and counted == 1, "counted %d, readout '%s'" % [counted, readout])
	if not arrivals.is_empty():
		note("stage %d: row 0's balls reach the arrival %.2f s after START (first) with %.2f s between first and last; the row's three balls are one hit for the health rule" % [stage, game_seconds(int(arrivals[0])), spread])
	arena.reset_round()
	await physics_frame

## ---------------------------------------------------------------- COVER MATRIX
func cover_matrix(stage: int, arena: Node3D) -> void:
	for head in arena.heads: head.set_physics_process(false)
	arena.set_physics_process(false)
	var forms := _forms(arena)
	var summary := {}
	for place in PLACES.keys():
		await _place(PLACES[place])
		var hit := 0; var stoppers := {}
		for head in arena.heads:
			var rec := await _shoot(stage, arena, head, place, "standing", forms)
			shots.append(rec)
			if rec.outcome == "player": hit += 1
			else: stoppers[rec.outcome] = int(stoppers.get(rec.outcome, 0)) + 1
		summary[place] = {"hit": hit, "stopped_by": stoppers}
		print("[arrays-review] stage %d cover at %-18s hit by %d of 9; stopped by %s" % [stage, place, hit, str(stoppers)])
	check("stage %d: the arrival is open to all nine heads" % stage, int(summary.arrival.hit) == 9, "%d/9" % int(summary.arrival.hit))
	check("stage %d: behind the left entrance refuge no head's zigzag reaches a standing visitor" % stage, int(summary.left_refuge.hit) == 0, "%d/9 hit, %s" % [int(summary.left_refuge.hit), str(summary.left_refuge.stopped_by)])
	check("stage %d: behind the right entrance refuge no head's zigzag reaches a standing visitor" % stage, int(summary.right_refuge.hit) == 0, "%d/9 hit, %s" % [int(summary.right_refuge.hit), str(summary.right_refuge.stopped_by)])
	var lines := []
	for place in PLACES.keys(): lines.append("%s %d/9" % [place, int(summary[place].hit)])
	note("stage %d cover, standing, one real zigzag from each head: %s" % [stage, "; ".join(lines)])
	arena.set_physics_process(true)

## ---------------------------------------------------------------- DODGE after the warning
func dodge(stage: int, arena: Node3D) -> void:
	for head in arena.heads: head.set_physics_process(false)
	arena.set_physics_process(false)
	var forms := _forms(arena)
	var table := {}
	var painted := 0; var off_world := 0; var floor_hits := 0
	for dist in [0.8, 1.5]:
		for side in [-1, 1]:
			var key := "%.1f m %s" % [dist, "left (-x)" if side < 0 else "right (+x)"]
			var toward_hit := 0; var toward := 0; var away_hit := 0; var away := 0
			for head in arena.heads:
				await _place(arena.arrival)
				var marks_before: int = arena.floor_marks.size()
				var rec := await _shoot(stage, arena, head, "arrival", "standing", forms, Vector3(side * dist, 0, 0))
				rec.dodge = key
				shots.append(rec)
				var toward_bend: bool = int(rec.bend_side) == side
				if toward_bend: toward += 1
				else: away += 1
				if rec.outcome == "player":
					if toward_bend: toward_hit += 1
					else: away_hit += 1
				if str(rec.outcome).begins_with("static:"): floor_hits += 1
				if rec.outcome == "off_world": off_world += 1
				if arena.floor_marks.size() > marks_before: painted += 1
			table[key] = {"toward_bend_hit": toward_hit, "toward_bend": toward, "away_from_bend_hit": away_hit, "away_from_bend": away}
			print("[arrays-review] stage %d dodge %s: stepping toward the last bend hit %d/%d, away from it hit %d/%d" % [stage, key, toward_hit, toward, away_hit, away])
	var far_hits: int = int(table["1.5 m left (-x)"].toward_bend_hit) + int(table["1.5 m left (-x)"].away_from_bend_hit) + int(table["1.5 m right (+x)"].toward_bend_hit) + int(table["1.5 m right (+x)"].away_from_bend_hit)
	check("stage %d: a 1.5 m sidestep after the ball leaves is missed by all nine heads either way" % stage, far_hits == 0, "%d of 18 hit" % far_hits)
	var near_toward: int = int(table["0.8 m left (-x)"].toward_bend_hit) + int(table["0.8 m right (+x)"].toward_bend_hit)
	var near_toward_n: int = int(table["0.8 m left (-x)"].toward_bend) + int(table["0.8 m right (+x)"].toward_bend)
	var near_away: int = int(table["0.8 m left (-x)"].away_from_bend_hit) + int(table["0.8 m right (+x)"].away_from_bend_hit)
	var near_away_n: int = int(table["0.8 m left (-x)"].away_from_bend) + int(table["0.8 m right (+x)"].away_from_bend)
	note("stage %d dodge 0.8 m: stepping toward the path's last bend is hit %d of %d times, stepping away from it %d of %d; the bend is the sign of the slot (even slots +, odd slots -)" % [stage, near_toward, near_toward_n, near_away, near_away_n])
	note("stage %d: of the 36 missed-or-hit flights from the arrival, %d met the floor, %d left the world, %d painted a tile (stage >= 3 paints)" % [stage, floor_hits, off_world, painted])
	if stage >= 3: check("stage %d: at least one missed volley ball at the arrival reaches the floor and paints it (the inherited colour rule can fire in play)" % stage, painted > 0, "%d painted, %d floor contacts, %d left the world" % [painted, floor_hits, off_world])
	arena.set_physics_process(true)
	arena.reset_round(); await physics_frame

## ---------------------------------------------------------------- FALLS, vacancies, passage
func falls(stage: int, arena: Node3D) -> void:
	for head in arena.heads: head.set_physics_process(true)
	arena.set_physics_process(true)
	arena.reset_round(); await physics_frame
	var top_centre: CharacterBody3D = arena.heads[1]
	var shot: RigidBody3D = load("res://commons/artifacts/ignorance_gallery/form_projectile.gd").new()
	shot.form = SphereMesh.new(); shot.form.radius = 0.07; shot.form.height = 0.14
	shot.position = top_centre.global_position + Vector3(0, 0, 0.8)
	shot.direction = Vector3.FORWARD; shot.speed = 3
	world.add_child(shot)
	for f in range(int(90 * 4 / time_scale)):
		await physics_frame
		if top_centre.destroyed: break
	check("stage %d: a real catalyst projectile empties the top-centre place [0, 1] and its label says EMPTY" % stage, top_centre.destroyed and str(arena.address_labels[1].text).contains("EMPTY"), str(arena.address_labels[1].text).replace("\n", " "))
	for head in arena.heads:
		if not head.destroyed: head.hit_by_catalyst_mode(Color.WHITE, "form")
	for f in range(int(ceil(5.0 * 60.0 / time_scale))): await physics_frame
	var on_floor := 0; var landing := {}
	for head in arena.heads:
		if head.fallen and absf(head.position.y - 0.3) < 0.1: on_floor += 1
		var key := "%.1f,%.1f" % [head.position.x, head.position.z]
		landing[key] = int(landing.get(key, 0)) + 1
	check("stage %d: all nine defeated heads fall through the open frame to the floor (y 0.3)" % stage, on_floor == 9, "%d/9; landing spots %s" % [on_floor, str(landing)])
	check("stage %d: nine down reads CLEAR / 9 OF 9 DOWN and the volleys rest" % stage, arena.completed and not arena.running and str(arena.readout.text).begins_with("CLEAR / 9 OF 9 DOWN"), str(arena.readout.text))
	await _place(Vector3(0, 0.12, 6.0))
	var through: bool = await walk_to(Vector3(0, 0.12, 1.0))
	check("stage %d: the walker passes the fallen column on the centre line" % stage, through)
	arena.reset_round(); await physics_frame; await physics_frame
	var restored: bool = arena.heads.all(func(h): return not h.destroyed and not h.fallen and Vector3(h.position).is_equal_approx(h.home_position)) and arena.address_labels.all(func(l): return not str(l.text).contains("EMPTY"))
	check("stage %d: RESET restores nine occupants at home with no EMPTY label" % stage, restored)
	# Vacancy in a row and in a column, heads held.
	for head in arena.heads: head.set_physics_process(false)
	arena.start_round(); arena.set_physics_process(false)
	arena.heads[4].hit_by_catalyst_mode(Color.WHITE, "form")
	arena.volley_step = 1; arena._begin_array_volley()
	var row_text: String = str(arena.volley_label.text)
	check("stage %d: with [1, 1] empty, row 1 fires [1, 0] and [1, 2] and the sign reads ROW [1] / 2 OF 3" % stage, arena.last_volley == [3, 5] and row_text == "ROW [1] / 2 OF 3", "%s, '%s'" % [str(arena.last_volley), row_text])
	arena.volley_step = 4; arena._begin_array_volley()
	var col_text: String = str(arena.volley_label.text)
	check("stage %d: with [1, 1] empty, column 1 fires [0, 1] and [2, 1] and the sign reads COLUMN [1] / 2 OF 3" % stage, arena.last_volley == [1, 7] and col_text == "COLUMN [1] / 2 OF 3", "%s, '%s'" % [str(arena.last_volley), col_text])
	arena.set_physics_process(true); arena.reset_round(); await physics_frame
	# Passage: the live array and the pickups behind it.
	await _place(Vector3(0, 0.12, 6.0))
	var centre: bool = await walk_to(Vector3(0, 0.12, 1.0))
	note("stage %d: walking the centre line through the live array (heads on layer 2, outside the walker's mask %d) %s; the walker passes through the body of [2, 1] at 1.3 m" % [stage, walker.collision_mask, "succeeds" if centre else "is blocked"])
	var reached := 0
	for p in arena.pickups:
		await _place(arena.arrival)
		if await walk_to(Vector3(p.global_position.x, 0.12, p.global_position.z)): reached += 1
	check("stage %d: the three pickups, two of them behind the array, are walked to from the arrival" % stage, reached == arena.pickups.size(), "%d/%d" % [reached, arena.pickups.size()])
	await _place(arena.arrival)

## ---------------------------------------------------------------- CLUTTER: a dodging visitor
## The real loop for 32 game seconds while the visitor sidesteps 1.5 m the moment a ball
## leaves, so every ball misses: how many balls and path drawings are alive at once, and
## for how long a missed ball and its line persist (lifetime 14 s against a 4.8 s interval).
func clutter(stage: int, arena: Node3D) -> void:
	await _place(arena.arrival)
	for head in arena.heads: head.set_physics_process(true)
	arena.set_physics_process(true)
	var side := [1]
	var callbacks: Array = []
	var born: Dictionary = {}
	var lived: Array = []
	var t0 := Engine.get_physics_frames()
	var events: Array = []
	for head in arena.heads:
		var slot: int = head.slot
		var cb := func(shot):
			born[shot.get_instance_id()] = Engine.get_physics_frames()
			events.append("sent %d at %.2f s" % [slot, game_seconds(Engine.get_physics_frames() - t0)])
			shot.tree_exiting.connect(func():
				lived.append(Engine.get_physics_frames() - int(born[shot.get_instance_id()]))
				events.append("exit %d at %.2f s, pos %s, spent %s, lifetime left %.1f" % [slot, game_seconds(Engine.get_physics_frames() - t0), str(_v(shot.global_position)), str(shot.spent), float(shot.lifetime)]))
			walker.global_position = arena.arrival + Vector3(side[0] * 1.5, 0, 0); walker.velocity = Vector3.ZERO
			side[0] = -side[0]
		head.ball_sent.connect(cb); callbacks.append([head, cb])
	arena.start_round()
	var live_max := 0; var lines_max := 0; var body_hits_before: int = arena.player_hits
	var ticks := int(ceil(32.0 * 60.0 / time_scale))
	var last_count := 0
	for i in range(ticks):
		await physics_frame
		var balls: Array = arena.get_children().filter(func(c): return c.get_script() != null and str(c.get_script().resource_path).ends_with("ladder_ball.gd") and not c.is_queued_for_deletion())
		if balls.size() != last_count:
			events.append("%.2f s: %d balls alive, running %s" % [game_seconds(i), balls.size(), str(arena.running)])
			last_count = balls.size()
		live_max = maxi(live_max, balls.size())
		var lines := 0
		for b in balls: lines += b.find_children("StoredPositionPath", "MeshInstance3D", false, false).size()
		for head in arena.heads:
			if is_instance_valid(head.path_preview): lines += 1
		lines_max = maxi(lines_max, lines)
	var hits: int = arena.player_hits - body_hits_before
	arena.rest()
	for pair in callbacks: pair[0].ball_sent.disconnect(pair[1])
	var longest := 0.0
	for t in lived: longest = maxf(longest, game_seconds(int(t)))
	for e in events: print("[arrays-review] clutter ", e)
	note("stage %d, 32 s of the real loop with a visitor who sidesteps 1.5 m as each ball leaves: %d hits counted, at most %d balls alive at once and %d path lines on screen at once; %d balls sent, %d left the tree, the longest after %.1f s" % [stage, hits, live_max, lines_max, born.size(), lived.size(), longest])
	check("stage %d: a sidestepping visitor is not hit in 32 s" % stage, hits == 0, "%d hits" % hits)
	check("stage %d: no more than one group's balls and lines are alive at once while the visitor dodges" % stage, live_max <= 3 and lines_max <= 6, "balls %d, lines %d" % [live_max, lines_max])
	arena.reset_round(); await physics_frame

## ---------------------------------------------------------------- CAPTURES (rendered)
func captures(stage: int, arena: Node3D) -> void:
	if not rendered:
		note("captures need the rendered backend"); return
	Engine.time_scale = 1.0
	for head in arena.heads: head.set_physics_process(false)
	arena.set_physics_process(false)
	await _place(arena.arrival)
	walker.camera.make_current()
	if stage == 2:
		await capture("s2-quiet")
		# Heads must be active to throw; activate first, since set_active clears a preview.
		for head in arena.heads: head.set_active(true)
		# Row 0 warns: the three stored paths and the white eyes.
		arena.volley_step = 0; arena._begin_array_volley()
		await capture("s2-row0-warning")
		for head in arena.heads:
			if is_instance_valid(head.path_preview): head.path_preview.hide()
		await capture("s2-row0-eyes-only")
		for head in arena.heads:
			if is_instance_valid(head.path_preview): head.path_preview.show()
		# The warning ends; the balls follow the same list for two seconds.
		var thrown := 0
		for head in arena.heads:
			if head.state == head.State.TELEGRAPH:
				head.advance(head.WINDUP + 0.01, head.target_position())
				thrown += head.projectiles.size()
		check("stage 2 captures: row 0 threw three balls for the flight frames", thrown == 3, str(thrown))
		for f in range(120): await physics_frame
		await capture("s2-row0-flight-2s")
		# The real overlap: row 1 warns while row 0 is still in the air.
		arena.volley_step = 1; arena._begin_array_volley()
		await capture("s2-overlap-row1-warning-row0-flight")
		for head in arena.heads: head.clear_shots(); head.set_active(false)
		await physics_frame
		for head in arena.heads: head.set_active(true)
		arena.volley_step = 4; arena._begin_array_volley()
		await capture("s2-column1-warning")
		for head in arena.heads: head.set_active(false)
		# The console view, where the visitor presses START.
		await _place(PLACES.console)
		for head in arena.heads: head.set_active(true)
		arena.volley_step = 0; arena._begin_array_volley()
		await capture("s2-console-row0-warning")
		for head in arena.heads: head.set_active(false)
		await _place(arena.arrival)
		arena.heads[4].hit_by_catalyst_mode(Color.WHITE, "form")
		arena.heads[4].set_physics_process(true)
		for f in range(150): await physics_frame
		await capture("s2-vacancy-11")
		for head in arena.heads:
			if not head.destroyed: head.hit_by_catalyst_mode(Color.WHITE, "form")
			head.set_physics_process(true)
		for f in range(240): await physics_frame
		await capture("s2-all-down")
		arena.reset_round()
	if stage == 4:
		await capture("s4-quiet")
		var capacity := root.get_node_or_null("CatalystCapabilityManager")
		var ability: Node3D = capacity.first_catalyst if capacity != null else null
		if ability != null and arena.floor_tile_bodies.size() > TILE_INDEX:
			var over: Vector3 = arena.floor_tile_bodies[TILE_INDEX].global_position + Vector3(0, 1.3, 0)
			ability.update_hands(Transform3D(Basis.IDENTITY, over + Vector3(-0.1, 0, 0)), Transform3D(Basis.IDENTITY, over + Vector3(0.1, 0, 0)), true, true, 0.2)
			ability._cooldown = 0.0
			var shot: RigidBody3D = ability.send_form(Vector3.DOWN)
			var began := Engine.get_physics_frames()
			while arena.floor_flashes.size() == 0 and Engine.get_physics_frames() - began < 120: await physics_frame
			var flashes: int = arena.floor_flashes.size()
			check("stage 4: one hand throw lights eighteen tile flashes at once", flashes == 18, str(flashes))
			for f in range(12): await physics_frame
			await capture("s4-flash-at-0.2s")
			for f in range(90): await physics_frame
			check("stage 4: the flashes are gone after 1.15 s", arena.floor_flashes.size() == 0, str(arena.floor_flashes.size()))
			await capture("s4-after-flash")
			ability._hide_all()
			if shot != null and is_instance_valid(shot): shot.queue_free()
	arena.set_physics_process(true)

## ---------------------------------------------------------------- helpers
func _place(at: Vector3) -> void:
	walker.global_position = at; walker.velocity = Vector3.ZERO
	await physics_frame; await physics_frame

func _forms(arena: Node3D) -> Array[AnimatableBody3D]:
	var out: Array[AnimatableBody3D] = []
	for child in arena.get_children():
		if child is AnimatableBody3D: out.append(child)
	return out

## One real zigzag ball from `head` at the walker's camera; `step` moves the walker the
## moment the ball leaves (the warning has ended by then). Outcome read from the physics
## space at the last live position: player / form / static / off_world / expired.
func _shoot(stage: int, arena: Node3D, head: CharacterBody3D, place: String, stance: String, forms: Array[AnimatableBody3D], step: Vector3 = Vector3.ZERO) -> Dictionary:
	head.set_active(true); head.target_override = null
	var aim: Vector3 = head.target_position()
	head.begin_telegraph(arena.to_local(aim))
	var ball: Node3D = head.throw_ball()
	var record := {"stage": stage, "place": place, "stance": stance, "head": head.slot, "walker": _v(walker.global_position), "aim": _v(aim), "head_at": _v(head.global_position)}
	if ball == null:
		record.outcome = "no_ball"; _rest(head); return record
	var pts: PackedVector3Array = ball.waypoints
	var length := 0.0
	for i in range(1, pts.size()): length += pts[i - 1].distance_to(pts[i])
	record.path_m = snappedf(length, 0.01)
	record.bend_side = int(signf(pts[3].x - pts[4].x)) if pts.size() == 5 else 0
	record.predicted = _predict(stage, ball.global_position, aim, forms)
	if step != Vector3.ZERO:
		walker.global_position += step; walker.velocity = Vector3.ZERO
		record.walker_after_step = _v(walker.global_position)
	var start: Vector3 = ball.global_position
	var hit_player := [false]
	ball.player_hit.connect(func(_body): hit_player[0] = true)
	var frames := 0; var last := start; var rf := 1.0; var left_world := false
	while is_instance_valid(ball) and not ball.is_queued_for_deletion() and not ball.spent and frames < MAX_FRAMES:
		last = ball.global_position; rf = float(ball.get("radius_factor"))
		if absf(last.x) > 6.6 or last.z > 12.6 or last.z < -12.6 or last.y < -0.5 or last.y > 12.0:
			left_world = true; break
		await physics_frame; frames += 1
	var outcome := "expired"
	if hit_player[0]: outcome = "player"
	elif left_world: outcome = "off_world"
	else:
		var from: Vector3 = ball.global_position if is_instance_valid(ball) else last
		var dir: Vector3 = Vector3(ball.direction).normalized() if is_instance_valid(ball) else (last - start).normalized()
		outcome = _next_collider(arena, from, dir, 0.09 * rf + 1.8 * time_scale / 60.0 + 0.05, forms)
		if outcome == "nothing": outcome = "timeout" if frames >= MAX_FRAMES else "expired"
	var end: Vector3 = ball.global_position if is_instance_valid(ball) else last
	record.outcome = outcome; record.frames = frames; record.flight_s = snappedf(game_seconds(frames), 0.01)
	record.stopped_at = _v(end); record.travelled = snappedf(start.distance_to(end), 0.01)
	_rest(head)
	await physics_frame
	return record

func _rest(head: CharacterBody3D) -> void:
	head.clear_shots(); head.set_active(false); head.target_override = null
	head.position = head.home_position; head.phase = 0.0

func _next_collider(arena: Node3D, from: Vector3, dir: Vector3, reach: float, forms: Array[AnimatableBody3D]) -> String:
	var space := arena.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from - dir * 0.05, from + dir * reach, 1 | 524288)
	q.collide_with_bodies = true; q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	var c: Node = null
	if not hit.is_empty(): c = hit.collider
	else:
		var sq := PhysicsShapeQueryParameters3D.new()
		var s := SphereShape3D.new(); s.radius = reach * 0.6; sq.shape = s
		sq.transform = Transform3D(Basis.IDENTITY, from + dir * (reach * 0.4)); sq.collision_mask = 1 | 524288
		sq.collide_with_bodies = true; sq.collide_with_areas = false
		var overlaps := space.intersect_shape(sq, 4)
		if overlaps.is_empty(): return "nothing"
		c = overlaps[0].collider
	if c == walker or c.is_in_group("player_body") or c.is_in_group("player"): return "player"
	if c is AnimatableBody3D and forms.has(c): return "form:" + str(c.name) if str(c.name).begins_with("PrimitiveCover") else "form:#%d" % forms.find(c)
	if c is StaticBody3D:
		var tile: int = arena.floor_tile_bodies.find(c)
		return "static:tile%d" % tile if tile >= 0 else "static:" + str(c.name)
	return c.get_class()

## Straight ray from the launch point to the aim point against the forms' boxes, with the
## ball's growing radius: what a visitor reading a straight line would expect.
func _predict(stage: int, start: Vector3, aim: Vector3, forms: Array[AnimatableBody3D]) -> String:
	var dir := (aim - start)
	var length := dir.length()
	if length < 0.01: return "degenerate"
	dir /= length
	var d := 0.0
	while d <= length:
		var p := start + dir * d
		var r := 0.09 * (minf(2.2, 1.0 + (d / 1.8) * 0.22) if stage >= 1 else 1.0)
		for i in range(forms.size()):
			var view := forms[i].get_child(1) as MeshInstance3D
			if view == null or view.mesh == null: continue
			var box: AABB = (view.global_transform * view.mesh.get_aabb()).grow(r)
			if box.has_point(p): return "form:" + str(forms[i].name) if str(forms[i].name).begins_with("PrimitiveCover") else "form:#%d" % i
		d += 0.05
	return "player"

func walk_to(target: Vector3) -> bool:
	var frames := 0
	while frames < int(ceil(900.0 * 4.0 / time_scale)) and frames < 1200:
		var to := Vector3(target.x - walker.global_position.x, 0, target.z - walker.global_position.z)
		if to.length() < 0.9: return true
		walker.velocity = Vector3(to.normalized().x * 2.5, -2.0, to.normalized().z * 2.5)
		walker.move_and_slide()
		await physics_frame; frames += 1
	return false

func _v(v: Vector3) -> Array: return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]

func capture(name: String) -> void:
	for f in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")
	print("[arrays-review] capture ", name)

func _source_version() -> Dictionary:
	var out := {}
	for p in ["res://commons/hazards/biome_ladder/ladder_encounter.gd", "res://commons/hazards/biome_ladder/ladder_skull.gd", "res://commons/hazards/biome_ladder/ladder_ball.gd", "res://commons/hazards/biome_ladder/array_path.gd", "res://commons/hazards/biome_ladder/ladder_world.gd"]:
		out[p.get_file()] = {"modified_unix": FileAccess.get_modified_time(p), "sha256": FileAccess.get_sha256(p)}
	return out

func finish() -> void:
	if done: return
	done = true
	Engine.time_scale = 1.0
	var passed := checks.filter(func(c): return c.passed).size()
	var report := {"written": Time.get_datetime_string_from_system(), "mode": mode, "rendered": rendered, "time_scale": time_scale, "stages": stages_to_run,
		"scope": "desktop walker and camera, real LadderBalls and a real catalyst projectile, signal-level calls; no headset, no hands",
		"source": _source_version(), "passed": passed, "total": checks.size(), "failures": failures, "notes": notes, "checks": checks, "rhythm": rhythm_records, "shots": shots}
	# One report per mode, so a short clutter or captures run never overwrites the physics report.
	var f := FileAccess.open(OUT + ("report.json" if mode == "physics" else "report-%s.json" % mode), FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(report, "\t")); f.close()
	print("[arrays-review] %s %d/%d  report %s" % ["PASS" if failures.is_empty() else "FAIL", passed, checks.size(), OUT])
	for line in failures: print("[arrays-review] FAIL ", line)
	quit(0 if failures.is_empty() else 1)
