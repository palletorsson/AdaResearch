# MidiExporter.gd
# Exports procedural songs to Standard MIDI File (SMF) format
#
# Creates multi-track MIDI files with one track per instrument
# Reference: Standard MIDI File 1.0 specification
#
# Usage:
#   MidiExporter.export_song("detroit_techno", "res://exports/detroit.mid")
#   MidiExporter.export_patterns("detroit_techno", "res://exports/detroit_patterns.mid", 126)

class_name MidiExporter
extends RefCounted

# MIDI Constants
const MIDI_HEADER = "MThd"
const MIDI_TRACK = "MTrk"
const TICKS_PER_QUARTER = 480  # Standard resolution

# MIDI Event Types
const NOTE_OFF = 0x80
const NOTE_ON = 0x90
const CONTROL_CHANGE = 0xB0
const PROGRAM_CHANGE = 0xC0
const META_EVENT = 0xFF

# Meta Event Types
const META_SEQUENCE_NAME = 0x03
const META_INSTRUMENT_NAME = 0x04
const META_TEMPO = 0x51
const META_TIME_SIGNATURE = 0x58
const META_END_OF_TRACK = 0x2F

# GM Drum Map (Channel 10 / 9 in 0-indexed)
const DRUM_NOTES = {
	"kick": 36,        # Bass Drum 1
	"snare": 38,       # Acoustic Snare
	"clap": 39,        # Hand Clap
	"rimshot": 37,     # Side Stick
	"hihat": 42,       # Closed Hi-Hat
	"hihat_open": 46,  # Open Hi-Hat
	"cr5000_kick": 36,
	"cr5000_snare": 38,
	"cr5000_hihat": 42,
	"shaker": 70,      # Maracas
	"fingersnap": 34,  # Metronome Click (close enough)
	"tambourine": 54,  # Tambourine
	"perc": 56,        # Cowbell
}

# Default melodic notes for instruments
const MELODIC_BASE = {
	"bass": 36,        # C2
	"sub": 36,         # C2
	"hoover": 48,      # C3
	"pad": 60,         # C4
	"stab": 60,        # C4
	"piano": 60,       # C4
	"organ": 60,       # C4
	"rhodes": 60,      # C4
	"strings": 60,     # C4
	"arp": 72,         # C5
	"sequence": 72,    # C5
	"sequencer": 72,   # C5
	"jupiter_arp": 72, # C5
	"lead": 72,        # C5
	"vocoder": 60,     # C4
	"singing_voice": 72, # C5
	"vocal": 60,       # C4
}

# GM Program numbers for instruments
const PROGRAM_MAP = {
	"bass": 33,        # Electric Bass (finger)
	"sub": 38,         # Synth Bass 1
	"hoover": 87,      # Lead 8 (bass + lead)
	"pad": 89,         # Pad 2 (warm)
	"stab": 81,        # Lead 2 (sawtooth)
	"piano": 4,        # Electric Piano 1
	"organ": 16,       # Drawbar Organ
	"rhodes": 4,       # Electric Piano 1
	"strings": 48,     # String Ensemble 1
	"arp": 83,         # Lead 4 (chiff)
	"sequence": 80,    # Lead 1 (square)
	"sequencer": 80,
	"jupiter_arp": 83,
	"lead": 81,        # Lead 2 (sawtooth)
	"vocoder": 54,     # Synth Voice
	"singing_voice": 54,
	"vocal": 54,
	"atmosphere": 99,  # FX 4 (atmosphere)
	"crackle": 121,    # Breath Noise
	"texture": 99,
}


static func export_song(genre_id: String, output_path: String, params: Dictionary = {}) -> bool:
	"""Export a full song's patterns to MIDI file"""
	print("MidiExporter: Exporting %s to %s" % [genre_id, output_path])
	
	var bpm = params.get("bpm", _get_default_bpm(genre_id))
	var num_bars = params.get("bars", 4)  # Default to 4 bars
	
	return export_patterns(genre_id, output_path, bpm, num_bars)


