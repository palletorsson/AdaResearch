extends SceneTree
## VR biome-brush artifact picker — parse + logic verification (no GPU needed).
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_vr_artifact_picker.gd
## Confirms: the menu UI parses + exposes the picker contract (signal + refresh
## method + category data), and BiomeBrushController toggles artifacts into the
## active element's list and emits them in the paint payload.

const MenuUI = preload("res://commons/hazards/becoming_catalyst/biome_brush_menu_ui.gd")
const Brush = preload("res://commons/hazards/becoming_catalyst/BiomeBrushController.gd")
const Palette = preload("res://commons/biome_layers/artifact_palette.gd")

var _fails := 0
func _ok(c: bool, l: String) -> void:
	print(("  PASS  " if c else "  FAIL  ") + l)
	if not c: _fails += 1

func _initialize() -> void:
	# 1) Palette category helpers ------------------------------------------------
	var cats: Array = Palette.categories()
	_ok(cats.size() > 0, "palette exposes %d categories" % cats.size())
	var first_cat := str(cats[0]) if cats.size() > 0 else ""
	var names: Array = Palette.names_in_category(first_cat)
	_ok(names.size() > 0, "category '%s' has %d artifacts" % [first_cat, names.size()])
	if names.size() > 0:
		_ok(Palette.category_of(str(names[0])) == first_cat, "category_of round-trips for '%s'" % str(names[0]))

	# 2) Menu UI parses + exposes the picker contract ----------------------------
	var menu: Control = MenuUI.new()
	get_root().add_child(menu)
	await process_frame
	await process_frame
	_ok(menu.has_signal("artifact_toggle_requested"), "menu has artifact_toggle_requested signal")
	_ok(menu.has_method("refresh_artifact_marks"), "menu has refresh_artifact_marks()")
	# Drive the picker page: pick a known artifact name as selected, build grid.
	var pick := str(names[0]) if names.size() > 0 else ""
	menu.refresh_artifact_marks([pick])
	menu._cats = Palette.categories()
	menu._cat_idx = menu._cats.find(first_cat)
	menu._refresh_artifacts()
	var marked := false
	for b in menu._art_buttons:
		if str(b.text).begins_with("✓ "):
			marked = true
	_ok(marked or names.size() > Palette.names_in_category(first_cat).size(), "selected artifact shows a ✓ mark on its button")

	# 3) BiomeBrushController toggles into the active element's list --------------
	var brush: Node3D = Brush.new()
	get_root().add_child(brush)
	brush.set_element("object")
	_ok(brush.active_element() == "object", "brush active element = object")
	var lst: Array = brush.toggle_artifact("prefab_sculpture")
	_ok("prefab_sculpture" in lst, "toggle adds artifact to the active element list")
	_ok("prefab_sculpture" in brush.active_artifacts(), "active_artifacts() reflects the toggle")
	# Picked-but-unpainted element → payload still emits a scatter layer with arts.
	var payload: Array = brush.paint_layers_payload()
	var found := false
	for layer in payload:
		if layer is Dictionary and str(layer.get("element")) == "object":
			var a = layer.get("artifacts")
			if a is Array and "prefab_sculpture" in a:
				found = true
	_ok(found, "paint payload emits an object layer carrying the picked artifact")
	brush.toggle_artifact("prefab_sculpture")
	_ok(not ("prefab_sculpture" in brush.active_artifacts()), "toggling again removes it")

	print("RESULT: ", "OK" if _fails == 0 else "%d FAIL" % _fails)
	quit(_fails)
