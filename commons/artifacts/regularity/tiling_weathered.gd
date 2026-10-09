extends Node3D
## The tiling hall's pattern comes back as a surface that ages. Left: the raster exactly as
## Tutorial_Tiling_Floor shows it (tiling_pattern.gd). Right: the same raster through
## wallpaper_tile.gdshader, with the Pattern Studio's aging layers - dirt (stains), wear,
## dust, sun fade, cracks, chips - on sliders. Palle, 2026-10-09: "somewhere in shader
## sequence we want to bring the same pattern back and add dirt, wear, dust, sun fade,
## cracks." Built for Shader_05_Patterns; config_mode "walls" stands both surfaces up.
const Pattern = preload("res://commons/artifacts/regularity/tiling_pattern.gd")
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
const AGING_SHADER = preload("res://commons/resourses/shaders/wallpaper_tile.gdshader")
const TITLES := ["TRANSLATE", "ALTERNATE", "QUARTER TURN", "REFLECT", "SHIFT ROWS", "ONE EXCEPTION"]
## slider label, shader uniform, map-token key. DIRT is the studio's "Stains".
const LAYERS := [
	["DIRT", "stain_amount", "dirt"], ["WEAR", "wear_amount", "wear"], ["DUST", "dust_amount", "dust"],
	["SUN FADE", "fade_amount", "fade"], ["CRACKS", "crack_density", "cracks"], ["CHIPS", "chip_amount", "chips"],
]
const SIZE := 5.0
const CELLS := 8.0   # tiling_pattern.gd draws 8 x 8 tiles; the shader puts grout, wear and dust on their joints
var walls := false
var rule := 2
var phase := 0
var exception := false
var amounts := {"stain_amount": 0.0, "wear_amount": 0.0, "dust_amount": 0.0, "fade_amount": 0.0, "crack_density": 0.0, "chip_amount": 0.0}
var clean: MeshInstance3D
var aged: MeshInstance3D
var material: ShaderMaterial
var readout: Label
var sliders := {}

func _ready() -> void:
	walls = str(get_meta("config_mode", "floor")) == "walls"
	var left: Vector3
	var right: Vector3
	var turn: Vector3
	var label_lift: Vector3
	var label_yaw := 180.0
	if walls:
		left = Vector3(-2.95, 2.7, -4.0)
		right = Vector3(2.95, 2.7, -4.0)
		turn = Vector3(0, 0, 0)
		label_lift = Vector3(0, 3.0, 0)
		label_yaw = 0.0
		Kit.box(self, "WallBacking", Vector3(0, 2.7, -4.07), Vector3(12.0, 5.4, 0.12), Color(0.08, 0.08, 0.08))
	else:
		left = Vector3(-2.95, 0.025, -3.6)
		right = Vector3(2.95, 0.025, -3.6)
		turn = Vector3(-90, 0, 0)
		label_lift = Vector3(0, 0.45, -2.6)
	var tex := _texture()
	clean = Kit.textured_plane(self, "Clean", Vector2(SIZE, SIZE), left, turn, tex)
	aged = Kit.textured_plane(self, "Aged", Vector2(SIZE, SIZE), right, turn, tex)
	material = ShaderMaterial.new()
	material.shader = AGING_SHADER
	material.set_shader_parameter("domain_texture", tex)
	material.set_shader_parameter("wallpaper_group", 0)        # P1: the raster is shown as it is
	material.set_shader_parameter("tile_scale", 1.0)           # one raster across the surface
	material.set_shader_parameter("cell_count", CELLS)
	material.set_shader_parameter("surface_metres", Vector2(1.0, 1.0))
	material.set_shader_parameter("roughness", 0.92)
	aged.material_override = material
	Kit.label(self, "THE SAME PATTERN", left + label_lift, label_yaw)
	Kit.label(self, "AFTER SOME TIME", right + label_lift, label_yaw)
	var p := Kit.panel(self, "ONE MOTIF, THEN TIME", Vector3(0, 1.2, 0.4))
	p.layout_columns = 4
	p.add_button("RULE").pressed.connect(cycle_rule)
	p.add_button("TURN MOTIF").pressed.connect(turn_motif)
	p.add_button("EXCEPTION").pressed.connect(toggle_exception)
	p.add_button("CLEAN").pressed.connect(clean_surface)
	for layer in LAYERS:
		var s: Node3D = p.add_slider(layer[0], layer[0])
		sliders[layer[1]] = s
		if s.has_signal("slider_moved"):
			s.slider_moved.connect(_on_layer_moved.bind(layer[1]))
	readout = p.add_readout("")
	_apply_amounts()
	refresh()

## Map-token keys: rule (index or title), turn (quarter-turns), exception, dirt, wear, dust,
## fade, cracks, chips (0-1). The museum may call this before _ready; values are kept and
## applied when the surfaces exist.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("rule"):
		var r = config["rule"]
		if r is String:
			var i := TITLES.find(str(r).to_upper())
			if i >= 0: rule = i
		else:
			rule = clampi(int(r), 0, TITLES.size() - 1)
	if config.has("turn"): phase = posmod(int(config["turn"]), 4)
	if config.has("exception"): exception = bool(config["exception"])
	for layer in LAYERS:
		if config.has(layer[2]):
			amounts[layer[1]] = clampf(float(config[layer[2]]), 0.0, 1.0)
	if material != null:
		_apply_amounts()
		refresh()

func cycle_rule() -> void:
	rule = (rule + 1) % TITLES.size()
	refresh()

func turn_motif() -> void:
	phase = (phase + 1) % 4
	refresh()

func toggle_exception() -> void:
	exception = not exception
	refresh()

func clean_surface() -> void:
	for key in amounts: amounts[key] = 0.0
	_apply_amounts()
	refresh()

func _on_layer_moved(value, key: String) -> void:
	amounts[key] = clampf(float(value), 0.0, 1.0)
	material.set_shader_parameter(key, amounts[key])
	_update_readout()

func _apply_amounts() -> void:
	for key in amounts:
		material.set_shader_parameter(key, amounts[key])
		var s = sliders.get(key)
		if s != null and s.has_method("set_normalized_value"):
			s.call("set_normalized_value", amounts[key])

func refresh() -> void:
	var tex := _texture()
	clean.material_override.albedo_texture = tex
	material.set_shader_parameter("domain_texture", tex)
	_update_readout()

func _update_readout() -> void:
	if readout == null: return
	var parts: PackedStringArray = []
	for layer in LAYERS:
		if amounts[layer[1]] > 0.005:
			parts.append("%s %.2f" % [layer[0].to_lower(), amounts[layer[1]]])
	var time_line := ", ".join(parts) if parts.size() > 0 else "clean"
	readout.text = "%s | motif %d | exception %s\n%s" % [TITLES[rule], phase * 90, "ON" if exception else "OFF", time_line]

func _texture() -> ImageTexture:
	return ImageTexture.create_from_image(Pattern.image_for(rule, phase, exception))
