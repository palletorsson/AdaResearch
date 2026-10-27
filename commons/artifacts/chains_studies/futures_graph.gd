extends RefCounted
## Stable body recipes are a separate history, not additions to the tutorial track.
const SOURCE := "res://commons/artifacts/chains_studies/futures.json"
const STORAGE := "res://commons/artifacts/chains_studies/futures_storage.json"
const BEAUTY_STUDIES := "res://commons/artifacts/chains_studies/beauty_studies.json"
const Builder := preload("res://commons/modular/builder.gd")
const Composite := preload("res://commons/modular/composite.gd")

static func initial() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SOURCE))

static func storage_path() -> String:
	var override := OS.get_environment("ADA_CHAINS_STATE_PATH")
	if not override.is_empty(): return override
	if OS.get_name() == "Windows":
		var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STORAGE))
		return str(config.windows)
	return ProjectSettings.globalize_path("user://chains-futures.json")

static func read_graph() -> Dictionary:
	var file := storage_path()
	if not FileAccess.file_exists(file): return initial()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
	if not parsed is Dictionary or parsed.get("schema", 0) != 1:
		return {"error": "Body history is unreadable. The saved file has been preserved."}
	return parsed

static func version(doc: Dictionary, id: String) -> Dictionary:
	for item in doc.get("versions", []):
		if str(item.id) == id: return item
	return {}

static func compile_recipe(recipe: Dictionary) -> Dictionary:
	# Both builders still consume numeric ties. Resolve them fresh from stable IDs.
	if recipe.get("op") != "connect" or recipe.get("of", {}).get("op") != "assemblage":
		return {"error": "A body must connect one named assemblage."}
	var out := recipe.duplicate(true)
	var ids: Array[String] = []
	for part in out.of.get("parts", []):
		var id := str(part.get("id", ""))
		if id.is_empty() or id in ids: return {"error": "Missing or repeated part ID: " + id}
		ids.append(id)
	if ids.is_empty() or ids.size() > 48: return {"error": "A body needs 1 to 48 parts."}
	var ties: Array = []
	for link in out.get("links", []):
		if str(link.a) not in ids or str(link.b) not in ids or link.a == link.b:
			return {"error": "Connection names an absent or identical endpoint."}
		if str(link.kind) not in ["rope", "rod", "spring"]: return {"error": "Unknown connection."}
		ties.append([ids.find(str(link.a)), ids.find(str(link.b)), str(link.kind)])
	out.erase("links")
	out.ties = ties
	return {"expression": out, "ids": ids}

static func build_body(recipe: Dictionary) -> Node3D:
	var compiled := compile_recipe(recipe)
	if compiled.has("error"): return null
	return Builder.build(compiled.expression, Composite.terms())

static func apply_command(doc: Dictionary, command: Dictionary) -> Dictionary:
	var action := str(command.get("action", ""))
	var current := version(doc, str(doc.cursor))
	if current.is_empty(): return {"error": "Unknown current version."}
	if action == "select":
		var selected := str(command.get("version", ""))
		if version(doc, selected).is_empty(): return {"error": "Unknown version."}
		doc.cursor = selected
		return {"message": "Replaying " + selected + ". No earlier version is changed."}
	if action == "parent":
		if current.parent != null: doc.cursor = current.parent
		return {"message": "Replaying the parent recipe."}
	if action == "tip":
		doc.cursor = doc.versions.back().id
		return {"message": "Replaying the latest accepted version."}
	if doc.versions.size() >= 256 or doc.events.size() >= 1024:
		return {"error": "Archive full. Existing versions remain available."}
	if action == "offer":
		if doc.pending != null: return {"error": "An offer is already waiting for Lumen."}
		var offer := {"id": "offer-" + str(doc.events.size()), "parent": current.id, "proposer": "splice", "recipient": "lumen", "operation": "gift"}
		doc.pending = offer
		_event(doc, offer, "proposed", null, [])
		return {"message": "Splice offers a loop. Lumen can accept or decline; nothing changes yet."}
	if action in ["accept", "decline"]:
		if doc.pending == null: return {"error": "There is no pending offer."}
		var offer: Dictionary = doc.pending.duplicate(true)
		doc.pending = null
		if action == "decline":
			_event(doc, offer, "rejected", null, [{"resident": "lumen", "decision": "decline"}])
			return {"message": "Lumen declines. The offer stays in history; the body stays unchanged."}
		current = version(doc, str(offer.parent))
		return _derive(doc, current, "gift", offer, command)
	if action == "branch":
		var operation: String = ["surface", "reach", "support"][mini(int(current.stage), 2)]
		if int(current.stage) >= 3: return apply_command(doc, {"action": "offer"})
		return _derive(doc, current, operation, {"parent": current.id, "proposer": "lumen", "recipient": "lumen", "operation": operation}, command)
	if action == "edit":
		return _derive(doc, current, "edit", {"parent": current.id, "proposer": "model_b", "recipient": "lumen", "operation": "edit"}, command)
	if action == "room":
		return _derive(doc, current, "room", {"parent": current.id, "proposer": "lumen", "recipient": "lumen", "operation": "room"}, command)
	if action == "study":
		var library: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BEAUTY_STUDIES))
		var study: Dictionary = {}
		for candidate in library.studies:
			if candidate.id == str(command.get("study", "")): study = candidate
		if study.is_empty(): return {"error": "Unknown authored body study."}
		return _derive(doc, current, "study", {"parent": current.id, "proposer": "model_b", "recipient": "lumen", "operation": "study", "study": study.id}, command, study)
	return {"error": "Unknown body-history action."}