static func export_patterns(genre_id: String, output_path: String, bpm: float = 120.0, num_bars: int = 4) -> bool:
	"""Export genre patterns to MIDI file with specified BPM and length"""
	
	var patterns = SoundbankGenerator.PATTERNS.get(genre_id, {})
	var bass_pattern = SoundbankGenerator.BASS_PATTERNS.get(genre_id, {})
	
	if patterns.is_empty():
		push_error("MidiExporter: No patterns found for genre: " + genre_id)
		return false
	
	# Collect all tracks
	var tracks: Array = []
	
	# Add drum tracks
	for instrument in patterns.keys():
		if DRUM_NOTES.has(instrument):
			var pattern = patterns[instrument]
			var track_data = _create_drum_track(instrument, pattern, num_bars, bpm)
			tracks.append(track_data)
	
	# Add melodic pattern tracks
	for instrument in patterns.keys():
		if not DRUM_NOTES.has(instrument) and MELODIC_BASE.has(instrument):
			var pattern = patterns[instrument]
			var track_data = _create_melodic_track(instrument, pattern, num_bars, bpm)
			tracks.append(track_data)
	
	# Add bass track if exists
	if bass_pattern.has("pattern"):
		var track_data = _create_bass_track(bass_pattern, num_bars, bpm)
		tracks.append(track_data)
	
	if tracks.is_empty():
		push_error("MidiExporter: No valid tracks to export")
		return false
	
	# Build MIDI file
	var midi_data = _build_midi_file(tracks, bpm, genre_id)
	
	# Save to file
	return _save_midi_file(midi_data, output_path)


static func export_stem_data(stem_data: Dictionary, output_path: String, bpm: float = 120.0) -> bool:
	"""Export stem editor data to MIDI file"""
	
	var tracks: Array = []
	var num_bars = stem_data.get("bars", 4)
	
	for track in stem_data.get("tracks", []):
		var instrument = track.get("name", "unknown")
		var pattern = track.get("pattern", [])
		var muted = track.get("muted", false)
		
		if muted or pattern.is_empty():
			continue
		
		if DRUM_NOTES.has(instrument):
			tracks.append(_create_drum_track(instrument, pattern, num_bars, bpm))
		elif MELODIC_BASE.has(instrument):
			tracks.append(_create_melodic_track(instrument, pattern, num_bars, bpm))
	
	if tracks.is_empty():
		push_error("MidiExporter: No tracks to export from stem data")
		return false
	
	var midi_data = _build_midi_file(tracks, bpm, "custom")
	return _save_midi_file(midi_data, output_path)


static func _create_drum_track(instrument: String, pattern: Array, num_bars: int, bpm: float) -> Dictionary:
	"""Create a drum track from pattern data"""
	var events: Array = []
	var note = DRUM_NOTES.get(instrument, 36)
	var ticks_per_step = TICKS_PER_QUARTER / 4  # 16th note = quarter of a quarter
	
	for bar in range(num_bars):
		var bar_offset = bar * 16 * ticks_per_step
		
		for step in range(pattern.size()):
			var vel_value = pattern[step]
			if vel_value <= 0:
				continue
			
			var velocity = _velocity_to_midi(vel_value)
			var tick = bar_offset + step * ticks_per_step
			var duration = ticks_per_step / 2  # Short drum hits
			
			events.append({
				"tick": tick,
				"type": "note",
				"note": note,
				"velocity": velocity,
				"duration": duration,
				"channel": 9  # Drum channel (0-indexed)
			})
	
	return {
		"name": instrument.capitalize(),
		"instrument": instrument,
		"channel": 9,
		"events": events,
		"is_drum": true
	}


static func _create_melodic_track(instrument: String, pattern: Array, num_bars: int, bpm: float) -> Dictionary:
	"""Create a melodic track from pattern data"""
	var events: Array = []
	var base_note = MELODIC_BASE.get(instrument, 60)
	var ticks_per_step = TICKS_PER_QUARTER / 4
	var channel = _get_channel_for_instrument(instrument)
	
	for bar in range(num_bars):
		var bar_offset = bar * 16 * ticks_per_step
		
		for step in range(pattern.size()):
			var vel_value = pattern[step]
			if vel_value <= 0:
				continue
			
			var velocity = _velocity_to_midi(vel_value)
			var tick = bar_offset + step * ticks_per_step
			
			# Calculate duration until next hit or end of pattern
			var duration = ticks_per_step
			for next_step in range(step + 1, pattern.size()):
				if pattern[next_step] > 0:
					duration = (next_step - step) * ticks_per_step
					break
				elif next_step == pattern.size() - 1:
					duration = (pattern.size() - step) * ticks_per_step
			
			events.append({
				"tick": tick,
				"type": "note",
				"note": base_note,
				"velocity": velocity,
				"duration": duration,
				"channel": channel
			})
	
	return {
		"name": instrument.capitalize(),
		"instrument": instrument,
		"channel": channel,
		"program": PROGRAM_MAP.get(instrument, 0),
		"events": events,
		"is_drum": false
	}


