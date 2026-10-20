extends SceneTree
## Six-stage review probe: Primitives, Transformation, Arrays, Colour, Tiling, Change.
## claude-edges-pilot, 2026-10-13. Owns nothing under commons/hazards/biome_ladder/.
##
## PHYSICS MODE (headless), per stage:
##   RETAINED     what the earlier stages gave is still here (heads, shelters, catalyst, hand,
##                motions, pickups, a floor that answers a real hand throw, the 3 x 3 array,
##                colour, the eighteen copies and flashes, the arrows).
##   NEW          the stage's own operation under real conditions: cover and the open lane
##                (0), moving forms (1), the row volleys of the real loop (2), a hand tint on
##                the floor and a skull ball that meets the floor (3), the second hit on a copy
##                (4), the field bending a centre ball, the preview predicting it, the one-turn
##                signal and what a sidestep before or after it does (5).
##   CONSISTENCY  the rules Palle asked for, as of this runtime: START keeps a floor edit;
##                REST stops the attack and keeps the edit; RESET restores everything.
##   CLUTTER      (stages 2 and 5) the real loop with a visitor who sidesteps every ball: how
##                long a missed ball and its line linger after leaving the playable area.
## CAPTURES MODE (rendered): the walker camera at the true arrival, every stage, the same
##   moments: quiet, the first warning, two seconds of flight, a hand throw's floor impact;
##   at Change the bent field preview, the turn signal and the committed line.
##
## Desktop evidence only. Writes ada_run/biome_ladder_six_review/. Exit 0 when every check
## passes; a failing check is a finding about the runtime as it stands.
## Run:
##   godot --path . --xr-mode off --headless --script res://tools/probes/biome_ladder_six_review.gd -- --time-scale=4
##   godot --path . --xr-mode off --no-window --rendering-method gl_compatibility --resolution 1440x1000 --script res://tools/probes/biome_ladder_six_review.gd -- --mode=captures

const WORLD := "res://commons/hazards/biome_ladder/ladder_world.tscn"
const OUT := "res://ada_run/biome_ladder_six_review/"
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
const MAX_FRAMES := 1500
const TILE_INDEX := 62          # x 2, z 10: world (-1, 0, 9), beside the arrival
const CENTRE_PATH_TILES := [51, 57]   # column 3 (x 0..2), rows 8 and 9: the cells a centre ball crosses
const EXPOSED := Vector3(0, 0.12, 8.0)

var mode := "physics"
var stages_to_run: Array[int] = [0, 1, 2, 3, 4, 5]
var time_scale := 4.0
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var notes: Array[String] = []
var stage_summaries: Dictionary = {}
var world: Node3D
var walker: CharacterBody3D
var ability: Node3D
var rendered := false
var done := false
var source_at_boot := {}

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
	print("[six] ", "PASS " if passed else "FAIL ", label, ("  " + detail) if detail != "" else "")

func note(text: String) -> void:
	notes.append(text); print("[six] note ", text)

func game_seconds(ticks: int) -> float: return float(ticks) * (time_scale if mode != "captures" else 1.0) / 60.0

func run() -> void:
	_args()
	rendered = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	source_at_boot = _source_version()
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
	ability = capacity.first_catalyst if capacity != null else null
	await process_frame
	note("route has %d stages: %s; walker mask %d, camera %.2f m over the feet; mode %s, time_scale %.1f" % [Route.STAGES.size(), ", ".join(Route.STAGES.map(func(s): return str(s.title))), walker.collision_mask, walker.camera.global_position.y - walker.global_position.y, mode, time_scale])
	if mode != "captures": Engine.time_scale = time_scale
	for stage in stages_to_run:
		if stage >= Route.STAGES.size():
			check("stage %d exists in the route" % stage, false); continue
		world.change_stage(stage)
		await physics_frame; await process_frame
		var arena: Node3D = world.arena
		check("stage %d (%s) is built" % [stage, Route.STAGES[stage].title], is_instance_valid(arena) and arena.stage == stage)
		stage_summaries[str(stage)] = {"title": Route.STAGES[stage].title}
		if mode == "captures":
			await captures(stage, arena)
			continue
		await retained(stage, arena)
		await new_operation(stage, arena)
		if stage >= 1: await consistency(stage, arena)
		if stage in [2, 5]: await clutter(stage, arena)
	Engine.time_scale = 1.0
	finish()

