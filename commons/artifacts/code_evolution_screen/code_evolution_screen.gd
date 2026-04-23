# Code Evolution Screen - Watch code build up stage by stage in VR
# Two SubViewport panels side by side: code (left) and thinking (right)
# Uses evolution.json files to define stages

# @identity
# essence: dual-panel 3D code viewer — left shows code accumulating line by line, right shows the reasoning behind each addition
# desire: to watch a program being born — not reading finished code, but seeing each decision unfold in time
# critical_parameter: the evolution.json file — each stage defines what code appears and why, making the build arc visible
# triggers: VR push buttons advance/retreat through stages; auto-play mode steps forward at configurable intervals
# emerges: the temporal experience of code construction — understanding is not "what does this do" but "why was this written next"
# needs: SubViewport panels [has]; push buttons [has]; evolution.json data [has]
# relationships: mirrors the web code-evolution player; placed in maps alongside the artifacts being explained
# truth: code is not a document — it is a sequence of decisions made visible

extends Node3D

signal stage_changed(stage_index: int)
signal evolution_completed

@export_category("Evolution Data")
@export var evolution_path: String = ""  # res:// path to evolution.json
@export var auto_play: bool = false
@export var auto_play_interval: float = 4.0

@export_category("Display")
@export var code_panel_width: float = 0.50
@export var thinking_panel_width: float = 0.35
@export var panel_height: float = 0.45
@export var panel_gap: float = 0.03
@export var font_size: int = 22
@export var thinking_font_size: int = 26

@export_category("Colors — Catppuccin Mocha")
@export var bg_color: Color = Color("1e1e2e")
@export var thinking_bg_color: Color = Color("313244")
@export var text_color: Color = Color("cdd6f4")
@export var keyword_color: Color = Color("cba6f7")
@export var type_color: Color = Color("89b4fa")
@export var string_color: Color = Color("a6e3a1")
@export var number_color: Color = Color("fab387")
@export var comment_color: Color = Color("9399b2")
@export var func_color: Color = Color("89dceb")
@export var annotation_color: Color = Color("f9e2af")
@export var highlight_color: Color = Color("fab387")
@export var stage_label_color: Color = Color("fab387")
@export var concept_color: Color = Color("bac2de")

# Internal state
var _stages: Array = []
var _current_stage: int = -1
var _auto_play_timer: float = 0.0
var _evolution_title: String = ""
var _evolution_desc: String = ""

# Code panel
var _code_viewport: SubViewport
var _code_sprite: Sprite3D
var _code_label: RichTextLabel
var _code_bg: ColorRect
var _code_panel_mesh: MeshInstance3D

# Thinking panel
var _think_viewport: SubViewport
var _think_sprite: Sprite3D
var _think_label: RichTextLabel
var _think_title_label: RichTextLabel
var _think_bg: ColorRect
var _think_panel_mesh: MeshInstance3D

# Stage indicator
var _stage_label: Label3D
var _title_label: Label3D

# Navigation buttons
var _next_button: Node3D
var _prev_button: Node3D
var _play_button: Node3D
var _control_plate: Node3D

# Syntax highlighting
const KEYWORDS = ["extends", "class_name", "var", "const", "func", "signal", "enum",
	"if", "elif", "else", "for", "while", "match", "return", "pass",
	"true", "false", "null", "self", "super", "preload", "load",
	"static", "export", "onready", "await", "break", "continue",
	"not", "and", "or", "is", "as", "in"]

const TYPES = ["Vector2", "Vector3", "Color", "Transform3D", "Basis", "AABB",
	"float", "int", "bool", "String", "Array", "Dictionary",
	"Node3D", "Node", "MeshInstance3D", "SphereMesh", "CylinderMesh",
	"StandardMaterial3D", "BaseMaterial3D", "Material",
	"AudioStreamPlayer3D", "AudioStreamWAV", "XRToolsPickable",
	"XRController3D", "Label3D", "GeometryInstance3D", "SubViewport",
	"RichTextLabel", "ColorRect", "Sprite3D", "QuadMesh",
	"PackedByteArray", "PI", "TAU", "INF", "Control"]


func _ready() -> void:
	_build_unified_housing()
	_load_evolution()
	if _stages.size() > 0:
		_go_to_stage(0)


var _discovery_attempts: int = 0

