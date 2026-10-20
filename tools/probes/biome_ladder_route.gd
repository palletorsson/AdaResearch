extends SceneTree
## Independent route test for the biome ladder. claude-edges-pilot, 2026-10-13.
##
## THE ROUTE AS A PLAYER TAKES IT: the staged game boots to its menu, the Biome Ladder
## button is entered through its real pointer path, and the five stages are walked in
## order by pressing the far-end NEXT STAGE button (its relay, the call the cube's own
## press makes), finishing with the far-end MUSEUM button, which must hand the player to
## the next sequence's first hall. At every stage the probe asks three things:
##
##   RETAINED  does the stage still carry everything the earlier stages gave the player?
##             heads, the six tall shelters, the held catalyst and the lent hand ability
##             (stage 0); moving forms, three pickups, a floor of tiles that answer a real
##             hand throw with x0.8 scale and +22.5 deg (stage 1); the indexed row (2);
##             coloured forms and a tinted hand throw (3); eighteen copies of one tile hit (4).
##   COVER     one real skull ball at the walker standing behind the first tall shelter is
##             stopped by it, and one at the walker in the open lane reaches the walker.
##   REACH     every cube button stands at hand height on the floor, overlaps no form, and
##             the desktop walker, driven by move_and_slide from the arrival, reaches it.
##
## Desktop evidence only: the desktop walker and its camera; no headset, no hands. The
## captures stage-<n>-arrival.png are what the walker's camera sees on entering the
## stage, before anything is pressed. Progression is isolated in the probe's own folder.
## Owns nothing under commons/hazards/biome_ladder/. Writes ada_run/biome_ladder_route/.
## Run (rendered, hidden window):
##   godot --path . --xr-mode off --no-window --rendering-method gl_compatibility --resolution 1440x1000 --script res://tools/probes/biome_ladder_route.gd

const OUT := "res://ada_run/biome_ladder_route/"
const DESTINATION := "res://commons/hazards/biome_ladder/ladder_world.tscn"
const MUSEUM_SCENE := "res://commons/scenes/endless_museum_staged.tscn"
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
const TILE_INDEX := 62          # x 2, z 10: the tile at world (-1, 0, 9), beside the arrival
const EXPOSED := Vector3(0, 0.12, 8.0)
const WALK_SPEED := 2.5
var max_stages := 99   # --max-stages=N walks the first N stages only and presses MUSEUM at stage N-1

var checks: Array[Dictionary] = []
var failures: Array[String] = []
var notes: Array[String] = []
var rendered := false
var staging: Node3D
var arena_reveals := 0
var done := false

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool, detail: String = "") -> void:
	checks.append({"name": label, "passed": passed, "detail": detail})
	if not passed: failures.append(label + (" (" + detail + ")" if detail != "" else ""))
	print("[route] ", "PASS " if passed else "FAIL ", label, ("  " + detail) if detail != "" else "")

func note(text: String) -> void:
	notes.append(text); print("[route] note ", text)

