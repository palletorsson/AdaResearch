extends SceneTree
## Independent cover test for the biome ladder. claude-edges-pilot, 2026-10-13 (B06).
##
## QUESTION. Does a form stop a skull's projectile when the walker stands behind it, and
## does a walker in the open lane get hit? Not a geometric estimate: each shot is the
## head's own LadderBall, launched by ladder_skull.throw_ball() after begin_telegraph(),
## aimed where the game aims (flying_skull.target_position(): the viewport camera, which
## in the desktop world is the walker's head), and followed under physics until it
## collides or expires. What it met is read back from the physics space at the contact.
##
## MOTION PHASES. From stage 1 the forms translate, turn and scale on the arena's clock
## (sin(clock * 0.6 + row phase), period TAU / 0.6 s) and the heads sway on their own
## phase. With --phases=N each stage is shot N times across one forms' cycle: before a
## shot the arena clock is set to the phase and the head is advanced to the same moment by
## its own advance() rule, and then everything keeps moving while the ball flies. A walker
## position "behind a form" is computed from where the form stands at that phase.
##
## Two stances behind every form, because the game aims at the camera: STANDING (the
## walker's real camera height) and CROUCHED (a target 1.0 m over the feet, the headset
## visitor who ducks). A prediction is kept beside every result: a straight ray from the
## launch point to the aim point, sampled against the forms' boxes with the ball's radius,
## so plan and physics can disagree in writing.
##
## Owns nothing under commons/hazards/biome_ladder/. Writes ada_run/biome_ladder_cover/.
## Run:  godot --path . --xr-mode off --headless --script res://tools/probes/biome_ladder_cover.gd \
##         -- --stages=1,2,3 --phases=6 --crouch=all --time-scale=3 --report=report_phases.json
## Defaults: all four stages, one phase, both stances, time scale 2, report.json.
## Exit 0 only when every exposed shot hit the walker AND, in every stage, at least one
## standing covered shot was stopped by a form. A failing exit is the finding.

const WORLD := "res://commons/hazards/biome_ladder/ladder_world.tscn"
const OUT := "res://ada_run/biome_ladder_cover"
const EXPOSED := [Vector3(0, 0.12, 10.5), Vector3(0, 0.12, 8.0), Vector3(-2, 0.12, 7.0), Vector3(2, 0.12, 5.0), Vector3(0, 0.12, 0.0)]
const CROUCH_HEIGHT := 1.0
const BEHIND := 1.35          # metres behind a form's centre, away from the head
const MAX_FRAMES := 1500      # 14 s lifetime at 60 Hz, with margin
const FORM_PERIOD := TAU / 0.6   # ladder_encounter._physics_process: sin(clock * 0.6 + phase)

var stages_to_run: Array[int] = [0, 1, 2, 3]
var phase_count := 1
var crouch_mode := "all"      # all | none | stage1
var time_scale := 2.0         # straight swept motion; divides the wall-clock
var report_name := "report.json"

var shots: Array[Dictionary] = []
var failures: Array[String] = []
var stage_forms := {}   # stage -> the forms as built at phase 0, so the report describes the geometry it measured

func _initialize() -> void: run.call_deferred()

func _args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--stages="):
			stages_to_run.clear()
			for s in a.substr(9).split(","): stages_to_run.append(int(s))
		elif a.begins_with("--phases="): phase_count = maxi(1, int(a.substr(9)))
		elif a.begins_with("--crouch="): crouch_mode = a.substr(9)
		elif a.begins_with("--time-scale="): time_scale = maxf(0.25, float(a.substr(13)))
		elif a.begins_with("--report="): report_name = a.substr(9)