func _process(delta: float) -> void:
	# Retry discovery for a few frames if evolution didn't load yet
	if _stages.size() == 0 and _discovery_attempts < 10:
		_discovery_attempts += 1
		_load_evolution()
		if _stages.size() > 0:
			_go_to_stage(0)

	if auto_play and _current_stage < _stages.size() - 1:
		_auto_play_timer += delta
		if _auto_play_timer >= auto_play_interval:
			_auto_play_timer = 0.0
			_next_stage()


# ---------- Unified Housing ----------

func _build_unified_housing() -> void:
	# ── Amiga-meets-Rams palette ──
	var BEIGE := Color(0.85, 0.82, 0.76)        # Amiga 1000 plastic
	var WARM_DARK := Color(0.22, 0.20, 0.18)     # dark bezel
	var ACCENT := Color(0.90, 0.45, 0.10)        # Amiga orange
	var ACCENT_ALT := Color(0.20, 0.35, 0.65)    # Amiga blue (Workbench)
	var RECESS := Color(0.78, 0.75, 0.68)         # button wells
	var SCREEN_DARK := Color(0.04, 0.04, 0.07)    # deep screen recess
	var BADGE_LIGHT := Color(0.95, 0.93, 0.88)    # raised logo strip

	# ── Dimensions — more room for header + controls ──
	var total_screen_w := code_panel_width + panel_gap + thinking_panel_width
	var header_h := 0.05    # title strip above screens
	var control_h := 0.10   # button strip below screens (was 0.08)
	var margin := 0.035     # cream border around screens (was 0.03)
	var housing_w := total_screen_w + margin * 2
	var housing_h := panel_height + header_h + control_h + margin * 2
	var housing_depth := 0.028  # slightly thicker — chunky Amiga plastic

	# Center everything on origin
	var cx := 0.0
	var code_cx := cx - (thinking_panel_width + panel_gap) / 2.0
	var think_cx := cx + (code_panel_width + panel_gap) / 2.0
	var screen_cy := (header_h - control_h) / 2.0   # screens centered but offset by header/control difference
	var header_cy := screen_cy + panel_height / 2.0 + header_h / 2.0 + 0.005  # header above screens
	var control_cy := screen_cy - panel_height / 2.0 - control_h / 2.0  # controls below screens

	# ═══════════════════════════════════════════════════════════════
	# OUTER HOUSING — one cream box with dark frame
	# ═══════════════════════════════════════════════════════════════

	var housing_cy := (header_cy + control_cy) / 2.0  # vertical center of entire unit

	# Dark frame (slightly larger, behind everything)
	var frame := MeshInstance3D.new()
	frame.name = "HousingFrame"
	var frame_box := BoxMesh.new()
	frame_box.size = Vector3(housing_w + 0.010, housing_h + 0.010, housing_depth)
	frame.mesh = frame_box
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = WARM_DARK
	frame_mat.metallic = 0.2
	frame_mat.roughness = 0.75
	frame.material_override = frame_mat
	frame.position = Vector3(cx, housing_cy, -housing_depth / 2.0 - 0.002)
	add_child(frame)

	# Beige body — Amiga plastic
	var body := MeshInstance3D.new()
	body.name = "HousingBody"
	var body_box := BoxMesh.new()
	body_box.size = Vector3(housing_w, housing_h, housing_depth)
	body.mesh = body_box
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = BEIGE
	body_mat.metallic = 0.02
	body_mat.roughness = 0.88
	body.material_override = body_mat
	body.position = Vector3(cx, housing_cy, -housing_depth / 2.0)
	add_child(body)

	# ── Amiga-style raised badge strip at top ──
	var badge := MeshInstance3D.new()
	badge.name = "BadgeStrip"
	var badge_box := BoxMesh.new()
	badge_box.size = Vector3(housing_w - 0.01, header_h - 0.008, 0.004)
	badge.mesh = badge_box
	var badge_mat := StandardMaterial3D.new()
	badge_mat.albedo_color = BADGE_LIGHT
	badge_mat.metallic = 0.0
	badge_mat.roughness = 0.92
	badge.material_override = badge_mat
	badge.position = Vector3(cx, header_cy, 0.001)
	add_child(badge)

	# Orange accent line under badge (Amiga stripe)
	var accent := MeshInstance3D.new()
	accent.name = "AmigaStripe"
	var accent_box := BoxMesh.new()
	accent_box.size = Vector3(housing_w - 0.02, 0.004, 0.005)
	accent.mesh = accent_box
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = ACCENT
	accent_mat.metallic = 0.4
	accent_mat.roughness = 0.4
	accent_mat.emission_enabled = true
	accent_mat.emission = ACCENT
	accent_mat.emission_energy_multiplier = 0.2
	accent.material_override = accent_mat
	accent.position = Vector3(cx, header_cy - header_h / 2.0 + 0.002, 0.003)
	add_child(accent)

	# Blue accent line (second Amiga stripe, thinner)
	var blue_stripe := MeshInstance3D.new()
	blue_stripe.name = "BlueStripe"
	var blue_box := BoxMesh.new()
	blue_box.size = Vector3(housing_w - 0.02, 0.002, 0.005)
	blue_stripe.mesh = blue_box
	var blue_mat := StandardMaterial3D.new()
	blue_mat.albedo_color = ACCENT_ALT
	blue_mat.metallic = 0.4
	blue_mat.roughness = 0.4
	blue_mat.emission_enabled = true
	blue_mat.emission = ACCENT_ALT
	blue_mat.emission_energy_multiplier = 0.15
	blue_stripe.material_override = blue_mat
	blue_stripe.position = Vector3(cx, header_cy - header_h / 2.0 - 0.001, 0.003)
	add_child(blue_stripe)

	# ═══════════════════════════════════════════════════════════════
	# SCREEN RECESSES — dark insets where the screens sit
	# ═══════════════════════════════════════════════════════════════

	# Code screen recess
	var code_recess := MeshInstance3D.new()
	code_recess.name = "CodeRecess"
	var cr_box := BoxMesh.new()
	cr_box.size = Vector3(code_panel_width + 0.008, panel_height + 0.008, 0.004)
	code_recess.mesh = cr_box
	var recess_mat := StandardMaterial3D.new()
	recess_mat.albedo_color = SCREEN_DARK
	recess_mat.roughness = 0.95
	code_recess.material_override = recess_mat
	code_recess.position = Vector3(code_cx, screen_cy, -0.001)
	add_child(code_recess)

	# Think screen recess
	var think_recess := MeshInstance3D.new()
	think_recess.name = "ThinkRecess"
	var tr_box := BoxMesh.new()
	tr_box.size = Vector3(thinking_panel_width + 0.008, panel_height + 0.008, 0.004)
	think_recess.mesh = tr_box
	think_recess.material_override = recess_mat
	think_recess.position = Vector3(think_cx, screen_cy, -0.001)
	add_child(think_recess)

	# ═══════════════════════════════════════════════════════════════
	# CODE SCREEN (SubViewport + Sprite3D)
	# ═══════════════════════════════════════════════════════════════

	var code_vp_w := int(code_panel_width * 1400)
	var code_vp_h := int(panel_height * 1400)

	_code_viewport = SubViewport.new()
	_code_viewport.name = "CodeViewport"
	_code_viewport.size = Vector2i(code_vp_w, code_vp_h)
	_code_viewport.transparent_bg = false
	_code_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_code_viewport.disable_3d = true
	add_child(_code_viewport)

	_code_bg = ColorRect.new()
	_code_bg.color = bg_color
	_code_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_code_viewport.add_child(_code_bg)

	_code_label = RichTextLabel.new()
	_code_label.name = "CodeLabel"
	_code_label.bbcode_enabled = true
	_code_label.fit_content = false
	_code_label.scroll_active = true
	_code_label.scroll_following = true
	_code_label.add_theme_font_size_override("normal_font_size", font_size)
	_code_label.add_theme_color_override("default_color", text_color)
	_code_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_code_label.position = Vector2(16, 16)
	_code_label.size = Vector2(code_vp_w - 32, code_vp_h - 32)
	_code_viewport.add_child(_code_label)

	_code_sprite = Sprite3D.new()
	_code_sprite.name = "CodeSprite"
	_code_sprite.texture = _code_viewport.get_texture()
	_code_sprite.pixel_size = code_panel_width / _code_viewport.size.x
	_code_sprite.position = Vector3(code_cx, screen_cy, 0.002)
	# Unshaded — text renders at full brightness regardless of scene lighting
	var code_sprite_mat := StandardMaterial3D.new()
	code_sprite_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	code_sprite_mat.albedo_texture = _code_viewport.get_texture()
	code_sprite_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_code_sprite.material_override = code_sprite_mat
	add_child(_code_sprite)

	# Reading light for code screen
	var code_light := OmniLight3D.new()
	code_light.name = "CodeScreenLight"
	code_light.light_color = Color(0.7, 0.8, 1.0)  # cool blue-white
	code_light.light_energy = 0.8
	code_light.light_indirect_energy = 0.3
	code_light.omni_range = 1.2
	code_light.omni_attenuation = 2.0
	code_light.shadow_enabled = false
	code_light.position = Vector3(code_cx, screen_cy, 0.25)
	add_child(code_light)

	# ═══════════════════════════════════════════════════════════════
	# THINKING SCREEN (SubViewport + Sprite3D)
	# ═══════════════════════════════════════════════════════════════

	var think_vp_w := int(thinking_panel_width * 1400)
	var think_vp_h := int(panel_height * 1400)

	_think_viewport = SubViewport.new()
	_think_viewport.name = "ThinkViewport"
	_think_viewport.size = Vector2i(think_vp_w, think_vp_h)
	_think_viewport.transparent_bg = false
	_think_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_think_viewport.disable_3d = true
	add_child(_think_viewport)

	_think_bg = ColorRect.new()
	_think_bg.color = thinking_bg_color
	_think_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_think_viewport.add_child(_think_bg)

	_think_title_label = RichTextLabel.new()
	_think_title_label.name = "ThinkTitle"
	_think_title_label.bbcode_enabled = true
	_think_title_label.fit_content = true
	_think_title_label.scroll_active = false
	_think_title_label.add_theme_font_size_override("normal_font_size", thinking_font_size + 4)
	_think_title_label.add_theme_color_override("default_color", text_color)
	_think_title_label.position = Vector2(24, 20)
	_think_title_label.size = Vector2(think_vp_w - 48, 60)
	_think_viewport.add_child(_think_title_label)

	_think_label = RichTextLabel.new()
	_think_label.name = "ThinkLabel"
	_think_label.bbcode_enabled = true
	_think_label.fit_content = true
	_think_label.scroll_active = false
	_think_label.add_theme_font_size_override("normal_font_size", thinking_font_size)
	_think_label.add_theme_color_override("default_color", Color.WHITE)
	_think_label.position = Vector2(24, 90)
	_think_label.size = Vector2(think_vp_w - 48, think_vp_h - 120)
	_think_viewport.add_child(_think_label)

	_think_sprite = Sprite3D.new()
	_think_sprite.name = "ThinkSprite"
	_think_sprite.texture = _think_viewport.get_texture()
	_think_sprite.pixel_size = thinking_panel_width / _think_viewport.size.x
	_think_sprite.position = Vector3(think_cx, screen_cy, 0.002)
	# Unshaded — text always readable
	var think_sprite_mat := StandardMaterial3D.new()
	think_sprite_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	think_sprite_mat.albedo_texture = _think_viewport.get_texture()
	think_sprite_mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	_think_sprite.material_override = think_sprite_mat
	add_child(_think_sprite)

	# Reading light for thinking screen
	var think_light := OmniLight3D.new()
	think_light.name = "ThinkScreenLight"
	think_light.light_color = Color(0.75, 0.75, 0.9)  # warmer than code
	think_light.light_energy = 0.6
	think_light.light_indirect_energy = 0.3
	think_light.omni_range = 1.0
	think_light.omni_attenuation = 2.0
	think_light.shadow_enabled = false
	think_light.position = Vector3(think_cx, screen_cy, 0.25)
	add_child(think_light)

	# ═══════════════════════════════════════════════════════════════
	# CONTROL STRIP — integrated into bottom of housing
	# ═══════════════════════════════════════════════════════════════

	# ── Bear stripe band between screens and controls ──
	var stripe_y_start := screen_cy - panel_height / 2.0 - 0.004
	var stripe_gap := 0.005
	var stripe_colors := [
		ACCENT,                          # orange
		Color(0.95, 0.85, 0.55),         # warm yellow
		Color(0.92, 0.90, 0.84),         # cream/white
		Color(0.45, 0.42, 0.38),         # warm grey
	]
	for i in stripe_colors.size():
		var stripe := MeshInstance3D.new()
		stripe.name = "Stripe_%d" % i
		var s_box := BoxMesh.new()
		s_box.size = Vector3(housing_w - 0.02, 0.003, 0.005)
		stripe.mesh = s_box
		var s_mat := StandardMaterial3D.new()
		s_mat.albedo_color = stripe_colors[i]
		s_mat.metallic = 0.3
		s_mat.roughness = 0.45
		s_mat.emission_enabled = true
		s_mat.emission = stripe_colors[i]
		s_mat.emission_energy_multiplier = 0.12
		stripe.material_override = s_mat
		stripe.position = Vector3(cx, stripe_y_start - i * stripe_gap, 0.003)
		add_child(stripe)

	# Button recesses
	var btn_spacing := 0.13
	var button_positions := [
		cx - btn_spacing,
		cx,
		cx + btn_spacing,
	]
	for bx in button_positions:
		var recess := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.020
		cyl.bottom_radius = 0.020
		cyl.height = 0.003
		cyl.radial_segments = 16
		recess.mesh = cyl
		var rec_mat := StandardMaterial3D.new()
		rec_mat.albedo_color = RECESS
		rec_mat.roughness = 0.9
		recess.material_override = rec_mat
		recess.position = Vector3(bx, control_cy, 0.001)
		recess.rotation_degrees.x = 90
		add_child(recess)

	# Push buttons
	var PushButton = preload("res://commons/interactables/push_button.tscn")

	_prev_button = PushButton.instantiate()
	_prev_button.name = "PrevButton"
	_prev_button.position = Vector3(button_positions[0], control_cy, 0.008)
	_prev_button.scale = Vector3(0.45, 0.45, 0.45)
	add_child(_prev_button)
	_prev_button.pressed.connect(_on_prev_pressed)

	_play_button = PushButton.instantiate()
	_play_button.name = "PlayButton"
	_play_button.position = Vector3(button_positions[1], control_cy, 0.008)
	_play_button.scale = Vector3(0.45, 0.45, 0.45)
	add_child(_play_button)
	_play_button.pressed.connect(_on_play_pressed)

	_next_button = PushButton.instantiate()
	_next_button.name = "NextButton"
	_next_button.position = Vector3(button_positions[2], control_cy, 0.008)
	_next_button.scale = Vector3(0.45, 0.45, 0.45)
	add_child(_next_button)
	_next_button.pressed.connect(_on_next_pressed)

	# Engraved labels
	var btn_labels := [
		{ "text": "PREV", "x": button_positions[0] },
		{ "text": "PLAY", "x": button_positions[1] },
		{ "text": "NEXT", "x": button_positions[2] },
	]
	for lbl_data in btn_labels:
		var lbl := Label3D.new()
		lbl.text = lbl_data["text"]
		lbl.font_size = 20
		lbl.pixel_size = 0.001
		lbl.modulate = WARM_DARK
		lbl.position = Vector3(lbl_data["x"], control_cy - 0.028, 0.001)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(lbl)

	# Status LED
	var led := MeshInstance3D.new()
	led.name = "StatusLED"
	var led_sphere := SphereMesh.new()
	led_sphere.radius = 0.005
	led_sphere.height = 0.010
	led.mesh = led_sphere
	var led_mat := StandardMaterial3D.new()
	led_mat.albedo_color = ACCENT
	led_mat.emission_enabled = true
	led_mat.emission = ACCENT
	led_mat.emission_energy_multiplier = 0.8
	led.material_override = led_mat
	led.position = Vector3(cx + housing_w / 2.0 - 0.025, control_cy, 0.003)
	add_child(led)

	# Stage counter label
	_stage_label = Label3D.new()
	_stage_label.name = "StageLabel"
	_stage_label.text = ""
	_stage_label.font_size = 24
	_stage_label.pixel_size = 0.001
	_stage_label.modulate = WARM_DARK
	_stage_label.position = Vector3(cx - housing_w / 2.0 + 0.04, control_cy, 0.001)
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_stage_label)

	# Title label (on housing top)
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = ""
	_title_label.font_size = 32
	_title_label.pixel_size = 0.001
	_title_label.modulate = WARM_DARK
	_title_label.position = Vector3(cx - housing_w / 2.0 + 0.035, header_cy, 0.005)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_title_label)


