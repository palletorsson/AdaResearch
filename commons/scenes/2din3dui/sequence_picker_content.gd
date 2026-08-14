extends Control

## Sequence picker 2D content — rendered via Viewport2Din3D.
## Reads the spine from commons/maps/curriculum_spine.json and builds one
## info card per sequence. Each card has a Play button that emits
## sequence_play_requested(sequence_name); the surrounding 3D wrapper
## bubbles the signal up so MainMenu can call SceneManager.start_sequence.

signal sequence_play_requested(sequence_name: String)
signal back_requested

const SPINE_PATH: String = "res://commons/maps/curriculum_spine.json"
const SEQUENCES_DIR: String = "res://commons/maps/sequences/"
const GLYPH_SCRIPT: GDScript = preload("res://commons/scenes/2din3dui/sequence_glyph.gd")

const PHASE_COLORS: Dictionary = {
	"F_order":      Color(0.227, 0.482, 1.000),
	"oscillation":  Color(0.490, 1.000, 0.659),
	"E_entropy":    Color(0.957, 0.635, 0.380),
	"lambda_edge":  Color(0.902, 0.224, 0.275),
	"integration":  Color(0.608, 0.365, 0.890),
	"relation":     Color(0.984, 0.890, 0.541),
	"synthesis":    Color(1.000, 1.000, 1.000),
}

@onready var _list: VBoxContainer = $Margin/Layout/Scroll/CardList
@onready var _title: Label = $Margin/Layout/Header/Title
@onready var _subtitle: Label = $Margin/Layout/Header/Subtitle
@onready var _back_btn: Button = $Margin/Layout/Footer/BackButton


func _ready() -> void:
	if _back_btn:
		_back_btn.pressed.connect(_on_back_pressed)
	_populate()


func _populate() -> void:
	for c in _list.get_children():
		c.queue_free()

	var entries: Array = _load_spine_sequences()
	if _subtitle:
		_subtitle.text = "%d sequences in the spine" % entries.size()

	# The endless museum — not a spine sequence but the negotiated building
	# that hosts all of them, pinned above the list. Gated on the staged
	# scene existing so a build without the museum shows the picker
	# exactly as before. MainMenu3D routes this id straight to
	# staging.load_scene rather than SceneManager.start_sequence.
	if ResourceLoader.exists("res://commons/scenes/endless_museum_staged.tscn"):
		_list.add_child(_build_card({
			"id": "endless_museum",
			"order": "∞",
			"phase": "",
			"qfep_role": "every sequence, one continuous building",
			"display_name": "Endless Museum",
			"description": "walk the whole spine as architecture",
			"map_count": 0,
		}))

	for entry in entries:
		var card := _build_card(entry)
		_list.add_child(card)


# ── Loading ───────────────────────────────────────────────────────────

func _load_spine_sequences() -> Array:
	var entries: Array = []
	var raw: String = FileAccess.get_file_as_string(SPINE_PATH)
	if raw.is_empty():
		push_warning("SequencePicker: curriculum_spine.json not readable")
		return entries
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("SequencePicker: spine parse failed")
		return entries
	var spine: Dictionary = parsed.get("spine", {})
	var sequences: Array = spine.get("sequences", [])
	for s in sequences:
		if not (s is Dictionary):
			continue
		var name_id: String = String(s.get("name", ""))
		if name_id == "":
			continue
		var meta: Dictionary = _load_sequence_meta(name_id)
		entries.append({
			"id": name_id,
			"order": s.get("order", 0),
			"phase": String(s.get("phase", "")),
			"qfep_role": String(s.get("qfep_role", "")),
			"display_name": _format_name(name_id),
			"description": String(meta.get("description", "")),
			"map_count": int(meta.get("map_count", 0)),
		})
	# Sort by spine order (numeric or float)
	entries.sort_custom(func(a, b): return float(a.get("order", 0.0)) < float(b.get("order", 0.0)))
	return entries


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
	# Sequence files use either {"sequences": {id: {...}}} or {id: {...}}
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


# ── Card construction ─────────────────────────────────────────────────

func _build_card(entry: Dictionary) -> PanelContainer:
	var phase: String = String(entry.get("phase", ""))
	var color: Color = PHASE_COLORS.get(phase, Color(0.55, 0.58, 0.65))

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 110)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.10, 0.12, 1.0)
	bg.border_color = color
	bg.border_width_left = 6
	bg.border_width_top = 0
	bg.border_width_right = 0
	bg.border_width_bottom = 0
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	bg.content_margin_left = 14
	bg.content_margin_right = 12
	bg.content_margin_top = 10
	bg.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", bg)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	# ── Left: sequence glyph (Portal-2-style chamber icon) ────────
	var glyph: Control = Control.new()
	glyph.set_script(GLYPH_SCRIPT)
	glyph.set("sequence_id", String(entry.get("id", "")))
	glyph.set("phase_color", color)
	glyph.custom_minimum_size = Vector2(90, 90)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(glyph)

	# ── Middle column: text ───────────────────────────────────────
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)

	var order_text: String = "%s" % str(entry.get("order", ""))
	var name_label := Label.new()
	name_label.text = "%s  ·  %s" % [order_text, String(entry.get("display_name", ""))]
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.97))
	col.add_child(name_label)

	var role_label := Label.new()
	var role_text: String = String(entry.get("qfep_role", ""))
	if role_text == "":
		role_text = String(entry.get("description", ""))
	role_label.text = role_text
	role_label.add_theme_font_size_override("font_size", 13)
	role_label.add_theme_color_override("font_color", Color(0.72, 0.74, 0.80))
	role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(role_label)

	var meta_label := Label.new()
	var map_count: int = int(entry.get("map_count", 0))
	var maps_text: String = "%d map%s" % [map_count, ("s" if map_count != 1 else "")]
	meta_label.text = "phase: %s  ·  %s" % [phase, maps_text]
	meta_label.add_theme_font_size_override("font_size", 11)
	meta_label.add_theme_color_override("font_color", color)
	col.add_child(meta_label)

	# ── Right column: play button ──────────────────────────────────
	var play := Button.new()
	play.text = "▶  PLAY"
	play.custom_minimum_size = Vector2(90, 60)
	play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	play.add_theme_font_size_override("font_size", 16)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = color
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.content_margin_left = 12
	btn_style.content_margin_right = 12
	btn_style.content_margin_top = 6
	btn_style.content_margin_bottom = 6
	play.add_theme_stylebox_override("normal", btn_style)
	var btn_hover := btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = color.lightened(0.15)
	play.add_theme_stylebox_override("hover", btn_hover)
	var btn_pressed := btn_style.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = color.darkened(0.15)
	play.add_theme_stylebox_override("pressed", btn_pressed)
	play.add_theme_color_override("font_color", Color(0.06, 0.06, 0.08))
	play.add_theme_color_override("font_hover_color", Color(0.06, 0.06, 0.08))
	row.add_child(play)

	var seq_id: String = String(entry.get("id", ""))
	play.pressed.connect(func(): _on_play_pressed(seq_id))

	return card


# ── Helpers ───────────────────────────────────────────────────────────

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


# ── Signals ───────────────────────────────────────────────────────────

func _on_play_pressed(sequence_name: String) -> void:
	print("SequencePicker: play %s" % sequence_name)
	sequence_play_requested.emit(sequence_name)


func _on_back_pressed() -> void:
	back_requested.emit()
