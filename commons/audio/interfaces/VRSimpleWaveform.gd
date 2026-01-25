extends Node3D

## VR Simple Waveform - Shows audio from a single bus only
## Use "source": "rack" in config to monitor rack audio instead of master

@export var source_bus: String = "Master"

@onready var _viewport: SubViewport = $WaveformViewport
@onready var _screen_mesh: MeshInstance3D = $ScreenMesh

func _ready() -> void:
	# Connect viewport texture to screen mesh
	if _viewport and _screen_mesh:
		var material = _screen_mesh.material_override as StandardMaterial3D
		if material:
			material.albedo_texture = _viewport.get_texture()
			material.emission_texture = _viewport.get_texture()

func set_source_bus(bus_name: String):
	"""Set the audio bus to monitor"""
	source_bus = bus_name
	if _viewport:
		var display = _viewport.get_node_or_null("SimpleWaveformDisplay")
		if display and display.has_method("set_source_bus"):
			display.set_source_bus(bus_name)

func set_frequency(freq: float):
	"""Set displayed frequency (affects wave visualization)"""
	if _viewport:
		var display = _viewport.get_node_or_null("SimpleWaveformDisplay")
		if display and display.has_method("set_frequency"):
			display.set_frequency(freq)

func set_amplitude(amp: float):
	"""Set displayed amplitude (0-1)"""
	if _viewport:
		var display = _viewport.get_node_or_null("SimpleWaveformDisplay")
		if display and display.has_method("set_amplitude"):
			display.set_amplitude(amp)

func set_param_name(text: String):
	var label = get_node_or_null("Chassis/LabelName")
	if label:
		label.text = text