## ---------------------------------------------------------------- RETAINED
func retained(stage: int, arena: Node3D) -> void:
	var shelters: Array = arena.get_children().filter(func(c): return c is AnimatableBody3D and str(c.name).begins_with("PrimitiveCover"))
	var expected_heads: int = 9 if stage >= 2 else 3
	check("stage %d keeps %d heads" % [stage, expected_heads], arena.heads.size() == expected_heads, str(arena.heads.size()))
	check("stage %d keeps the six tall shelters" % stage, shelters.size() == 6, str(shelters.size()))
	check("stage %d keeps the held catalyst and the lent hand" % stage, is_instance_valid(arena.catalyst) and ability != null and ability.unlocked)
	if stage >= 1:
		check("stage %d keeps the learned motions, three pickups and the 72-tile floor" % stage, arena.motions.size() > 0 and arena.pickups.size() == 3 and arena.floor_tile_bodies.size() == 72, "motions %d pickups %d tiles %d" % [arena.motions.size(), arena.pickups.size(), arena.floor_tile_bodies.size()])
		var hits: int = await hand_throw(arena, TILE_INDEX)
		var tile: MeshInstance3D = arena.floor_tiles[TILE_INDEX]
		check("stage %d: a tile answers a real hand throw with x0.8 and +22.5 deg" % stage, hits >= 1 and is_equal_approx(tile.scale.x, pow(0.8, hits)) and is_equal_approx(rad_to_deg(tile.rotation.y), 22.5 * hits), "hits %d scale %.2f rot %.1f" % [hits, tile.scale.x, rad_to_deg(tile.rotation.y)])
	if stage >= 2:
		var grid: bool = arena.heads.size() == 9
		for i in range(arena.heads.size()):
			@warning_ignore("integer_division")
			var row: int = i / 3
			if not Vector3(arena.heads[i].home_position).is_equal_approx(Vector3((i % 3 - 1) * 2.4, 3.9 - row * 1.3, 3.5)): grid = false
		check("stage %d keeps the addressed 3 x 3 array with nine labels" % stage, grid and arena.address_labels.size() == 9)
	if stage >= 3:
		var hues := {}
		for f in arena.get_children().filter(func(c): return c is AnimatableBody3D):
			var view := f.get_child(1) as MeshInstance3D
			if view != null and view.material_override is StandardMaterial3D:
				var c: Color = view.material_override.albedo_color
				if c.s > 0.3: hues[snappedf(c.h, 0.05)] = true
		check("stage %d keeps coloured forms and the hand's tint on the floor" % stage, hues.size() >= 3 and arena.floor_marks.has(TILE_INDEX), "%d hues, marks %d" % [hues.size(), arena.floor_marks.size()])
	if stage >= 4:
		var copies: int = arena.floor_tile_hits.size()
		check("stage %d keeps the eighteen copies of one hit, flashing together" % stage, copies == 18 and arena.floor_flashes.size() == 18, "copies %d flashes %d" % [copies, arena.floor_flashes.size()])
	if stage >= 5:
		var field_slots: Array = arena.heads.filter(func(h): return h.uses_field()).map(func(h): return h.slot)
		check("stage %d adds 72 arrows and gives the field to the centre column only" % stage, is_instance_valid(arena.direction_field) and arena.direction_field.arrows.size() == 72 and field_slots == [1, 4, 7], str(field_slots))
	arena.reset_round(); await physics_frame