static func _create_bass_track(bass_cfg: Dictionary, num_bars: int, bpm: float) -> Dictionary:
	"""Create bass track from bass pattern configuration"""
	var events: Array = []
	var pattern = bass_cfg.get("pattern", [])
	var style = bass_cfg.get("style", "sustained")
	var base_note = 36  # C2
	var ticks_per_step = TICKS_PER_QUARTER / 4
	var channel = 1  # Bass on channel 2
	
	for bar in range(num_bars):
		var bar_offset = bar * 16 * ticks_per_step
		
		for step in range(pattern.size()):
			var vel_value = pattern[step]
			if vel_value <= 0:
				continue
			
			var velocity = _velocity_to_midi(vel_value)
			var tick = bar_offset + step * ticks_per_step
			
			# Duration based on style
			var duration: int
			match style:
				"short":
					duration = ticks_per_step / 2
				"continuous":
					duration = 16 * ticks_per_step  # Full bar
				"walking":
					duration = ticks_per_step * 3  # Slightly overlapping
				_:  # sustained
					# Find next hit
					duration = ticks_per_step * 2
					for next_step in range(step + 1, pattern.size()):
						if pattern[next_step] > 0:
							duration = (next_step - step) * ticks_per_step - ticks_per_step / 4
							break
			
			events.append({
				"tick": tick,
				"type": "note",
				"note": base_note,
				"velocity": velocity,
				"duration": duration,
				"channel": channel
			})
	
	return {
		"name": "Bass",
		"instrument": "bass",
		"channel": channel,
		"program": PROGRAM_MAP.get("bass", 33),
		"events": events,
		"is_drum": false
	}


static func _build_midi_file(tracks: Array, bpm: float, song_name: String) -> PackedByteArray:
	"""Build complete MIDI file from tracks"""
	var output = PackedByteArray()
	
	# Header chunk
	output.append_array(_create_header_chunk(tracks.size() + 1))  # +1 for tempo track
	
	# Tempo/conductor track (track 0)
	output.append_array(_create_tempo_track(bpm, song_name))
	
	# Instrument tracks
	for track in tracks:
		output.append_array(_create_track_chunk(track))
	
	return output


static func _create_header_chunk(num_tracks: int) -> PackedByteArray:
	"""Create MIDI header chunk"""
	var chunk = PackedByteArray()
	
	# "MThd"
	chunk.append_array(MIDI_HEADER.to_utf8_buffer())
	
	# Chunk length (always 6)
	chunk.append_array(_int_to_bytes(6, 4))
	
	# Format type (1 = multi-track)
	chunk.append_array(_int_to_bytes(1, 2))
	
	# Number of tracks
	chunk.append_array(_int_to_bytes(num_tracks, 2))
	
	# Ticks per quarter note
	chunk.append_array(_int_to_bytes(TICKS_PER_QUARTER, 2))
	
	return chunk


