@tool
extends Node3D

## Principal VR Audio Monitor
## Visualizes audio waves in 3D using a SubViewport and WaveformDisplay

@export var monitor_name: String = "PRINCIPAL MONITOR"
@export var audio_bus: String = "Master"
@export var auto_connect: bool = true

@onready var viewport = $SubViewport
@onready var display = $SubViewport/WaveformDisplay
@onready var name_label = $Chassis/LabelName

func _ready():
	if name_label: name_label.text = monitor_name
	
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

func set_mode(is_spectrum: bool):
	if display:
		# Toggle between Oscilloscope and Spectrum if supported
		# For now, WaveformDisplay is primarily a spectral sine wave
		pass
