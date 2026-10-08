extends "res://commons/artifacts/spine_films/film_stage.gd"
const Palette = preload("res://commons/artifacts/spine_films/foundation_c/palette.gd")
const CHALK := Color("e2e8e2")
const SLATE := Color("263647")
const PINK := Color("cf709b")
const TEAL := Color("5db7b0")
var palette_a: Palette
var palette_b: Palette
var shared := false
var manual := false
var last_action := ""
var receiver_indices: Array[int] = [0, 0]
var receiver_colours: Array[Color] = [Palette.INKS[0], Palette.INKS[0]]
var _auto_key := ""
var _instances: Array[MeshInstance3D] = []
var _instance_labels: Array[Label3D] = []
var _receivers: Array[MeshInstance3D] = []
var _receiver_labels: Array[Label3D] = []
var _references: Array[MeshInstance3D] = []
var _readout: Label3D
var _operation: Label3D

func _build() -> void:
	title_text = "One class; whose state changes?"
	duration = 24.0
	phases.assign(["Create two independent instances", "Advance A; B keeps its index", "Link resets to one shared instance", "Advance B; refresh both receivers"])
	notes.assign([
		"A and B refer to two Palette objects made from one class. Each begins at index 0.",
		"advance() changes only the object it is called on. Both previews explicitly read their palettes after the action.",
		"LINK creates a fresh Palette at index 0 and gives both A and B a reference to it. Two references; one state.",
		"Calling advance() through B changes the shared object. Refreshing the receivers makes the same new colour visible twice."
	])
	source_paths.assign(["res://commons/artifacts/spine_films/foundation_source.js"])
	evidence = {"source_lines": [96, 112], "inks": ["#cf709b", "#5db7b0", "#d9b358"], "native_class": "RefCounted Palette", "explicit_refresh": true, "limitation": "Proposed Palette teaching model; it does not bind to the museum's existing floor cells."}
	add_box(Vector3(0, .04, 0), Vector3(5.8, .08, 4.3), SLATE)
	for i in 2:
		var x := -1.65 if i == 0 else 1.65
		var state := add_box(Vector3(x, 1.78, -1.08), Vector3(1.15, .76, .85), CHALK)
		_instances.append(state)
		var state_label := add_label("", Vector3(x, 2.46, -1.08), CHALK)
		state_label.font_size = 28
		_instance_labels.append(state_label)
		add_box(Vector3(x, .13, .92), Vector3(1.66, .18, 1.25), Color("435264"))
		var receiver := add_box(Vector3(x, .44, .92), Vector3(1.45, .46, 1.04), Palette.INKS[0])
		_receivers.append(receiver)
		var receiver_label := add_label("", Vector3(x, .94, 1.55), CHALK)
		receiver_label.font_size = 30
		_receiver_labels.append(receiver_label)
		var reference := add_rod(Vector3(x, .74, .78), state.position + Vector3(0, -.42, .22), .028, CHALK)
		_references.append(reference)
	for i in 3:
		add_box(Vector3((i - 1) * .51, .17, 1.63), Vector3(.38, .13, .36), Palette.INKS[i])
		add_label(str(i), Vector3((i - 1) * .51, .43, 1.78), CHALK).font_size = 23
	_readout = add_label("", Vector3(0, 3.35, -.3), CHALK)
	_readout.font_size = 33
	_operation = add_label("", Vector3(0, 2.96, -.3), TEAL)
	_operation.font_size = 26
	_reset_palettes()
	frame_scene(Vector3(0, 1.5, 0), 11.4, .27, .35)

func _reset_palettes() -> void:
	palette_a = Palette.new()
	palette_b = palette_a if shared else Palette.new()
	refresh_receivers()

func refresh_receivers() -> void:
	# State mutation and refreshing a visible receiver are deliberately separate.
	receiver_indices.assign([palette_a.index, palette_b.index])
	receiver_colours.assign([palette_a.colour(), palette_b.colour()])
	for i in _receivers.size():
		(_receivers[i].material_override as StandardMaterial3D).albedo_color = receiver_colours[i]