# ---------- Data Loading ----------

func _load_evolution() -> void:
	if evolution_path.is_empty():
		# Try to find evolution.json from map metadata
		_try_discover_evolution()
		return

	if not FileAccess.file_exists(evolution_path):
		push_warning("CodeEvolutionScreen: evolution file not found: %s" % evolution_path)
		return

	var file := FileAccess.open(evolution_path, FileAccess.READ)
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("CodeEvolutionScreen: failed to parse evolution JSON")
		return

	var data: Dictionary = json.data
	_evolution_title = data.get("title", "Code Evolution")
	_evolution_desc = data.get("description", "")
	_stages = data.get("stages", [])

	if _title_label:
		_title_label.text = _evolution_title


func _try_discover_evolution() -> void:
	# Method 1: Check map_name metadata from GridInteractablesComponent
	if has_meta("map_name"):
		var map_name: String = get_meta("map_name")
		if not map_name.is_empty():
			var p := "res://commons/maps/%s/evolution.json" % map_name
			if FileAccess.file_exists(p):
				evolution_path = p
				_load_evolution()
				return

	# Method 2: Walk up the scene tree to find MapRoot or similar
	var node := get_parent()
	while node:
		if node.has_meta("map_name"):
			var map_name: String = node.get_meta("map_name")
			var p := "res://commons/maps/%s/evolution.json" % map_name
			if FileAccess.file_exists(p):
				evolution_path = p
				_load_evolution()
				return
		node = node.get_parent() if node.get_parent() != node else null

	# Method 3: Scan all map directories for any evolution.json
	var maps_dir := "res://commons/maps"
	var dir := DirAccess.open(maps_dir)
	if dir:
		dir.list_dir_begin()
		var folder := dir.get_next()
		while folder != "":
			if dir.current_is_dir() and folder != "sequences" and folder != "catalog":
				var p := "%s/%s/evolution.json" % [maps_dir, folder]
				if FileAccess.file_exists(p):
					evolution_path = p
					_load_evolution()
					return
			folder = dir.get_next()
		dir.list_dir_end()