func run() -> void:
	_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var capacity := root.get_node_or_null("CatalystCapabilityManager")
	if capacity != null: capacity.progression_file = OUT + "/isolated-capacity.json"
	var world: Node3D = load(WORLD).instantiate(); root.add_child(world); current_scene = world
	for i in range(300):
		if world.is_map_ready(): break
		await process_frame
	if not world.is_map_ready():
		print("[cover] FAIL world not ready"); quit(1); return
	var walker: CharacterBody3D = world.walker
	walker.set_physics_process(false)   # the walker stands where it is put; nothing else about it changes
	# The staged game makes the walker's camera current in scene_loaded(); a direct load does
	# not, and flying_skull.target_position() aims at the viewport camera. Without this the
	# heads aim at the parked XR rig 98 m below the floor.
	walker.camera.make_current()
	await process_frame
	var current := root.get_camera_3d()
	print("[cover] stages %s phases %d crouch %s time_scale %.1f" % [str(stages_to_run), phase_count, crouch_mode, time_scale])
	print("[cover] walker layer=%d mask=%d groups=%s camera_y=%.2f current_camera=%s" % [walker.collision_layer, walker.collision_mask, str(walker.get_groups()), walker.camera.global_position.y - walker.global_position.y, str(current.get_path()) if current != null else "none"])
	Engine.time_scale = time_scale
	var crouch := Node3D.new(); crouch.name = "CrouchTarget"; root.add_child(crouch)
	for stage in stages_to_run:
		world.change_stage(stage)
		await physics_frame; await process_frame
		var arena: Node3D = world.arena
		for head in arena.heads: head.set_physics_process(false)
		var forms := _forms(arena)
		stage_forms[str(stage)] = forms.map(func(f): return _describe(f, forms.find(f)))
		var phases := phase_count if stage >= 1 else 1
		var crouched_here := crouch_mode == "all" or (crouch_mode == "stage1" and stage == 1)
		print("[cover] stage %d: %d forms, %d heads, %d phase(s)" % [stage, forms.size(), arena.heads.size(), phases])
		for k in range(phases):
			var seconds := FORM_PERIOD * float(k) / float(phases)
			# The lane. Aimed where the game aims. A lane position is EXPOSED only if the
			# straight line from its nearest head (swayed to this phase) to the camera meets no
			# form; otherwise it is SCREENED, and a form is the expected outcome.
			for at in EXPOSED:
				await _place(walker, at)
				var head: CharacterBody3D = _nearest_head(arena, walker.global_position)
				await _prepare(stage, arena, head, seconds, walker.camera.global_position)
				var clear := _predict(stage, head.global_position, walker.camera.global_position, forms, -1) == "player"
				shots.append(await _shoot(stage, k, seconds, arena, head, walker, forms, "exposed" if clear else "screened", "standing", null, -1))
			# Covered: behind every form as it stands at this phase, relative to its nearest head.
			for f in range(forms.size()):
				var form: AnimatableBody3D = forms[f]
				var head: CharacterBody3D = _nearest_head(arena, form.global_position)
				await _prepare(stage, arena, head, seconds, form.global_position)
				var at := _behind(form, head)
				if at == Vector3.INF: continue
				await _place(walker, at)
				shots.append(await _shoot(stage, k, seconds, arena, head, walker, forms, "covered", "standing", null, f))
				if crouched_here:
					await _prepare(stage, arena, head, seconds, form.global_position)
					crouch.global_position = walker.global_position + Vector3.UP * CROUCH_HEIGHT
					shots.append(await _shoot(stage, k, seconds, arena, head, walker, forms, "covered", "crouched", crouch, f))
	Engine.time_scale = 1.0
	_verdict()
	world.queue_free(); await process_frame
	quit(0 if failures.is_empty() else 1)

## Put the arena and the head at a moment of the motion cycle. The forms follow the
## arena clock in their own _physics_process; the head is moved by its own advance()
## rule, with its telegraph timer pushed far back so advancing cannot make it fire.
func _prepare(stage: int, arena: Node3D, head: CharacterBody3D, seconds: float, aim: Vector3) -> void:
	arena.clock = seconds
	await physics_frame; await physics_frame
	head.position = head.home_position; head.phase = 0.0
	if stage >= 1 and seconds > 0.0:
		head.set_active(true)
		head.elapsed = -1000.0
		head.advance(seconds, aim)
	await physics_frame

