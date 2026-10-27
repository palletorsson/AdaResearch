extends Control
## Shared prefab library. Desktop uses pictures; the world board uses dense labels.
## Stable catalogue IDs carry configurations through the bridge, never parsed labels.
signal spawn_requested(token: String, is_prop: bool)
signal remove_last_requested()
signal close_requested()

const SPAWNLISTS := "res://commons/data/void_spawnlists.json"
const BRIDGE := "http://127.0.0.1:8772"
const PAGE := 192
var label_mode := false
var _board_style := false
var _background: StyleBoxFlat
var _data: Dictionary = {}
var _items: Dictionary = {}
var _tree: Tree
var _search: LineEdit
var _title: Label
var _grid: GridContainer
var _status: Label
var _scroll: ScrollContainer
var _detail: Label
var _place: Button
var _favorite: Button
var _view: Button
var _tokens: Array = []
var _shown := 0
var _selected := ""
var _favorites: Array = []
var _recent: Array = []
var _thumbs: Dictionary = {}
var _thumb_queue: Array = []
var _http: HTTPRequest
var _http_busy := false
var _public_dir := ""

func _ready() -> void:
	_public_dir = ProjectSettings.globalize_path("res://").path_join("../ada_encyclopedia/public")
	if not DirAccess.dir_exists_absolute(_public_dir):
		_public_dir = ""
	var prefs := ConfigFile.new()
	if prefs.load("user://prefab-library.cfg") == OK:
		_favorites = prefs.get_value("library", "favorites", [])
		_recent = prefs.get_value("library", "recent", [])
	_build()
	_load_data()

func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 42
	b.pressed.connect(action)
	return b

func _build() -> void:
	var theme := Theme.new()
	theme.default_font_size = 19
	self.theme = theme
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	_background = style
	style.bg_color = Color("18242b")
	style.set_corner_radius_all(10)
	style.set_content_margin_all(20)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	bg.add_child(body)
	var top := HBoxContainer.new()
	body.add_child(top)
	var brand := Label.new()
	brand.text = "ADA / PREFABS"
	brand.add_theme_font_size_override("font_size", 26)
	top.add_child(brand)
	_search = LineEdit.new()
	_search.placeholder_text = "Search names, variants, materials…"
	_search.size_flags_horizontal = SIZE_EXPAND_FILL
	_search.text_changed.connect(_on_search)
	top.add_child(_search)
	_view = _button("Labels", func(): set_label_mode(not label_mode))
	top.add_child(_view)
	top.add_child(_button("Close", func(): close_requested.emit()))
	var main := HBoxContainer.new()
	main.size_flags_vertical = SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 16)
	body.add_child(main)
	_tree = Tree.new()
	_tree.hide_root = true
	_tree.custom_minimum_size.x = 235
	_tree.size_flags_vertical = SIZE_EXPAND_FILL
	_tree.item_selected.connect(_on_tree_selected)
	main.add_child(_tree)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	main.add_child(right)
	_title = Label.new()
	right.add_child(_title)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.get_v_scroll_bar().value_changed.connect(func(_v):
		var bar := _scroll.get_v_scroll_bar()
		if bar.value + bar.page >= bar.max_value - 150: _append_page())
	right.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_scroll.add_child(_grid)
	_scroll.resized.connect(_resize_grid)
	var nav := HBoxContainer.new()
	right.add_child(nav)
	nav.add_child(_button("↑ Scroll up", func(): _scroll.scroll_vertical -= int(_scroll.size.y * 0.8)))
	nav.add_child(_button("↓ Scroll down", func():
		_append_page()
		_scroll.scroll_vertical += int(_scroll.size.y * 0.8)))
	_detail = Label.new()
	_detail.text = "Choose a prefab to see its full name and prepare placement."
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size.y = 48
	body.add_child(_detail)
	var actions := HBoxContainer.new()
	body.add_child(actions)
	_place = _button("Place selected →", _place_selected)
	_place.disabled = true
	actions.add_child(_place)
	_favorite = _button("☆ Favourite", _toggle_favorite)
	_favorite.disabled = true
	actions.add_child(_favorite)
	_status = Label.new()
	_status.size_flags_horizontal = SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 16)
	actions.add_child(_status)
	set_label_mode(label_mode)