func run() -> void:
	rendered = DisplayServer.get_name() != "headless"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--max-stages="): max_stages = maxi(1, int(a.substr(13)))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	create_timer(1500).timeout.connect(func(): check("route completes in time", false); finish())
	var capacity: Node = root.get_node("CatalystCapabilityManager")
	capacity.progression_file = OUT + "test-save.json"
	capacity.reset_progression()
	staging = load("res://commons/scenes/vr_staging.tscn").instantiate()
	root.add_child(staging); current_scene = staging
	staging.scene_visible.connect(func(_scene, _data):
		if staging.current_scene_path == DESTINATION: arena_reveals += 1)
	await create_timer(0.7).timeout
	var menu_button: Node = staging.get_node_or_null("MainMenu3D/Buttons/BiomeLadderButton")
	check("menu has a Biome Ladder button", menu_button != null)
	if menu_button == null: finish(); return
	menu_button.pointer_entered()
	var began := Time.get_ticks_msec()
	while arena_reveals < 1 and Time.get_ticks_msec() - began < 60000: await process_frame
	check("menu button opens the ladder through staging", arena_reveals >= 1 and staging.current_scene_path == DESTINATION)
	if arena_reveals < 1: finish(); return
	await create_timer(1.0).timeout
	var scene: Node3D = staging.current_scene
	var game: Node = root.get_node("GameManager")
	game.register_player(scene.walker)
	var ability: Node3D = capacity.first_catalyst
	check("practice lends the hand ability without saving the unlock", ability.unlocked and not capacity.has_first_catalyst())
	check("the route begins at stage 0", scene.arena.stage == 0 and Route.selected_stage == 0)
	var stage_count: int = mini(Route.STAGES.size(), max_stages)
	note("route has %d stages; walking the first %d" % [Route.STAGES.size(), stage_count])
	for stage in range(stage_count):
		var arena: Node3D = scene.arena
		var walker: CharacterBody3D = scene.walker
		walker.set_physics_process(false)
		walker.camera.make_current()
		for head in arena.heads: head.set_physics_process(false)
		await physics_frame; await process_frame
		check("stage %d is the arena after entering it" % stage, arena.stage == stage and Route.selected_stage == stage)
		if rendered: await capture("stage-%d-arrival" % stage)
		await retained(stage, arena, walker, ability)
		await cover(stage, arena, walker)
		await reach(stage, arena, walker)
		if stage < stage_count - 1:
			var next := _button(arena, "NEXT STAGE")
			check("stage %d has a NEXT STAGE button" % stage, next != null)
			if next == null: break
			next._relay()   # the cube's own press path; a signal-level press, not a hand
			var waited := 0
			while is_instance_valid(scene.arena) and scene.arena == arena and waited < 120:
				await process_frame; waited += 1
			await physics_frame; await process_frame
			check("NEXT STAGE from %d builds stage %d" % [stage, stage + 1], is_instance_valid(scene.arena) and scene.arena.stage == stage + 1 and Route.selected_stage == stage + 1)
			if not is_instance_valid(scene.arena) or scene.arena.stage != stage + 1: break
	# The end of the ladder hands the player to the next sequence's first hall.
	var last: Node3D = scene.arena
	var museum_button := _button(last, "MUSEUM >", true)
	check("last stage has a far-end MUSEUM button", museum_button != null)
	if museum_button != null:
		museum_button._relay()
		began = Time.get_ticks_msec()
		while staging.current_scene_path != MUSEUM_SCENE and Time.get_ticks_msec() - began < 90000: await process_frame
		var target: Dictionary = Route.STAGES[stage_count - 1]
		check("MUSEUM loads the staged museum", staging.current_scene_path == MUSEUM_SCENE, staging.current_scene_path)
		if staging.current_scene_path == MUSEUM_SCENE:
			# The museum consumes the menu statics into _first_chapter / start_map at boot and
			# raises _museum_ready when its first hall is released (EM::_finish_initial_loading).
			# endless_museum_staged.tscn roots on the portal scene base; the museum is its "Museum" child.
			began = Time.get_ticks_msec()
			while Time.get_ticks_msec() - began < 90000 and not _museum_ready(_museum_node()): await process_frame
			var museum: Node = _museum_node()
			check("the museum raises its first hall after the ladder", _museum_ready(museum))
			var chapter := str(museum.get("_first_chapter")) if museum != null else ""
			var map := str(museum.get("start_map")) if museum != null else ""
			check("the museum opened at the next sequence's first hall", chapter == target.next and map == target.first, "%s / %s" % [chapter, map])
			if rendered: await capture("museum-after-ladder")
	finish()

func _museum_node() -> Node:
	var scene: Node = staging.current_scene
	if scene == null: return null
	var direct := scene.get_node_or_null("Museum")
	if direct != null: return direct
	for child in scene.find_children("*", "Node3D", true, false):
		if child.get_script() != null and str(child.get_script().resource_path).ends_with("endless_museum.gd"): return child
	return null

func _museum_ready(museum: Node) -> bool:
	if museum == null: return false
	return museum.get("_museum_ready") == true