## ---------------------------------------------------------------- NEW operation
func new_operation(stage: int, arena: Node3D) -> void:
	var forms := _forms(arena)
	match stage:
		0:
			await _place(EXPOSED)
			var open: Dictionary = await _shoot(stage, arena, _nearest_head(arena, walker.global_position), "lane", forms)
			var shelter: Node3D = arena.get_node("PrimitiveCover_0_Left")
			var head: CharacterBody3D = _nearest_head(arena, shelter.global_position)
			var f := Vector2(shelter.global_position.x, shelter.global_position.z); var h := Vector2(head.global_position.x, head.global_position.z)
			var behind := f + (f - h).normalized() * 1.35
			await _place(Vector3(behind.x, 0.12, behind.y))
			var covered: Dictionary = await _shoot(stage, arena, head, "behind_shelter", forms)
			check("stage 0: a real ball reaches the visitor in the open lane and is stopped behind the first shelter", open.outcome == "player" and str(covered.outcome).begins_with("form"), "%s / %s" % [open.outcome, covered.outcome])
			var before: Array = arena.heads.map(func(hd): return Vector3(hd.global_position))
			for head2 in arena.heads: head2.set_physics_process(true)
			for i in range(int(ceil(2.0 * 60.0 / time_scale))): await physics_frame
			var moved: int = 0
			for i in range(arena.heads.size()):
				if not Vector3(arena.heads[i].global_position).is_equal_approx(before[i]): moved += 1
			check("stage 0: the heads stand still (no motion before Transformation)", moved == 0, "%d moved" % moved)
		1:
			var sample_a: Array = arena.motions.map(func(m): return Vector3(m.body.global_position))
			var scale_a: Array = arena.motions.map(func(m): return float(m.view.scale.x))
			for i in range(int(ceil(2.0 * 60.0 / time_scale))): await physics_frame
			var translated := 0; var scaled := 0; var turned := 0
			for i in range(arena.motions.size()):
				var m: Dictionary = arena.motions[i]
				if int(m.kind) == 0 and not Vector3(m.body.global_position).is_equal_approx(sample_a[i]): translated += 1
				if int(m.kind) == 2 and not is_equal_approx(float(m.view.scale.x), float(scale_a[i])): scaled += 1
				if int(m.kind) == 1 and absf(float(m.body.rotation.y)) > 0.01: turned += 1
			check("stage 1: forms translate, turn and scale on the arena clock", translated > 0 and scaled > 0 and turned > 0, "translate %d turn %d scale %d" % [translated, turned, scaled])
			# Heads sway only while active (ladder_skull.advance returns early otherwise): in READY they hold still.
			var home: Vector3 = arena.heads[0].home_position
			for head in arena.heads: head.set_physics_process(true)
			for i in range(int(ceil(1.0 * 60.0 / time_scale))): await physics_frame
			var still_in_ready: bool = Vector3(arena.heads[0].position).is_equal_approx(home)
			for head in arena.heads: head.set_active(true)
			for i in range(int(ceil(2.0 * 60.0 / time_scale))): await physics_frame
			check("stage 1: the heads hold still before START and sway from their homes once active", still_in_ready and not Vector3(arena.heads[0].position).is_equal_approx(home), "ready still %s, active offset %s" % [str(still_in_ready), str(_v(arena.heads[0].position - home))])
			for head in arena.heads: head.set_active(false); head.position = head.home_position
		2:
			await _place(Vector3(-4.35, 0.12, 7.9))
			var groups: Array = await _real_loop_groups(arena, 7.0)
			check("stage 2: the real loop fires row 0 then row 1, three balls each in one tick", groups.size() >= 2 and groups[0].slots == [0, 1, 2] and groups[1].slots == [3, 4, 5], str(groups.map(func(g): return str(g.slots))))
		3:
			# The hand's tint is on the tile from RETAINED (reset since). Paint again and read it.
			var hits: int = await hand_throw(arena, TILE_INDEX)
			var tint: Variant = arena.floor_marks.get(TILE_INDEX)
			check("stage 3: a hand throw leaves its own saturated colour on the tile it hit", hits >= 1 and tint is Color and Color(tint).s > 0.5, str(tint))
			# A skull ball that meets the floor paints the tile it meets.
			var marks_before: int = arena.floor_marks.size()
			var marker := Marker3D.new(); marker.position = Vector3(0, 0.3, 7.0); world.add_child(marker)
			var head: CharacterBody3D = arena.heads[0]
			head.set_active(true); head.target_override = marker
			head.begin_telegraph(arena.to_local(head.target_position()))
			var ball: Node3D = head.throw_ball()
			var frames := 0
			while is_instance_valid(ball) and not ball.is_queued_for_deletion() and frames < MAX_FRAMES:
				await physics_frame; frames += 1
			await physics_frame
			var painted: int = arena.floor_marks.size() - marks_before
			check("stage 3: a skull ball aimed low enough to meet the floor paints the tile it meets", painted == 1, "%d tiles painted" % painted)
			head.clear_shots(); head.set_active(false); head.target_override = null; marker.queue_free()
			# Ordinary play from the arrival: how often does a skull ball paint the floor?
			arena.reset_round(); await physics_frame
			marks_before = arena.floor_marks.size()
			var hits_counted: int = await _dodging_loop(arena, 16.0)
			note("stage 3, 16 s of the real loop with a visitor sidestepping every ball at the arrival: %d tiles painted by skull balls, %d hits counted" % [arena.floor_marks.size() - marks_before, hits_counted])
		4:
			var first: int = await hand_throw(arena, TILE_INDEX)
			var second: int = await hand_throw(arena, TILE_INDEX)
			var twice: int = arena.floor_tile_hits.keys().filter(func(k): return int(arena.floor_tile_hits[k]) == 2).size()
			check("stage 4: a second hit on the same copy address updates all eighteen copies again", first == 1 and second == 2 and twice == 18 and arena.floor_tile_hits.size() == 18, "tiles at 2 hits: %d" % twice)
		5:
			await change_operation(arena)
	arena.reset_round(); await physics_frame

