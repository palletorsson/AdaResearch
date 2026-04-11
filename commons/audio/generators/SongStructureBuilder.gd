# SongStructureBuilder.gd
# Shared helper for building AudioStreamInteractive songs from a configuration.
# Eliminates boilerplate duplicated across all generate_*_song functions in AudioSynthesizer.
#
# Usage:
#   var config = SongStructureBuilder.SongConfig.new()
#   config.genre_id = "detroit_techno"
#   config.bpm = 125.0
#   config.scale_type = "minor"
#   config.octave_suffix = "2"
#   config.crossfade = 2.0
#   config.sections = [
#       {"name": "Intro", "instruments": ["kick", "hihat"]},
#       {"name": "Build", "instruments": ["kick", "hihat", "bass", "stab"]},
#       {"name": "Main", "instruments": ["kick", "hihat", "clap", "bass", "stab", "pad"]},
#       {"name": "Breakdown", "instruments": ["pad", "hihat"]},
#   ]
#   config.section_generator = func(prog, scale, instruments, bar_dur):
#       return AudioSynthesizer._generate_detroit_section(prog, scale, instruments, bar_dur)
#   var song = SongStructureBuilder.build_song(config, parameters)

extends RefCounted
class_name SongStructureBuilder


class SongConfig:
	## Genre identifier for parameter merging and progression lookup.
	var genre_id: String = ""
	## Beats per minute.
	var bpm: float = 120.0
	## "major" or "minor".
	var scale_type: String = "minor"
	## Octave suffix appended to the random root note (e.g. "2", "3", "4").
	var octave_suffix: String = "3"
	## Crossfade duration in seconds between sections.
	var crossfade: float = 2.0
	## Array of Dictionaries: [{"name": String, "instruments": Array[String]}]
	var sections: Array = []
	## Callable that generates a section WAV stream.
	## Signature: func(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV
	var section_generator: Callable = Callable()


## Build an AudioStreamInteractive song from a SongConfig and optional runtime parameters.
## This replaces the duplicated boilerplate in every generate_*_song function.
static func build_song(config: SongConfig, parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = AudioSynthesizer._merge_with_song_research_parameters(config.genre_id, parameters)
	randomize()

	var bpm = config.bpm
	var bar_duration = 240.0 / bpm

	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + config.octave_suffix
	var scale: Array
	if config.scale_type == "major":
		scale = PopMusicTheory.get_major_scale_notes(root_note)
	else:
		scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = AudioSynthesizer._resolve_progression_from_parameters(
		parameters,
		AudioSynthesizer._default_progression_for_song(str(parameters.get("song_id", ""))),
		scale
	)

	print("AudioSynthesizer: Generating %s in %s" % [config.genre_id, root_note])

	var clip_count = config.sections.size()
	var playback = AudioStreamInteractive.new()
	playback.clip_count = clip_count
	playback.initial_clip = 0

	for idx in range(clip_count):
		var section = config.sections[idx]
		var section_name: String = section.get("name", "Section %d" % idx)
		var instruments: Array = section.get("instruments", [])

		var stream: AudioStreamWAV
		if config.section_generator.is_valid():
			stream = config.section_generator.call(progression, scale, instruments, bar_duration)
		else:
			push_error("SongStructureBuilder: No section_generator set for " + config.genre_id)
			continue

		playback.set_clip_stream(idx, stream)
		playback.set_clip_name(idx, section_name)

		# Auto-advance to next clip (last clip wraps to first)
		var next_clip = (idx + 1) % clip_count
		playback.set_clip_auto_advance(idx, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
		playback.set_clip_auto_advance_next_clip(idx, next_clip)

	# Add crossfade transitions between all sequential sections
	var xfade = config.crossfade
	for idx in range(clip_count):
		var next_clip = (idx + 1) % clip_count
		playback.add_transition(
			idx, next_clip,
			AudioStreamInteractive.TRANSITION_FROM_TIME_END,
			AudioStreamInteractive.TRANSITION_TO_TIME_START,
			AudioStreamInteractive.FADE_CROSS,
			xfade
		)

	return playback
