# MidiImporter.gd
# Imports Standard MIDI Files and converts them to song configuration format
#
# Supports both Format 0 (single track) and Format 1 (multi-track) MIDI files
# Converts MIDI data to pattern arrays compatible with SoundbankGenerator
#
# Usage:
#   var song_config = MidiImporter.import_midi("res://imports/song.mid")
#   var stream = SoundbankGenerator.generate_from_config(song_config)

class_name MidiImporter
extends RefCounted

# MIDI Constants (same as exporter)
const MIDI_HEADER = "MThd"
const MIDI_TRACK = "MTrk"

const NOTE_OFF = 0x80
const NOTE_ON = 0x90
const AFTERTOUCH = 0xA0
const CONTROL_CHANGE = 0xB0
const PROGRAM_CHANGE = 0xC0
const CHANNEL_PRESSURE = 0xD0
const PITCH_BEND = 0xE0
const SYSTEM_EXCLUSIVE = 0xF0
const META_EVENT = 0xFF

const META_SEQUENCE_NAME = 0x03
const META_INSTRUMENT_NAME = 0x04
const META_TEMPO = 0x51
const META_TIME_SIGNATURE = 0x58
const META_END_OF_TRACK = 0x2F

# Reverse drum map (MIDI note -> instrument name)
const DRUM_MAP = {
	36: "kick",
	35: "kick",
	38: "snare",
	40: "snare",
	39: "clap",
	37: "rimshot",
	42: "hihat",
	44: "hihat",
	46: "hihat_open",
	70: "shaker",
	54: "tambourine",
	56: "perc",
}

# Note ranges for melodic instrument detection
const INSTRUMENT_RANGES = {
	"bass": [24, 48],      # C1-C3
	"pad": [48, 84],       # C3-C6
	"lead": [60, 96],      # C4-C7
	"arp": [60, 96],
}


class MidiFile:
	var format: int = 1
	var num_tracks: int = 0
	var ticks_per_quarter: int = 480
	var tempo: float = 120.0
	var time_signature_num: int = 4
	var time_signature_den: int = 4
	var tracks: Array = []


class MidiTrack:
	var name: String = ""
	var channel: int = 0
	var program: int = 0
	var is_drum: bool = false
	var notes: Array = []  # Array of {tick, note, velocity, duration, channel}


class MidiNote:
	var tick: int = 0
	var note: int = 60
	var velocity: int = 100
	var duration: int = 480
	var channel: int = 0


static func import_midi(path: String) -> Dictionary:
	"""Import MIDI file and return song configuration"""
	print("MidiImporter: Loading %s" % path)
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MidiImporter: Cannot open file: " + path)
		return {}
	
	var data = file.get_buffer(file.get_length())
	file.close()
	
	var midi = _parse_midi(data)
	if midi == null:
		return {}
	
	return _convert_to_song_config(midi)


static func import_to_patterns(path: String) -> Dictionary:
	"""Import MIDI file and return raw pattern data"""
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MidiImporter: Cannot open file: " + path)
		return {}
	
	var data = file.get_buffer(file.get_length())
	file.close()
	
	var midi = _parse_midi(data)
	if midi == null:
		return {}
	
	return _extract_patterns(midi)


static func _parse_midi(data: PackedByteArray) -> MidiFile:
	"""Parse MIDI file data"""
	var pos = 0
	
	# Check header
	if data.size() < 14:
		push_error("MidiImporter: File too small")
		return null
	
	var header_id = data.slice(pos, pos + 4).get_string_from_utf8()
	if header_id != MIDI_HEADER:
		push_error("MidiImporter: Invalid MIDI header: " + header_id)
		return null
	pos += 4
	
	var header_length = _read_int(data, pos, 4)
	pos += 4
	
	var midi = MidiFile.new()
	midi.format = _read_int(data, pos, 2)
	pos += 2
	midi.num_tracks = _read_int(data, pos, 2)
	pos += 2
	midi.ticks_per_quarter = _read_int(data, pos, 2)
	pos += 2
	
	print("MidiImporter: Format %d, %d tracks, %d ticks/quarter" % [
		midi.format, midi.num_tracks, midi.ticks_per_quarter
	])
	
	# Parse tracks
	for i in range(midi.num_tracks):
		if pos >= data.size():
			break
		
		var track_result = _parse_track(data, pos, midi)
		if track_result.track != null:
			midi.tracks.append(track_result.track)
		pos = track_result.end_pos
	
	return midi


