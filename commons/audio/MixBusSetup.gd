## MixBusSetup.gd
## Programmatic per-instrument audio bus creation with tailored effects.
## Call MixBusSetup.setup() from any scene that needs the bus routing.
## Idempotent — safe to call multiple times.

class_name MixBusSetup
extends RefCounted

# Bus indices (set after creation)
static var bus_drums: int = -1
static var bus_bass: int = -1
static var bus_synth: int = -1   # Pads, vocoder, sequences
static var bus_lead: int = -1

static var _initialized: bool = false

# ── Effect slot indices per bus (for runtime tweaking) ──
# Drums: [0] Compressor, [1] Reverb, [2] Limiter
# Bass:  [0] Compressor, [1] Filter
# Synth: [0] Chorus, [1] Reverb, [2] Delay
# Lead:  [0] Delay, [1] Reverb

# ── Genre Presets ──────────────────────────────────────────────────────
const PRESETS: Dictionary = {
	"prog": {
		"synth_reverb_wet": 0.4,
		"synth_chorus_depth": 12.0,
		"lead_delay_ms": 500,
		"lead_reverb_wet": 0.25,
		"drums_compression_threshold": -10,
		"drums_reverb_wet": 0.12,
	},
	"techno": {
		"synth_reverb_wet": 0.2,
		"drums_compression_threshold": -15,
		"drums_reverb_wet": 0.05,
		"bass_filter_cutoff": 2000,
	},
	"acid": {
		"bass_filter_cutoff": 3500,
		"synth_reverb_wet": 0.15,
		"lead_delay_ms": 250,
	},
	"kraftwerk": {
		"synth_reverb_wet": 0.2,
		"synth_chorus_depth": 8.0,
		"drums_reverb_wet": 0.05,
		"lead_delay_ms": 375,
	},
	"ambient": {
		"synth_reverb_wet": 0.5,
		"synth_chorus_depth": 15.0,
		"lead_reverb_wet": 0.45,
		"drums_reverb_wet": 0.25,
	},
}


# ── Public API ─────────────────────────────────────────────────────────

static func setup() -> void:
	"""Create instrument buses with tailored effects. Idempotent."""
	if _initialized:
		return
	_initialized = true

	bus_drums = _ensure_bus("Drums")
	bus_bass  = _ensure_bus("Bass")
	bus_synth = _ensure_bus("Synth")
	bus_lead  = _ensure_bus("Lead")

	_setup_drums_effects(bus_drums)
	_setup_bass_effects(bus_bass)
	_setup_synth_effects(bus_synth)
	_setup_lead_effects(bus_lead)
	_ensure_master_safety()

	print("MixBusSetup: buses ready — Drums=%d  Bass=%d  Synth=%d  Lead=%d" % [
		bus_drums, bus_bass, bus_synth, bus_lead])


static func get_bus_for_instrument(track_name: String, is_drum: bool) -> String:
	"""Map a track name (+ drum flag) to the correct bus name."""
	if is_drum:
		return "Drums"
	var instrument := _detect_type(track_name)
	match instrument:
		"bass", "acid":
			return "Bass"
		"lead":
			return "Lead"
		"pad", "sequence", "vocoder":
			return "Synth"
		_:
			return "Synth"


static func apply_preset(preset_name: String) -> void:
	"""Apply a genre preset to the instrument buses."""
	if not _initialized:
		setup()
	var preset: Dictionary = PRESETS.get(preset_name, PRESETS.get("prog", {}))
	_apply_preset_values(preset)


static func apply_song_effects(effects: Dictionary) -> void:
	"""Apply per-song effect overrides from a JSON 'effects' block."""
	if not _initialized:
		setup()
	if effects.is_empty():
		return
	_apply_song_effect_block(effects)


# ── Bus creation ───────────────────────────────────────────────────────

static func _ensure_bus(bus_name: String) -> int:
	"""Return the index of an existing bus, or create a new one routed to Master."""
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		# Bus already exists — clear its effects so we rebuild them fresh
		while AudioServer.get_bus_effect_count(idx) > 0:
			AudioServer.remove_bus_effect(idx, 0)
		return idx
	# Create new bus
	var new_idx := AudioServer.bus_count
	AudioServer.add_bus(new_idx)
	AudioServer.set_bus_name(new_idx, bus_name)
	AudioServer.set_bus_send(new_idx, "Master")
	return new_idx


# ── Per-bus effect chains ──────────────────────────────────────────────

