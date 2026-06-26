extends Node3D
## In-world editor for the curation station — you WALK the bay (DesktopPlayer) and:
##   · TAB        open/close the menu (frees the mouse)
##   · PRESETS    rebuild the whole bay from a gene config (curation_station.apply_grid_config)
##   · PALETTE    click a station piece -> it spawns on the floor in front of you
##   · G          aim at a spawned piece + press G to carry it (follows where you look); G again drops
##   · X          aim at a spawned piece + press X to remove it
##   · WASD+mouse walk + look (the player)
##
## Non-invasive: added as a sibling of CurationStation + DesktopPlayer, touches neither.
## The composer owns the bay (edited via presets); pieces you add yourself are free-form
## (tagged `curation_editable`) and individually carry/remove-able.

const STATION := {
	"station_plinth": "res://commons/artifacts/station/station_plinth.tscn",
	"station_pillar": "res://commons/artifacts/station/station_pillar.tscn",
	"station_stage": "res://commons/artifacts/station/station_stage.tscn",
	"station_cabinet": "res://commons/artifacts/station/station_cabinet.tscn",
	"station_wall": "res://commons/artifacts/station/station_wall.tscn",
	"station_barrier": "res://commons/artifacts/station/station_barrier.tscn",
	"station_bench": "res://commons/artifacts/station/station_bench.tscn",
	"station_crates": "res://commons/artifacts/station/station_crates.tscn",
	"station_panel": "res://commons/artifacts/station/station_panel.tscn",
	"station_gantry": "res://commons/artifacts/station/station_gantry.tscn",
	"station_console_desk": "res://commons/artifacts/station/station_console_desk.tscn",
}

# Preset bays — gene configs handed to curation_station.apply_grid_config().
const PRESETS := {
	"Solo Pavilion": {"artifacts": ["point"], "with_wall": true, "with_pillars": true,
		"with_cabinets": false, "with_crates": false, "with_gantry": false, "with_console": false, "layout": "row"},
	"Console Wall": {"artifacts": ["ca_rule_explorer", "distribution_sampler"], "with_wall": true,
		"with_console": true, "with_pillars": true, "with_cabinets": false, "with_gantry": false, "layout": "row"},
	"Gantry Bench": {"artifacts": ["point", "ca_rule_explorer", "distribution_sampler"], "with_gantry": true,
		"with_wall": true, "with_pillars": false, "with_console": false, "with_cabinets": false, "layout": "row"},
	"Vitrine Alcove": {"artifacts": ["point", "ca_rule_explorer"], "with_cabinets": true, "with_wall": true,
		"with_pillars": true, "with_gantry": false, "with_console": false, "layout": "row"},
	"Two-Zone Corner": {"artifacts": ["point", "ca_rule_explorer", "distribution_sampler", "grid_3d_4x4x4"],
		"layout": "corner", "with_wall": true, "with_pillars": true, "with_cabinets": false, "with_console": false},
	"Open Lab": {"artifacts": ["point", "ca_rule_explorer", "", "distribution_sampler", "grid_3d_4x4x4"],
		"with_wall": false, "with_pillars": false, "with_barrier": false, "with_gantry": false, "with_console": false, "layout": "row"},
}

const C_PANEL := Color(0.11, 0.12, 0.15, 0.96)
const C_ACCENT := Color(0.86, 0.40, 0.16)
const C_TEXT := Color(0.87, 0.88, 0.90)

var _player: Node3D = null
var _camera: Camera3D = null
var _station: Node = null
var _container: Node3D = null      # holds free-form spawned pieces
var _carry: Node3D = null          # piece currently being carried
var _menu: PanelContainer = null
var _status: Label = null


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player_body")
	if _player and _player.has_node("Head/Camera3D"):
		_camera = _player.get_node("Head/Camera3D")
	_station = get_parent().get_node_or_null("CurationStation")
	_container = Node3D.new()
	_container.name = "FreeProps"
	add_child(_container)
	_build_ui()


# ── UI ────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# Always-on hint + status (top-left).
	var hint := Label.new()
	hint.position = Vector2(14, 10)
	hint.add_theme_color_override("font_color", C_TEXT)
	hint.add_theme_font_size_override("font_size", 13)
	hint.text = "TAB menu   ·   G carry / drop   ·   X remove   ·   WASD + mouse walk"
	layer.add_child(hint)
	_status = Label.new()
	_status.position = Vector2(14, 32)
	_status.add_theme_color_override("font_color", C_ACCENT)
	_status.add_theme_font_size_override("font_size", 12)
	layer.add_child(_status)

	# Menu panel (hidden until TAB).
	_menu = PanelContainer.new()
	_menu.visible = false
	_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_PANEL
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16)
	_menu.add_theme_stylebox_override("panel", sb)
	layer.add_child(_menu)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_menu.add_child(vb)

	vb.add_child(_heading("PRESET BAYS"))
	var prow := HFlowContainer.new()
	prow.add_theme_constant_override("h_separation", 6)
	prow.add_theme_constant_override("v_separation", 6)
	vb.add_child(prow)
	for name in PRESETS.keys():
		var b := Button.new()
		b.text = str(name)
		b.pressed.connect(_apply_preset.bind(str(name)))
		prow.add_child(b)

	vb.add_child(_sep())
	vb.add_child(_heading("ADD A PIECE  (spawns in front of you)"))
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.custom_minimum_size = Vector2(560, 0)
	vb.add_child(grid)
	for token in STATION.keys():
		var pb := Button.new()
		pb.text = str(token).replace("station_", "")
		pb.tooltip_text = str(token)
		pb.custom_minimum_size = Vector2(120, 34)
		pb.pressed.connect(_spawn.bind(str(token)))
		grid.add_child(pb)

	vb.add_child(_sep())
	var close := Button.new()
	close.text = "Close  (TAB)"
	close.pressed.connect(_toggle_menu)
	vb.add_child(close)