static func _parse_track(data: PackedByteArray, start_pos: int, midi: MidiFile) -> Dictionary:
	"""Parse a single MIDI track"""
	var pos = start_pos
	
	# Track header
	var track_id = data.slice(pos, pos + 4).get_string_from_utf8()
	if track_id != MIDI_TRACK:
		push_error("MidiImporter: Invalid track header at %d" % pos)
		return {"track": null, "end_pos": pos + 8}
	pos += 4
	
	var track_length = _read_int(data, pos, 4)
	pos += 4
	
	var track_end = pos + track_length
	var track = MidiTrack.new()
	
	var running_status = 0
	var absolute_tick = 0
	var pending_notes = {}  # note -> {tick, velocity}
	
	while pos < track_end and pos < data.size():
		# Read delta time
		var vlq_result = _read_variable_length(data, pos)
		var delta_time = vlq_result.value
		pos = vlq_result.end_pos
		absolute_tick += delta_time
		
		if pos >= data.size():
			break
		
		var status = data[pos]
		
		# Handle running status
		if status < 0x80:
			status = running_status
		else:
			pos += 1
			if status < 0xF0:
				running_status = status
		
		var event_type = status & 0xF0
		var channel = status & 0x0F
		
		match event_type:
			NOTE_OFF:
				var note = data[pos]
				var velocity = data[pos + 1]
				pos += 2
				
				# Complete pending note
				var key = "%d_%d" % [channel, note]
				if pending_notes.has(key):
					var pending = pending_notes[key]
					var midi_note = MidiNote.new()
					midi_note.tick = pending.tick
					midi_note.note = note
					midi_note.velocity = pending.velocity
					midi_note.duration = absolute_tick - pending.tick
					midi_note.channel = channel
					track.notes.append(midi_note)
					pending_notes.erase(key)
				
				if channel == 9:
					track.is_drum = true
				track.channel = channel
			
			NOTE_ON:
				var note = data[pos]
				var velocity = data[pos + 1]
				pos += 2
				
				if velocity == 0:
					# Note off via velocity 0
					var key = "%d_%d" % [channel, note]
					if pending_notes.has(key):
						var pending = pending_notes[key]
						var midi_note = MidiNote.new()
						midi_note.tick = pending.tick
						midi_note.note = note
						midi_note.velocity = pending.velocity
						midi_note.duration = absolute_tick - pending.tick
						midi_note.channel = channel
						track.notes.append(midi_note)
						pending_notes.erase(key)
				else:
					# New note on
					var key = "%d_%d" % [channel, note]
					pending_notes[key] = {"tick": absolute_tick, "velocity": velocity}
				
				if channel == 9:
					track.is_drum = true
				track.channel = channel
			
			AFTERTOUCH:
				pos += 2
			
			CONTROL_CHANGE:
				pos += 2
			
			PROGRAM_CHANGE:
				track.program = data[pos]
				pos += 1
			
			CHANNEL_PRESSURE:
				pos += 1
			
			PITCH_BEND:
				pos += 2
			
			_:
				if status == META_EVENT:
					var meta_type = data[pos]
					pos += 1
					var length_result = _read_variable_length(data, pos)
					var meta_length = length_result.value
					pos = length_result.end_pos
					
					match meta_type:
						META_SEQUENCE_NAME, META_INSTRUMENT_NAME:
							track.name = data.slice(pos, pos + meta_length).get_string_from_utf8()
						
						META_TEMPO:
							if meta_length >= 3:
								var microseconds = (data[pos] << 16) | (data[pos + 1] << 8) | data[pos + 2]
								midi.tempo = 60000000.0 / float(microseconds)
						
						META_TIME_SIGNATURE:
							if meta_length >= 4:
								midi.time_signature_num = data[pos]
								midi.time_signature_den = 1 << data[pos + 1]
						
						META_END_OF_TRACK:
							pass
					
					pos += meta_length
				
				elif status == SYSTEM_EXCLUSIVE:
					# Skip sysex
					while pos < data.size() and data[pos] != 0xF7:
						pos += 1
					pos += 1
	
	return {"track": track, "end_pos": track_end}


static func _convert_to_song_config(midi: MidiFile) -> Dictionary:
	"""Convert parsed MIDI to song configuration format"""
	
	var config = {
		"bpm": midi.tempo,
		"time_signature": [midi.time_signature_num, midi.time_signature_den],
		"ticks_per_quarter": midi.ticks_per_quarter,
		"patterns": {},
		"bass_pattern": {},
		"tracks": []
	}
	
	for track in midi.tracks:
		if track.notes.is_empty():
			continue
		
		var track_info = {
			"name": track.name if track.name else "Track %d" % (config.tracks.size() + 1),
			"channel": track.channel,
			"program": track.program,
			"is_drum": track.is_drum,
			"notes": []
		}
		
		# Convert notes
		for note in track.notes:
			track_info.notes.append({
				"tick": note.tick,
				"note": note.note,
				"velocity": note.velocity,
				"duration": note.duration
			})
		
		config.tracks.append(track_info)
		
		# Extract patterns (quantize to 16th notes)
		var patterns = _extract_track_patterns(track, midi)
		for pattern_name in patterns:
			if config.patterns.has(pattern_name):
				# Merge patterns
				var existing = config.patterns[pattern_name]
				var new_pattern = patterns[pattern_name]
				for i in range(mini(existing.size(), new_pattern.size())):
					if new_pattern[i] > 0:
						existing[i] = maxf(existing[i], new_pattern[i])
			else:
				config.patterns[pattern_name] = patterns[pattern_name]
	
	return config


