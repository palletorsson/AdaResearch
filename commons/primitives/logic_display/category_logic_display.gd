extends Node3D

@onready var ui: Control = $SubViewport/CategoryLogicDisplayUI
@onready var viewport: SubViewport = $SubViewport
@onready var screen: MeshInstance3D = $Screen

# Initial equation to display, can be set from editor or code
@export var equation: Array = ["point", "plus", "point", "arrow", "line"]

func _ready() -> void:
	# Fix ViewportTexture issue by assigning it manually
	var material = screen.get_active_material(0)
	if material:
		material.albedo_texture = viewport.get_texture()
	
	# If equation is set in editor, display it deferred to ensure UI is ready
	if not equation.is_empty():
		call_deferred("display_equation", equation)

func display_equation(items: Array) -> void:
	equation = items
	if ui:
		ui.set_equation(items)