static func _create_tempo_track(bpm: float, song_name: String) -> PackedByteArray:
	"""Create tempo/conductor track"""
	var events = PackedByteArray()
	
	# Track name meta event
	events.append(0x00)  # Delta time
	events.append(META_EVENT)
	events.append(META_SEQUENCE_NAME)
	var name_bytes = song_name.to_utf8_buffer()
	events.append_array(_create_variable_length(name_bytes.size()))
	events.append_array(name_bytes)
	
	# Time signature (4/4)
	events.append(0x00)
	events.append(META_EVENT)
	events.append(META_TIME_SIGNATURE)
	events.append(0x04)  # Length
	events.append(0x04)  # Numerator (4)
	events.append(0x02)  # Denominator (2^2 = 4)
	events.append(0x18)  # Clocks per metronome click (24)
	events.append(0x08)  # 32nd notes per quarter (8)
	
	# Tempo (microseconds per quarter note)
	var microseconds_per_beat = int(60000000.0 / bpm)
	events.append(0x00)
	events.append(META_EVENT)
	events.append(META_TEMPO)
	events.append(0x03)  # Length
	events.append((microseconds_per_beat >> 16) & 0xFF)
	events.append((microseconds_per_beat >> 8) & 0xFF)
	events.append(microseconds_per_beat & 0xFF)
	
	# End of track
	events.append(0x00)
	events.append(META_EVENT)
	events.append(META_END_OF_TRACK)
	events.append(0x00)
	
	# Build track chunk
	var chunk = PackedByteArray()
	chunk.append_array(MIDI_TRACK.to_utf8_buffer())
	chunk.append_array(_int_to_bytes(events.size(), 4))
	chunk.append_array(events)
	
	return chunk


static func _create_track_chunk(track: Dictionary) -> PackedByteArray:
	"""Create a single track chunk"""
	var events = PackedByteArray()
	var channel = track.get("channel", 0)
	
	# Track name
	events.append(0x00)
	events.append(META_EVENT)
	events.append(META_INSTRUMENT_NAME)
	var name_bytes = track.get("name", "Track").to_utf8_buffer()
	events.append_array(_create_variable_length(name_bytes.size()))
	events.append_array(name_bytes)
	
	# Program change (for melodic instruments)
	if not track.get("is_drum", false):
		events.append(0x00)
		events.append(PROGRAM_CHANGE | channel)
		events.append(track.get("program", 0))
	
	# Sort events by tick
	var note_events = track.get("events", [])
	note_events.sort_custom(func(a, b): return a.tick < b.tick)
	
	# Create note on/off events
	var all_events: Array = []
	for ev in note_events:
		all_events.append({
			"tick": ev.tick,
			"status": NOTE_ON | ev.channel,
			"data1": ev.note,
			"data2": ev.velocity
		})
		all_events.append({
			"tick": ev.tick + ev.duration,
			"status": NOTE_OFF | ev.channel,
			"data1": ev.note,
			"data2": 0
		})
	
	# Sort all events
	all_events.sort_custom(func(a, b): return a.tick < b.tick)
	
	# Convert to delta times and add to events
	var last_tick = 0
	for ev in all_events:
		var delta = ev.tick - last_tick
		events.append_array(_create_variable_length(delta))
		events.append(ev.status)
		events.append(ev.data1)
		events.append(ev.data2)
		last_tick = ev.tick
	
	# End of track
	events.append(0x00)
	events.append(META_EVENT)
	events.append(META_END_OF_TRACK)
	events.append(0x00)
	
	# Build track chunk
	var chunk = PackedByteArray()
	chunk.append_array(MIDI_TRACK.to_utf8_buffer())
	chunk.append_array(_int_to_bytes(events.size(), 4))
	chunk.append_array(events)
	
	return chunk


static func _create_variable_length(value: int) -> PackedByteArray:
	"""Create variable-length quantity (VLQ) for MIDI"""
	var result = PackedByteArray()
	
	if value == 0:
		result.append(0)
		return result
	
	var bytes: Array = []
	var temp = value
	
	while temp > 0:
		bytes.append(temp & 0x7F)
		temp >>= 7
	
	bytes.reverse()
	
	for i in range(bytes.size()):
		if i < bytes.size() - 1:
			result.append(bytes[i] | 0x80)
		else:
			result.append(bytes[i])
	
	return result


static func _int_to_bytes(value: int, num_bytes: int) -> PackedByteArray:
	"""Convert integer to big-endian bytes"""
	var result = PackedByteArray()
	for i in range(num_bytes - 1, -1, -1):
		result.append((value >> (i * 8)) & 0xFF)
	return result


static func _velocity_to_midi(vel_value: float) -> int:
	"""Convert pattern velocity (0-2+) to MIDI velocity (1-127)"""
	if vel_value >= 2.0:
		return 127  # Accent
	elif vel_value >= 1.0:
		return 100  # Normal
	elif vel_value > 0:
		return int(vel_value * 70) + 30  # Ghost notes (30-100)
	return 0


