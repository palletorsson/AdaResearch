extends Node

## LayerToggleOverlay -- debug visibility toggles for the spine runner.
##
## Shortcuts:
##   F1 = structure (floor/wall blocks)
##   F2 = utilities (teleporters, spawns, ceilings, pipes)
##   F3 = interactables (artifacts)
##   F4 = biome / ambient (nature, critters)
##   F5 = highlight structure (emissive override, reveals invisible blocks)
##
## Attach as a child of SpineRunner (or any node in the scene) and the overlay
## will find the runner's slots automatically.

@export var runner_path: NodePath

var _runner: Node = null
var _show := {
	"structure":    true,
	"utilities":    true,
	"interactables":true,
	"biome":        false,
}
var _highlight_structure := false
var _hud_canvas: CanvasLayer
var _hud_label: Label


func _ready() -> void:
	_runner = get_node_or_null(runner_path) if not runner_path.is_empty() else null
	if _runner == null:
		_runner = get_parent().find_child("SpineRunner", true, false)
	if _runner == null:
		push_warning("LayerToggleOverlay: no SpineRunner found")
	_hud_canvas = CanvasLayer.new()
	_hud_canvas.layer = 101
	add_child(_hud_canvas)
	_hud_label = Label.new()
	_hud_label.position = Vector2(12, 180)
	_hud_label.size = Vector2(360, 160)
	_hud_label.add_theme_font_size_override("font_size", 12)
	_hud_label.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.82)
	style.border_color = Color(0.35, 0.42, 0.55, 0.6)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_hud_label.add_theme_stylebox_override("normal", style)
	_hud_canvas.add_child(_hud_label)
	_refresh_label()
	# Periodically re-apply in case new slots spawn (seam fires)
	var tm := Timer.new()
	tm.wait_time = 0.5
	tm.autostart = true
	tm.timeout.connect(_apply_all)
	add_child(tm)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F1: _toggle("structure")
		KEY_F2: _toggle("utilities")
		KEY_F3: _toggle("interactables")
		KEY_F4: _toggle("biome")
		KEY_F5:
			_highlight_structure = not _highlight_structure
			_apply_structure_highlight()
			_refresh_label()


func _toggle(layer: String) -> void:
	_show[layer] = not _show[layer]
	_apply_all()
	_refresh_label()


func _apply_all() -> void:
	if _runner == null:
		_runner = get_parent().find_child("SpineRunner", true, false)
		if _runner == null: return
	var counts := {"structure": 0, "utilities": 0, "interactables": 0, "biome": 0, "unknown": 0}
	for slot in _runner.get_children():
		if not (slot is Node3D): continue
		_walk(slot, counts, 0)
	_refresh_label(counts)


func _walk(node: Node, counts: Dictionary, depth: int) -> void:
	if depth > 3:   # don't go arbitrarily deep into artifacts
		return
	for child in node.get_children():
		var cat := _categorize(child)
		if cat != "":
			counts[cat] = counts.get(cat, 0) + 1
			if "visible" in child:
				child.visible = _show.get(cat, true)
		# Descend into containers we recognize but not into leaf artifacts
		if cat in ["", "structure", "utilities", "biome"]:
			_walk(child, counts, depth + 1)


func _categorize(node: Node) -> String:
	var n := node.name.to_lower()
	if n.contains("gridcollision") or n.contains("gridmultimesh") or n.contains("structure") \
	   or n.contains("ceiling") or n.contains("wall"):
		return "structure"
	if n.contains("pipe") or n.contains("teleport") or n.contains("spawnmark") or n.contains("spawn_marker") \
	   or n.contains("utility") or n.contains("utilities") or n.contains("label3d"):
		return "utilities"
	if n.contains("biome") or n.contains("critter") or n.contains("nature") or n.contains("ecosystem"):
		return "biome"
	# Nodes inside InteractablesContainer are artifacts
	if node is Node3D:
		return "interactables"
	return ""


func _apply_structure_highlight() -> void:
	if _runner == null: return
	for slot in _runner.get_children():
		if not (slot is Node3D): continue
		for mmi in _find_by_name_contains(slot, "gridmultimesh"):
			if mmi is MultiMeshInstance3D:
				if _highlight_structure:
					var mat := StandardMaterial3D.new()
					mat.albedo_color = Color(0.4, 0.9, 1.0)
					mat.emission_enabled = true
					mat.emission = Color(0.2, 0.5, 0.8)
					mat.emission_energy_multiplier = 1.5
					mmi.material_override = mat
				else:
					mmi.material_override = null


func _find_by_name_contains(node: Node, substr: String, out: Array = []) -> Array:
	for child in node.get_children():
		if child.name.to_lower().contains(substr):
			out.append(child)
		_find_by_name_contains(child, substr, out)
	return out


func _refresh_label(counts: Dictionary = {}) -> void:
	var lines: Array = []
	lines.append("LAYERS (F1-F5 to toggle)")
	lines.append("─────────────────────────────")
	var fmt = func(k: String, label: String) -> String:
		var state := "on " if _show.get(k, true) else "OFF"
		var c: int = int(counts.get(k, -1))
		var c_str := ("  [%d]" % c) if c >= 0 else ""
		return "  F%s %s  %s%s" % [_key_for(k), label, state, c_str]
	lines.append(fmt.call("structure",    "structure      "))
	lines.append(fmt.call("utilities",    "utilities      "))
	lines.append(fmt.call("interactables","interactables  "))
	lines.append(fmt.call("biome",        "biome          "))
	lines.append("  F5 highlight struct: " + ("ON " if _highlight_structure else "off"))
	_hud_label.text = "\n".join(lines)


func _key_for(k: String) -> String:
	return {"structure":"1","utilities":"2","interactables":"3","biome":"4"}.get(k, "?")