static func _setup_drums_effects(idx: int) -> void:
	"""Drums: Compressor → Reverb (tiny room) → Limiter"""
	# [0] Compressor — punchy transients
	var comp := AudioEffectCompressor.new()
	comp.threshold = -12.0
	comp.ratio = 4.0
	comp.attack_us = 1000.0    # 1 ms
	comp.release_ms = 50.0
	comp.gain = 3.0
	AudioServer.add_bus_effect(idx, comp)

	# [1] Reverb — just a touch of room
	var verb := AudioEffectReverb.new()
	verb.room_size = 0.3
	verb.damping = 0.7
	verb.wet = 0.08
	verb.dry = 0.92
	verb.spread = 0.6
	AudioServer.add_bus_effect(idx, verb)

	# [2] Limiter — safety
	var lim := AudioEffectLimiter.new()
	lim.ceiling_db = -1.0
	lim.threshold_db = -6.0
	AudioServer.add_bus_effect(idx, lim)


static func _setup_bass_effects(idx: int) -> void:
	"""Bass: Compressor → Lowpass filter (remove harshness). Dry, tight."""
	# [0] Compressor — even level
	var comp := AudioEffectCompressor.new()
	comp.threshold = -8.0
	comp.ratio = 3.0
	comp.attack_us = 5000.0    # 5 ms
	comp.release_ms = 100.0
	comp.gain = 2.0
	AudioServer.add_bus_effect(idx, comp)

	# [1] Lowpass filter — tame highs
	var filt := AudioEffectFilter.new()
	filt.cutoff_hz = 2500.0
	filt.resonance = 0.3
	filt.db = AudioEffectFilter.FILTER_12DB
	AudioServer.add_bus_effect(idx, filt)


static func _setup_synth_effects(idx: int) -> void:
	"""Synth (pads/vocoder/sequences): Chorus → Reverb (lush) → Delay (subtle echo)"""
	# [0] Chorus — stereo width
	var chorus := AudioEffectChorus.new()
	chorus.voice_count = 2
	chorus.set("voice/1/delay_ms", 15.0)
	chorus.set("voice/1/rate_hz", 0.8)
	chorus.set("voice/1/depth_ms", 10.0)
	chorus.set("voice/1/level_db", 0.0)
	chorus.set("voice/2/delay_ms", 20.0)
	chorus.set("voice/2/rate_hz", 0.9)
	chorus.set("voice/2/depth_ms", 8.0)
	chorus.set("voice/2/level_db", 0.0)
	chorus.dry = 0.8
	chorus.wet = 0.2
	AudioServer.add_bus_effect(idx, chorus)

	# [1] Reverb — lush space
	var verb := AudioEffectReverb.new()
	verb.room_size = 0.65
	verb.damping = 0.4
	verb.wet = 0.35
	verb.dry = 0.65
	verb.spread = 0.8
	AudioServer.add_bus_effect(idx, verb)

	# [2] Delay — subtle echo
	var delay := AudioEffectDelay.new()
	delay.tap1_active = true
	delay.tap1_delay_ms = 375.0
	delay.tap1_level_db = -10.0
	delay.tap2_active = false
	delay.feedback_active = true
	delay.feedback_delay_ms = 375.0
	delay.feedback_level_db = -14.0
	delay.dry = 0.85
	AudioServer.add_bus_effect(idx, delay)


static func _setup_lead_effects(idx: int) -> void:
	"""Lead: Delay (prominent echo) → Reverb (medium space)"""
	# [0] Delay — rhythmic echo
	var delay := AudioEffectDelay.new()
	delay.tap1_active = true
	delay.tap1_delay_ms = 375.0
	delay.tap1_level_db = -6.0
	delay.tap2_active = false
	delay.feedback_active = true
	delay.feedback_delay_ms = 375.0
	delay.feedback_level_db = -12.0
	delay.dry = 0.8
	AudioServer.add_bus_effect(idx, delay)

	# [1] Reverb — medium space
	var verb := AudioEffectReverb.new()
	verb.room_size = 0.5
	verb.damping = 0.5
	verb.wet = 0.2
	verb.dry = 0.8
	verb.spread = 0.7
	AudioServer.add_bus_effect(idx, verb)