## Change: the field bends the centre ball, the preview predicts it, the signal is the dodge.
func change_operation(arena: Node3D) -> void:
	var field: Node3D = arena.direction_field
	check("stage 5: untouched arrows prescribe forward motion", Vector3(field.sample(Vector3(1, 0.5, 5))).is_equal_approx(Vector3.BACK))
	for t in CENTRE_PATH_TILES: await hand_throw(arena, t)
	var turned := Vector3.BACK.rotated(Vector3.UP, deg_to_rad(22.5))
	check("stage 5: two hand throws on the centre path's cells turn their arrows 22.5 deg (36 copies)", arena.floor_tile_hits.size() == 36 and Vector3(field.sample(Vector3(1, 0.5, 5))).is_equal_approx(turned) and Vector3(field.sample(Vector3(1, 0.5, 7))).is_equal_approx(turned), "hits %d" % arena.floor_tile_hits.size())
	await _place(arena.arrival)
	var centre: CharacterBody3D = arena.heads[4]
	# (iii) the preview predicts the field phase of the flight
	centre.set_physics_process(true); centre.set_active(true); centre.target_override = null
	centre.begin_telegraph(arena.to_local(centre.target_position()))
	var preview: PackedVector3Array = centre.pending_path.duplicate()
	var ball: Node3D = centre.throw_ball()
	var announced := [false]; var committed := [false]
	var announce_tick := [0]; var commit_tick := [0]
	var t0 := Engine.get_physics_frames()
	ball.turn_announced.connect(func(): announced[0] = true; announce_tick[0] = Engine.get_physics_frames() - t0)
	ball.turn_committed.connect(func(): committed[0] = true; commit_tick[0] = Engine.get_physics_frames() - t0)
	var frames := 0
	while is_instance_valid(ball) and not announced[0] and frames < 200:
		await physics_frame; frames += 1
	var at_signal: Vector3 = ball.global_position if is_instance_valid(ball) else Vector3.INF
	var predicted_end: Vector3 = preview[preview.size() - 1] if preview.size() > 0 else Vector3.INF
	check("stage 5: the warning's drawn path predicts where the field phase ends", announced[0] and at_signal.distance_to(predicted_end) < 0.2, "ball at %s, preview end %s, %.2f m apart after %.2f s" % [str(_v(at_signal)), str(_v(predicted_end)), at_signal.distance_to(predicted_end), game_seconds(announce_tick[0])])
	check("stage 5: the turned field bends the centre ball sideways before the signal", announced[0] and absf(at_signal.x) > 0.6, "x %.2f after the 1.4 s field phase" % at_signal.x)
	# (iv) the signal: the ball holds, a white line stands, the target is the camera at the signal
	var sampled: Vector3 = ball.sampled_target if is_instance_valid(ball) else Vector3.INF
	var cam_at_signal: Vector3 = walker.camera.global_position
	for i in range(int(ceil(0.4 * 60.0 / time_scale))): await physics_frame
	var held: bool = is_instance_valid(ball) and ball.global_position.is_equal_approx(at_signal) and is_instance_valid(ball.turn_line)
	check("stage 5: during the signal the ball holds still with a white line to the sampled target, the visitor's head", held and sampled.distance_to(cam_at_signal) < 0.05, "sampled %s camera %s" % [str(_v(sampled)), str(_v(cam_at_signal))])
	frames = 0
	while is_instance_valid(ball) and not committed[0] and frames < 200:
		await physics_frame; frames += 1
	var commit_dir: Vector3 = Vector3(ball.direction).normalized() if is_instance_valid(ball) else Vector3.ZERO
	check("stage 5: after 0.9 s the ball turns once toward the sampled target and the line goes", committed[0] and is_instance_valid(ball) and commit_dir.dot(at_signal.direction_to(sampled)) > 0.99 and not is_instance_valid(ball.turn_line), "signal lasted %.2f s" % game_seconds(commit_tick[0] - announce_tick[0]))
	# standing still: when does it land?
	var hit := [false]; var hit_tick := [0]
	ball.player_hit.connect(func(_b): hit[0] = true; hit_tick[0] = Engine.get_physics_frames() - t0)
	frames = 0
	while is_instance_valid(ball) and not ball.is_queued_for_deletion() and frames < MAX_FRAMES:
		await physics_frame; frames += 1
	check("stage 5: a visitor who stands still is hit by the committed ball", hit[0])
	if hit[0]: note("stage 5 centre ball: field phase %.2f s, signal %.2f s, impact %.2f s after the signal began (%.2f s after the throw)" % [game_seconds(announce_tick[0]), game_seconds(commit_tick[0] - announce_tick[0]), game_seconds(hit_tick[0] - announce_tick[0]), game_seconds(hit_tick[0])])
	centre.clear_shots(); await physics_frame
	# dodge AFTER the signal: the ball keeps the remembered spot
	await _place(arena.arrival)
	var after: String = await _change_dodge(arena, centre, "after_signal")
	check("stage 5: a 1.5 m sidestep after the signal is missed (the ball keeps the remembered spot)", after != "player", after)
	# dodge BEFORE the signal: the ball samples the new spot
	await _place(arena.arrival)
	var before: String = await _change_dodge(arena, centre, "before_signal")
	check("stage 5: a 1.5 m sidestep during the field phase is followed (the sample comes at the signal)", before == "player", before)
	# the outer columns keep the zigzag
	var outer: CharacterBody3D = arena.heads[0]
	outer.set_active(true); outer.begin_telegraph(arena.to_local(outer.target_position()))
	var zig: Node3D = outer.throw_ball()
	# B22 (16:56) appends a sixth stored position so a miss ends on a floor tile: five learned points plus the landing.
	check("stage 5: the outer columns keep the zigzag (five learned positions plus the floor landing)", zig != null and zig.waypoints.size() == 6 and zig.get("flight") == null, "%d points" % (zig.waypoints.size() if zig != null else 0))
	outer.clear_shots(); outer.set_active(false); centre.set_active(false)
	var d: float = walker.camera.global_position.distance_to(at_signal)
	note("stage 5 readability: at the signal the centre ball is %.1f m from the visitor, radius %.2f m (%.1f deg), white for 0.9 s with a one-pixel white line; the dodge window from the signal is the 0.9 s plus %.1f m of flight at 1.8 m/s" % [d, 0.09 * 1.31, rad_to_deg(2 * atan(0.09 * 1.31 / d)), d])

func _change_dodge(arena: Node3D, centre: CharacterBody3D, when: String) -> String:
	centre.set_physics_process(true); centre.set_active(true); centre.target_override = null
	centre.begin_telegraph(arena.to_local(centre.target_position()))
	var ball: Node3D = centre.throw_ball()
	var stepped := [false]
	var hit := [false]
	ball.player_hit.connect(func(_b): hit[0] = true)
	if when == "after_signal":
		ball.turn_announced.connect(func():
			walker.global_position = arena.arrival + Vector3(1.5, 0, 0); walker.velocity = Vector3.ZERO; stepped[0] = true)
	var frames := 0
	while is_instance_valid(ball) and not ball.is_queued_for_deletion() and frames < MAX_FRAMES:
		if when == "before_signal" and not stepped[0] and frames >= int(ceil(0.5 * 60.0 / time_scale)):
			walker.global_position = arena.arrival + Vector3(1.5, 0, 0); walker.velocity = Vector3.ZERO; stepped[0] = true
		var p: Vector3 = ball.global_position
		if absf(p.x) > 6.6 or p.z > 12.6 or p.y < -0.5: break
		await physics_frame; frames += 1
	var outcome := "player" if hit[0] else ("off_world" if is_instance_valid(ball) and not ball.is_queued_for_deletion() else "stopped")
	centre.clear_shots(); await physics_frame
	return outcome

