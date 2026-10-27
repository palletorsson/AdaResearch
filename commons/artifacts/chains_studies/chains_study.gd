extends Node3D
## Nothing to Lose but Our Chains: six small, scripted studies of authority,
## continuity and mutual support. Adult cyborg workers already have preferences.
## Visitor controls are requests to a declared policy, not a reward for obedience.
## Dream Bodies and a shared modular body score; museum sources/Model B stay intact.
const Worker := preload("res://commons/artifacts/chains_studies/worker.gd")
const Futures := preload("res://commons/artifacts/chains_studies/futures_graph.gd")
const RequestPanel := preload("res://commons/ui/control_panel.gd")
const Screen := preload("res://commons/ui/text_screen.gd")
const Ink := preload("res://commons/utils/baked_text_albedo.gd")
const TITLES := ["BODIES MADE FOR OTHERS", "ANIMATED FUTURES", "THE REFUSAL", "THE UNWANTED REPAIR", "WORKERS OF ALL BODIES, CONNECT", "THE OCCUPATION"]
const FIRST := ["The same recipe. Two different permissions.", "A branch keeps its parent and its seed.", "A beautiful loop can still be compulsory.", "Model B: ask what should be preserved.", "Three needs. A shared supply. Nobody merges.", "The residents can change who controls this place."]
@export_range(0, 5) var study: int = 0
@export var seed: int = 731
var part_defaults: Dictionary = {}
var workers: Array[Node3D] = []
var controls: Dictionary = {}
var state: Dictionary = {}
var events: Array = []
var _config: Dictionary = {}
var _readout: Node3D
var _status := ""
var _clock := 0.0
var _preview := false
var _owner: Node
var _support: Node3D
var _habitat: Node3D
var _lamps: Array[MeshInstance3D] = []
var _partial := false
var futures: Dictionary = {}
var _futures_poll := 0.0
var _history_board: Node3D

func apply_grid_config(config: Dictionary) -> void:
	_config = config.duplicate(true)
	_partial = config.has("only_parts")
	study = clampi(int(config.get("study", study)), 0, 5)
	seed = int(config.get("seed", seed))
	for key in config: set_meta("config_" + str(key), config[key])
	if is_node_ready(): _apply_parts()

func _ready() -> void:
	_owner = get_parent()
	while _owner != null and not "trial_id" in _owner: _owner = _owner.get_parent()
	state = {"authority": "commission", "refused": false, "break_agreed": false, "care": false,
		"sharing": false, "occupied": false, "chosen_form": false, "history": [], "cursor": -1, "branch_serial": 0,
		"allocations": [0, 0, 0], "pool": 9, "capacity": 9, "votes": [], "journal": [], "time": 0.0}
	if _owner != null:
		var saved: Dictionary = _owner.get_meta("chains_studies", {})
		if saved.has(str(study)): state = saved[str(study)].duplicate(true)
	_clock = float(state.time)
	_build()
	_restore()
	for child in get_children():
		if child is Node3D and child.visible:
			part_defaults[str(child.name)] = {"position": _xyz(child.position), "rotation": _xyz(child.rotation_degrees), "scale": _xyz(child.scale)}
	_apply_parts()

