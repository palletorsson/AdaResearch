extends Node3D
## Air Music Display Case
## A 0.5m glass display case with dark wood frame containing the Air Music system.
## Inspired by Ferm Living Miru - minimalist Scandinavian design.

@export var case_scale: float = 0.5  # Overall case size (0.5m cube)
@export var frame_color: Color = Color(0.25, 0.15, 0.08, 1.0)  # Dark walnut brown
@export var frame_thickness: float = 0.02  # Thicker for wood appearance
@export var base_height: float = 0.04  # Wood platform base
@export var audio_volume_db: float = -12.0  # Quieter than default
@export var inner_scale: float = 0.35  # Scale of content inside (half of case)

var air_music_instance: Node3D

func _ready():
	_setup_frame()
	_setup_base()
	_setup_air_music()
	_adjust_audio()

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
			
			# Remove the length labels
			var label = frame.get_node_or_null(line_name + "/lineContainer/LengthLabel")
			if label:
				label.queue_free()

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

func _adjust_audio():
	# Tone down the audio volume
	if air_music_instance:
		var synth = air_music_instance.get_node_or_null("FMPianoSynth")
		if synth and synth is AudioStreamPlayer:
			synth.volume_db = audio_volume_db
		
		# Also reduce intensity for subtler ambient effect
		var intensity = air_music_instance.get_node_or_null("IntensityController")
		if intensity and intensity.has_method("set"):
			# Make the intensity cycle longer for more ambient feel
			intensity.set("period", 90.0)