static func _extract_patterns(midi: MidiFile) -> Dictionary:
	"""Extract patterns from MIDI file"""
	var patterns = {}
	
	for track in midi.tracks:
		var track_patterns = _extract_track_patterns(track, midi)
		for pattern_name in track_patterns:
			patterns[pattern_name] = track_patterns[pattern_name]
	
	return {
		"bpm": midi.tempo,
		"patterns": patterns
	}


static func _extract_track_patterns(track: MidiTrack, midi: MidiFile) -> Dictionary:
	"""Extract 16-step patterns from a track"""
	var patterns = {}
	var ticks_per_16th = midi.ticks_per_quarter / 4
	
	# Group notes by instrument/pitch
	var note_groups = {}
	
	for note in track.notes:
		var group_key: String
		
		if track.is_drum:
			# Use drum map
			var instrument = DRUM_MAP.get(note.note, "perc")
			group_key = instrument
		else:
			# Use track name or detect by range
			if track.name:
				group_key = track.name.to_lower().replace(" ", "_")
			else:
				group_key = _detect_instrument_type(note.note)
		
		if not note_groups.has(group_key):
			note_groups[group_key] = []
		note_groups[group_key].append(note)
	
	# Convert each group to pattern
	for group_key in note_groups:
		var notes = note_groups[group_key]
		var pattern = _notes_to_pattern(notes, ticks_per_16th)
		patterns[group_key] = pattern
	
	return patterns


static func _notes_to_pattern(notes: Array, ticks_per_16th: int) -> Array:
	"""Convert note array to 16-step pattern"""
	var pattern = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var bar_ticks = ticks_per_16th * 16
	
	for note in notes:
		# Quantize to step
		var step = int(round(float(note.tick % bar_ticks) / float(ticks_per_16th)))
		step = clampi(step, 0, 15)
		
		# Convert velocity to pattern value
		var vel_value: float
		if note.velocity >= 110:
			vel_value = 2.0  # Accent
		elif note.velocity >= 80:
			vel_value = 1.0  # Normal
		else:
			vel_value = float(note.velocity) / 127.0  # Ghost
		
		# Take maximum velocity for overlapping notes
		pattern[step] = maxf(pattern[step], vel_value)
	
	return pattern


static func _detect_instrument_type(note: int) -> String:
	"""Detect instrument type from MIDI note number"""
	if note < 36:
		return "sub"
	elif note < 48:
		return "bass"
	elif note < 60:
		return "pad"
	elif note < 84:
		return "lead"
	else:
		return "arp"


static func _read_int(data: PackedByteArray, pos: int, num_bytes: int) -> int:
	"""Read big-endian integer from data"""
	var result = 0
	for i in range(num_bytes):
		if pos + i < data.size():
			result = (result << 8) | data[pos + i]
	return result


static func _read_variable_length(data: PackedByteArray, pos: int) -> Dictionary:
	"""Read variable-length quantity from data"""
	var result = 0
	var end_pos = pos
	
	while end_pos < data.size():
		var byte = data[end_pos]
		result = (result << 7) | (byte & 0x7F)
		end_pos += 1
		
		if (byte & 0x80) == 0:
			break
	
	return {"value": result, "end_pos": end_pos}


static func create_song_from_patterns(patterns: Dictionary, genre_template: String = "") -> Dictionary:
	"""Create a full song config from imported patterns, optionally using a genre template"""
	var config = {
		"bpm": patterns.get("bpm", 120.0),
		"patterns": patterns.get("patterns", {}),
		"structure": SoundbankGenerator.STRUCTURES.get(genre_template, {
			"sections": ["main"],
			"bars": [16]
		}),
		"velocity": SoundbankGenerator.VELOCITY.get(genre_template, SoundbankGenerator.VELOCITY["detroit_techno"]),
		"swing": SoundbankGenerator.SWING.get(genre_template, 0.0)
	}
	
	return config


static func get_pattern_preview(pattern: Array) -> String:
	"""Get ASCII preview of pattern for display"""
	var result = ""
	for i in range(pattern.size()):
		if pattern[i] >= 2:
			result += "█"
		elif pattern[i] >= 1:
			result += "▓"
		elif pattern[i] > 0:
			result += "░"
		else:
			result += "·"
		
		if i == 3 or i == 7 or i == 11:
			result += " "
	
	return result