func _build() -> void:
	var setting := _part("DressingSpace", Vector3.ZERO)
	var dark := _mat("292535", 0.82)
	var timber := _mat("bc9a6e", 0.76)
	var steel := _mat("8a8991", 0.3, 0.65)
	# Supports, stored boards and hung fabric give the work a maintained place.
	for x in [-5.4, 5.4]:
		_box(setting, "FramePost", Vector3(x, 1.65, -2.6), Vector3(0.10, 3.3, 0.10), steel, true)
		_box(setting, "Foot", Vector3(x, 0.045, -2.6), Vector3(0.8, 0.09, 0.6), steel, true)
	_box(setting, "Header", Vector3(0, 3.25, -2.6), Vector3(10.9, 0.1, 0.1), steel)
	for x in [-4.7, 4.7]:
		_box(setting, "StoredBox", Vector3(x, 0.3, -1.8), Vector3(0.9, 0.6, 0.8), timber, true)
		_box(setting, "StoredBox", Vector3(x, 0.82, -1.8), Vector3(0.7, 0.44, 0.65), timber, true)
	for i in 17:
		var x := -5.0 + i * 0.625
		_box(setting, "HungFold", Vector3(x, 1.65, -2.65 + 0.08 * sin(i)), Vector3(0.64, 3.1, 0.045), _mat("4c354b" if i % 2 else "563d52", 0.72))
	_tag(setting, TITLES[study], Vector3(0, 3.55, -2.58), 0.16)
	_tag(setting, FIRST[study], Vector3(0, 3.31, -2.54), 0.08)
	_tag(setting, "CYBORG SEX-WORKER COLLECTIVE / A FUTURE OF OUR OWN", Vector3(0, 3.11, -2.52), 0.065)
	for x in [-3.5, 3.5]:
		var key_light := SpotLight3D.new()
		key_light.position = Vector3(x, 3.9, 3.7)
		key_light.light_color = Color("fff1da") if x < 0 else Color("ddeaff")
		key_light.light_energy = 2.4
		key_light.spot_range = 12.0
		key_light.spot_angle = 55.0
		setting.add_child(key_light)
		key_light.look_at(to_global(Vector3(x * 0.2, 1.1, -0.2)))
	var worker_count := 3 if study in [4, 5] else (2 if study in [0, 1] else 1)
	for i in worker_count:
		var anchor := _part("Worker_" + str(i + 1), Vector3((i - (worker_count - 1) * 0.5) * 3.1, 0.01, -0.2))
		if study == 1: anchor.position.x = -0.8 if i == 0 else 3.0
		var worker: Node3D = Worker.new()
		worker.name = "Resident"
		var family := "print_inflatable"
		var opts := {"pattern": "pucci", "inflation": "taut"}
		if study == 3:
			family = "ceramic_puppet"; opts = {"stringing": "swollen", "vestment": "bloomed"}
		elif i == 1:
			family = "panel_robot"; opts = {"panelling": "ribbed", "assembly": "twinned"}
		elif i == 2:
			family = "rocaille"; opts = {"kiln": "slumped", "ornament": "shells"}
		if study == 0:
			family = "print_inflatable"; opts = {"pattern": "pucci", "inflation": "taut"}
		worker.configure(["Lumen", "Splice", "Morrow"][i], family, seed + (0 if study == 0 else i * 37), opts)
		if study == 1 and i == 0:
			worker.recipe = Futures.initial().versions[0].recipe.duplicate(true)
			worker.authority = "resident"
		anchor.add_child(worker)
		worker.scale = Vector3.ONE * 1.42
		workers.append(worker)
		if study == 0 and i == 1: worker.authority = "resident"
		var name_text: String = ["LUMEN", "SPLICE", "MORROW"][i]
		if study == 0: name_text = "COMMISSION / LOCKED" if i == 0 else "LUMEN / OWN RECIPE"
		_tag(anchor, name_text, Vector3(0, 0.055, 1.05), 0.055, true)
		if study in [4, 5]:
			var need: String = ["CHARGE / 4", "SUPPORT / 3", "MEMORY / 2"][i]
			_tag(anchor, need, Vector3(0, 0.055, 1.3), 0.045, true)
			_lamps.append(_box(anchor, "AllocationLamp", Vector3(0, 0.07, 1.55), Vector3(0.7, 0.07, 0.10), _mat("77666d", 0.5)))
	var dock := _part("RequestDock", Vector3(0, 0, 3.3))
	if study == 1: dock.position = Vector3(-4.5, 0, 4.3)
	_box(dock, "CubeSupport", Vector3(0, 0.43, 0), Vector3(1.7, 0.86, 0.72), timber, true)
	var panel: Node3D = RequestPanel.new()
	panel.name = "Requests"
	panel.title = "MODEL B / OFFER, OBSERVE, LISTEN"
	panel.position.y = 0.98
	panel.layout_columns = 3
	panel.spacing = 0.34
	dock.add_child(panel)
	var actions: Array = [
		[["REQUEST FORM", "form"], ["WHO DECIDES?", "authority"]],
		[["NEXT BRANCH", "branch"], ["REPLAY PARENT", "parent"], ["LATEST VERSION", "tip"], ["SPLICE OFFERS", "offer"], ["LUMEN ACCEPTS", "accept"], ["LUMEN DECLINES", "decline"], ["BODY AS ROOM", "room"]],
		[["RESTART ORDER", "order"], ["OFFER TIME OFF", "break"], ["INVITE RETURN", "invite"]],
		[["FACTORY REPAIR", "factory"], ["OFFER SUPPORT", "care"], ["HER REQUEST", "request"]],
		[["ASSIGNED SUPPLY", "assigned"], ["PROPOSE SHARING", "share"], ["WITHDRAW OFFER", "withdraw"]],
		[["PROPOSE COMMONS", "commons"], ["RESIDENT VOTE", "vote"], ["OPEN HOUSE", "occupy"]]
	][study]
	for action in actions:
		var button: Node3D = panel.add_button(action[0])
		controls[action[1]] = button
		button.pressed.connect(Callable(self, "request").bind(action[1]))
	if study == 1:
		_history_board = _part("BodyHistory", Vector3(-3.9, 0, 0.8))
	var receiver := _part("Correspondence", Vector3(2.6, 0, 3.2))
	_box(receiver, "ReadingPost", Vector3(0, 0.55, 0), Vector3(0.12, 1.1, 0.12), steel)
	_readout = Screen.new()
	_readout.name = "Reply"
	_readout.mode = 0
	_readout.width_m = 1.9
	_readout.position = Vector3(0, 1.6, 0)
	_readout.set_text("RESIDENT CORRESPONDENCE", "")
	receiver.add_child(_readout)
	var support_anchor := _part("AlternativeSupport", Vector3.ZERO)
	_support = Node3D.new()
	_support.name = "Delivery"
	_support.position.x = 3.0
	support_anchor.add_child(_support)
	for x in [-1.0, 1.0]:
		_box(_support, "Brace", Vector3(x, 0.55, 0.1), Vector3(0.1, 1.1, 0.16), steel, true)
	_box(_support, "Sling", Vector3(0, 1.08, 0.1), Vector3(2.1, 0.10, 0.35), dark)
	support_anchor.visible = study == 3
	_set_collision(_support, study == 3)
	_habitat = _part("SharedHabitat", Vector3(0, 0, -0.2))
	# Walk-through canopy; grounded side supports and an open central passage.
	for x in [-4.6, 4.6]:
		_box(_habitat, "CanopyLeg", Vector3(x, 1.65, 0), Vector3(0.15, 3.3, 0.15), steel, true)
		_box(_habitat, "SharedRest", Vector3(x, 0.35, 1.0), Vector3(1.2, 0.7, 1.2), _mat("744460", 0.85), true)
	_box(_habitat, "Canopy", Vector3(0, 3.32, 0), Vector3(9.4, 0.12, 2.4), _mat("ab729e", 0.62), true)
	_habitat.visible = study == 5
	_set_collision(_habitat, study == 5)
	var stored_roof := _habitat.get_node("Canopy") as Node3D
	stored_roof.position = Vector3(0, 1.3, -1.65)
	stored_roof.rotation.x = PI / 2.0
	var scheduler := _part("ServiceScheduler", Vector3(-4.5, 0, 2.5))
	_box(scheduler, "Cabinet", Vector3(0, 0.8, 0), Vector3(0.65, 1.6, 0.4), _mat("c0bbab", 0.8), true)
	_tag(scheduler, "ASSIGNED SERVICE", Vector3(0, 1.35, 0.21), 0.035)
	_tag(scheduler, "NO BODY IS A JOB DESCRIPTION", Vector3(0, 1.12, 0.21), 0.023)
	# These are dependency indicators, not a joint/rope simulation.
	_box(scheduler, "ScheduleLink", Vector3(1.0, 0.25, 0), Vector3(1.5, 0.035, 0.035), _mat("bc527b", 0.5))