static func _get_channel_for_instrument(instrument: String) -> int:
	"""Get MIDI channel for instrument (avoid channel 10/9 for drums)"""
	var channel_map = {
		"bass": 1,
		"sub": 1,
		"hoover": 1,
		"pad": 2,
		"strings": 2,
		"atmosphere": 2,
		"stab": 3,
		"piano": 4,
		"organ": 4,
		"rhodes": 4,
		"arp": 5,
		"sequence": 5,
		"sequencer": 5,
		"jupiter_arp": 5,
		"lead": 6,
		"vocoder": 7,
		"vocal": 7,
		"singing_voice": 7,
	}
	return channel_map.get(instrument, 0)


static func _get_default_bpm(genre_id: String) -> float:
	"""Get default BPM for genre"""
	var bpm_map = {
		"moroder_disco": 126.0,
		"detroit_techno": 126.0,
		"synthwave": 118.0,
		"burial": 130.0,
		"boards_of_canada": 100.0,
		"rave": 145.0,
		"kraftwerk": 129.0,
		"madonna_80s": 118.0,
		"gypsy_woman_house": 122.0,
		"dub_house": 122.0,
		"nineties_rnb": 92.0,
		"chromatic_story": 100.0,
		"vangelis_cs80": 90.0,
		"replicants_dawn": 120.0,
		"foggy_frequencies": 130.0,
		"chicago_dusseldorf": 122.0,
		"k_bass": 170.0,
	}
	return bpm_map.get(genre_id, 120.0)


# ===========================================================================
# MidiCapture export — for AudioSynthesizer procedural songs
# ===========================================================================

static func export_from_capture(capture: MidiCapture, output_path: String) -> bool:
	"""Export a MidiCapture to Standard MIDI File.
	Used for AudioSynthesizer songs (prog_odyssey, kraftwerk, prog_synth_70s, etc.)
	that have no SoundbankGenerator.PATTERNS data."""
	if capture == null or capture.tracks.is_empty():
		push_error("MidiExporter: Cannot export — capture is null or has no tracks")
		return false

	print("MidiExporter: Exporting capture '%s' (%d tracks) to %s" % [capture.song_name, capture.tracks.size(), output_path])
	var midi_data = _build_midi_file_from_capture(capture)
	return _save_midi_file(midi_data, output_path)


static func _build_midi_file_from_capture(capture: MidiCapture) -> PackedByteArray:
	"""Build a complete Standard MIDI File from MidiCapture data.
	Handles multiple tempo changes, section markers, and proper track names."""
	var output = PackedByteArray()

	# Header chunk (format 1: multi-track)
	output.append_array(_create_header_chunk(capture.tracks.size() + 1))  # +1 for conductor track

	# Conductor track (track 0): tempo map + section markers
	output.append_array(_create_conductor_track_from_capture(capture))

	# Instrument tracks
	for track in capture.tracks:
		output.append_array(_create_capture_track_chunk(track))

	return output