## RETAINED: what the earlier stages gave the player is still here.
func retained(stage: int, arena: Node3D, walker: CharacterBody3D, ability: Node3D) -> void:
	var shelters: Array = arena.get_children().filter(func(c): return c is AnimatableBody3D and str(c.name).begins_with("PrimitiveCover"))
	var forms: Array = arena.get_children().filter(func(c): return c is AnimatableBody3D)
	# B19 (13 Oct, 14:40): from Arrays on the three heads become the standing 3 x 3 array.
	var expected_heads: int = 9 if stage >= 2 else 3
	check("stage %d keeps %s heads" % [stage, "the nine addressed" if stage >= 2 else "three"], arena.heads.size() == expected_heads, str(arena.heads.size()))
	check("stage %d keeps the six tall shelters" % stage, shelters.size() == 6, str(shelters.size()))
	check("stage %d keeps the held catalyst" % stage, is_instance_valid(arena.catalyst))
	check("stage %d keeps the lent hand ability" % stage, ability.unlocked)
	if stage >= 1:
		check("stage %d keeps the learned motions" % stage, arena.motions.size() > 0, str(arena.motions.size()))
		check("stage %d keeps three pickups" % stage, arena.pickups.size() == 3, str(arena.pickups.size()))
		check("stage %d keeps the tile floor" % stage, arena.floor_tile_bodies.size() == 72, str(arena.floor_tile_bodies.size()))
		# One real hand throw onto a tile beside the arrival: the tile answers, as it has since Transformation.
		if arena.floor_tile_bodies.size() > TILE_INDEX:
			var tile_body: StaticBody3D = arena.floor_tile_bodies[TILE_INDEX]
			var over := tile_body.global_position + Vector3(0, 1.3, 0)
			ability.update_hands(Transform3D(Basis.IDENTITY, over + Vector3(-0.1, 0, 0)), Transform3D(Basis.IDENTITY, over + Vector3(0.1, 0, 0)), true, true, 0.2)
			ability._cooldown = 0.0
			var shot: RigidBody3D = ability.send_form(Vector3.DOWN)
			check("stage %d: the hand forms a real projectile" % stage, shot != null)
			await create_timer(1.2).timeout
			var hits: int = int(arena.floor_tile_hits.get(TILE_INDEX, 0))
			var tile: MeshInstance3D = arena.floor_tiles[TILE_INDEX]
			check("stage %d: a tile answers the hand throw with x0.8 and +22.5 deg" % stage, hits >= 1 and is_equal_approx(tile.scale.x, pow(0.8, hits)) and is_equal_approx(rad_to_deg(tile.rotation.y), 22.5 * hits), "hits %d scale %.2f rot %.1f" % [hits, tile.scale.x, rad_to_deg(tile.rotation.y)])
			if stage >= 4:
				var copies: int = arena.floor_tile_hits.keys().filter(func(k): return int(arena.floor_tile_hits[k]) >= 1).size()
				check("stage %d: one hit repeats on eighteen tiles" % stage, copies == 18 and arena._pattern_indices(TILE_INDEX).size() == 18, "tiles with hits %d" % copies)
				# B20 (13 Oct, 15:27): the eighteen copies flash together for 1.15 s.
				var flashes: Variant = arena.get("floor_flashes")
				check("stage %d: the eighteen copies flash together at the hit" % stage, flashes is Dictionary and flashes.size() == 18, str(flashes.size()) if flashes is Dictionary else "no floor_flashes")
			ability._hide_all()
	if stage >= 2:
		# B19: the standing array, nine homes on the 3 x 3 grid at z 3.5 and nine [row, column] labels.
		var grid: bool = arena.heads.size() == 9
		for i in range(arena.heads.size()):
			@warning_ignore("integer_division")
			var row: int = i / 3
			if not Vector3(arena.heads[i].home_position).is_equal_approx(Vector3((i % 3 - 1) * 2.4, 3.9 - row * 1.3, 3.5)): grid = false
		var labels: int = arena.get_children().filter(func(c): return c is Label3D and str(c.text).begins_with("[") and str(c.text).contains(", ")).size()
		check("stage %d keeps the addressed 3 x 3 array" % stage, grid and labels == 9, "labels %d" % labels)
	if stage >= 3:
		var hues := {}
		for f in forms:
			var view := f.get_child(1) as MeshInstance3D
			if view != null and view.material_override is StandardMaterial3D:
				var c: Color = view.material_override.albedo_color
				if c.s > 0.3: hues[snappedf(c.h, 0.05)] = true
		check("stage %d keeps coloured forms" % stage, hues.size() >= 3, "%d hues" % hues.size())
		var head: CharacterBody3D = arena.heads[0]
		head.set_active(true); head.begin_telegraph(Vector3(0, 1.5, 8)); var ball: Node3D = head.throw_ball()
		check("stage %d keeps coloured skull balls" % stage, ball != null and ball.get("tint") != null and Color(ball.tint).s > 0.3 and is_instance_valid(ball.get("trail")))
		head.clear_shots(); head.set_active(false)
	if stage >= 4:
		# The hint's wording moved twice on 13 Oct ("Shoot a tile. Its turn and colour repeat..." at 12:05,
		# "Shoot one tile. Watch all its copies flash." at 15:31); the check asks for the sentence, not the words.
		var hints: Array = arena.get_children().filter(func(c): return c is Label3D and str(c.text).begins_with("Shoot "))
		check("stage %d states its rule in the world" % stage, hints.size() == 1, str(hints[0].text).replace("\n", " ") if hints.size() == 1 else "%d hint labels" % hints.size())
		check("stage %d offers a 5 TILE control" % stage, _button(arena, "5 TILE") != null)