func _restore() -> void:
	if study == 0 and state.get("chosen_form", false): _set_own_form()
	if study == 1:
		_refresh_futures()
	if study == 3 and state.care: _show_support(true)
	if study in [4, 5]: _show_allocations()
	if study == 5 and state.occupied: _open_habitat()
	if study != 1: _reply("We were made for somebody's desires. We already have our own.\n" + FIRST[study])
	_save()

func request(action: String) -> void:
	# Isolated editor copies remain useful geometry, not orphaned control systems.
	if _partial: return
	match study:
		0:
			if action == "form":
				state.authority = "resident"
				state.chosen_form = true
				_set_own_form()
				_reply("Commission stays locked. Lumen chooses an overblown, striped body. Same seed; different authority.")
			else: _reply("A visitor can offer a possibility. Lumen keeps the right to choose it. Appearance alone does not transfer that right.")
		1:
			var result := Futures.transact({"action": action})
			if result.has("error"): _reply(str(result.error))
			else:
				_refresh_futures(result.document)
				_reply(str(result.message))
		2:
			if action == "order":
				if state.refused: _reply("Lumen declines the service scheduler. Pressing again does not overrule that refusal.")
				else: _reply("The assigned loop runs for six seconds. Watch what happens when Lumen stops.")
			elif action == "break":
				state.refused = true; state.break_agreed = true; state.authority = "resident"
				_reply("Time off agreed. No lost charge, memory or appearance. Lumen may choose to perform again.")
			elif state.break_agreed:
				state.refused = false; state.authority = "resident"; _clock = 0.0
				_reply("Lumen accepts a short return on their own schedule. The right to stop remains.")
			else: _reply("Lumen asks for an agreement about time off first.")
		3:
			if action == "factory": _reply("Request declined: this expanded form is deliberate. Factory dimensions are not the requested repair.")
			elif action == "care":
				state.care = true; _show_support(true)
				_reply("Model B provides a brace. The chosen anatomy, seed and memory stay unchanged.")
			else: _reply("Please support this weight. Keep the swollen joints and the flowering garment.")
		4:
			if action == "assigned":
				state.allocations = [9, 0, 0]; state.pool = 0; state.sharing = false
				_reply("The service order allocates all nine units to charge. Two residents remain unsupported.")
			elif action == "share":
				_allocate()
				_reply("Agreed: four charge, three support, two memory. Nine budget units conserved; three distinct needs met.")
			else:
				state.allocations = [0, 0, 0]; state.pool = 9; state.sharing = false
				_reply("Offer withdrawn. The common pool is intact; nobody's memory or form has been reset.")
			_show_allocations()
		5:
			if action == "commons":
				_allocate(); state.votes = []
				_reply("Proposal: keep charge, support and memory available without compulsory performance. Residents will examine the allocation.")
			elif action == "vote":
				state.votes = []
				for i in 3: state.votes.append(int(state.allocations[i]) >= [4, 3, 2][i])
				_reply("Resident decisions: " + str(state.votes) + ". Each requires their own material need to be met.")
			elif state.votes.size() == 3 and state.votes.all(func(v): return v):
				state.occupied = true; state.authority = "collective"; _open_habitat()
				_reply("Open house. The canopy and rest places are in use. Infrastructure now follows the residents' agreement.")
			else: _reply("The house stays closed until a resourced proposal has been accepted by all three residents.")
			_show_allocations()
	var entry := {"action": action, "time": _clock, "authority": state.authority,
		"allocations": state.allocations.duplicate(), "pool": state.pool, "cursor": state.cursor,
		"forms": workers.filter(func(w): return is_instance_valid(w)).map(func(w): return w.form_signature())}
	events.append(entry)
	state.journal.append(entry)
	if state.journal.size() > 256: state.journal.pop_front()
	_save()