func _heading(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", C_ACCENT)
	l.add_theme_font_size_override("font_size", 13)
	return l


func _sep() -> HSeparator:
	return HSeparator.new()


# ── Input ─────────────────────────────────────────────────────────────
func _unhandled_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	match (ev as InputEventKey).keycode:
		KEY_TAB:
			_toggle_menu()
			get_viewport().set_input_as_handled()
		KEY_G:
			if _menu == null or not _menu.visible:
				_toggle_carry()
		KEY_X:
			if _menu == null or not _menu.visible:
				_remove_aimed()


func _toggle_menu() -> void:
	if _menu == null:
		return
	var open := not _menu.visible
	_menu.visible = open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
	_set_status("menu open — pick a preset or a piece" if open else "")


# ── Presets ───────────────────────────────────────────────────────────
func _apply_preset(name: String) -> void:
	if _station == null or not _station.has_method("apply_grid_config"):
		_set_status("no CurationStation to rebuild")
		return
	var cfg: Dictionary = PRESETS.get(name, {})
	_station.apply_grid_config(cfg)
	_set_status("preset: %s" % name)


# ── Add / carry / remove ──────────────────────────────────────────────
func _spawn(token: String) -> void:
	var path: String = STATION.get(token, "")
	if path == "" or not ResourceLoader.exists(path):
		_set_status("missing: %s" % token)
		return
	var packed = load(path)
	if packed == null:
		return
	var inst: Node = packed.instantiate()
	_container.add_child(inst)
	if inst is Node3D:
		inst.add_to_group("curation_editable")
		(inst as Node3D).global_position = _front_floor_point(3.0)
	_set_status("added %s — aim + G to carry it into place" % token)


func _toggle_carry() -> void:
	if _carry != null and is_instance_valid(_carry):
		_carry = null
		_set_status("dropped")
		return
	var n := _aimed_prop()
	if n != null:
		_carry = n
		_set_status("carrying %s — look where it should go, G to drop" % n.name)
	else:
		_set_status("aim at a piece you added, then G")


func _remove_aimed() -> void:
	var n := _aimed_prop()
	if n != null:
		if n == _carry:
			_carry = null
		_set_status("removed %s" % n.name)
		n.queue_free()
	else:
		_set_status("aim at a piece you added, then X")


func _process(_delta: float) -> void:
	if _carry != null and is_instance_valid(_carry):
		_carry.global_position = _aim_floor_point(4.0)


# ── Aim helpers ───────────────────────────────────────────────────────
func _front_floor_point(dist: float) -> Vector3:
	if _player == null:
		return Vector3.ZERO
	var fwd := Vector3.FORWARD
	if _camera != null:
		fwd = -_camera.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.01:
		fwd = Vector3.FORWARD
	fwd = fwd.normalized()
	var p := _player.global_position + fwd * dist
	return Vector3(p.x, 0.0, p.z)


func _aim_floor_point(fallback_dist: float) -> Vector3:
	if _camera == null:
		return _front_floor_point(fallback_dist)
	var from := _camera.global_position
	var dir := -_camera.global_transform.basis.z
	if absf(dir.y) > 0.001:
		var t := -from.y / dir.y
		if t > 0.0:
			var hit := from + dir * t
			return Vector3(hit.x, 0.0, hit.z)
	var f := from + dir * fallback_dist
	return Vector3(f.x, 0.0, f.z)


func _aimed_prop() -> Node3D:
	# Nearest spawned piece to the crosshair (screen centre) — collider-independent,
	# since the station pieces are display meshes with no physics body.
	if _camera == null:
		return null
	var center := get_viewport().get_visible_rect().size * 0.5
	var best: Node3D = null
	var best_d := 90.0
	for n in get_tree().get_nodes_in_group("curation_editable"):
		if not (n is Node3D) or n == _carry:
			continue
		var probe: Vector3 = (n as Node3D).global_position + Vector3(0.0, 0.8, 0.0)
		if _camera.is_position_behind(probe):
			continue
		var d := _camera.unproject_position(probe).distance_to(center)
		if d < best_d:
			best_d = d
			best = n
	return best


func _set_status(msg: String) -> void:
	if _status != null:
		_status.text = msg
