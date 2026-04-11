extends Node3D
class_name AirMusicDisplayCase
## Air Music Display Case
## A 0.5m glass display case with dark wood frame containing the Air Music system.
## Inspired by Ferm Living Miru - minimalist Scandinavian design.

## Overall case size in meters (0.5m cube default)

# @identity
# essence: display_case(air_music_instance, sliders[]) — framed exhibition of generative audio
# desire: Examine a generative air music system like a museum specimen with parameter controls
# critical_parameter: audio_volume_db — balances the sonic presence against the visual display
# triggers: slider adjustments modify the contained air music system parameters
# emerges: the museum-as-instrument — display cases that you play rather than observe
# needs: VR sliders [has], air music system [has]
# relationships: depends on air music generation; contrasts with SoundscapeRadioRack (curated display vs radio tuning); unlocks contemplative audio interaction
# truth: Framing sound as specimen transforms listening from passive reception to active examination.

@export_range(0.1, 2.0, 0.05) var case_scale: float = 0.5
## Dark walnut brown frame color
@export var frame_color: Color = Color(0.25, 0.15, 0.08, 1.0)
## Frame edge thickness in meters
@export_range(0.005, 0.1, 0.005) var frame_thickness: float = 0.02
## Height of the wooden platform base
@export_range(0.01, 0.2, 0.01) var base_height: float = 0.04
## Audio volume in decibels (negative = quieter)
@export_range(-40.0, 0.0, 0.5) var audio_volume_db: float = -12.0
## Scale of content inside the case relative to case size
@export_range(0.1, 1.0, 0.05) var inner_scale: float = 0.35

var SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")

var air_music_instance: Node3D
var _volume_slider: Node3D

func _ready():
	_setup_frame()
	_setup_base()
	_setup_air_music()
	_adjust_audio()
	_setup_controls()

## Scales the frame and applies wood color/thickness to all 12 cube lines.
func _setup_frame():
	# Scale the frame down
	var frame = $Frame
	if frame:
		frame.scale = Vector3.ONE * case_scale
		
		# Configure cube_lines with dark wood color and remove labels
		for i in range(1, 13):
			var line_name = "Line%d" % i
			var line_node = frame.get_node_or_null(line_name + "/lineContainer")
			if line_node and line_node.has_method("set_line_properties"):
				line_node.set_line_properties(frame_thickness, frame_color)
			
			# Remove the length labels (deferred — they're created in line's _ready)
			if line_node:
				_remove_label_deferred(line_node)
		
		# Also hide the cube label
		var cube_label = frame.get_node_or_null("Label3D")
		if cube_label:
			cube_label.visible = false

## Waits one frame then removes the auto-generated length label from a line node.
func _remove_label_deferred(line_node: Node) -> void:
	# Wait a frame so the line's _ready() has created the label
	await get_tree().process_frame
	var label = line_node.get_node_or_null("LengthLabel")
	if label:
		label.queue_free()

## Creates and styles the wooden base platform beneath the display case.
func _setup_base():
	# Create wooden base platform
	var base = $Base
	if base:
		var mesh = base.mesh as BoxMesh
		if mesh:
			var base_size = case_scale * 1.1
			mesh.size = Vector3(base_size, base_height, base_size)
		base.position.y = (-0.5 * case_scale) - (base_height / 2)
		
		# Create wood material
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.18, 0.1)  # Dark wood
		mat.roughness = 0.8
		mat.metallic = 0.0
		base.material_override = mat

## Scales, positions, and cleans up the embedded air music system.
func _setup_air_music():
	# Scale and position the air music system inside the case
	air_music_instance = $AirMusicContent
	if air_music_instance:
		air_music_instance.scale = Vector3.ONE * inner_scale
		# Center it inside the scaled case
		air_music_instance.position = Vector3(0, -0.05 * case_scale, 0)
		
		# Hide the label - we're in a display case, not a standalone demo
		var label = air_music_instance.get_node_or_null("Visualizer/Label")
		if label:
			label.visible = false
		
		# Hide the camera - we don't need an internal camera
		var cam = air_music_instance.get_node_or_null("Camera3D")
		if cam:
			cam.queue_free()

## Reduces audio volume and slows the intensity cycle for ambient effect.
func _adjust_audio():
	# Tone down the audio volume
	if air_music_instance:
		var synth = air_music_instance.get_node_or_null("FMPianoSynth")
		if synth and synth is AudioStreamPlayer3D:
			synth.volume_db = audio_volume_db
		elif synth and synth is AudioStreamPlayer:
			synth.volume_db = audio_volume_db
		
		# Also reduce intensity for subtler ambient effect
		var intensity = air_music_instance.get_node_or_null("IntensityController")
		if intensity and intensity.has_method("set"):
			# Make the intensity cycle longer for more ambient feel
			intensity.set("period", 90.0)

## Adds a VR volume slider below the display case.
func _setup_controls():
	_volume_slider = SliderScene.instantiate()
	_volume_slider.position = Vector3(0, (-0.5 * case_scale) - base_height - 0.05, 0.3)
	_volume_slider.set_param_name("Volume")
	_volume_slider.set_normalized_value(remap(audio_volume_db, -40.0, 0.0, 0.0, 1.0))
	_volume_slider.slider_moved.connect(_on_volume_changed)
	add_child(_volume_slider)

func _on_volume_changed():
	var val = _volume_slider.get_normalized_value()
	audio_volume_db = remap(val, 0.0, 1.0, -40.0, 0.0)
	if air_music_instance:
		var synth = air_music_instance.get_node_or_null("FMPianoSynth")
		if synth and (synth is AudioStreamPlayer3D or synth is AudioStreamPlayer):
			synth.volume_db = audio_volume_db

func apply_grid_config(config_data: Dictionary) -> void:
	pass