static func _derive(doc: Dictionary, parent: Dictionary, operation: String, proposal: Dictionary, command: Dictionary, study: Dictionary = {}) -> Dictionary:
	var recipe: Dictionary = parent.recipe.duplicate(true)
	var parts: Array = recipe.of.parts
	var number: int = doc.versions.size()
	var id := "v-%03d" % number
	if operation == "study":
		recipe = study.recipe.duplicate(true)
	elif operation == "room":
		recipe = doc.modules.room.recipe.duplicate(true)
	elif operation == "surface":
		for part in parts:
			if str(part.id) in ["torso", "left_reach", "right_reach"]:
				part.of = {"op": "associate", "surface": "pink_rim", "of": part.of}
	elif operation in ["reach", "gift"]:
		var key := ("reach-" if operation == "reach" else "gift-") + id
		var extra: Dictionary = doc.modules["reach" if operation == "reach" else "gift"].duplicate(true)
		extra.id = key
		# Insert before existing parts deliberately: stable links must survive reordering.
		parts.insert(1, extra)
		recipe.links.append({"a": "torso", "b": key, "kind": "spring" if operation == "gift" else "rod"})
	elif operation == "support":
		for part in parts:
			if str(part.id) == "left_support": part.at = [-0.68, 0.43, 0.12]; part.rot = [0, 0, -32]
			if str(part.id) == "right_support": part.at = [0.68, 0.43, 0.12]; part.rot = [0, 0, 32]
	elif operation == "edit":
		var target := str(command.get("part", ""))
		var found := false
		for part in parts:
			if str(part.id) != target: continue
			var at: Variant = command.get("at")
			if not at is Array or at.size() != 3: return {"error": "Position requires three metres."}
			for axis in 3:
				var value: Variant = at[axis]
				if not (value is float or value is int) or not is_finite(float(value)) or float(value) < -2.5 or float(value) > (4.0 if axis == 1 else 2.5):
					return {"error": "Keep parts within the body's authoring space."}
			part.at = at.duplicate(); found = true
		if not found: return {"error": "Unknown part ID."}
	var compiled := compile_recipe(recipe)
	if compiled.has("error"): return compiled
	var result := {"id": id, "parent": parent.id, "resident": "lumen", "stage": mini(4, int(parent.stage) + (0 if operation == "edit" else 1)), "label": str(doc.labels.get(operation, "Rearranged by request")), "seed": 731 + number * 37, "grammar_version": doc.grammar_version, "operation": operation, "recipe": recipe}
	result.inhabitable = operation == "room" or bool(parent.get("inhabitable", false))
	if operation == "study":
		result.label = study.label
		result.study = study.id
		result.inhabitable = bool(study.get("inhabitable", false))
	if result.inhabitable: result.stage = 5
	doc.versions.append(result); doc.cursor = id
	_event(doc, proposal, "accepted", id, [{"resident": "lumen", "decision": "accept"}])
	return {"message": "Lumen accepts " + str(result.label) + ". Parent " + str(parent.id) + " remains available."}

static func _event(doc: Dictionary, proposal: Dictionary, outcome: String, result: Variant, approvals: Array) -> void:
	var event_seed: int = int(version(doc, str(result)).seed) if result != null else 731 + doc.versions.size() * 37
	doc.events.append({"id": "event-" + str(doc.events.size()), "parent": proposal.parent, "proposer": proposal.proposer, "recipient": "lumen", "operation": proposal.operation, "outcome": outcome, "result": result, "approvals": approvals, "seed": event_seed, "grammar_version": doc.grammar_version, "time": Time.get_datetime_string_from_system(true), "authored": false})
	if proposal.has("study"): doc.events.back().study = proposal.study
	if outcome == "accepted": doc.residents.lumen.memory.append("Accepted " + str(result))
	if outcome == "rejected": doc.residents.lumen.memory.append("Declined " + str(proposal.operation))

static func transact(command: Dictionary) -> Dictionary:
	var file := storage_path()
	DirAccess.make_dir_recursive_absolute(file.get_base_dir())
	var lock := file + ".lock"
	if DirAccess.make_dir_absolute(lock) != OK: return {"error": "History is being saved elsewhere. Try again."}
	var doc := read_graph()
	var reply := doc if doc.has("error") else apply_command(doc, command)
	if not reply.has("error"):
		doc.revision = int(doc.revision) + 1
		var handle := FileAccess.open(file + ".tmp", FileAccess.WRITE)
		if handle == null: reply = {"error": "Could not write body history."}
		else:
			handle.store_string(JSON.stringify(doc, "\t", true, true)); handle.close()
			if DirAccess.rename_absolute(file + ".tmp", file) != OK: reply = {"error": "Could not commit body history."}
	DirAccess.remove_absolute(lock)
	if not reply.has("error"): reply.document = doc
	return reply
