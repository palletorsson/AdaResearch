extends "res://commons/artifacts/timing_machines/iso_shapes_workshop.gd"
## The tower uses the museum's gallery and controls, with a fixed reference
## frame for comparing a held mesh to the new cut through the same field.
const Links = preload("res://commons/void/trials/isosurfaces/floor_links.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const Outline = preload("res://commons/void/trials/isosurfaces/shapes_outline.gdshader")
const HELD_SLOTS := [1, 4]
const DISPLAY_X := [2.8, -4.0]

var _overlay := false
var _held_level := 0.0
var _held_material := ShaderMaterial.new()
var _held_names: Array[String] = []
var _header: Label3D


func _bind() -> void:
	var hall := get_parent()
	while hall != null and not hall.has_meta("em_map"):
		hall = hall.get_parent()
	if hall == null:
		return
	for attempt in 100:
		model = Links.find_artifact(hall, "mc_shapes_gallery")
		if model != null:
			break
		await get_tree().create_timer(0.1).timeout
	if model == null:
		readout = label("Shape gallery missing", Vector3(0, 1.4, 2.0))
		return
	repertoire_index = model.ROSTERS.keys().find(model.repertoire)
	level_index = model.ISO_LEVELS.keys().find(model.likeness)
	_held_material.shader = Outline
	ids = ["HOLD", "LEVEL", "OVERLAY", "REPERTOIRE", "RESET", "CLEAR", "RULE"]
	_build_compact_console(ids, "SHAPE GALLERY")
	for button in buttons.values():
		Rack.make_button_rectangular(button)
	rule_card = label("Chair = seat ∪ back ∪ legs\nCup = (outer cylinder − inner cylinder) ∪ handle\nLEVEL cuts all six fields at the same value.", Vector3(0, 2.1, 1.5), 0.0011)
	rule_card.visible = false
	_header = label("", Vector3(0, 2.55, 1.4), 0.0016)
	_header.outline_size = 10
	for at in [Vector3(-3.5, 4.4, -0.75), Vector3(3.5, 4.4, -4.0)]:
		var lamp := OmniLight3D.new()
		lamp.position = at
		lamp.omni_range = 11.0
		lamp.light_energy = 2.2
		add_child(lamp)
	ready_for_input = true
	refresh()


func _build_compact_console_support(width: float, casing: Material) -> void:
	var hall: Node3D = get_parent().get_parent()
	var floor: int = hall.get_meta("void_content_floor", -1)
	var ceiling := 5.64
	if floor > 0:
		var layout: Dictionary = hall.get_parent().building.spec
		ceiling = float(layout.levels[floor - 1]) - float(layout.levels[floor]) - float(layout.slab_thickness)
	var side := width * 0.5 - 0.13
	box(Vector3(side, (ceiling + 1.0) * 0.5, 1.78), Vector3(0.1, ceiling - 1.0, 0.13), casing)
	box(Vector3(side, ceiling - 0.06, 1.78), Vector3(0.4, 0.12, 0.32), casing)


func act(id: String) -> void:
	if not ready_for_input or busy:
		return
	if id == "OVERLAY":
		if comparisons.is_empty():
			_header.text = "PRESS HOLD FIRST"
			return
		if not _same_shapes(generators()):
			_header.text = "RETURN TO THE HELD REPERTOIRE"
			return
		_overlay = not _overlay
		actions_taken += 1
		refresh()
		return
	await super.act(id)


func _hold_pair() -> void:
	_clear_pair()
	_held_level = model._iso_level()
	var items := generators()
	for i in HELD_SLOTS:
		var original: MeshInstance3D = items[i]
		var copy := MeshInstance3D.new()
		copy.mesh = original.mesh.duplicate()
		copy.material_override = _held_material
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(copy)
		comparisons.append(copy)
		_held_names.append(model._shape_label(original.shape_type))
		var caption := label("", Vector3.ZERO, 0.002)
		caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		captions.append(caption)


func _clear_pair() -> void:
	super._clear_pair()
	_held_names.clear()
	_overlay = false


func _same_shapes(items: Array) -> bool:
	for i in HELD_SLOTS.size():
		if _held_names[i] != model._shape_label(items[HELD_SLOTS[i]].shape_type):
			return false
	return true


func refresh() -> void:
	var items := generators()
	var missing := 0
	for i in items.size():
		var item: MeshInstance3D = items[i]
		var empty: bool = item.num_triangles == 0
		missing += int(empty)
		var caption: Label3D = model._owned[i * 2 + 1]
		caption.text = model._shape_label(item.shape_type) + ("  /  EMPTY" if empty else "")
		caption.global_position.y = item.global_position.y + maxf(0.4, item.get_aabb().end.y * item.global_basis.y.length()) + 0.22
		caption.pixel_size = 0.0035
		caption.outline_size = 10
	var status := "%d surfaces  /  %d empty" % [items.size() - missing, missing] if actual_meshes() else "GPU extraction unavailable"
	readout.text = "%s  /  LEVEL %+.1f\n%s\n64³ samples per shape" % [model.repertoire.to_upper(), model._iso_level(), status]
	_header.text = "HOLD THE MIDDLE PAIR"
	if comparisons.is_empty():
		return
	_overlay = _overlay and _same_shapes(items)
	_header.text = "%s %s & %s  /  %+.1f" % ["OVERLAY" if _overlay else "HELD", _held_names[0].to_upper(), _held_names[1].to_upper(), _held_level]
	for i in comparisons.size():
		var copy := comparisons[i]
		var original: MeshInstance3D = items[HELD_SLOTS[i]]
		copy.global_transform = original.global_transform
		if not _overlay:
			copy.global_position = model.to_global(Vector3(DISPLAY_X[i], -1.3, 0.35))
			copy.global_position.y -= copy.get_aabb().position.y * copy.global_basis.y.length()
		var empty := copy.mesh.get_surface_count() == 0
		var caption := captions[i]
		caption.visible = not _overlay or empty
		caption.text = "HELD %s%s" % [_held_names[i].to_upper(), "  /  EMPTY" if empty else ""]
		caption.global_position = copy.global_position + Vector3.UP * (copy.get_aabb().end.y * copy.global_basis.y.length() + 0.24)