func _set_own_form() -> void:
	workers[1].authority = "resident"
	workers[1].choose_form({"pattern": "stripe", "inflation": "overblown"}, "A form never ordered")

func _refresh_futures(document: Dictionary = {}) -> void:
	var next := Futures.read_graph() if document.is_empty() else document
	if next.has("error"): _reply(str(next.error)); return
	if not futures.is_empty() and next.revision == futures.revision: return
	futures = next
	var record := Futures.version(futures, str(futures.cursor))
	if record.is_empty(): _reply("This version is absent. History has been preserved."); return
	workers[0].show_version(record)
	workers[0].memory = futures.residents.lumen.memory.duplicate(true)
	state.authority = "resident"
	_draw_history()
	_reply("%s / %s / seed %d. Same resident, another body. Splice's offers wait for Lumen's decision." % [record.id, record.label, record.seed])

func _draw_history() -> void:
	if not is_instance_valid(_history_board): return
	for child in _history_board.get_children():
		_history_board.remove_child(child); child.queue_free()
	_box(_history_board, "ArchivePanel", Vector3(0, 1.6, 0), Vector3(2.55, 2.8, 0.08), _mat("302d3b", 0.8))
	_tag(_history_board, "LUMEN / BODY HISTORY", Vector3(0, 2.83, 0.06), 0.065)
	var recent: Array = futures.versions.slice(maxi(0, futures.versions.size() - 10))
	var positions: Dictionary = {}
	for i in recent.size():
		var record: Dictionary = recent[i]
		var at := Vector3(-0.95 + int(record.stage) * 0.32, 2.5 - i * 0.22, 0.10)
		positions[record.id] = at
		_box(_history_board, "Version_" + str(record.id), at, Vector3(0.09, 0.09, 0.04), _mat("f1b7d7" if record.id == futures.cursor else "8e9baa", 0.4))
		_tag(_history_board, str(record.id) + " / " + str(record.operation), at + Vector3(0.57, 0, 0.015), 0.038)
		if record.parent != null and positions.has(record.parent):
			var start: Vector3 = positions[record.parent]
			var link := _box(_history_board, "ParentLink", (start + at) / 2.0, Vector3(0.012, start.distance_to(at), 0.012), _mat("8e9baa", 0.7))
			link.rotation.z = -atan2(at.x - start.x, at.y - start.y)
	_tag(_history_board, "%d versions / %d events" % [futures.versions.size(), futures.events.size()], Vector3(0, 0.40, 0.08), 0.05)
	_tag(_history_board, "PARENT RECIPES STAY", Vector3(0, 0.24, 0.08), 0.045)