## Quiet enamel-board palette; dense labels retain their family-colour edge.
func set_board_style() -> void:
	_board_style = true
	_background.bg_color = Color("e4e4db")
	_background.set_corner_radius_all(0)
	for type in ["Label", "Button", "LineEdit", "Tree"]:
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_selected_color"]:
			theme.set_color(key, type, Color("26312d"))
		theme.set_color("font_disabled_color", type, Color("747b74"))
	for type in ["Button", "LineEdit", "Tree"]:
		for state in ["normal", "panel", "hover", "pressed", "focus", "selected", "selected_focus", "disabled"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("c5d5ca") if state in ["hover", "selected", "selected_focus", "pressed"] else Color("f0f0e8")
			style.set_content_margin_all(10)
			if state == "focus":
				style.bg_color = Color(0, 0, 0, 0)
				style.set_border_width_all(2)
				style.border_color = Color("be582e")
			theme.set_stylebox(state, type, style)
	theme.set_color("font_placeholder_color", "LineEdit", Color("647069"))
	theme.set_color("guide_color", "Tree", Color("979e92"))

func set_label_mode(value: bool) -> void:
	label_mode = value
	if _grid == null: return
	_view.text = "Pictures" if label_mode else "Labels"
	_resize_grid()
	_show_items(_tokens, _title.text)

func _resize_grid() -> void:
	_grid.columns = maxi(1, int(_scroll.size.x / (235.0 if label_mode else 180.0)))

func set_status(text: String) -> void:
	if _status != null: _status.text = text

func _load_data() -> void:
	if FileAccess.file_exists(SPAWNLISTS):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPAWNLISTS))
		if d is Dictionary:
			_take_data(d)
			return
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_r, code, _h, body):
		req.queue_free()
		var d: Variant = JSON.parse_string(body.get_string_from_utf8()) if code == 200 else null
		if d is Dictionary: _take_data(d)
		else: set_status("Library unavailable. Connect the live bridge and retry."))
	req.request(BRIDGE + "/spawnlists")

func _tree_node(parent: TreeItem, title: String, tokens: Array) -> TreeItem:
	var n := _tree.create_item(parent)
	n.set_text(0, "%s · %d" % [title, tokens.size()])
	n.set_metadata(0, {"items": tokens, "title": title})
	return n

func _take_data(d: Dictionary) -> void:
	_data = d
	_items = d.get("items", {})
	_tree.clear()
	var root := _tree.create_item()
	_tree_node(root, "All prefabs", _items.keys())
	_tree_node(root, "Favourites", _favorites)
	_tree_node(root, "Recent", _recent)
	var kit: Array = _items.keys().filter(func(k): return str(k).begins_with("kit:"))
	var first := _tree_node(root, "Construction kit", kit)
	var families: Dictionary = {}
	for key in _items:
		var family: String = str(_items[key].get("family", "Studies"))
		if not families.has(family): families[family] = []
		families[family].append(key)
	var family_root := _tree_node(root, "Families", _items.keys())
	family_root.collapsed = true
	for family in families: _tree_node(family_root, family, families[family])
	for tree in d.get("trees", []):
		for seq in tree.get("children", []):
			var si := _tree_node(root, str(seq.get("title", seq.id)), seq.get("items", []))
			si.collapsed = true
			for m in seq.get("children", []): _tree_node(si, str(m.get("label", m.id)), m.get("items", []))
	first.select(0)
	_show_items(kit, "Construction kit")
	set_status("%d prefabs · select, aim, place · placed objects stay" % _items.size())

func _on_tree_selected() -> void:
	var it := _tree.get_selected()
	if it == null: return
	_search.set_block_signals(true)
	_search.text = ""
	_search.set_block_signals(false)
	var meta: Dictionary = it.get_metadata(0)
	var tokens: Array = meta.items
	if meta.title == "Favourites": tokens = _favorites
	if meta.title == "Recent": tokens = _recent
	_show_items(tokens, meta.title)

func _on_search(text: String) -> void:
	var q := text.strip_edges().to_lower()
	if q.is_empty():
		_on_tree_selected()
		return
	var hits: Array = []
	for key in _items:
		var it: Dictionary = _items[key]
		var haystack := (str(key) + " " + str(it.get("short_label", "")) + " " + str(it.get("label", "")) + " " + str(it.get("family", "")) + " " + str(it.get("description", ""))).to_lower()
		var matches := true
		for word in q.split(" ", false):
			if not haystack.contains(word): matches = false
		if matches: hits.append(key)
	_show_items(hits, "Search: " + text)