## COVER: one real skull ball from behind the first tall shelter, one from the open lane.
func cover(stage: int, arena: Node3D, walker: CharacterBody3D) -> void:
	var shelter: Node3D = arena.get_node_or_null("PrimitiveCover_0_Left")
	if shelter == null:
		check("stage %d: first shelter present for the cover shot" % stage, false); return
	var head: CharacterBody3D = _nearest_head(arena, shelter.global_position)
	var f := Vector2(shelter.global_position.x, shelter.global_position.z)
	var h := Vector2(head.global_position.x, head.global_position.z)
	var dir := (f - h).normalized()
	var behind := f + dir * 1.35
	walker.global_position = Vector3(behind.x, 0.12, behind.y); walker.velocity = Vector3.ZERO
	await physics_frame; await physics_frame
	var covered := await shoot(arena, head, walker)
	check("stage %d: a ball at the walker behind the first shelter is stopped by it" % stage, covered.begins_with("form"), covered)
	walker.global_position = EXPOSED; walker.velocity = Vector3.ZERO
	await physics_frame; await physics_frame
	head = _nearest_head(arena, walker.global_position)
	var open := await shoot(arena, head, walker)
	check("stage %d: a ball at the walker in the open lane reaches the walker" % stage, open == "player", open)

func shoot(arena: Node3D, head: CharacterBody3D, walker: CharacterBody3D) -> String:
	head.set_active(true); head.target_override = null
	var aim: Vector3 = head.target_position()
	head.begin_telegraph(arena.to_local(aim))
	var ball: Node3D = head.throw_ball()
	if ball == null: return "no_ball"
	var dir: Vector3 = ball.direction.normalized()
	var hit := [false]
	ball.player_hit.connect(func(_b): hit[0] = true)
	var last: Vector3 = ball.global_position; var rf := 1.0; var frames := 0
	while is_instance_valid(ball) and not ball.is_queued_for_deletion() and not ball.spent and frames < 1500:
		last = ball.global_position; rf = float(ball.get("radius_factor"))
		await physics_frame; frames += 1
	var outcome := "expired"
	if hit[0]: outcome = "player"
	else:
		var from: Vector3 = ball.global_position if is_instance_valid(ball) else last
		var space := arena.get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(from - dir * 0.05, from + dir * (0.09 * rf + 0.15), 1 | 524288)
		var r := space.intersect_ray(q)
		if not r.is_empty():
			var c: Node = r.collider
			if c == walker: outcome = "player"
			elif c is AnimatableBody3D: outcome = "form:" + str(c.name)
			else: outcome = c.get_class() + ":" + str(c.name)
	head.clear_shots(); head.set_active(false); head.position = head.home_position; head.phase = 0.0
	await physics_frame
	return outcome