## ---------------------------------------------------------------- CONSISTENCY
func consistency(stage: int, arena: Node3D) -> void:
	arena.reset_round(); await physics_frame
	for head in arena.heads: head.set_physics_process(true)
	arena.set_physics_process(true)
	await _place(Vector3(-4.35, 0.12, 7.9))   # behind the refuge: the loop runs, nobody is hit
	var start_button: Node3D = arena.start_button
	var caption_ready: String = str(start_button.label) if is_instance_valid(start_button) else "?"
	# 1. an edit while READY, then START
	await hand_throw(arena, TILE_INDEX)
	var e1: Dictionary = _edit_state(arena)
	arena.start_round(); await physics_frame
	var after_start: Dictionary = _edit_state(arena)
	check("stage %d: START keeps a floor edit made before it (forthcoming rule)" % stage, arena.running and _same_edit(e1, after_start), "before %s, after START %s" % [_edit_text(e1), _edit_text(after_start)])
	# 2. an edit while PLAY, then REST
	await hand_throw(arena, TILE_INDEX)
	var e2: Dictionary = _edit_state(arena)
	var ticks := int(ceil((4.0 if stage >= 2 else 4.0) * 60.0 / time_scale))
	var saw_attack := false
	for i in range(ticks):
		await physics_frame
		if arena.heads.any(func(h): return h.state == h.State.TELEGRAPH) or _live_balls(arena).size() > 0: saw_attack = true
	arena.rest(); await physics_frame
	var caption_rested: String = str(start_button.label) if is_instance_valid(start_button) else "?"
	check("stage %d: the START control reads START when ready and RESUME after REST" % stage, caption_ready == "START" and caption_rested == "RESUME", "%s / %s" % [caption_ready, caption_rested])
	var quiet: bool = not arena.running and arena.heads.all(func(h): return not h.active and h.state != h.State.TELEGRAPH and not is_instance_valid(h.path_preview)) and _live_balls(arena).is_empty()
	check("stage %d: REST stops the attack (no active head, no warning, no ball)" % stage, saw_attack and quiet, "attack seen %s, quiet %s" % [str(saw_attack), str(quiet)])
	check("stage %d: REST keeps the floor edit" % stage, _same_edit(e2, _edit_state(arena)), "before %s, after REST %s" % [_edit_text(e2), _edit_text(_edit_state(arena))])
	# 3. START again after REST (resume), then RESET
	arena.start_round(); await physics_frame
	check("stage %d: START after REST keeps the floor edit (forthcoming rule)" % stage, arena.running and _same_edit(e2, _edit_state(arena)), "after START %s" % _edit_text(_edit_state(arena)))
	await hand_throw(arena, TILE_INDEX)
	arena.reset_round(); await physics_frame
	var restored: Dictionary = _edit_state(arena)
	var heads_home: bool = arena.heads.all(func(h): return not h.destroyed and Vector3(h.position).is_equal_approx(h.home_position))
	var game: Node = root.get_node_or_null("GameManager")
	var health_full: bool = game == null or is_equal_approx(float(game.player_health), float(game.max_player_health))
	check("stage %d: RESET restores the encounter (floor, flashes, arrows, heads, pickups, health, READY)" % stage, not arena.running and int(restored.hits) == 0 and int(restored.marks) == 0 and int(restored.flashes) == 0 and is_equal_approx(float(restored.tile_scale), 1.0) and is_equal_approx(float(restored.tile_rot), 0.0) and (stage < 5 or Vector3(restored.arrow).is_equal_approx(Vector3.BACK)) and heads_home and arena.pickups.all(func(p): return p.visible) and health_full and arena.player_hits == 0, _edit_text(restored))
	await _place(arena.arrival)

func _edit_state(arena: Node3D) -> Dictionary:
	var tile: MeshInstance3D = arena.floor_tiles[TILE_INDEX]
	var arrow := Vector3.BACK
	if is_instance_valid(arena.get("direction_field")): arrow = arena.direction_field.sample(tile.global_position + Vector3(0, 0.5, 0))
	return {"hits": arena.floor_tile_hits.size(), "tile_hits": int(arena.floor_tile_hits.get(TILE_INDEX, 0)), "marks": arena.floor_marks.size(), "flashes": arena.floor_flashes.size(),
		"tile_scale": tile.scale.x, "tile_rot": rad_to_deg(tile.rotation.y), "arrow": arrow}

func _same_edit(a: Dictionary, b: Dictionary) -> bool:
	return int(a.hits) == int(b.hits) and int(a.tile_hits) == int(b.tile_hits) and int(a.marks) == int(b.marks) and is_equal_approx(float(a.tile_scale), float(b.tile_scale)) and is_equal_approx(float(a.tile_rot), float(b.tile_rot)) and Vector3(a.arrow).is_equal_approx(Vector3(b.arrow))