func _show_items(tokens: Array, title: String) -> void:
	_tokens = tokens.duplicate()
	_title.text = title
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	_thumb_queue.clear()
	_shown = 0
	_append_page()
	_scroll.scroll_vertical = 0

func _append_page() -> void:
	var end := mini(_shown + PAGE, _tokens.size())
	while _shown < end:
		var key := str(_tokens[_shown])
		_shown += 1
		if not _items.has(key): continue
		var it: Dictionary = _items[key]
		var b := Button.new()
		b.name = "Prefab_" + str(_shown)
		b.custom_minimum_size = Vector2(225, 54) if label_mode else Vector2(170, 150)
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.text = str(it.get("short_label", key)) if label_mode else str(it.get("label", key))
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 20 if label_mode else 16)
		b.tooltip_text = str(it.get("label", key)) + "\n" + str(it.get("description", ""))
		var color := Color(str(it.get("color", "#80c9b4")))
		for state in ["normal", "hover", "focus", "pressed"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("eeeee6").lerp(color, 0.08 if state == "normal" else 0.28) if _board_style else color.darkened(0.72 if state == "normal" else 0.5)
			style.border_color = color
			style.border_width_left = 4
			style.set_content_margin_all(10)
			style.set_corner_radius_all(4)
			b.add_theme_stylebox_override(state, style)
		b.pressed.connect(func(): _select(key))
		_grid.add_child(b)
		if not label_mode:
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			b.expand_icon = true
			var url := str(it.get("thumbnail") if it.get("thumbnail") != null else "")
			if not url.is_empty(): _want_thumb(url, b)

func _select(key: String) -> void:
	_selected = key
	var it: Dictionary = _items[key]
	_detail.text = "%s  /  %s\n%s" % [str(it.get("short_label", key)), str(it.get("label", key)), str(it.get("description", ""))]
	_place.disabled = false
	_favorite.disabled = false
	_favorite.text = "★ Favourite" if key in _favorites else "☆ Favourite"

func _save_preferences() -> void:
	var prefs := ConfigFile.new()
	prefs.set_value("library", "favorites", _favorites)
	prefs.set_value("library", "recent", _recent)
	prefs.save("user://prefab-library.cfg")

func _toggle_favorite() -> void:
	if _selected in _favorites: _favorites.erase(_selected)
	else: _favorites.append(_selected)
	_save_preferences()
	_select(_selected)

func _place_selected() -> void:
	if _selected.is_empty(): return
	_recent.erase(_selected)
	_recent.push_front(_selected)
	if _recent.size() > 30: _recent.resize(30)
	_save_preferences()
	spawn_requested.emit(_selected, false)

func _want_thumb(url: String, b: Button) -> void:
	if _thumbs.has(url):
		b.icon = _thumbs[url]
		return
	if _public_dir != "":
		var path: String = _public_dir.path_join(url.lstrip("/"))
		if FileAccess.file_exists(path):
			var img := Image.load_from_file(path)
			if img != null:
				img.resize(160, int(160.0 * float(img.get_height()) / maxf(1.0, float(img.get_width()))))
				var tex := ImageTexture.create_from_image(img)
				_thumbs[url] = tex
				b.icon = tex
				return
	_thumb_queue.append([url, b])
	_pump_thumbs()


func _pump_thumbs() -> void:
	if _http_busy or _thumb_queue.is_empty():
		return
	if _http == null:
		_http = HTTPRequest.new()
		add_child(_http)
		_http.request_completed.connect(_on_thumb)
	var job: Array = _thumb_queue.pop_front()
	var url: String = job[0]
	_http.set_meta("job", job)
	_http_busy = _http.request(BRIDGE + "/prefab-thumb?url=" + url.uri_encode()) == OK
	if not _http_busy:
		_pump_thumbs()


func _on_thumb(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_http_busy = false
	var job: Variant = _http.get_meta("job", null)
	if code == 200 and job is Array:
		var img := Image.new()
		if img.load_png_from_buffer(body) == OK:
			img.resize(160, int(160.0 * float(img.get_height()) / maxf(1.0, float(img.get_width()))))
			var tex := ImageTexture.create_from_image(img)
			_thumbs[(job as Array)[0]] = tex
			var b: Variant = (job as Array)[1]
			if is_instance_valid(b) and b is Button:
				(b as Button).icon = tex
	_pump_thumbs()