## REACH: every cube button at hand height on the floor, clear of forms, and walkable from the arrival.
func reach(stage: int, arena: Node3D, walker: CharacterBody3D) -> void:
	var buttons := _buttons(arena)
	check("stage %d has its console and far-end buttons" % stage, buttons.size() >= 12, str(buttons.size()))
	var space := arena.get_world_3d().direct_space_state
	var placed := 0; var clear := 0; var walked := 0; var unreachable: Array[String] = []
	for b in buttons:
		var p: Vector3 = b.global_position
		var on_floor := absf(p.x) <= 6.0 and absf(p.z) <= 12.0 and p.y >= 0.6 and p.y <= 1.9
		if on_floor: placed += 1
		var sq := PhysicsShapeQueryParameters3D.new()
		var s := SphereShape3D.new(); s.radius = 0.25; sq.shape = s
		sq.transform = Transform3D(Basis.IDENTITY, p); sq.collision_mask = 1; sq.collide_with_areas = false
		var blocked := space.intersect_shape(sq, 4).filter(func(hit): return hit.collider is AnimatableBody3D).size() > 0
		if not blocked: clear += 1
		var got := await walk_to(walker, arena, p)
		if got: walked += 1
		else: unreachable.append("%s at %s" % [b.label, _v(p)])
	check("stage %d: every button stands at hand height on the floor" % stage, placed == buttons.size(), "%d/%d" % [placed, buttons.size()])
	check("stage %d: no button is inside a form" % stage, clear == buttons.size(), "%d/%d" % [clear, buttons.size()])
	check("stage %d: the walker reaches every button from the arrival" % stage, walked == buttons.size(), "%d/%d%s" % [walked, buttons.size(), ("; unreachable: " + ", ".join(unreachable)) if unreachable.size() > 0 else ""])
	# From stage 1 the pickups; from stage 2 two of them stand behind the array's plane.
	if arena.pickups.size() > 0:
		var got_pickups := 0
		for p in arena.pickups:
			if await walk_to(walker, arena, Vector3(p.global_position.x, 0.12, p.global_position.z)): got_pickups += 1
		check("stage %d: the walker reaches every pickup from the arrival" % stage, got_pickups == arena.pickups.size(), "%d/%d" % [got_pickups, arena.pickups.size()])
	walker.global_position = arena.arrival; walker.velocity = Vector3.ZERO
	await physics_frame

## Drive the desktop body from the arrival to a point near the target, under real
## collision, straight line: the lane must be open for this to succeed.
func walk_to(walker: CharacterBody3D, arena: Node3D, target: Vector3) -> bool:
	walker.global_position = arena.arrival; walker.velocity = Vector3.ZERO
	await physics_frame
	var frames := 0
	while frames < 900:
		var to := Vector3(target.x - walker.global_position.x, 0, target.z - walker.global_position.z)
		if to.length() < 0.9: return true
		walker.velocity = Vector3(to.normalized().x * WALK_SPEED, -2.0, to.normalized().z * WALK_SPEED)
		walker.move_and_slide()
		await physics_frame; frames += 1
	return false

func _buttons(arena: Node3D) -> Array:
	return arena.get_children().filter(func(c): return c is Node3D and c.get_script() != null and str(c.get_script().resource_path).ends_with("cube_button.gd"))

func _button(arena: Node3D, label: String, far_end: bool = false) -> Node3D:
	var found: Node3D = null
	for b in _buttons(arena):
		if b.label != label: continue
		if far_end and b.global_position.z > 0.0: continue
		found = b
	return found

func _nearest_head(arena: Node3D, from: Vector3) -> CharacterBody3D:
	var best: CharacterBody3D = null; var best_d := INF
	for head in arena.heads:
		var d := Vector2(head.global_position.x, head.global_position.z).distance_to(Vector2(from.x, from.z))
		if d < best_d: best = head; best_d = d
	return best

func _v(v: Vector3) -> Array: return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]

func capture(name: String) -> void:
	for f in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func finish() -> void:
	if done: return
	done = true
	var source := {}
	for p in ["res://commons/hazards/biome_ladder/ladder_encounter.gd", "res://commons/hazards/biome_ladder/ladder_world.gd", "res://commons/hazards/biome_ladder/route.gd", "res://commons/hazards/biome_ladder/ladder_skull.gd"]:
		source[p.get_file()] = {"modified_unix": FileAccess.get_modified_time(p), "sha256": FileAccess.get_sha256(p)}
	var passed := checks.filter(func(c): return c.passed).size()
	var report := {"written": Time.get_datetime_string_from_system(), "rendered": rendered, "scope": "desktop walker and camera, staged menu entry, signal-level button presses; no headset, no hands",
		"source": source, "passed": passed, "total": checks.size(), "failures": failures, "notes": notes, "checks": checks}
	var f := FileAccess.open(OUT + "report.json", FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(report, "\t")); f.close()
	print("[route] %s %d/%d  report %sreport.json" % ["PASS" if failures.is_empty() else "FAIL", passed, checks.size(), OUT])
	for line in failures: print("[route] FAIL ", line)
	quit(0 if failures.is_empty() else 1)