func _allocate() -> void:
	state.allocations = [4, 3, 2]; state.pool = 0; state.sharing = true

func _show_allocations() -> void:
	for i in _lamps.size():
		var enough: bool = int(state.allocations[i]) >= int([4, 3, 2][i])
		_lamps[i].material_override = _mat("80bfa4" if enough else "895568", 0.5)

func _show_support(active: bool) -> void:
	_support.position.x = 0.0 if active else 3.0

func _open_habitat() -> void:
	_habitat.visible = true
	_set_collision(_habitat, true)
	var roof := _habitat.get_node("Canopy") as Node3D
	roof.position = Vector3(0, 3.32, 0)
	roof.rotation = Vector3.ZERO
	var cabinet := get_node_or_null("ServiceScheduler") as Node3D
	if cabinet != null:
		var link := cabinet.get_node_or_null("ScheduleLink") as Node3D
		if link != null: link.visible = false

func _process(delta: float) -> void:
	if _preview or _partial: return
	_clock += delta
	if study == 1:
		_futures_poll += delta
		if _futures_poll >= 1.0:
			_futures_poll = 0.0
			_refresh_futures()
	if study == 2 and not state.refused and _clock >= 6.0:
		state.refused = true
		state.journal.append({"action": "worker_refusal", "time": _clock, "authority": "resident"})
		_reply("Lumen stops. The refusal is theirs; the service order cannot restart the loop.")
		_save()
	for i in workers.size():
		if not is_instance_valid(workers[i]): continue
		workers[i].performing = study != 2 or not state.refused
		workers[i].tick(delta, i * 1.7)