func _forms(arena: Node3D) -> Array[AnimatableBody3D]:
	var out: Array[AnimatableBody3D] = []
	for child in arena.get_children():
		if child is AnimatableBody3D: out.append(child)
	return out

func _nearest_head(arena: Node3D, from: Vector3) -> CharacterBody3D:
	var best: CharacterBody3D = null; var best_d := INF
	for head in arena.heads:
		var d := Vector2(head.global_position.x, head.global_position.z).distance_to(Vector2(from.x, from.z))
		if d < best_d: best = head; best_d = d
	return best

## A standing place behind the form, on the line from the head through the form's centre.
func _behind(form: AnimatableBody3D, head: CharacterBody3D) -> Vector3:
	var f := Vector2(form.global_position.x, form.global_position.z)
	var h := Vector2(head.global_position.x, head.global_position.z)
	if f.distance_to(h) < 0.01: return Vector3.INF
	var dir := (f - h).normalized()
	var p := f + dir * BEHIND
	p.x = clampf(p.x, -5.5, 5.5); p.y = clampf(p.y, -11.5, 11.5)
	if p.distance_to(f) < 0.95: return Vector3.INF   # clamped into the form; cannot stand there
	if p.distance_to(h) < 1.2: return Vector3.INF
	return Vector3(p.x, 0.12, p.y)

func _place(walker: CharacterBody3D, at: Vector3) -> void:
	walker.global_position = at; walker.velocity = Vector3.ZERO
	await physics_frame; await physics_frame

func _shoot(stage: int, phase_index: int, seconds: float, arena: Node3D, head: CharacterBody3D, walker: CharacterBody3D, forms: Array[AnimatableBody3D], place: String, stance: String, target_node: Node3D, form_index: int) -> Dictionary:
	head.set_active(true)
	head.target_override = target_node
	var aim: Vector3 = head.target_position()
	head.begin_telegraph(arena.to_local(aim))
	var ball: Node3D = head.throw_ball()
	var record := {"stage": stage, "phase": phase_index, "phase_s": snappedf(seconds, 0.01), "clock_at_launch": snappedf(arena.clock, 0.01),
		"place": place, "stance": stance, "form": form_index, "head": head.slot,
		"walker": _v(walker.global_position), "aim": _v(aim), "head_at": _v(head.global_position)}
	if ball == null:
		record.outcome = "no_ball"; _rest(head); return record
	var start: Vector3 = ball.global_position
	var dir: Vector3 = ball.direction.normalized()
	var hit_player := [false]
	ball.player_hit.connect(func(_body): hit_player[0] = true)
	record.predicted = _predict(stage, start, arena.to_global(head.destination), forms, form_index)
	var frames := 0
	var last := start
	var rf := 1.0
	# The ball frees itself in the physics step in which it collides, so by the time this
	# coroutine resumes it is usually gone. Keep its last live position and radius; the
	# collider is then found by a short ray along the flight from that position.
	while is_instance_valid(ball) and not ball.is_queued_for_deletion() and not ball.spent and frames < MAX_FRAMES:
		last = ball.global_position
		rf = float(ball.get("radius_factor"))
		await physics_frame
		frames += 1
	var outcome := "expired"
	if hit_player[0]: outcome = "player"
	else:
		var from := ball.global_position if is_instance_valid(ball) else last
		outcome = _next_collider(arena, from, dir, 0.09 * rf + 1.8 * time_scale / 60.0 + 0.05, walker, forms)
		if outcome == "nothing": outcome = "timeout" if frames >= MAX_FRAMES else "expired"
	var end: Vector3 = ball.global_position if is_instance_valid(ball) else last
	record.outcome = outcome; record.frames = frames; record.stopped_at = _v(end); record.travelled = snappedf(start.distance_to(end), 0.01)
	_rest(head)
	await physics_frame
	print("[cover] stage %d ph %d %-8s %-9s head %d form %2d -> %-18s predicted %-10s walker %s aim %s" % [stage, phase_index, place, stance, head.slot, form_index, outcome, record.predicted, record.walker, record.aim])
	return record

