extends "res://commons/artifacts/spine_films/film_stage.gd"
const ArrayState = preload("res://commons/artifacts/spine_films/foundation_c/array_model.gd")
const CHALK := Color("e2e8e2")
const PINK := Color("cf709b")
const TEAL := Color("5db7b0")
const SLATE := Color("263647")
var model := ArrayState.new()
var manual := false
var last_action := ""
var _auto_key := ""
var _bodies: Array[MeshInstance3D] = []
var _labels: Array[Label3D] = []
var _selection: Node3D
var _readout: Label3D
var _assignment: Label3D

func _build() -> void:
	title_text = "An empty address still exists"
	duration = 24.0
	phases.assign(["Sixteen slots keep sixteen values", "Selecting reads; it does not write", "Change one value, leave it, return", "One rule writes all sixteen slots"])
	notes.assign([
		"The solids display true. Every low socket remains an address, including a slot whose value is false.",
		"Selection moves through cells[x][z]. Every value stays true while the selected address changes.",
		"WRITE toggles cells[1][1] to false. Selecting another slot and returning does not restore it.",
		"RULE writes (x + z) % 2 == 0 into every slot. Selecting an address afterwards only reads it."
	])
	source_paths.assign(["res://commons/artifacts/spine_films/foundation_source.js"])
	evidence = {"source_lines": [82, 94], "dimensions": [4, 4], "storage_order": "cells[x][z]", "initial_selection": [1, 1], "boolean_values": true, "native_port": true}
	add_box(Vector3(0, .05, 0), Vector3(4.8, .1, 4.8), SLATE)
	for z in 4:
		for x in 4:
			var at := slot_position(x, z)
			add_box(at + Vector3(0, .13, 0), Vector3(.93, .14, .93), Color("405466"))
			var body := add_box(at + Vector3(0, .57, 0), Vector3(.77, .73, .77), CHALK)
			_bodies.append(body)
			var label := add_label("%d,%d" % [x, z], at + Vector3(0, 1.12, 0), CHALK)
			label.font_size = 24
			label.pixel_size = .006
			_labels.append(label)
	_selection = Node3D.new()
	display.add_child(_selection)
	for side in [-1.0, 1.0]:
		add_box(Vector3(side * .51, .24, 0), Vector3(.045, .055, 1.06), PINK, _selection)
		add_box(Vector3(0, .24, side * .51), Vector3(1.06, .055, .045), PINK, _selection)
	_readout = add_label("", Vector3(0, 3.15, -.35), CHALK)
	_readout.font_size = 38
	_assignment = add_label("", Vector3(0, 2.76, -.35), TEAL)
	_assignment.font_size = 27
	add_rod(Vector3(-2.1, .19, 2.2), Vector3(2.1, .19, 2.2), .018, TEAL)
	add_label("x  0  →  3", Vector3(0, .25, 2.65), TEAL)
	add_rod(Vector3(-2.2, .19, -2.1), Vector3(-2.2, .19, 2.1), .018, TEAL)
	add_label("z  0 → 3", Vector3(-2.65, .65, 0), TEAL).font_size = 25
	frame_scene(Vector3(0, 1.0, 0), 10.7, .37, .65)

func slot_position(x: int, z: int) -> Vector3:
	return Vector3((float(x) - 1.5) * 1.1, 0, (float(z) - 1.5) * 1.1)

func _draw(time: float) -> void:
	if not manual:
		_apply_autoplay(time)
	_selection.position = slot_position(model.selected.x, model.selected.y)
	_selection.position.y = .73 if model.read_selected() else 0.0
	for z in 4:
		for x in 4:
			var i := z * 4 + x
			_bodies[i].visible = model.cells[x][z]
			_labels[i].modulate = PINK if model.selected == Vector2i(x, z) else CHALK
			_labels[i].position.y = 1.12 if model.cells[x][z] else .36
	_readout.text = "cells[%d][%d] = %s" % [model.selected.x, model.selected.y, str(model.read_selected())]
	_assignment.text = last_action

func _apply_autoplay(time: float) -> void:
	var phase := phase_index(time)
	var u := phase_progress(time)
	var sub := mini(15, int(u * 16.0)) if phase == 1 or phase == 3 else (mini(2, int(u * 3.0)) if phase == 2 else 0)
	var key := "%d:%d" % [phase, sub]
	if key == _auto_key:
		return
	_auto_key = key
	model.reset()
	match phase:
		0:
			last_action = "4 × 4 addresses / all true"
		1:
			model.select_slot(sub % 4, sub / 4)
			last_action = "SELECT / values unchanged"
		2:
			model.write_selected()
			if sub == 1:
				model.select_slot(2, 1)
			last_action = "WRITE / then select elsewhere" if sub < 2 else "RETURN / false was kept"
		3:
			model.checker()
			model.select_slot(sub % 4, sub / 4)
			last_action = "RULE / (x + z) % 2 == 0"

func experiment_controls() -> Array:
	return [{"key": "next", "label": "NEXT SLOT"}, {"key": "write", "label": "WRITE"}, {"key": "rule", "label": "RULE"}, {"key": "reset", "label": "RESET"}]

func experiment_snapshot() -> Dictionary:
	return {"cells": model.snapshot(), "selected": [model.selected.x, model.selected.y], "value": model.read_selected(), "manual": manual}

func experiment_action(key: String) -> void:
	if not key in ["next", "write", "rule", "reset"]:
		return
	manual = true
	running = false
	match key:
		"next":
			model.next_slot()
			last_action = "SELECT / values unchanged"
		"write":
			model.write_selected()
			last_action = "WRITE / toggle the selected Boolean"
		"rule":
			model.checker()
			last_action = "RULE / (x + z) % 2 == 0"
		"reset":
			model.reset()
			last_action = "RESET / all true; selection 1,1"
	refresh()

func refresh() -> void:
	super.refresh()
	if manual:
		_note.text = "NEXT SLOT reads another address. WRITE toggles one value. RULE overwrites the grid; RESET restores all true."
		_footer.text = "MANUAL / your values remain until you write, apply a rule, reset or replay"

func replay() -> void:
	manual = false
	_auto_key = ""
	model.reset()
	super.replay()

func validation() -> Dictionary:
	var sample := ArrayState.new()
	var original := sample.snapshot()
	var seen := {}
	for i in 16:
		seen[sample.selected] = true
		sample.next_slot()
	var selection_read_only := sample.snapshot() == original
	sample.write_selected()
	var retained: bool = not sample.cells[1][1] and sample.cells[0][0]
	sample.checker()
	var exact := true
	for x in 4:
		for z in 4:
			exact = exact and sample.cells[x][z] == ((x + z) % 2 == 0)
	sample.reset()
	var checks := {"sixteen_addresses": seen.size() == 16, "selection_reads_only": selection_read_only, "single_write": retained, "exact_rule": exact, "reset": sample.snapshot() == original and sample.selected == Vector2i(1, 1), "reused_meshes": _bodies.size() == 16}
	return {"passed": not checks.values().has(false), "checks": checks, "evidence": evidence}
