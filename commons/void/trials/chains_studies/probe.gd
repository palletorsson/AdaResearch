extends "res://tools/probes/void_transfer_probe.gd"
const Futures := preload("res://commons/artifacts/chains_studies/futures_graph.gd")

func debug_cases() -> Dictionary:
	return {"body-views": 2, "beauty-studies": 2}

func run_debug_case(_name: String, tag: String) -> void:
	take_photos = true
	var s: Node3D = station("study-2")
	if _name == "beauty-studies":
		var prior_path := OS.get_environment("ADA_CHAINS_STATE_PATH")
		OS.set_environment("ADA_CHAINS_STATE_PATH", out.path_join("beauty-history-" + str(xr) + ".json"))
		if FileAccess.file_exists(Futures.storage_path()): DirAccess.remove_absolute(Futures.storage_path())
		var originals: Array = Futures.initial().versions.duplicate(true)
		var library: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Futures.BEAUTY_STUDIES))
		for study in library.studies:
			Futures.transact({"action": "select", "version": "room-within"})
			var reply := Futures.transact({"action": "study", "study": study.id})
			check(tag + study.id + " accepted as a new branch", not reply.has("error"))
			if reply.has("error"): continue
			s._refresh_futures(reply.document); await frames(15)
			var record := Futures.version(reply.document, str(reply.document.cursor))
			check(tag + study.id + " preserves earlier recipes and named parts", reply.document.versions.slice(0, 6) == originals and record.parent == "room-within" and s.workers[0].body.has_node("torso"))
			check(tag + study.id + " stationary body below storey height", s.workers[0].inhabitable and s.workers[0].pose_root.transform.is_equal_approx(Transform3D.IDENTITY) and _size(s.workers[0]).y < 5.8)
			game.place_player(s.to_global(Vector3(-0.8, 0.06, 2.2))); await frames(18)
			var entered: bool = await move_to(s.to_global(Vector3(-0.8, 0.15, -0.15)), false, 180)
			check(tag + study.id + " real player enters the body", entered and game.body.is_on_floor())
			var exited: bool = await move_to(s.to_global(Vector3(-0.8, 0.06, 2.2)), false, 180)
			check(tag + study.id + " real player leaves through doorway", exited)
			if not xr:
				await photo(str(study.id), s.to_global(Vector3(0.3, 2.8, 6.6)), s.to_global(Vector3(-0.8, 2.4, 0)))
				await photo(str(study.id) + "-inside", s.to_global(Vector3(-0.8, 1.65, -0.6)), s.to_global(Vector3(-0.8, 1.5, 3.0)))
		var before: Dictionary = Futures.read_graph()
		var rejected := Futures.transact({"action": "study", "study": "missing"})
		check(tag + "unknown study preserves the archive", rejected.has("error") and JSON.stringify(Futures.read_graph()) == JSON.stringify(before))
		OS.set_environment("ADA_CHAINS_STATE_PATH", prior_path)
		return
	check(tag + "capture shows the selected inhabitable body", s.workers[0].inhabitable)
	await photo("body-front", s.to_global(Vector3(-0.8, 2.4, 5.8)), s.to_global(Vector3(-0.8, 2.4, 0)))
	await photo("body-inside", s.to_global(Vector3(-0.8, 1.65, -0.6)), s.to_global(Vector3(-0.8, 1.5, 3.0)))
## Mouse and synthetic-XR input reach the real request controls. Policies are
## scripted fictional demonstrations, not emergent social intelligence.

func receipt_scope() -> Dictionary:
	return {"scope": "Six scripted studies: mouse/synthetic-XR requests, modular recipe replay/branching, stable named connection endpoints, offer/accept/decline persistence, real player entry and exit through the body doorway, refusal and return, care, conserved allocation, conditional vote and canopy. Floor visits are programmatic; full descent and physical-headset play are not accepted."}

func capture_floor() -> void:
	var y: float = game.building.spec.levels[level]
	await photo("%02d-study" % level, Vector3(8, y + 3.7, 8.4), Vector3(0, y + 1.4, 0.8))
	if level in [1, 6]:
		await photo("%02d-eye-height" % level, Vector3(-2.2, y + 1.65, 6.0), Vector3(0, y + 1.3, 0))

func _input_position(node: Node3D) -> void:
	var dock: Node3D = node.get_node("RequestDock")
	game.place_player(dock.to_global(Vector3(0, 0.06, 2.15)))
	await frames(22)

func _size(node: Node3D) -> Vector3:
	var boxes: Array = []
	geometry(node, boxes)
	if boxes.is_empty(): return Vector3.ZERO
	var bounds: AABB = boxes[0]
	for box in boxes: bounds = bounds.merge(box)
	return bounds.size

