extends PanelContainer
class_name WHPalette
## ALL-PROPS palette for the wall-hangar editor.
##
## Scans every res://commons/artifacts/registry/*.json on _ready(), collects each
## artifact that has a `scene`, and presents them as a filterable, scrolling list:
##   · a SEARCH box      — live case-insensitive substring over lookup_name / name / category
##   · a CATEGORY dropdown — "All" + every distinct category, narrows the list further
##   · a list of buttons — one per artifact, showing its display name (falls back to lookup_name)
##
## Emits `picked(lookup_name)` when an item is clicked. The host docks this on the left,
## calls set_wall_tokens([...]) to mark which lookup_names mount on the wall (◰) vs floor (▣),
## and connects `picked` to its own stamp handler.
##
## Self-contained: owns its own colours / styleboxes, depends on no other new file.

signal picked(lookup_name: String)

const REGISTRY_DIR := "res://commons/artifacts/registry/"
const PANEL_WIDTH := 320.0

const C_BG := Color(0.11, 0.12, 0.15, 0.97)
const C_TEXT := Color(0.87, 0.88, 0.90)
const C_ACCENT := Color(0.86, 0.40, 0.16)
const C_DIM := Color(0.58, 0.60, 0.64)
const C_ROW := Color(0.16, 0.17, 0.21, 1.0)
const C_ROW_HOVER := Color(0.22, 0.23, 0.28, 1.0)

# Every scene-bearing artifact found, as {lookup_name, name, scene, category}.
var _items: Array[Dictionary] = []
# lookup_name -> true for wall-mountable pieces (set via set_wall_tokens).
var _wall_tokens: Dictionary = {}

var _search: LineEdit = null
var _category: OptionButton = null
var _list: VBoxContainer = null
var _count_label: Label = null
var _title: Label = null
var _reg_only: Array = []      # if non-empty, show only these registries
var _reg_skip: Array = []      # always hide these registries
var _exclude_lookups: Dictionary = {}   # hide these specific lookup_names


func _ready() -> void:
	custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_panel_style()
	_scan_registries()
	_build_ui()
	_refresh_list()


# ── Public API ────────────────────────────────────────────────────────
## Remember which lookup_names mount on the wall. Marks them with "◰"; floor pieces get "▣".
## Pass an Array of String lookup-names. Default (never called) = everything reads as floor.
func set_wall_tokens(tokens: Array) -> void:
	_wall_tokens.clear()
	for t in tokens:
		_wall_tokens[str(t)] = true
	if _list != null:
		_refresh_list()


## How many scene-bearing artifacts were collected (after scanning).
func item_count() -> int:
	return _items.size()


## Restrict which registries appear: show only `only` (if non-empty) and always hide
## `skip`. Pass registry basenames, e.g. ["station","packaging","furniture"].
func set_registries(only: Array = [], skip: Array = []) -> void:
	_reg_only = []
	for r in only:
		_reg_only.append(str(r))
	_reg_skip = []
	for r in skip:
		_reg_skip.append(str(r))
	_rebuild_categories()
	_refresh_list()


## Set the panel heading (default "PROPS").
func set_title(t: String) -> void:
	if _title != null:
		_title.text = t


## Hide specific lookup_names (e.g. the DNA props that live in the bottom bar).
func set_exclude_lookups(lookups: Array) -> void:
	_exclude_lookups.clear()
	for l in lookups:
		_exclude_lookups[str(l)] = true
	_rebuild_categories()
	_refresh_list()


func _passes_registry(it: Dictionary) -> bool:
	if _exclude_lookups.has(str(it.get("lookup_name", ""))):
		return false
	var reg := str(it.get("registry", ""))
	if _reg_skip.has(reg):
		return false
	if not _reg_only.is_empty() and not _reg_only.has(reg):
		return false
	return true


func _rebuild_categories() -> void:
	if _category == null:
		return
	_category.clear()
	_category.add_item("All", 0)
	var seen: Dictionary = {}
	for it in _items:
		if _passes_registry(it):
			seen[str(it["category"])] = true
	var cats := seen.keys()
	cats.sort()
	for cat in cats:
		_category.add_item(str(cat))


