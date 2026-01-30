extends Node3D

signal pressed

@export var pressed_color: Color = Color(0.2, 0.8, 1.0, 1.0)
@export var released_color: Color = Color(1.0, 0.0, 0.0, 1.0)

@onready var _interactable: Node = $"InteractableAreaButton"
@onready var _button_mesh: MeshInstance3D = $"Button/ButtonMesh"
var _button_material: StandardMaterial3D
var _is_pressed_visual := false

var _colors_initialized: bool = false

func _ready() -> void:
	_button_material = _get_button_material()
	_connect_signals()
	# Defer initial color sync to allow controller to set colors first
	await get_tree().process_frame
	await get_tree().process_frame
	if not _colors_initialized:
		_sync_color_to_state()
		_colors_initialized = true

func _process(_delta: float) -> void:
	if _colors_initialized:
		_sync_color_to_state()

func _connect_signals() -> void:
	if not _interactable:
		return
	if _interactable.has_signal("button_pressed") and not _interactable.is_connected("button_pressed", Callable(self, "_on_button_pressed")):
		_interactable.connect("button_pressed", Callable(self, "_on_button_pressed"))
	if _interactable.has_signal("button_released") and not _interactable.is_connected("button_released", Callable(self, "_on_button_released")):
		_interactable.connect("button_released", Callable(self, "_on_button_released"))

func _sync_color_to_state() -> void:
	_set_visual_state(_is_interactable_pressed())

func _set_visual_state(pressed: bool, force: bool = false) -> void:
	if not force and _is_pressed_visual == pressed:
		return
	_is_pressed_visual = pressed
	_apply_color(pressed_color if pressed else released_color)

func update_colors():
	"""Call this after changing pressed_color or released_color externally"""
	_colors_initialized = true
	_set_visual_state(_is_interactable_pressed(), true)

func _get_button_material() -> StandardMaterial3D:
	if not _button_mesh:
		return null
	var material := _button_mesh.get_surface_override_material(0)
	if not material:
		material = _button_mesh.material_override
	if not material and _button_mesh.mesh and _button_mesh.mesh.get_surface_count() > 0:
		material = _button_mesh.mesh.surface_get_material(0)
		if material:
			material = material.duplicate()
			_button_mesh.set_surface_override_material(0, material)
	return material

func _apply_color(color: Color) -> void:
	if not _button_material:
		_button_material = _get_button_material()
	if _button_material:
		_button_material.albedo_color = color
		# Add emission for visibility in VR
		_button_material.emission_enabled = true
		_button_material.emission = color
		_button_material.emission_energy_multiplier = 0.5

func _is_interactable_pressed() -> bool:
	if not _interactable or not _interactable.has_method("is_xr_class"):
		return false
	if not _interactable.is_xr_class("XRToolsInteractableAreaButton"):
		return false
	return bool(_interactable.get("pressed"))

func _on_button_pressed(_button) -> void:
	pressed.emit()
	_set_visual_state(true)

func _on_button_released(_button) -> void:
	_set_visual_state(false)