static func _ensure_master_safety() -> void:
	"""Make sure Master bus has a limiter + spectrum analyzer (preserves existing)."""
	var master := AudioServer.get_bus_index("Master")
	if master < 0:
		return

	# Check what's already on Master
	var has_limiter := false
	var has_spectrum := false
	for i in range(AudioServer.get_bus_effect_count(master)):
		var fx := AudioServer.get_bus_effect(master, i)
		if fx is AudioEffectLimiter:
			has_limiter = true
		if fx is AudioEffectSpectrumAnalyzer:
			has_spectrum = true

	if not has_limiter:
		var lim := AudioEffectLimiter.new()
		lim.ceiling_db = -0.5
		lim.threshold_db = -6.0
		AudioServer.add_bus_effect(master, lim)

	if not has_spectrum:
		var analyzer := AudioEffectSpectrumAnalyzer.new()
		analyzer.buffer_length = 0.1
		analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
		AudioServer.add_bus_effect(master, analyzer)


# ── Instrument type detection (mirrors MidiPianoRoll._detect_instrument_type) ──

static func _detect_type(track_name: String) -> String:
	var n := track_name.to_lower()
	if "pad" in n or "mellotron" in n:
		return "pad"
	elif "bass" in n or "sub" in n:
		return "bass"
	elif "lead" in n or "elp" in n:
		return "lead"
	elif "seq" in n or "kraftwerk" in n or "arp" in n:
		return "sequence"
	elif "vocoder" in n:
		return "vocoder"
	elif "acid" in n or "303" in n:
		return "acid"
	else:
		return "default"


# ── Preset application ────────────────────────────────────────────────

static func _apply_preset_values(preset: Dictionary) -> void:
	# Drums
	if bus_drums >= 0:
		if preset.has("drums_compression_threshold"):
			var comp = AudioServer.get_bus_effect(bus_drums, 0)
			if comp is AudioEffectCompressor:
				comp.threshold = preset["drums_compression_threshold"]
		if preset.has("drums_reverb_wet"):
			var verb = AudioServer.get_bus_effect(bus_drums, 1)
			if verb is AudioEffectReverb:
				verb.wet = preset["drums_reverb_wet"]
				verb.dry = 1.0 - preset["drums_reverb_wet"]

	# Bass
	if bus_bass >= 0:
		if preset.has("bass_filter_cutoff"):
			var filt = AudioServer.get_bus_effect(bus_bass, 1)
			if filt is AudioEffectFilter:
				filt.cutoff_hz = preset["bass_filter_cutoff"]

	# Synth
	if bus_synth >= 0:
		if preset.has("synth_reverb_wet"):
			var verb = AudioServer.get_bus_effect(bus_synth, 1)
			if verb is AudioEffectReverb:
				verb.wet = clampf(preset["synth_reverb_wet"], 0.0, 0.5)
				verb.dry = 1.0 - verb.wet
		if preset.has("synth_chorus_depth"):
			var chorus = AudioServer.get_bus_effect(bus_synth, 0)
			if chorus is AudioEffectChorus:
				chorus.set("voice/1/depth_ms", preset["synth_chorus_depth"])
				chorus.set("voice/2/depth_ms", preset["synth_chorus_depth"] * 0.8)

	# Lead
	if bus_lead >= 0:
		if preset.has("lead_delay_ms"):
			var delay = AudioServer.get_bus_effect(bus_lead, 0)
			if delay is AudioEffectDelay:
				delay.tap1_delay_ms = preset["lead_delay_ms"]
				delay.feedback_delay_ms = preset["lead_delay_ms"]
		if preset.has("lead_reverb_wet"):
			var verb = AudioServer.get_bus_effect(bus_lead, 1)
			if verb is AudioEffectReverb:
				verb.wet = clampf(preset["lead_reverb_wet"], 0.0, 0.5)
				verb.dry = 1.0 - verb.wet


