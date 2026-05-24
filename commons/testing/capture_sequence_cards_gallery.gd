## Render each spine-sequence picker card as a standalone PNG, plus
## per-card JSON sidecar + manifest. Output mirrors the existing
## /dna gallery convention.
extends SceneTree

const PICKER_CONTENT: String = "res://commons/scenes/2din3dui/sequence_picker_content.tscn"
const SPINE_PATH: String = "res://commons/maps/curriculum_spine.json"
const SEQUENCES_DIR: String = "res://commons/maps/sequences/"
const PUBLIC_BASE: String = "/sequence-cards-gallery"
const CARD_SIZE: Vector2i = Vector2i(1024, 260)

const PHASE_HEX: Dictionary = {
	"F_order":     "#3A7BFF",
	"oscillation": "#7DFFA8",
	"E_entropy":   "#F4A261",
	"lambda_edge": "#E63946",
	"integration": "#9B5DE5",
	"relation":    "#FBE38A",
	"synthesis":   "#FFFFFF",
}

var _output_dir: String = "user://sequence_cards_gallery"


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	var content_scene: PackedScene = load(PICKER_CONTENT)
	if content_scene == null:
		push_error("Could not load picker content scene")
		quit(1)
		return
	var content: Control = content_scene.instantiate()
	var stage: SubViewport = SubViewport.new()
	stage.size = Vector2i(640, 1600)
	stage.own_world_3d = false
	stage.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage.transparent_bg = false
	get_root().add_child(stage)
	stage.add_child(content)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)

	for i in range(8):
		await get_root().get_tree().process_frame
	await create_timer(0.4).timeout
	for i in range(4):
		await get_root().get_tree().process_frame

	var card_list: Node = content.find_child("CardList", true, false)
	if card_list == null:
		push_error("CardList not found")
		quit(1)
		return

	var spine_entries: Dictionary = _load_spine_entries_by_id()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	var entries: Array = []
	var cards: Array = card_list.get_children().duplicate()

	for raw in cards:
		var card: PanelContainer = raw as PanelContainer
		if card == null:
			continue

		var sequence_id: String = _find_sequence_id_for_card(card, spine_entries)
		if sequence_id == "":
			continue

		var card_vp: SubViewport = SubViewport.new()
		card_vp.size = CARD_SIZE
		card_vp.own_world_3d = false
		card_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		card_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		card_vp.transparent_bg = false
		get_root().add_child(card_vp)

		var bg := ColorRect.new()
		bg.color = Color(0.055, 0.055, 0.070)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_vp.add_child(bg)

		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 24)
		margin.add_theme_constant_override("margin_right", 24)
		margin.add_theme_constant_override("margin_top", 16)
		margin.add_theme_constant_override("margin_bottom", 16)
		card_vp.add_child(margin)

		card.get_parent().remove_child(card)
		margin.add_child(card)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL

		await get_root().get_tree().process_frame
		await get_root().get_tree().process_frame
		await create_timer(0.10).timeout
		await get_root().get_tree().process_frame

		var img: Image = card_vp.get_texture().get_image()
		img.save_png("%s/%s.png" % [_output_dir, sequence_id])

		var spine_entry: Dictionary = spine_entries.get(sequence_id, {})
		var phase_name: String = String(spine_entry.get("phase", ""))
		var sidecar: Dictionary = {
			"id": sequence_id,
			"label": _format_name(sequence_id),
			"phase": phase_name,
			"phase_hex": PHASE_HEX.get(phase_name, "#888888"),
			"qfep_role": String(spine_entry.get("qfep_role", "")),
			"description": String(spine_entry.get("description", "")),
			"map_count": int(spine_entry.get("map_count", 0)),
			"order": float(spine_entry.get("order", 0)),
			"image": "%s/%s.png" % [PUBLIC_BASE, sequence_id],
		}
		var sf := FileAccess.open("%s/%s.json" % [_output_dir, sequence_id], FileAccess.WRITE)
		sf.store_string(JSON.stringify(sidecar, "\t"))
		sf.close()

		entries.append(sidecar)
		print("[%s] saved (%s)" % [sequence_id, phase_name])

		card_vp.queue_free()
		await get_root().get_tree().process_frame

	entries.sort_custom(func(a, b): return float(a.get("order", 0.0)) < float(b.get("order", 0.0)))

	var manifest := {
		"version": 1,
		"slug": "sequence-cards-gallery",
		"description": "Each of the 22 spine sequences as a picker card — sequence number, name, qfep_role, phase colour, map count, and a procedural Portal-2-style chamber glyph drawn live in GDScript. Same SequenceGlyph Control is used in the main-menu sequence picker; this gallery publishes the catalog so all 22 chamber icons are browsable side-by-side.",
		"capture_size": [CARD_SIZE.x, CARD_SIZE.y],
		"phase_colors": PHASE_HEX,
		"entries": entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d cards saved" % entries.size())
	quit(0)


func _load_spine_entries_by_id() -> Dictionary:
	var out: Dictionary = {}
	var raw: String = FileAccess.get_file_as_string(SPINE_PATH)
	if raw.is_empty():
		return out
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return out
	var spine: Dictionary = parsed.get("spine", {})
	var seqs: Array = spine.get("sequences", [])
	for s in seqs:
		if not (s is Dictionary):
			continue
		var name_id: String = String(s.get("name", ""))
		if name_id == "":
			continue
		var entry: Dictionary = {
			"id": name_id,
			"order": s.get("order", 0),
			"phase": String(s.get("phase", "")),
			"qfep_role": String(s.get("qfep_role", "")),
			"display_name": _format_name(name_id),
		}
		var meta: Dictionary = _load_sequence_meta(name_id)
		entry["description"] = meta.get("description", "")
		entry["map_count"] = meta.get("map_count", 0)
		out[name_id] = entry
	return out


func _load_sequence_meta(sequence_id: String) -> Dictionary:
	var path: String = SEQUENCES_DIR + sequence_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var raw: String = FileAccess.get_file_as_string(path)
	if raw.is_empty():
		return {}
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return {}
	var sequences: Dictionary = parsed.get("sequences", parsed)
	if not (sequences is Dictionary):
		return {}
	var seq: Dictionary = sequences.get(sequence_id, {})
	if not (seq is Dictionary):
		return {}
	var maps_field = seq.get("maps", seq.get("content", []))
	var map_count: int = maps_field.size() if maps_field is Array else 0
	return {
		"description": seq.get("description", ""),
		"map_count": map_count,
	}


func _format_name(raw: String) -> String:
	var out := ""
	var capitalize_next := true
	for i in range(raw.length()):
		var c: String = raw[i]
		if c == "_":
			out += " "
			capitalize_next = true
			continue
		if capitalize_next:
			out += c.to_upper()
			capitalize_next = false
		else:
			out += c
	return out


func _find_sequence_id_for_card(card: PanelContainer, spine_by_id: Dictionary) -> String:
	var labels: Array = []
	_collect_labels(card, labels)
	if labels.is_empty():
		return ""
	var first_text: String = String(labels[0].text)
	var parts: PackedStringArray = first_text.split("·")
	if parts.size() < 2:
		return ""
	var display: String = parts[1].strip_edges()
	for sid in spine_by_id.keys():
		if String(spine_by_id[sid].get("display_name", "")) == display:
			return sid
	return ""


func _collect_labels(n: Node, out: Array) -> void:
	if n is Label:
		out.append(n)
	for c in n.get_children():
		_collect_labels(c, out)
