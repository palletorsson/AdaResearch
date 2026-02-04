# SongExporter.gd
# Exports procedurally generated songs to WAV files
#
# Usage (from Godot console or script):
#   SongExporter.export_song("detroit_techno", "res://exports/detroit.wav")
#   SongExporter.export_midnight_metroplex("res://exports/midnight_metroplex.wav")

class_name SongExporter
extends RefCounted

const SAMPLE_RATE = 44100.0


static func export_song(genre_id: String, output_path: String, params: Dictionary = {}) -> bool:
	"""Export a soundbank-based song to WAV file"""
	print("SongExporter: Generating %s..." % genre_id)
	
	var stream = SoundbankGenerator.generate_song(genre_id, params)
	if stream == null:
		push_error("SongExporter: Failed to generate song for " + genre_id)
		return false
	
	return _export_interactive_stream(stream, output_path)


static func export_midnight_metroplex(output_path: String = "res://exports/midnight_metroplex.wav") -> bool:
	"""Export the Midnight Metroplex Detroit Techno track"""
	return export_song("detroit_techno", output_path, {})


static func export_interactive_to_wav(stream: AudioStreamInteractive, output_path: String) -> int:
	"""Export an existing AudioStreamInteractive to WAV file. Returns OK on success."""
	if stream == null:
		push_error("SongExporter: No stream provided")
		return ERR_INVALID_PARAMETER
	
	var success = _export_interactive_stream(stream, output_path)
	return OK if success else ERR_FILE_CANT_WRITE


static func _export_interactive_stream(stream: AudioStreamInteractive, output_path: String) -> bool:
	"""Convert an AudioStreamInteractive to a single WAV file"""
	
	# Collect all section audio data
	var all_samples: PackedFloat32Array = PackedFloat32Array()
	var clip_count = stream.clip_count
	
	print("SongExporter: Concatenating %d sections..." % clip_count)
	
	for i in range(clip_count):
		var clip_name = stream.get_clip_name(i)
		var clip_stream = stream.get_clip_stream(i)
		
		if clip_stream == null:
			push_warning("SongExporter: Clip %d (%s) has no stream" % [i, clip_name])
			continue
		
		if clip_stream is AudioStreamWAV:
			var wav: AudioStreamWAV = clip_stream
			var section_samples = _wav_to_float_array(wav)
			print("  Section '%s': %d samples (%.1fs)" % [clip_name, section_samples.size(), section_samples.size() / SAMPLE_RATE])
			all_samples.append_array(section_samples)
		else:
			push_warning("SongExporter: Clip %d (%s) is not AudioStreamWAV" % [i, clip_name])
	
	if all_samples.is_empty():
		push_error("SongExporter: No audio data to export")
		return false
	
	# Add short crossfades between sections (already done in generator, but ensure smooth)
	_apply_fade_envelope(all_samples, int(SAMPLE_RATE * 0.05))
	
	# Create output WAV
	var final_wav = _create_wav_stream(all_samples)
	
	# Ensure output directory exists
	var dir_path = output_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	
	# Save to file
	var success = _save_wav_file(final_wav, output_path)
	
	if success:
		var duration = all_samples.size() / SAMPLE_RATE
		print("SongExporter: Exported %.1fs of audio to %s" % [duration, output_path])
	
	return success


static func _wav_to_float_array(wav: AudioStreamWAV) -> PackedFloat32Array:
	"""Convert AudioStreamWAV data to float array"""
	var data = wav.data
	var samples = PackedFloat32Array()
	
	if wav.format == AudioStreamWAV.FORMAT_16_BITS:
		var sample_count = data.size() / 2
		if wav.stereo:
			sample_count /= 2  # Mono output
		samples.resize(sample_count)
		
		for i in range(sample_count):
			var byte_idx = i * 2
			if wav.stereo:
				byte_idx = i * 4  # Skip to left channel only
			
			if byte_idx + 1 < data.size():
				var lo = data[byte_idx]
				var hi = data[byte_idx + 1]
				var sample_16 = lo | (hi << 8)
				if sample_16 >= 32768:
					sample_16 -= 65536
				samples[i] = float(sample_16) / 32767.0
	
	elif wav.format == AudioStreamWAV.FORMAT_8_BITS:
		var sample_count = data.size()
		if wav.stereo:
			sample_count /= 2
		samples.resize(sample_count)
		
		for i in range(sample_count):
			var byte_idx = i
			if wav.stereo:
				byte_idx = i * 2
			samples[i] = (float(data[byte_idx]) - 128.0) / 128.0
	
	return samples


static func _create_wav_stream(buffer: PackedFloat32Array) -> AudioStreamWAV:
	"""Create AudioStreamWAV from float buffer"""
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(SAMPLE_RATE)
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(buffer.size() * 2)
	
	for i in range(buffer.size()):
		var sample_16 = int(clampf(buffer[i], -1.0, 1.0) * 32767.0)
		data[i * 2] = sample_16 & 0xFF
		data[i * 2 + 1] = (sample_16 >> 8) & 0xFF
	
	stream.data = data
	return stream


static func _apply_fade_envelope(buffer: PackedFloat32Array, fade_samples: int) -> void:
	"""Apply fade in/out to avoid clicks"""
	var size = buffer.size()
	for i in range(mini(fade_samples, size)):
		var fade = float(i) / fade_samples
		buffer[i] *= fade
		buffer[size - 1 - i] *= fade


static func _save_wav_file(wav: AudioStreamWAV, path: String) -> bool:
	"""Save AudioStreamWAV to disk as a proper WAV file"""
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SongExporter: Cannot open file for writing: " + path)
		return false
	
	var data = wav.data
	var sample_rate = wav.mix_rate
	var channels = 2 if wav.stereo else 1
	var bits_per_sample = 16 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 8
	var byte_rate = sample_rate * channels * bits_per_sample / 8
	var block_align = channels * bits_per_sample / 8
	
	# WAV header
	file.store_string("RIFF")
	file.store_32(36 + data.size())  # File size - 8
	file.store_string("WAVE")
	
	# fmt chunk
	file.store_string("fmt ")
	file.store_32(16)  # Chunk size
	file.store_16(1)   # PCM format
	file.store_16(channels)
	file.store_32(sample_rate)
	file.store_32(byte_rate)
	file.store_16(block_align)
	file.store_16(bits_per_sample)
	
	# data chunk
	file.store_string("data")
	file.store_32(data.size())
	file.store_buffer(data)
	
	file.close()
	return true


# === CONVENIENCE EXPORTS ===

static func export_detroit(output_path: String = "res://exports/detroit_techno.wav") -> bool:
	return export_song("detroit_techno", output_path)

static func export_synthwave(output_path: String = "res://exports/synthwave.wav") -> bool:
	return export_song("synthwave", output_path)

static func export_burial(output_path: String = "res://exports/burial.wav") -> bool:
	return export_song("burial", output_path)

static func export_boards_of_canada(output_path: String = "res://exports/boards_of_canada.wav") -> bool:
	return export_song("boards_of_canada", output_path)

static func export_rave(output_path: String = "res://exports/rave.wav") -> bool:
	return export_song("rave", output_path)

static func export_kraftwerk(output_path: String = "res://exports/kraftwerk.wav") -> bool:
	return export_song("kraftwerk", output_path)
