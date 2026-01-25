extends Node3D

## VR Waveform Display - Rack module for oscilloscope-style waveform visualization
## Shows real-time audio waveform
## Can be configured to monitor a specific audio bus instead of Master

@export var viewport_path: NodePath = NodePath("WaveformViewport")
@export var screen_mesh_path: NodePath = NodePath("ScreenMesh")
@export var source_bus: String = "Master"  # Audio bus to monitor

@onready var _viewport: SubViewport = get_node_or_null(viewport_path)
@onready var _screen_mesh: MeshInstance3D = get_node_or_null(screen_mesh_path)

func _ready() -> void:
	# Connect viewport texture to screen mesh
	if _viewport and _screen_mesh:
		var material = _screen_mesh.material_override as StandardMaterial3D
		if material:
			material.albedo_texture = _viewport.get_texture()
			material.emission_texture = _viewport.get_texture()
	# Note: Don't apply source bus here - let child use its default (Master)
	# The controller will call set_source_bus() if a custom bus is needed

func _apply_source_bus():
	"""Apply source bus setting to the waveform display inside viewport"""
	if _viewport:
		var waveform_display = _viewport.get_node_or_null("WaveformDisplay")
		if waveform_display and waveform_display.has_method("set_source_bus"):
			waveform_display.set_source_bus(source_bus)
		elif waveform_display:
			waveform_display.source_bus = source_bus

func set_source_bus(bus_name: String):
	"""Set the audio bus to monitor"""
	source_bus = bus_name
	_apply_source_bus()

func set_param_name(text: String):
	var label = get_node_or_null("Chassis/LabelName")
	if label:
		label.text = text
