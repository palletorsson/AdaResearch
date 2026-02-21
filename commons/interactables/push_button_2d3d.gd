extends XRToolsPickable

signal pressed

@export var label_text: String = "2D/3D TEST":
	set(value):
		label_text = value
		_sync_label_text()

@export var pressed_color: Color = Color(0.2, 0.85, 1.0, 1.0)
@export var released_color: Color = Color(0.12, 0.12, 0.15, 1.0)
@export var freeze_on_drop: bool = true:
	set(value):
		freeze_on_drop = value
		_apply_release_mode()
@export var grab_scale_multiplier: float = 1.03

@onready var _viewport_2d_in_3d: Node = $"Viewport2Din3D"
@onready var _indicator: MeshInstance3D = $"Indicator"
@onready var _interactable: Node = $"InteractableAreaButton"

var _ui_button: Button = null
var _is_pressed_visual := false
var _base_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	super()
	_apply_release_mode()
	if freeze_on_drop:
		freeze = true
	picked_up.connect(_on_pickable_picked_up)
	dropped.connect(_on_pickable_dropped)
	_base_scale = scale

	_bind_ui_button()
	if _ui_button == null:
		await get_tree().process_frame
		_bind_ui_button()
	_connect_3d_signals()
	_sync_label_text()
	_set_visual_state(false, true)

func _bind_ui_button() -> void:
	if _ui_button:
		return

	var scene_instance: Node = null
	if _viewport_2d_in_3d and _viewport_2d_in_3d.has_method("get_scene_instance"):
		scene_instance = _viewport_2d_in_3d.call("get_scene_instance")

	if scene_instance == null:
		return

	if scene_instance is Button:
		_ui_button = scene_instance as Button
	else:
		_ui_button = scene_instance.find_child("Button", true, false) as Button

	if _ui_button == null:
		push_warning("PushButton2D3D: Could not find a Button node in viewport scene.")
		return

	# Connect the 2D UI button signals as well (for pointer/ray interaction)
	if not _ui_button.pressed.is_connected(_on_ui_pressed):
		_ui_button.pressed.connect(_on_ui_pressed)
	if not _ui_button.button_down.is_connected(_on_ui_button_down):
		_ui_button.button_down.connect(_on_ui_button_down)
	if not _ui_button.button_up.is_connected(_on_ui_button_up):
		_ui_button.button_up.connect(_on_ui_button_up)

func _connect_3d_signals() -> void:
	if not _interactable:
		return
	if _interactable.has_signal("button_pressed") and not _interactable.is_connected("button_pressed", Callable(self, "_on_3d_button_pressed")):
		_interactable.connect("button_pressed", Callable(self, "_on_3d_button_pressed"))
	if _interactable.has_signal("button_released") and not _interactable.is_connected("button_released", Callable(self, "_on_3d_button_released")):
		_interactable.connect("button_released", Callable(self, "_on_3d_button_released"))

func _sync_label_text() -> void:
	if _ui_button:
		_ui_button.text = label_text

func _set_visual_state(is_pressed: bool, force: bool = false) -> void:
	if not force and _is_pressed_visual == is_pressed:
		return
	_is_pressed_visual = is_pressed

	# Update the 3D indicator
	_update_indicator_color(pressed_color if is_pressed else released_color, is_pressed)

	# Update the 2D button to reflect the state visually
	_update_2d_button_state(is_pressed)

func _update_indicator_color(color: Color, is_pressed: bool) -> void:
	if _indicator == null:
		return
	var material := _indicator.get_surface_override_material(0) as StandardMaterial3D
	if material == null:
		return
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.6 if is_pressed else 0.2

func _update_2d_button_state(is_pressed: bool) -> void:
	if _ui_button == null:
		return
	# Visually update the 2D button (e.g. toggle flat style or color)
	if is_pressed:
		_ui_button.add_theme_color_override("font_color", pressed_color)
		_ui_button.add_theme_color_override("font_hover_color", pressed_color)
	else:
		_ui_button.remove_theme_color_override("font_color")
		_ui_button.remove_theme_color_override("font_hover_color")

# --- 3D physical push button callbacks ---
func _on_3d_button_pressed(_button) -> void:
	pressed.emit()
	_set_visual_state(true)

func _on_3d_button_released(_button) -> void:
	_set_visual_state(false)

# --- 2D UI pointer/ray button callbacks ---
func _on_ui_pressed() -> void:
	pressed.emit()

func _on_ui_button_down() -> void:
	_set_visual_state(true)

func _on_ui_button_up() -> void:
	_set_visual_state(false)

# --- External trigger ---
func trigger() -> void:
	pressed.emit()
	_set_visual_state(true)
	var tween := create_tween()
	tween.tween_interval(0.12)
	tween.tween_callback(Callable(self, "_set_visual_state").bind(false))

# --- External color update ---
func update_colors():
	"""Call this after changing pressed_color or released_color externally"""
	_set_visual_state(_is_pressed_visual, true)

func _apply_release_mode() -> void:
	release_mode = ReleaseMode.FROZEN if freeze_on_drop else ReleaseMode.ORIGINAL

func _on_pickable_picked_up(_pickable) -> void:
	scale = _base_scale * max(grab_scale_multiplier, 1.0)

func _on_pickable_dropped(_pickable) -> void:
	scale = _base_scale
	if freeze_on_drop:
		freeze = true
