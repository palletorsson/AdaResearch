# MidiCapture.gd
# Utility class for capturing MIDI data from AudioSynthesizer song generators.
# Songs that generate audio procedurally (prog_odyssey, kraftwerk, prog_synth_70s, etc.)
# have no SoundbankGenerator.PATTERNS data. This class captures their musical information
# as MIDI events for export.
#
# Usage:
#   var capture = MidiCapture.new()
#   capture.song_name = "Prog Odyssey"
#   capture.bpm = 100.0
#   var pad_track = capture.add_track("Moog Pad", 0, 89)
#   capture.add_note(pad_track, 0, 60, 70, 1920)
#   MidiExporter.export_from_capture(capture, "res://exports/song.mid")

class_name MidiCapture
extends RefCounted

# Captured MIDI data from a song generation
# Each track: { name: String, channel: int, program: int, is_drum: bool, events: Array[Dictionary] }
# Each event: { tick: int, note: int, velocity: int, duration: int }

var tracks: Array[Dictionary] = []
var bpm: float = 120.0
var song_name: String = ""
var ticks_per_quarter: int = 480
var sections: Array[Dictionary] = []  # { name: String, start_tick: int, bpm: float }


func add_track(track_name: String, channel: int, program: int = 0, is_drum: bool = false) -> int:
	var idx = tracks.size()
	tracks.append({
		"name": track_name,
		"channel": channel,
		"program": program,
		"is_drum": is_drum,
		"events": []
	})
	return idx


func add_note(track_idx: int, tick: int, note: int, velocity: int, duration: int):
	if track_idx < 0 or track_idx >= tracks.size():
		return
	tracks[track_idx].events.append({
		"tick": tick,
		"note": clampi(note, 0, 127),
		"velocity": clampi(velocity, 1, 127),
		"duration": maxi(duration, 1)
	})


func add_section(section_name: String, start_tick: int, section_bpm: float = -1.0):
	sections.append({
		"name": section_name,
		"start_tick": start_tick,
		"bpm": section_bpm if section_bpm > 0 else bpm
	})


# Helpers

func bars_to_ticks(bars: float) -> int:
	return int(bars * 4 * ticks_per_quarter)


func beat_to_ticks(beats: float) -> int:
	return int(beats * ticks_per_quarter)


func note_name_to_midi(note: String) -> int:
	# "C4" -> 60, "B2" -> 47, "F#3" -> 54
	var note_map = {
		"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
		"F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11
	}
	# Extract note name (everything except last character which is octave)
	var key = note.substr(0, note.length() - 1)
	var octave = int(note.substr(note.length() - 1))
	return note_map.get(key, 0) + (octave + 1) * 12


func freq_to_midi(freq: float) -> int:
	# f = 440 * 2^((n-69)/12) => n = 69 + 12*log2(f/440)
	if freq <= 0:
		return 60
	return clampi(int(round(69.0 + 12.0 * log(freq / 440.0) / log(2.0))), 0, 127)