# ---------- Stage Navigation ----------

func _go_to_stage(index: int) -> void:
	if index < 0 or index >= _stages.size():
		return
	_current_stage = index
	_auto_play_timer = 0.0

	var stage: Dictionary = _stages[_current_stage]
	_update_code_display(stage.get("code", ""))
	_update_thinking_display(stage)
	_update_stage_label()
	stage_changed.emit(_current_stage)

	if _current_stage >= _stages.size() - 1:
		evolution_completed.emit()


func _next_stage() -> void:
	_go_to_stage(_current_stage + 1)


func _prev_stage() -> void:
	_go_to_stage(_current_stage - 1)


func _on_next_pressed() -> void:
	_next_stage()


func _on_prev_pressed() -> void:
	_prev_stage()


func _on_play_pressed() -> void:
	if _current_stage >= _stages.size() - 1:
		# At end — reset to beginning
		_go_to_stage(0)
	else:
		# Toggle auto-play
		auto_play = not auto_play
		_auto_play_timer = 0.0


# ---------- Display Updates ----------

func _update_code_display(code: String) -> void:
	if not _code_label:
		return
	var highlighted := _syntax_highlight_full(code)
	_code_label.text = highlighted
	# Scroll to bottom so new code is visible
	await get_tree().process_frame
	_code_label.scroll_to_line(_code_label.get_line_count())