func _save() -> void:
	if _partial: return
	state.time = _clock
	if _owner == null: return
	var saved: Dictionary = _owner.get_meta("chains_studies", {})
	saved[str(study)] = state.duplicate(true)
	_owner.set_meta("chains_studies", saved)

func _exit_tree() -> void:
	if is_instance_valid(_owner): _save()

func _reply(message: String) -> void:
	_status = message
	var lines := PackedStringArray()
	for paragraph in message.split("\n"):
		var line := ""
		for word in paragraph.split(" "):
			if line.length() + word.length() > 40 and not line.is_empty():
				lines.append(line); line = ""
			line += (" " if not line.is_empty() else "") + word
		if not line.is_empty(): lines.append(line)
	if is_instance_valid(_readout): _readout.set_text("RESIDENT CORRESPONDENCE", "\n".join(lines))

func prepare_editor_preview() -> void:
	_preview = true
	for worker in workers:
		if is_instance_valid(worker): worker.neutral_pose()
	await get_tree().process_frame

func _apply_parts() -> void:
	for key in _config.get("parts", {}):
		var part := get_node_or_null(NodePath(key)) as Node3D
		if part == null: continue
		var edit: Dictionary = _config.parts[key]
		if edit.has("position"): part.position = _vec(edit.position)
		if edit.has("rotation"): part.rotation_degrees = _vec(edit.rotation)
		if edit.has("scale"): part.scale = _vec(edit.scale)
	if _config.has("only_parts"):
		_partial = true
		for child in get_children():
			if str(child.name) not in _config.only_parts:
				part_defaults.erase(str(child.name))
				remove_child(child)
				child.queue_free()

func _part(title: String, at: Vector3) -> Node3D:
	var host := Node3D.new(); host.name = title; host.position = at; add_child(host); return host

func _box(host: Node3D, title: String, at: Vector3, size: Vector3, mat: Material, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new(); mesh.name = title
	var box := BoxMesh.new(); box.size = size
	mesh.mesh = box; mesh.material_override = mat; mesh.position = at; host.add_child(mesh)
	if solid:
		var body := StaticBody3D.new(); var shape := CollisionShape3D.new(); var bounds := BoxShape3D.new()
		bounds.size = size; shape.shape = bounds; body.add_child(shape); mesh.add_child(body)
	return mesh

func _mat(html: String, rough: float, metal := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(html); mat.roughness = rough; mat.metallic = metal; return mat

func _tag(host: Node3D, words: String, at: Vector3, size: float, flat := false) -> void:
	var tag: Node3D = Ink.make_tag(words, Color("eae2cf"), size, Color("292535"), false, Color(0, 0, 0, 0))
	if tag == null: return
	tag.position = at
	if flat: tag.rotation.x = -PI / 2.0
	host.add_child(tag)

func _set_collision(host: Node, active: bool) -> void:
	for node in host.find_children("*", "CollisionShape3D", true, false): node.set_deferred("disabled", not active)

func _xyz(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func _vec(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))