func _draw(time: float) -> void:
	if not manual:
		_apply_autoplay(time)
	var same := palette_a == palette_b
	_instances[0].position = Vector3(0 if same else -1.65, 1.78, -1.08)
	_instances[1].visible = not same
	_instance_labels[1].visible = not same
	for i in 2:
		var state := palette_a if i == 0 else palette_b
		(_instances[i].material_override as StandardMaterial3D).albedo_color = state.colour()
		_instance_labels[i].position = _instances[i].position + Vector3(0, .68, 0)
		_instance_labels[i].text = "Palette %d / index %d" % [i + 1, state.index]
		_receiver_labels[i].text = "%s reads %d" % ["A" if i == 0 else "B", receiver_indices[i]]
		var x := -1.65 if i == 0 else 1.65
		var a := Vector3(x, .74, .78)
		var b := _instances[0 if same else i].position + Vector3(0, -.42, .22)
		_pose_rod(_references[i], a, b)
		(_references[i].material_override as StandardMaterial3D).albedo_color = PINK if same else CHALK
	_readout.text = "TWO REFERENCES / ONE INSTANCE" if same else "ONE CLASS / TWO INSTANCES"
	_operation.text = last_action

func _pose_rod(node: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	var mesh := node.mesh as CylinderMesh
	node.position = (a + b) * .5
	node.basis = Basis(Quaternion(Vector3.UP, (b - a).normalized())).scaled_local(Vector3(1, length / mesh.height, 1))

func _apply_autoplay(time: float) -> void:
	var phase := phase_index(time)
	var u := phase_progress(time)
	var advances := mini(2, 1 + int(u * 2.0)) if phase == 1 else ((1 if u < .35 else (2 if u < .87 else 3)) if phase == 3 else 0)
	var key := "%d:%d" % [phase, advances]
	if key == _auto_key:
		return
	_auto_key = key
	var desired_shared := phase >= 2
	if shared != desired_shared or palette_a == null:
		shared = desired_shared
		_reset_palettes()
	var target_a := advances % 3 if phase == 1 or phase == 3 else 0
	var target_b := advances % 3 if phase == 3 else 0
	if phase == 3:
		while palette_b.index != target_b:
			palette_b.advance()
	else:
		while palette_a.index != target_a:
			palette_a.advance()
		if not shared:
			while palette_b.index != target_b:
				palette_b.advance()
	refresh_receivers()
	match phase:
		0: last_action = "Palette.new() / two separate objects"
		1: last_action = "A.advance() / then refresh A and B"
		2: last_action = "LINK / B refers to A's new Palette"
		3: last_action = "B.advance() / then refresh A and B"

func experiment_controls() -> Array:
	return [{"key": "a", "label": "ADVANCE A"}, {"key": "b", "label": "ADVANCE B"}, {"key": "link", "label": "LINK / UNLINK"}, {"key": "reset", "label": "RESET"}]

func experiment_snapshot() -> Dictionary:
	return {"indices": [palette_a.index, palette_b.index], "shared": palette_a == palette_b, "object_ids": [palette_a.get_instance_id(), palette_b.get_instance_id()], "receiver_indices": receiver_indices.duplicate(), "receiver_colours": [receiver_colours[0].to_html(false), receiver_colours[1].to_html(false)], "manual": manual}

func experiment_action(key: String) -> void:
	if not key in ["a", "b", "link", "reset"]:
		return
	manual = true
	running = false
	match key:
		"a":
			palette_a.advance()
			last_action = "A.advance() / then refresh A and B"
		"b":
			palette_b.advance()
			last_action = "B.advance() / then refresh A and B"
		"link":
			shared = not shared
			_reset_palettes()
			last_action = "LINK / fresh shared state at 0" if shared else "UNLINK / two fresh states at 0"
		"reset":
			_reset_palettes()
			last_action = "RESET / link setting retained; indices 0"
	refresh_receivers()
	refresh()

func refresh() -> void:
	super.refresh()
	if manual:
		_note.text = "Shared references read one state. LINK / UNLINK creates fresh state; RESET keeps the current link setting."
		_footer.text = "MANUAL / proposed Palette class study; original museum floor bindings are unchanged"

func replay() -> void:
	manual = false
	shared = false
	_auto_key = ""
	_reset_palettes()
	super.replay()

func validation() -> Dictionary:
	var a := Palette.new()
	var b := Palette.new()
	var separate := a.get_instance_id() != b.get_instance_id()
	a.advance()
	var independent := a.index == 1 and b.index == 0
	b = a
	b.advance()
	var alias := a.index == 2 and b.index == 2 and a.get_instance_id() == b.get_instance_id()
	a.advance()
	var wraps := a.index == 0 and b.index == 0
	var checks := {"different_objects": separate, "independent_advance": independent, "same_reference": alias, "three_ink_cycle": wraps, "exact_inks": Palette.INKS == [Color("cf709b"), Color("5db7b0"), Color("d9b358")], "reused_meshes": _instances.size() == 2 and _receivers.size() == 2 and _references.size() == 2}
	return {"passed": not checks.values().has(false), "checks": checks, "evidence": evidence}