func focused_checks(tag: String) -> void:
	var s: Node3D = station("study-" + str(level))
	await _input_position(s)
	check(tag + "study identity " + str(level), s.study == level - 1 and not s.workers.is_empty())
	check(tag + "editable named members " + str(level), s.part_defaults.has("RequestDock") and s.part_defaults.has("Worker_1"))
	if level == 1:
		var commissioned: String = s.workers[0].form_signature()
		var free: String = s.workers[1].form_signature()
		var size_before: Vector3 = _size(s.workers[1])
		check(tag + "same initial grammar and seed", s.workers[0].body_seed == s.workers[1].body_seed and s.workers[0].options == s.workers[1].options)
		await press(s.controls.form)
		check(tag + "request changes resident authority", s.state.authority == "resident")
		check(tag + "commission remains unchanged", s.workers[0].form_signature() == commissioned)
		check(tag + "resident chooses real new geometry", s.workers[1].form_signature() != free and not _size(s.workers[1]).is_equal_approx(size_before))
		var original_transform: Transform3D = s.get_node("Worker_1").transform
		var journal_before: Array = s.state.journal.duplicate(true)
		var copied: Node3D = load("res://commons/artifacts/chains_studies/study_1.tscn").instantiate()
		copied.apply_grid_config({"study": 0, "seed": 731, "only_parts": ["Worker_1"],
			"parts": {"Worker_1": {"position": [1.2, 0.1, 0], "rotation": [0, 45, 0]}}})
		game.add_child(copied)
		copied.global_position = Vector3(15, game.building.spec.levels[level], 0)
		copied.rotation_degrees.y = 90
		await frames(15)
		check(tag + "native edited copy isolates one real member", copied.get_child_count() == 1 and not _size(copied).is_zero_approx())
		check(tag + "copy preserves authored local position and rotation", copied.get_node("Worker_1").position.is_equal_approx(Vector3(1.2, 0.1, 0)) and is_equal_approx(copied.get_node("Worker_1").rotation_degrees.y, 45))
		copied.queue_free(); await frames(4)
		check(tag + "copied member cannot rewrite source policy or placement", s.get_node("Worker_1").transform.is_equal_approx(original_transform) and s.state.journal == journal_before and s._owner.get_meta("chains_studies")["0"].journal == journal_before)
	elif level == 2:
		var originals: Array = s.futures.versions.duplicate(true)
		check(tag + "five grammar versions plus walk-in body", originals.size() == 6)
		var identity: String = s.workers[0].identity
		var relationships: Dictionary = s.futures.residents.lumen.relationships.duplicate(true)
		Futures.transact({"action": "select", "version": "v-000"}); s._refresh_futures()
		await press(s.controls.branch)
		check(tag + "branch records parent recipe", s.futures.versions.size() == 7 and s.futures.versions[6].parent == "v-000")
		await press(s.controls.parent)
		check(tag + "replay retains seed and actual recipe", s.futures.cursor == "v-000" and s.workers[0].body_seed == originals[0].seed and s.workers[0].recipe == originals[0].recipe)
		await press(s.controls.branch)
		check(tag + "sibling keeps earlier future", s.futures.versions.size() == 8 and s.futures.versions[7].parent == "v-000" and s.futures.versions[6].parent == "v-000")
		check(tag + "all original recipes remain unchanged", s.futures.versions.slice(0, 6) == originals)
		Futures.transact({"action": "select", "version": "v-002"}); s._refresh_futures()
		var links: Array = s.workers[0].body.get_meta("connect")
		var children: Array = s.workers[0].body.get_children().filter(func(n): return not n.has_meta("tie"))
		var correct := true
		for i in links.size():
			var link: Dictionary = originals[2].recipe.links[i]
			correct = correct and children[int(links[i][0])].get_meta("part_id") == link.a and children[int(links[i][1])].get_meta("part_id") == link.b
		check(tag + "inserted limb leaves actual connections on named parts", correct and children[1].get_meta("part_id") == "extra_reach")
		var before: String = s.workers[0].form_signature()
		await press(s.controls.offer)
		check(tag + "an offer alone cannot change the recipient", s.futures.pending != null and s.workers[0].form_signature() == before)
		await press(s.controls.decline)
		check(tag + "decline stays in the archive without changing body", s.futures.events.back().outcome == "rejected" and s.workers[0].form_signature() == before)
		await press(s.controls.offer); await press(s.controls.accept)
		check(tag + "accepted gift is built as a connected named part", s.futures.events.back().approvals[0].decision == "accept" and s.workers[0].recipe.of.parts[1].id.begins_with("gift-") and s.workers[0].body.has_node(NodePath(s.workers[0].recipe.of.parts[1].id)))
		check(tag + "body version preserves resident identity and relations", s.workers[0].identity == identity and s.futures.residents.lumen.relationships == relationships)
		check(tag + "event retains the built version seed", s.futures.events.back().seed == s.workers[0].body_seed)
		var saved := Futures.read_graph()
		# JSON numbers reload as floats. Compare both through the same JSON reader;
		# int 731 and float 731.0 have different Variant/serialized representations.
		check(tag + "accepted and rejected decisions survive disk reload", JSON.parse_string(JSON.stringify(saved)) == JSON.parse_string(JSON.stringify(s.futures)))
		Futures.transact({"action": "select", "version": "room-within"}); s._refresh_futures(); await frames(12)
		check(tag + "walk-in body is stationary", s.workers[0].inhabitable and s.workers[0].pose_root.transform.is_equal_approx(Transform3D.IDENTITY))
		game.place_player(s.to_global(Vector3(-0.8, 0.06, 2.2))); await frames(20)
		var entered: bool = await move_to(s.to_global(Vector3(-0.8, 0.15, -0.15)), false, 180)
		check(tag + "real player crosses doorway and stands inside body", entered and game.body.is_on_floor() and absf(s.to_local(game.body.global_position).z) < 0.7)
		if not xr:
			await photo("02-inside-body", s.to_global(Vector3(-0.8, 1.65, -0.6)), s.to_global(Vector3(-0.8, 1.5, 3.0)))
		var exited: bool = await move_to(s.to_global(Vector3(-0.8, 0.06, 2.2)), false, 180)
		check(tag + "real player leaves the body through its doorway", exited)
	elif level == 3:
		await frames(390)
		check(tag + "worker stops the assigned loop", s.state.refused and not s.workers[0].performing)
		var before: String = s.workers[0].form_signature()
		await press(s.controls.order)
		check(tag + "service order cannot override refusal", s.state.refused)
		await press(s.controls.break)
		check(tag + "time off preserves form", s.state.break_agreed and s.workers[0].form_signature() == before)
		await press(s.controls.invite)
		check(tag + "agreed invitation permits chosen return", not s.state.refused and s.state.authority == "resident")
	elif level == 4:
		var before: String = s.workers[0].form_signature()
		await press(s.controls.factory)
		check(tag + "unwanted factory repair is declined", not s.state.care and s.workers[0].form_signature() == before)
		await press(s.controls.care)
		check(tag + "requested support arrives", s.state.care and is_zero_approx(s.get_node("AlternativeSupport/Delivery").position.x))
		check(tag + "support preserves chosen anatomy", s.workers[0].form_signature() == before)
	elif level == 5:
		await press(s.controls.assigned)
		check(tag + "assigned allocation leaves two needs unmet", s.state.allocations == [9, 0, 0])
		await press(s.controls.share)
		check(tag + "different needs met without merging", s.state.allocations == [4, 3, 2] and s.workers.size() == 3)
		check(tag + "allocation conserves nine units", s.state.pool + s.state.allocations.reduce(func(a, b): return a + b, 0) == 9)
		await press(s.controls.withdraw)
		check(tag + "withdrawal restores common pool", s.state.pool == 9 and s.state.allocations == [0, 0, 0])
		await press(s.controls.share)
	elif level == 6:
		await press(s.controls.occupy)
		check(tag + "unresourced occupation declined", not s.state.occupied)
		await press(s.controls.commons)
		await press(s.controls.vote)
		check(tag + "three local conditions accepted", s.state.votes == [true, true, true])
		await press(s.controls.occupy)
		var roof: Node3D = s.get_node("SharedHabitat/Canopy")
		check(tag + "residents open the actual habitat", s.state.occupied and s.state.authority == "collective" and is_zero_approx(roof.rotation.x) and roof.position.y > 3.0)
		check(tag + "canopy collider follows the visible panel", roof.get_child(0) is StaticBody3D)
	check(tag + "session journal records requests " + str(level), not s.state.journal.is_empty())

func visit(use_xr: bool) -> void:
	OS.set_environment("ADA_CHAINS_STATE_PATH", out.path_join("futures-test-" + str(use_xr) + ".json"))
	if FileAccess.file_exists(Futures.storage_path()): DirAccess.remove_absolute(Futures.storage_path())
	level = 1
	await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	check(tag + "arrival on standard slab", game.checkpoint == 1 and game.body.is_on_floor() and game.building.spec.width == 42)
	for index in range(1, 7):
		level = index
		game.place_player(game.spawn_for(level))
		await frames(35)
		inspect_floor(tag)
		await focused_checks(tag)
		if not xr: await capture_floor()
	game.place_player(game.spawn_for(1)); await frames(30)
	level = 1
	var returned: Node3D = station("study-1")
	check(tag + "resident choice survives floor residency", returned.state.authority == "resident" and returned.workers[1].options.inflation == "overblown")
	game.queue_free(); await frames(12)
	if xr:
		for item in [head, left, right]: XRServer.remove_tracker(item)
	OS.set_environment("ADA_CHAINS_STATE_PATH", "")