# ── Scan ──────────────────────────────────────────────────────────────
func _scan_registries() -> void:
	_items.clear()
	var seen: Dictionary = {}            # lookup_name -> true, de-dupe across files
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir == null:
		push_warning("WHPalette: cannot open %s" % REGISTRY_DIR)
		return
	var names := dir.get_files()
	names.sort()
	for fname in names:
		if not fname.to_lower().ends_with(".json"):
			continue
		var text := FileAccess.get_file_as_string(REGISTRY_DIR + fname)
		if text == "":
			continue
		var parsed: Variant = JSON.parse_string(text)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = parsed
		var file_category := str(data.get("category", ""))
		# Two shapes: entries nested under "artifacts", or keyed at the root.
		var entries: Dictionary = {}
		var nested: Variant = data.get("artifacts")
		if typeof(nested) == TYPE_DICTIONARY:
			entries = nested
		else:
			entries = data
		for key in entries.keys():
			var entry: Variant = entries[key]
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var rec: Dictionary = entry
			var scene := str(rec.get("scene", ""))
			if scene == "":
				continue                 # skip entries with no scene
			var lookup := str(rec.get("lookup_name", key))
			if seen.has(lookup):
				continue
			seen[lookup] = true
			var disp := str(rec.get("name", ""))
			if disp == "":
				disp = lookup
			var cat := str(rec.get("category", ""))
			if cat == "" or cat == "unknown":
				cat = file_category if file_category != "" else "uncategorized"
			_items.append({
				"lookup_name": lookup,
				"name": disp,
				"scene": scene,
				"category": cat,
				"registry": fname.get_basename(),
			})
	_items.sort_custom(func(a, b): return str(a["name"]).naturalnocasecmp_to(str(b["name"])) < 0)


func _distinct_categories() -> Array[String]:
	var seen: Dictionary = {}
	for it in _items:
		seen[str(it["category"])] = true
	var out: Array[String] = []
	for k in seen.keys():
		out.append(str(k))
	out.sort()
	return out


# ── UI ────────────────────────────────────────────────────────────────
func _apply_panel_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_BG
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	sb.border_color = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.35)
	sb.border_width_left = 2
	add_theme_stylebox_override("panel", sb)


func _build_ui() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(col)

	var title := Label.new()
	title.text = "PROPS"
	title.add_theme_color_override("font_color", C_ACCENT)
	title.add_theme_font_size_override("font_size", 14)
	_title = title
	col.add_child(title)

	_search = LineEdit.new()
	_search.placeholder_text = "filter…"
	_search.clear_button_enabled = true
	_search.add_theme_color_override("font_color", C_TEXT)
	_search.add_theme_color_override("font_placeholder_color", C_DIM)
	_search.text_changed.connect(_on_filter_changed)
	col.add_child(_search)

	_category = OptionButton.new()
	_category.add_item("All", 0)
	for cat in _distinct_categories():
		_category.add_item(cat)
	_category.item_selected.connect(_on_category_selected)
	col.add_child(_category)

	_count_label = Label.new()
	_count_label.add_theme_color_override("font_color", C_DIM)
	_count_label.add_theme_font_size_override("font_size", 11)
	col.add_child(_count_label)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0.0, 360.0)
	col.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


func _on_filter_changed(_text: String) -> void:
	_refresh_list()


func _on_category_selected(_idx: int) -> void:
	_refresh_list()


func _selected_category() -> String:
	if _category == null or _category.get_selected_id() == 0:
		return ""
	return _category.get_item_text(_category.get_selected())


func _refresh_list() -> void:
	if _list == null:
		return
	for c in _list.get_children():
		c.queue_free()
	var needle := ("" if _search == null else _search.text).strip_edges().to_lower()
	var cat_filter := _selected_category()
	var shown := 0
	var total := 0
	for it in _items:
		if not _passes_registry(it):
			continue
		total += 1
		var cat := str(it["category"])
		if cat_filter != "" and cat != cat_filter:
			continue
		if needle != "":
			var hay := (str(it["lookup_name"]) + " " + str(it["name"]) + " " + cat).to_lower()
			if not hay.contains(needle):
				continue
		_list.add_child(_make_row(it))
		shown += 1
	if _count_label != null:
		_count_label.text = "%d / %d" % [shown, total]


func _make_row(it: Dictionary) -> Button:
	var lookup := str(it["lookup_name"])
	var is_wall: bool = _wall_tokens.has(lookup)
	var b := Button.new()
	b.text = ("◰ " if is_wall else "▣ ") + str(it["name"])
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.tooltip_text = "%s\n%s\n%s" % [lookup, str(it["category"]), str(it["scene"])]
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0.0, 26.0)
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", C_ACCENT)
	b.add_theme_font_size_override("font_size", 12)
	var normal := StyleBoxFlat.new()
	normal.bg_color = C_ROW
	normal.set_corner_radius_all(3)
	normal.content_margin_left = 8
	normal.content_margin_right = 6
	normal.content_margin_top = 3
	normal.content_margin_bottom = 3
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = C_ROW_HOVER
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func(): picked.emit(lookup))
	return b