func _rest(head: CharacterBody3D) -> void:
	head.clear_shots(); head.set_active(false); head.target_override = null
	head.position = head.home_position; head.phase = 0.0

## The first body a ball at `from`, flying along `dir`, meets within `reach` metres,
## through the ball's own collision mask.
func _next_collider(arena: Node3D, from: Vector3, dir: Vector3, reach: float, walker: CharacterBody3D, forms: Array[AnimatableBody3D]) -> String:
	var space := arena.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from - dir * 0.05, from + dir * reach, 1 | 524288)
	q.collide_with_bodies = true; q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	var c: Node = null
	if not hit.is_empty(): c = hit.collider
	else:
		# A tangential contact (the top of a sphere, the rim of a cylinder) can lie beside
		# the ray; ask what overlaps a ball one step further along the flight.
		var sq := PhysicsShapeQueryParameters3D.new()
		var s := SphereShape3D.new(); s.radius = reach * 0.6; sq.shape = s
		sq.transform = Transform3D(Basis.IDENTITY, from + dir * (reach * 0.4)); sq.collision_mask = 1 | 524288
		sq.collide_with_bodies = true; sq.collide_with_areas = false
		var overlaps := space.intersect_shape(sq, 4)
		if overlaps.is_empty(): return "nothing"
		c = overlaps[0].collider
	if c == walker or c.is_in_group("player_body") or c.is_in_group("player"): return "player"
	if c is AnimatableBody3D and forms.has(c):
		var view := c.get_child(1) as MeshInstance3D
		return "form:" + (view.mesh.get_class() if view != null and view.mesh != null else "?") + "#" + str(forms.find(c))
	if c is StaticBody3D: return "static:" + c.name
	return c.get_class()

## Straight ray from the launch point to the aim point, sampled against the forms' boxes
## as they stand at launch.
func _predict(stage: int, start: Vector3, aim: Vector3, forms: Array[AnimatableBody3D], form_index: int) -> String:
	var dir := (aim - start)
	var length := dir.length()
	if length < 0.01: return "degenerate"
	dir /= length
	var step := 0.05; var d := 0.0
	while d <= length:
		var p := start + dir * d
		var t := d / 1.8
		var r := 0.09 * (minf(2.2, 1.0 + t * 0.22) if stage >= 1 else 1.0)
		for i in range(forms.size()):
			var view := forms[i].get_child(1) as MeshInstance3D
			if view == null or view.mesh == null: continue
			var box: AABB = (view.global_transform * view.mesh.get_aabb()).grow(r)
			if box.has_point(p): return "form#%d" % i
		d += step
	return "player"

func _v(v: Vector3) -> Array: return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]

func _describe(form: AnimatableBody3D, index: int) -> Dictionary:
	var view := form.get_child(1) as MeshInstance3D
	var box: AABB = (view.global_transform * view.mesh.get_aabb()) if view != null and view.mesh != null else AABB()
	return {"index": index, "name": form.name, "mesh": view.mesh.get_class() if view != null and view.mesh != null else "?",
		"at": _v(form.global_position), "size": _v(box.size), "top": snappedf(box.end.y, 0.01)}

func _source_version() -> Dictionary:
	var out := {}
	for p in ["res://commons/hazards/biome_ladder/ladder_encounter.gd", "res://commons/hazards/biome_ladder/ladder_skull.gd", "res://commons/hazards/biome_ladder/ladder_ball.gd", "res://commons/hazards/catalyst_counterpart/flying_skull.gd"]:
		out[p.get_file()] = {"modified_unix": FileAccess.get_modified_time(p), "sha256": FileAccess.get_sha256(p)}
	return out