func _edit_text(e: Dictionary) -> String:
	return "tiles hit %d (this tile %d), marks %d, scale %.2f, rot %.1f" % [int(e.hits), int(e.tile_hits), int(e.marks), float(e.tile_scale), float(e.tile_rot)]

## ---------------------------------------------------------------- CLUTTER
func clutter(stage: int, arena: Node3D) -> void:
	arena.reset_round(); await physics_frame
	await _place(arena.arrival)
	for head in arena.heads: head.set_physics_process(true)
	arena.set_physics_process(true)
	var side := [1]
	var born: Dictionary = {}       # id -> tick
	var left: Dictionary = {}       # id -> tick the ball first left the playable area
	var passed: Dictionary = {}     # id -> tick the ball first flew past the visitor (z > 11)
	var exited: Dictionary = {}     # id -> tick it left the tree
	var t0 := Engine.get_physics_frames() + 1
	var callbacks: Array = []
	var step := func():
		walker.global_position = arena.arrival + Vector3(side[0] * 1.5, 0, 0); walker.velocity = Vector3.ZERO
		side[0] = -side[0]
	for head in arena.heads:
		var cb := func(shot):
			born[shot.get_instance_id()] = Engine.get_physics_frames() - t0
			shot.tree_exiting.connect(func(): exited[shot.get_instance_id()] = Engine.get_physics_frames() - t0)
			if shot.has_signal("turn_announced"): shot.turn_announced.connect(step)
			else: step.call()
		head.ball_sent.connect(cb); callbacks.append([head, cb])
	arena.start_round()
	var live_max := 0; var lines_max := 0
	var ticks := int(ceil(24.0 * 60.0 / time_scale))
	for i in range(ticks):
		await physics_frame
		var balls: Array = _live_balls(arena)
		live_max = maxi(live_max, balls.size())
		var lines := 0
		for b in balls:
			lines += b.find_children("StoredPositionPath", "MeshInstance3D", false, false).size()
			var p: Vector3 = b.global_position
			if (absf(p.x) > 6.5 or absf(p.z) > 12.5 or p.y < 0.0) and not left.has(b.get_instance_id()): left[b.get_instance_id()] = i
			if p.z > 11.0 and not passed.has(b.get_instance_id()): passed[b.get_instance_id()] = i
		for head in arena.heads:
			if is_instance_valid(head.path_preview): lines += 1
		lines_max = maxi(lines_max, lines)
	var hits: int = arena.player_hits
	arena.rest()
	for pair in callbacks: pair[0].ball_sent.disconnect(pair[1])
	var worst_outside := 0.0
	for id in left.keys():
		if exited.has(id): worst_outside = maxf(worst_outside, game_seconds(int(exited[id]) - int(left[id])))
	var still_outside: int = left.keys().filter(func(id): return not exited.has(id)).size()
	var worst_passed := 0.0
	for id in passed.keys():
		if exited.has(id): worst_passed = maxf(worst_passed, game_seconds(int(exited[id]) - int(passed[id])))
	var still_passed: int = passed.keys().filter(func(id): return not exited.has(id) and int(passed[id]) < ticks - int(ceil(2.0 * 60.0 / time_scale))).size()
	# Every miss must end: its whole life from the head, flight included, within 7.5 s (a zigzag
	# to the entrance flies 4.3 s and lands 0.7 s later; a Change ball follows 1.4 s, signals 0.9 s
	# and flies to the arena edge), and nothing sent more than 7.5 s before the end is still alive.
	var longest_life := 0.0
	for id in exited.keys():
		if born.has(id): longest_life = maxf(longest_life, game_seconds(int(exited[id]) - int(born[id])))
	var lingering: int = born.keys().filter(func(id): return not exited.has(id) and int(born[id]) < ticks - int(ceil(7.5 * 60.0 / time_scale))).size()
	note("stage %d, 24 s of the real loop with a visitor who sidesteps 1.5 m at every ball (at Change, at its signal): %d hits, %d balls sent, %d ended, the longest life %.1f s, %d sent more than 7.5 s before the end still alive; %d flew past the visitor's cell (gone within %.1f s), %d left the playable area (gone within %.1f s); at most %d balls and %d lines alive at once" % [stage, hits, born.size(), exited.size(), longest_life, lingering, passed.size(), worst_passed, left.size(), worst_outside, live_max, lines_max])
	check("stage %d: a sidestepping visitor is not hit" % stage, hits == 0, "%d hits" % hits)
	check("stage %d: every missed ball and its path end within 7.5 s of leaving the head" % stage, exited.size() > 0 and longest_life <= 7.5 and lingering == 0 and still_passed == 0 and still_outside == 0, "longest life %.1f s, lingering %d, past the visitor still alive %d, outside still alive %d" % [longest_life, lingering, still_passed, still_outside])
	# A group lands about 6.2 s after its warning began and the next group leaves at 6.0 s, so two
	# groups may overlap for a moment; three generations (nine balls) is the clutter this guards.
	check("stage %d: never more than two groups' balls and lines share the screen while the visitor dodges" % stage, live_max <= 6 and lines_max <= 6, "balls %d, lines %d" % [live_max, lines_max])
	arena.reset_round(); await physics_frame