static func _apply_song_effect_block(effects: Dictionary) -> void:
	"""Apply a per-song JSON 'effects' block to bus effects."""
	# Drums
	var drums_fx: Dictionary = effects.get("drums", {})
	if bus_drums >= 0 and not drums_fx.is_empty():
		var comp_cfg: Dictionary = drums_fx.get("compression", {})
		if not comp_cfg.is_empty():
			var comp = AudioServer.get_bus_effect(bus_drums, 0)
			if comp is AudioEffectCompressor:
				if comp_cfg.has("threshold_db"):
					comp.threshold = comp_cfg["threshold_db"]
				if comp_cfg.has("ratio"):
					comp.ratio = comp_cfg["ratio"]
		var verb_cfg: Dictionary = drums_fx.get("reverb", {})
		if not verb_cfg.is_empty():
			var verb = AudioServer.get_bus_effect(bus_drums, 1)
			if verb is AudioEffectReverb:
				if verb_cfg.has("room_size"):
					verb.room_size = verb_cfg["room_size"]
				if verb_cfg.has("wet"):
					verb.wet = clampf(verb_cfg["wet"], 0.0, 0.5)
					verb.dry = 1.0 - verb.wet

	# Bass
	var bass_fx: Dictionary = effects.get("bass", {})
	if bus_bass >= 0 and not bass_fx.is_empty():
		var comp_cfg: Dictionary = bass_fx.get("compression", {})
		if not comp_cfg.is_empty():
			var comp = AudioServer.get_bus_effect(bus_bass, 0)
			if comp is AudioEffectCompressor:
				if comp_cfg.has("threshold_db"):
					comp.threshold = comp_cfg["threshold_db"]
				if comp_cfg.has("ratio"):
					comp.ratio = comp_cfg["ratio"]
		if bass_fx.has("filter_cutoff_hz"):
			var filt = AudioServer.get_bus_effect(bus_bass, 1)
			if filt is AudioEffectFilter:
				filt.cutoff_hz = bass_fx["filter_cutoff_hz"]

	# Synth
	var synth_fx: Dictionary = effects.get("synth", {})
	if bus_synth >= 0 and not synth_fx.is_empty():
		var chorus_cfg: Dictionary = synth_fx.get("chorus", {})
		if not chorus_cfg.is_empty():
			var chorus = AudioServer.get_bus_effect(bus_synth, 0)
			if chorus is AudioEffectChorus:
				if chorus_cfg.has("depth_ms"):
					chorus.set("voice/1/depth_ms", chorus_cfg["depth_ms"])
					chorus.set("voice/2/depth_ms", chorus_cfg["depth_ms"] * 0.8)
				if chorus_cfg.has("wet"):
					chorus.wet = chorus_cfg["wet"]
					chorus.dry = 1.0 - chorus_cfg["wet"]
		var verb_cfg: Dictionary = synth_fx.get("reverb", {})
		if not verb_cfg.is_empty():
			var verb = AudioServer.get_bus_effect(bus_synth, 1)
			if verb is AudioEffectReverb:
				if verb_cfg.has("room_size"):
					verb.room_size = verb_cfg["room_size"]
				if verb_cfg.has("wet"):
					verb.wet = clampf(verb_cfg["wet"], 0.0, 0.5)
					verb.dry = 1.0 - verb.wet
		var delay_cfg: Dictionary = synth_fx.get("delay", {})
		if not delay_cfg.is_empty():
			var delay = AudioServer.get_bus_effect(bus_synth, 2)
			if delay is AudioEffectDelay:
				if delay_cfg.has("time_ms"):
					delay.tap1_delay_ms = delay_cfg["time_ms"]
					delay.feedback_delay_ms = delay_cfg["time_ms"]
				if delay_cfg.has("level_db"):
					delay.tap1_level_db = delay_cfg["level_db"]
				if delay_cfg.has("feedback_db"):
					delay.feedback_level_db = delay_cfg["feedback_db"]

	# Lead
	var lead_fx: Dictionary = effects.get("lead", {})
	if bus_lead >= 0 and not lead_fx.is_empty():
		var delay_cfg: Dictionary = lead_fx.get("delay", {})
		if not delay_cfg.is_empty():
			var delay = AudioServer.get_bus_effect(bus_lead, 0)
			if delay is AudioEffectDelay:
				if delay_cfg.has("time_ms"):
					delay.tap1_delay_ms = delay_cfg["time_ms"]
					delay.feedback_delay_ms = delay_cfg["time_ms"]
				if delay_cfg.has("level_db"):
					delay.tap1_level_db = delay_cfg["level_db"]
				if delay_cfg.has("feedback_db"):
					delay.feedback_level_db = delay_cfg["feedback_db"]
		var verb_cfg: Dictionary = lead_fx.get("reverb", {})
		if not verb_cfg.is_empty():
			var verb = AudioServer.get_bus_effect(bus_lead, 1)
			if verb is AudioEffectReverb:
				if verb_cfg.has("room_size"):
					verb.room_size = verb_cfg["room_size"]
				if verb_cfg.has("wet"):
					verb.wet = clampf(verb_cfg["wet"], 0.0, 0.5)
					verb.dry = 1.0 - verb.wet
