# MessageItem.gd
extends HBoxContainer

@onready var timestamp_label = $Timestamp
@onready var source_label = $Source
@onready var message_label = $Message

# Audio player for console sounds
var audio_player: AudioStreamPlayer

# Color scheme for different message types
var type_colors = {
	"info": Color.GREEN,
	"warning": Color.GREEN,
	"error": Color.RED,
	"debug": Color.GREEN,
	"success": Color.GREEN
}

func _ready():
	"""Initialize audio player for console sounds"""
	create_console_sound()

func create_console_sound():
	"""Create a simple console beep sound"""
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# Create a simple beep sound programmatically
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	
	# Generate a short beep (0.1 seconds)
	var duration = 0.1
	var samples = int(duration * stream.mix_rate)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	# Create a simple sine wave beep at 800Hz
	var frequency = 800.0
	for i in range(samples):
		var t = float(i) / stream.mix_rate
		var sample = sin(2.0 * PI * frequency * t) * 0.3  # 30% volume
		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_int)
	
	stream.data = data
	audio_player.stream = stream
	audio_player.volume_db = -10.0  # Slightly quieter

func play_console_sound():
	"""Play the console beep sound"""
	if audio_player and audio_player.stream:
		audio_player.play()

func convert_to_12_hour(time_24h: String) -> String:
	"""Convert 24-hour time (HH:MM:SS) to 12-hour format (H:MM AM/PM)"""
	var time_parts = time_24h.split(":")
	if time_parts.size() < 2:
		return time_24h
	
	var hour = int(time_parts[0])
	var minute = time_parts[1]
	var am_pm = "AM"
	
	# Convert to 12-hour format
	if hour == 0:
		hour = 12
	elif hour == 12:
		am_pm = "PM"
	elif hour > 12:
		hour = hour - 12
		am_pm = "PM"
	
	# Format as "H:MM AM/PM" (remove leading zero from hour)
	return "%d:%s %s" % [hour, minute, am_pm]

func setup_message(message_data: Dictionary):
	var text = message_data.get("text", "")
	var type = message_data.get("type", "info")
	var source = message_data.get("source", "system")
	var timestamp = message_data.get("timestamp", "")
	
	# Play console sound for new message
	play_console_sound()
	
	# Format timestamp (extract just time portion and convert to 12-hour format)
	var time_part = ""
	if timestamp.length() > 0:
		# Handle both formats: "YYYY-MM-DD HH:MM:SS" and "YYYY-MM-DDTHH:MM:SS"
		var time_24h = ""
		if "T" in timestamp:
			# ISO format: 2025-09-19T13:41:34
			var parts = timestamp.split("T")
			if parts.size() >= 2:
				time_24h = parts[1].substr(0, 8)  # Get HH:MM:SS
		else:
			# Space format: 2025-09-19 13:41:34
			var parts = timestamp.split(" ")
			if parts.size() >= 2:
				time_24h = parts[1].substr(0, 8)  # Get HH:MM:SS
		
		if time_24h.length() > 0:
			time_part = convert_to_12_hour(time_24h)
		else:
			time_part = timestamp
	
	# Ensure nodes are ready before setting text
	if not timestamp_label:
		timestamp_label = $Timestamp
	if not source_label:
		source_label = $Source
	if not message_label:
		message_label = $Message
	
	# Set the labels
	if timestamp_label:
		timestamp_label.text = time_part
		timestamp_label.add_theme_color_override("font_color", Color.GREEN)
	if source_label:
		source_label.text = "[%s]" % source.to_upper()
		source_label.add_theme_color_override("font_color", Color.GREEN)
	if message_label:
		message_label.text = text
		message_label.add_theme_color_override("font_color", Color.GREEN)
	