## ---------------------------------------------------------------- CAPTURES (rendered)
func captures(stage: int, arena: Node3D) -> void:
	if not rendered:
		note("captures need the rendered backend"); return
	var s := "s%d" % stage
	for head in arena.heads: head.set_physics_process(false)
	arena.set_physics_process(false); arena.set_process(false)   # the clock (disco hues) holds
	await _place(arena.arrival)
	walker.camera.make_current()
	await capture(s + "-quiet")
	# the first warning
	for head in arena.heads: head.set_active(true)
	if stage >= 2:
		arena.volley_step = 0; arena._begin_array_volley()
	else:
		for head in arena.heads: head.begin_telegraph(arena.to_local(head.target_position()))
	await capture(s + "-warning")
	var thrown := 0
	for head in arena.heads:
		if head.state == head.State.TELEGRAPH:
			head.advance(head.WINDUP + 0.01, head.target_position()); thrown += head.projectiles.size()
	for f in range(120): await physics_frame
	await capture(s + "-flight-2s")
	note("%s: %d balls thrown for the flight frame" % [s, thrown])
	for head in arena.heads: head.clear_shots(); head.set_active(false)
	await physics_frame
	# a hand throw's floor impact beside the arrival
	if stage >= 1:
		await hand_throw(arena, TILE_INDEX)
		for f in range(18): await physics_frame
		await capture(s + "-floor-hit")
	if stage == 5:
		for t in CENTRE_PATH_TILES: await hand_throw(arena, t)
		var centre: CharacterBody3D = arena.heads[4]
		centre.set_active(true); centre.begin_telegraph(arena.to_local(centre.target_position()))
		await capture("s5-field-bent-preview")
		centre.set_physics_process(true)
		var ball: Node3D = centre.throw_ball()
		var announced := [false]; var committed := [false]
		ball.turn_announced.connect(func(): announced[0] = true)
		ball.turn_committed.connect(func(): committed[0] = true)
		var frames := 0
		while is_instance_valid(ball) and not announced[0] and frames < 200: await physics_frame; frames += 1
		for f in range(18): await physics_frame
		await capture("s5-turn-signal")
		if is_instance_valid(ball):
			var cam: Camera3D = walker.camera
			var on_screen: Vector2 = cam.unproject_position(ball.global_position)
			var halo: float = cam.unproject_position(ball.global_position + cam.global_basis.x * 0.14 * float(ball.radius_factor)).distance_to(on_screen)
			note("s5 signal: the ball is at world %s, %.1f m from the camera, screen (%.0f, %.0f), its halo %.0f px in radius; the sampled target %s is the camera %s; the white line runs from the ball to the camera, so it is seen end-on" % [str(_v(ball.global_position)), cam.global_position.distance_to(ball.global_position), on_screen.x, on_screen.y, halo, str(_v(ball.sampled_target)), str(_v(cam.global_position))])
			# The same instant from beside the lane, where the line is seen from the side.
			var standing: Vector3 = walker.global_position
			walker.global_position = Vector3(4.6, 0.12, 8.6); walker.velocity = Vector3.ZERO
			walker.look_at(Vector3(ball.global_position.x, 0.12, ball.global_position.z))
			await physics_frame
			await capture("s5-turn-signal-from-the-side")
			walker.global_position = standing; walker.rotation = Vector3.ZERO; walker.velocity = Vector3.ZERO
			await physics_frame
		frames = 0
		while is_instance_valid(ball) and not committed[0] and frames < 200: await physics_frame; frames += 1
		for f in range(30): await physics_frame
		await capture("s5-committed")
		centre.clear_shots(); centre.set_active(false); centre.set_physics_process(false)
	arena.set_process(true); arena.set_physics_process(true)
	arena.reset_round(); await physics_frame

## ---------------------------------------------------------------- helpers
func _place(at: Vector3) -> void:
	walker.global_position = at; walker.velocity = Vector3.ZERO
	await physics_frame; await physics_frame

func _forms(arena: Node3D) -> Array[AnimatableBody3D]:
	var out: Array[AnimatableBody3D] = []
	for child in arena.get_children():
		if child is AnimatableBody3D: out.append(child)
	return out

func _live_balls(arena: Node3D) -> Array:
	return arena.get_children().filter(func(c): return c.get_script() != null and str(c.get_script().resource_path).ends_with("_ball.gd") and not c.is_queued_for_deletion())

func _nearest_head(arena: Node3D, from: Vector3) -> CharacterBody3D:
	var best: CharacterBody3D = null; var best_d := INF
	for head in arena.heads:
		var d := Vector2(head.global_position.x, head.global_position.z).distance_to(Vector2(from.x, from.z))
		if d < best_d: best = head; best_d = d
	return best

func _buttons(arena: Node3D) -> Array:
	return arena.get_children().filter(func(c): return c is Node3D and c.get_script() != null and str(c.get_script().resource_path).ends_with("cube_button.gd"))

func _button(arena: Node3D, label: String) -> Node3D:
	for b in _buttons(arena):
		if b.label == label: return b
	return null