func _update_thinking_display(stage: Dictionary) -> void:
	if not _think_label or not _think_title_label:
		return

	var title: String = stage.get("title", "")
	var thinking: String = stage.get("thinking", "")
	var concepts: Array = stage.get("concepts", [])

	# Title with stage number
	var title_color := highlight_color.to_html(false)
	_think_title_label.text = "[color=#%s]%d[/color]  %s" % [
		title_color, _current_stage + 1, title
	]

	# Thinking text + concepts
	var body := thinking
	if concepts.size() > 0:
		body += "\n\n[color=#%s]CONCEPTS[/color]\n" % comment_color.to_html(false)
		var concept_tags := PackedStringArray()
		for c in concepts:
			concept_tags.append("[color=#%s]%s[/color]" % [concept_color.to_html(false), str(c)])
		body += "  ".join(concept_tags)

	_think_label.text = body


func _update_stage_label() -> void:
	if not _stage_label:
		return
	_stage_label.text = "Stage %d / %d" % [_current_stage + 1, _stages.size()]


# ---------- Syntax Highlighting ----------

func _syntax_highlight_full(code: String) -> String:
	var lines := code.split("\n")
	var result_lines := PackedStringArray()

	for i in lines.size():
		var line := lines[i]
		var line_num := "[color=#%s]%2d[/color] " % [comment_color.to_html(false), i + 1]
		result_lines.append(line_num + _syntax_highlight_line(line))

	return "\n".join(result_lines)