func _is_form(s: Dictionary) -> bool: return str(s.outcome).begins_with("form")

func _verdict() -> void:
	var summary := {}
	for stage in stages_to_run:
		var phases := phase_count if stage >= 1 else 1
		var stage_standing_stopped := 0; var stage_standing := 0
		var stage_exposed_hit := 0; var stage_exposed := 0
		var per_phase := []
		for k in range(phases):
			var mine := shots.filter(func(s): return s.stage == stage and s.phase == k)
			var exposed := mine.filter(func(s): return s.place == "exposed")
			var screened := mine.filter(func(s): return s.place == "screened")
			var standing := mine.filter(func(s): return s.place == "covered" and s.stance == "standing")
			var crouched := mine.filter(func(s): return s.place == "covered" and s.stance == "crouched")
			var exposed_hit := exposed.filter(func(s): return s.outcome == "player").size()
			var screened_stopped := screened.filter(_is_form).size()
			var standing_stopped := standing.filter(_is_form).size()
			var crouched_stopped := crouched.filter(_is_form).size()
			var predicted := mine.filter(func(s): return s.has("predicted"))
			var agree := predicted.filter(func(s): return str(s.predicted).begins_with("form") == _is_form(s)).size()
			var row := {"phase": k, "phase_s": snappedf(FORM_PERIOD * float(k) / float(phases), 0.01), "exposed_hit": exposed_hit, "exposed": exposed.size(),
				"screened_stopped": screened_stopped, "screened": screened.size(), "standing_stopped": standing_stopped, "standing": standing.size(),
				"crouched_stopped": crouched_stopped, "crouched": crouched.size(), "prediction_agrees": agree, "predicted": predicted.size()}
			per_phase.append(row)
			stage_standing_stopped += standing_stopped; stage_standing += standing.size()
			stage_exposed_hit += exposed_hit; stage_exposed += exposed.size()
			print("[cover] STAGE %d PHASE %d (%.1f s)  exposed hit %d/%d  screened stopped %d/%d  cover stops standing %d/%d  crouched %d/%d  prediction agrees %d/%d" % [stage, k, row.phase_s, exposed_hit, exposed.size(), screened_stopped, screened.size(), standing_stopped, standing.size(), crouched_stopped, crouched.size(), agree, predicted.size()])
		summary[str(stage)] = {"phases": per_phase, "standing_stopped": stage_standing_stopped, "standing": stage_standing, "exposed_hit": stage_exposed_hit, "exposed": stage_exposed}
		if stage_exposed_hit < stage_exposed: failures.append("stage %d: %d of %d exposed shots did not hit the walker" % [stage, stage_exposed - stage_exposed_hit, stage_exposed])
		if stage_standing > 0 and stage_standing_stopped == 0: failures.append("stage %d: no form stopped a shot at a standing walker in any phase" % stage)
	var report := {"written": Time.get_datetime_string_from_system(), "time_scale": time_scale, "behind_m": BEHIND, "crouch_height_m": CROUCH_HEIGHT,
		"phases": phase_count, "form_period_s": snappedf(FORM_PERIOD, 0.001), "stages": stages_to_run, "crouch": crouch_mode,
		"aim_rule": "flying_skull.target_position(): target_override else the viewport camera (the walker's head)",
		"source": _source_version(), "forms_at_phase_0": stage_forms,
		"summary": summary, "failures": failures, "shots": shots}
	var f := FileAccess.open(OUT + "/" + report_name, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(report, "\t")); f.close()
	for line in failures: print("[cover] FAIL ", line)
	print("[cover] %s  (%d shots, report %s/%s)" % ["PASS" if failures.is_empty() else "FAIL", shots.size(), OUT, report_name])
