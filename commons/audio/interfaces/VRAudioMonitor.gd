@tool
extends Node3D

## Principal VR Audio Monitor
## Visualizes audio waves in 3D using a SubViewport and WaveformDisplay

@export var monitor_name: String = "PRINCIPAL MONITOR"
@export var audio_bus: String = "Master"
@export var auto_connect: bool = true

@onready var viewport_2d = $ScreenOrigin/Viewport2Din3D
@onready var name_label = $Chassis/LabelName
var display: Node

func _ready():
	if name_label: name_label.text = monitor_name
	
	# Access the instantiated scene from Viewport2Din3D
	# It usually instantiates 'scene' as a child of its internal SubViewport
	if viewport_2d:
		# Wait for the scene to likely be ready or access it if already there
		var scene_instance = viewport_2d.get_scene_instance()
		if scene_instance:
			display = scene_instance.get_node_or_null("WaveformDisplay")
		
		# Fallback if get_scene_instance isn't immediate or available (depends on XR Tools version)
		if not display:
			# Try to find it manually in the viewport
			var vp = viewport_2d.get_node_or_null("Viewport") 
			if vp:
				for child in vp.get_children():
					var wd = child.get_node_or_null("WaveformDisplay")
					if wd:
						display = wd
						break
					if child.name == "VRAudioMonitorUI": # The root of our scene
						display = child.get_node_or_null("WaveformDisplay")
						break
	
	# If we are in the same scene as a UVAC, try to connect to it
	if auto_connect:
		_find_and_connect_to_uvac()

func _find_and_connect_to_uvac():
	# Look for UVAC in parent or siblings
	var parent = get_parent()
	if not parent: return
	
	for child in parent.get_children():
		if child.has_signal("sound_played"):
			child.connect("sound_played", _on_sound_played)
			print("VRAudioMonitor: Connected to UVAC")
			break

func _on_sound_played(_stream):
	# We could use the stream here, but waveform display currently monitors the bus
	# This is a hook for future granular monitoring
	pass

func set_mode(_is_spectrum: bool):
	if display:
		# Toggle between Oscilloscope and Spectrum if supported
		# For now, WaveformDisplay is primarily a spectral sine wave
		pass