## A real hand throw straight down onto a tile; returns that tile's hit count afterwards.
func hand_throw(arena: Node3D, tile_index: int) -> int:
	if ability == null or arena.floor_tile_bodies.size() <= tile_index: return -1
	var over: Vector3 = arena.floor_tile_bodies[tile_index].global_position + Vector3(0, 1.3, 0)
	ability.update_hands(Transform3D(Basis.IDENTITY, over + Vector3(-0.1, 0, 0)), Transform3D(Basis.IDENTITY, over + Vector3(0.1, 0, 0)), true, true, 0.2)
	ability._cooldown = 0.0
	var shot: RigidBody3D = ability.send_form(Vector3.DOWN)
	if shot == null:
		note("hand throw refused (unlocked %s, formed %s)" % [str(ability.unlocked), str(ability.get("formed"))]); return -1
	var frames := 0
	while is_instance_valid(shot) and not shot.has_hit and frames < 120:
		await physics_frame; frames += 1
	await physics_frame
	ability._hide_all()
	return int(arena.floor_tile_hits.get(tile_index, 0))

## One real ball from `head` at the walker's camera, followed to its end.
func _shoot(stage: int, arena: Node3D, head: CharacterBody3D, place: String, forms: Array[AnimatableBody3D]) -> Dictionary:
	head.set_active(true); head.target_override = null
	var aim: Vector3 = head.target_position()
	head.begin_telegraph(arena.to_local(aim))
	var ball: Node3D = head.throw_ball()
	var record := {"stage": stage, "place": place, "head": head.slot, "walker": _v(walker.global_position), "aim": _v(aim)}
	if ball == null:
		record.outcome = "no_ball"; _rest(head); return record
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
	record.outcome = outcome; record.flight_s = snappedf(game_seconds(frames), 0.01)
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
	if c is AnimatableBody3D and forms.has(c): return "form:" + str(c.name)
	if c is StaticBody3D:
		var tile: int = arena.floor_tile_bodies.find(c)
		return "static:tile%d" % tile if tile >= 0 else "static:" + str(c.name)
	return c.get_class()

## The real loop from a safe place: which heads fire together, grouped by tick.
func _real_loop_groups(arena: Node3D, seconds: float) -> Array:
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
	for i in range(int(ceil(seconds * 60.0 / time_scale))): await physics_frame
	arena.rest()
	for pair in callbacks: pair[0].ball_sent.disconnect(pair[1])
	var groups: Array = []
	for e in sent:
		if groups.is_empty() or groups[-1].tick != e.tick: groups.append({"tick": e.tick, "slots": []})
		groups[-1].slots.append(e.slot)
	for g in groups: g.slots.sort()
	return groups

## The real loop with a visitor who sidesteps every ball; returns the hits counted.
func _dodging_loop(arena: Node3D, seconds: float) -> int:
	await _place(arena.arrival)
	for head in arena.heads: head.set_physics_process(true)
	arena.set_physics_process(true)
	var side := [1]
	var callbacks: Array = []
	for head in arena.heads:
		var cb := func(_shot):
			walker.global_position = arena.arrival + Vector3(side[0] * 1.5, 0, 0); walker.velocity = Vector3.ZERO
			side[0] = -side[0]
		head.ball_sent.connect(cb); callbacks.append([head, cb])
	arena.start_round()
	for i in range(int(ceil(seconds * 60.0 / time_scale))): await physics_frame
	var hits: int = arena.player_hits
	arena.rest()
	for pair in callbacks: pair[0].ball_sent.disconnect(pair[1])
	return hits

func _v(v: Vector3) -> Array: return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]

func capture(name: String) -> void:
	for f in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")
	print("[six] capture ", name)

func _source_version() -> Dictionary:
	var out := {}
	for p in ["res://commons/hazards/biome_ladder/ladder_encounter.gd", "res://commons/hazards/biome_ladder/ladder_skull.gd", "res://commons/hazards/biome_ladder/ladder_ball.gd", "res://commons/hazards/biome_ladder/change_ball.gd", "res://commons/hazards/biome_ladder/direction_field.gd", "res://commons/hazards/biome_ladder/array_path.gd", "res://commons/hazards/biome_ladder/ladder_world.gd", "res://commons/hazards/biome_ladder/route.gd"]:
		out[p.get_file()] = {"modified_unix": FileAccess.get_modified_time(p), "sha256": FileAccess.get_sha256(p)}
	return out

func finish() -> void:
	if done: return
	done = true
	Engine.time_scale = 1.0
	var passed := checks.filter(func(c): return c.passed).size()
	var report := {"written": Time.get_datetime_string_from_system(), "mode": mode, "rendered": rendered, "time_scale": time_scale, "stages": stages_to_run,
		"scope": "desktop walker and camera, real LadderBalls, ChangeBalls and a real hand projectile, signal-level calls; no headset, no hands",
		"source_at_boot": source_at_boot, "passed": passed, "total": checks.size(), "failures": failures, "notes": notes, "checks": checks, "stages_seen": stage_summaries}
	var f := FileAccess.open(OUT + ("report.json" if mode == "physics" else "report-%s.json" % mode), FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(report, "\t")); f.close()
	print("[six] %s %d/%d  report %s" % ["PASS" if failures.is_empty() else "FAIL", passed, checks.size(), OUT])
	for line in failures: print("[six] FAIL ", line)
	quit(0 if failures.is_empty() else 1)
