extends Node3D

## VR Spectrum Display - Rack module for frequency spectrum visualization
## Shows real-time frequency analysis of audio output

@export var viewport_path: NodePath = NodePath("SpectrumViewport")
@export var screen_mesh_path: NodePath = NodePath("ScreenMesh")

@onready var _viewport: SubViewport = get_node_or_null(viewport_path)
@onready var _screen_mesh: MeshInstance3D = get_node_or_null(screen_mesh_path)

func _ready() -> void:
	# Connect viewport texture to screen mesh
	if _viewport and _screen_mesh:
		var material = _screen_mesh.material_override as StandardMaterial3D
		if material:
			material.albedo_texture = _viewport.get_texture()
			material.emission_texture = _viewport.get_texture()

func set_param_name(text: String):
	var label = get_node_or_null("Chassis/LabelName")
	if label:
		label.text = text