static func _create_conductor_track_from_capture(capture: MidiCapture) -> PackedByteArray:
	"""Create the conductor (tempo) track from MidiCapture sections.
	Includes tempo changes at section boundaries and section marker meta events."""
	var events = PackedByteArray()

	# Track name
	events.append(0x00)
	events.append(META_EVENT)
	events.append(META_SEQUENCE_NAME)
	var name_bytes = capture.song_name.to_utf8_buffer()
	events.append_array(_create_variable_length(name_bytes.size()))
	events.append_array(name_bytes)

	# Time signature (4/4) at tick 0
	events.append(0x00)
	events.append(META_EVENT)
	events.append(META_TIME_SIGNATURE)
	events.append(0x04)
	events.append(0x04)  # Numerator
	events.append(0x02)  # Denominator (2^2 = 4)
	events.append(0x18)  # MIDI clocks per metronome click
	events.append(0x08)  # 32nd notes per quarter

	# Build a sorted list of tempo/marker events from sections
	var tempo_events: Array = []
	if capture.sections.is_empty():
		# No sections defined — just write a single tempo at tick 0
		tempo_events.append({"tick": 0, "bpm": capture.bpm, "name": ""})
	else:
		for section in capture.sections:
			tempo_events.append({
				"tick": section.get("start_tick", 0),
				"bpm": section.get("bpm", capture.bpm),
				"name": section.get("name", "")
			})
	tempo_events.sort_custom(func(a, b): return a.tick < b.tick)

	# Write tempo changes and markers as delta-timed events
	var last_tick = 0
	for ev in tempo_events:
		var delta = ev.tick - last_tick

		# Section marker (FF 06 = Marker)
		if not ev.name.is_empty():
			events.append_array(_create_variable_length(delta))
			events.append(META_EVENT)
			events.append(0x06)  # Marker meta event
			var marker_bytes = ev.name.to_utf8_buffer()
			events.append_array(_create_variable_length(marker_bytes.size()))
			events.append_array(marker_bytes)
			delta = 0  # Reset delta — tempo follows immediately

		# Tempo change (FF 51 03)
		var usec = int(60000000.0 / ev.bpm)
		events.append_array(_create_variable_length(delta))
		events.append(META_EVENT)
		events.append(META_TEMPO)
		events.append(0x03)
		events.append((usec >> 16) & 0xFF)
		events.append((usec >> 8) & 0xFF)
		events.append(usec & 0xFF)

		last_tick = ev.tick

	# End of track
	events.append(0x00)
	events.append(META_EVENT)
	events.append(META_END_OF_TRACK)
	events.append(0x00)

	var chunk = PackedByteArray()
	chunk.append_array(MIDI_TRACK.to_utf8_buffer())
	chunk.append_array(_int_to_bytes(events.size(), 4))
	chunk.append_array(events)
	return chunk


static func _create_capture_track_chunk(track: Dictionary) -> PackedByteArray:
	"""Create one instrument track chunk from MidiCapture track data."""
	var events = PackedByteArray()
	var channel = track.get("channel", 0)

	# Track / instrument name
	events.append(0x00)
	events.append(META_EVENT)
	events.append(META_INSTRUMENT_NAME)
	var name_bytes = track.get("name", "Track").to_utf8_buffer()
	events.append_array(_create_variable_length(name_bytes.size()))
	events.append_array(name_bytes)

	# Program change (melodic instruments only)
	if not track.get("is_drum", false):
		events.append(0x00)
		events.append(PROGRAM_CHANGE | channel)
		events.append(track.get("program", 0) & 0x7F)

	# Collect & sort note events
	var note_events: Array = track.get("events", []).duplicate()
	note_events.sort_custom(func(a, b): return a.tick < b.tick)

	# Expand into note-on / note-off pairs
	var all_events: Array = []
	for ev in note_events:
		all_events.append({
			"tick": ev.tick,
			"status": NOTE_ON | channel,
			"data1": ev.note & 0x7F,
			"data2": ev.velocity & 0x7F
		})
		all_events.append({
			"tick": ev.tick + ev.duration,
			"status": NOTE_OFF | channel,
			"data1": ev.note & 0x7F,
			"data2": 0
		})

	# Sort all events by tick (note-off before note-on at same tick for clean output)
	all_events.sort_custom(func(a, b):
		if a.tick != b.tick:
			return a.tick < b.tick
		# Note-off (0x8x) before note-on (0x9x) at the same tick
		return (a.status & 0xF0) < (b.status & 0xF0)
	)

	# Write as delta-timed MIDI events
	var last_tick = 0
	for ev in all_events:
		var delta = ev.tick - last_tick
		if delta < 0:
			delta = 0
		events.append_array(_create_variable_length(delta))
		events.append(ev.status)
		events.append(ev.data1)
		events.append(ev.data2)
		last_tick = ev.tick

	# End of track
	events.append(0x00)
	events.append(META_EVENT)
	events.append(META_END_OF_TRACK)
	events.append(0x00)

	var chunk = PackedByteArray()
	chunk.append_array(MIDI_TRACK.to_utf8_buffer())
	chunk.append_array(_int_to_bytes(events.size(), 4))
	chunk.append_array(events)
	return chunk


static func _save_midi_file(data: PackedByteArray, path: String) -> bool:
	"""Save MIDI data to file"""
	
	# Ensure directory exists
	var dir_path = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("MidiExporter: Cannot open file for writing: " + path)
		return false
	
	file.store_buffer(data)
	file.close()
	
	print("MidiExporter: Saved MIDI file to " + path)
	return true