func _syntax_highlight_line(line: String) -> String:
	# Handle comments first
	var comment_idx := line.find("#")
	if comment_idx >= 0:
		var before := line.substr(0, comment_idx)
		var comment := line.substr(comment_idx)
		return _highlight_code(before) + "[color=#%s]%s[/color]" % [
			comment_color.to_html(false), comment
		]
	return _highlight_code(line)


func _highlight_code(text: String) -> String:
	var result := text

	# Strings
	var str_regex := RegEx.new()
	str_regex.compile('"[^"]*"')
	var str_matches := str_regex.search_all(result)
	for i in range(str_matches.size() - 1, -1, -1):
		var m := str_matches[i]
		var repl := "[color=#%s]%s[/color]" % [string_color.to_html(false), m.get_string()]
		result = result.substr(0, m.get_start()) + repl + result.substr(m.get_end())

	# Annotations (@export, @tool, @identity)
	var anno_regex := RegEx.new()
	anno_regex.compile("@\\w+")
	var anno_matches := anno_regex.search_all(result)
	for i in range(anno_matches.size() - 1, -1, -1):
		var m := anno_matches[i]
		var repl := "[color=#%s]%s[/color]" % [annotation_color.to_html(false), m.get_string()]
		result = result.substr(0, m.get_start()) + repl + result.substr(m.get_end())

	# Numbers
	var num_regex := RegEx.new()
	num_regex.compile("\\b\\d+\\.?\\d*\\b")
	var num_matches := num_regex.search_all(result)
	for i in range(num_matches.size() - 1, -1, -1):
		var m := num_matches[i]
		var repl := "[color=#%s]%s[/color]" % [number_color.to_html(false), m.get_string()]
		result = result.substr(0, m.get_start()) + repl + result.substr(m.get_end())

	# func definitions (before keyword pass)
	var func_regex := RegEx.new()
	func_regex.compile("\\bfunc\\s+(\\w+)")
	var func_matches := func_regex.search_all(result)
	for i in range(func_matches.size() - 1, -1, -1):
		var m := func_matches[i]
		var fn_name := m.get_string(1)
		var repl := "[color=#%s]func[/color] [color=#%s]%s[/color]" % [
			keyword_color.to_html(false), func_color.to_html(false), fn_name
		]
		result = result.substr(0, m.get_start()) + repl + result.substr(m.get_end())

	# Keywords
	for kw in KEYWORDS:
		var kw_regex := RegEx.new()
		kw_regex.compile("\\b" + kw + "\\b")
		var kw_matches := kw_regex.search_all(result)
		for i in range(kw_matches.size() - 1, -1, -1):
			var m := kw_matches[i]
			# Skip if already inside a [color] tag
			var before_text := result.substr(0, m.get_start())
			if before_text.count("[color=") > before_text.count("[/color]"):
				continue
			var repl := "[color=#%s]%s[/color]" % [keyword_color.to_html(false), m.get_string()]
			result = result.substr(0, m.get_start()) + repl + result.substr(m.get_end())

	# Types
	for tp in TYPES:
		var tp_regex := RegEx.new()
		tp_regex.compile("\\b" + tp + "\\b")
		var tp_matches := tp_regex.search_all(result)
		for i in range(tp_matches.size() - 1, -1, -1):
			var m := tp_matches[i]
			var before_text := result.substr(0, m.get_start())
			if before_text.count("[color=") > before_text.count("[/color]"):
				continue
			var repl := "[color=#%s]%s[/color]" % [type_color.to_html(false), m.get_string()]
			result = result.substr(0, m.get_start()) + repl + result.substr(m.get_end())

	return result


# ---------- Grid Config Integration ----------

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("evolution_path"):
		evolution_path = config_data["evolution_path"]
		_load_evolution()
		if _stages.size() > 0:
			_go_to_stage(0)
	if config_data.has("auto_play"):
		auto_play = config_data["auto_play"]
	if config_data.has("auto_play_interval"):
		auto_play_interval = config_data["auto_play_interval"]
