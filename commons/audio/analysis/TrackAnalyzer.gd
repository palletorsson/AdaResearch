class_name TrackAnalyzer
extends RefCounted
## Track analysis based on the three-layer evaluation framework:
## A) Composition (structure, theme, meaning)
## B) Production (sound design, frequency, dynamics, space)
## C) Game-readiness (looping, adaptivity, implementation)

const SAMPLE_RATE = 44100.0

# Frequency band definitions (Hz) - aligned with production framework
const BANDS = {
	"sub": {"min": 20, "max": 60, "role": "kick_tail_or_sub"},
	"bass": {"min": 60, "max": 200, "role": "bass_body"},
	"low_mid": {"min": 200, "max": 500, "role": "danger_zone"},
	"mid": {"min": 500, "max": 2000, "role": "intelligibility"},
	"presence": {"min": 2000, "max": 5000, "role": "attack_clarity_vo_conflict"},
	"air": {"min": 5000, "max": 16000, "role": "sheen_space"}
}

# Genre-specific ideal balances
const GENRE_PROFILES = {
	"techno": {"sub": 0.18, "bass": 0.25, "low_mid": 0.10, "mid": 0.22, "presence": 0.15, "air": 0.10, "lambda": 0.25},
	"ambient": {"sub": 0.08, "bass": 0.15, "low_mid": 0.18, "mid": 0.28, "presence": 0.16, "air": 0.15, "lambda": 0.35},
	"epic": {"sub": 0.15, "bass": 0.20, "low_mid": 0.15, "mid": 0.25, "presence": 0.15, "air": 0.10, "lambda": 0.30},
	"dnb": {"sub": 0.15, "bass": 0.28, "low_mid": 0.12, "mid": 0.20, "presence": 0.15, "air": 0.10, "lambda": 0.45},
	"house": {"sub": 0.14, "bass": 0.24, "low_mid": 0.15, "mid": 0.24, "presence": 0.13, "air": 0.10, "lambda": 0.40},
	"idm": {"sub": 0.12, "bass": 0.18, "low_mid": 0.15, "mid": 0.25, "presence": 0.18, "air": 0.12, "lambda": 0.55},
	"neutral": {"sub": 0.12, "bass": 0.20, "low_mid": 0.15, "mid": 0.25, "presence": 0.16, "air": 0.12, "lambda": 0.40}
}


## Full track analysis returning the 10-point rubric + detailed metrics
static func analyze_track(audio: PackedFloat32Array, bpm: float = 120.0, genre: String = "neutral") -> Dictionary:
	var profile = GENRE_PROFILES.get(genre, GENRE_PROFILES["neutral"])
	
	var result = {
		# The 10-point rubric (each 1-5)
		"rubric": {
			"identity_token": 0.0,
			"cohesion": 0.0,
			"controlled_variation": 0.0,
			"energy_arc": 0.0,
			"frequency_allocation": 0.0,
			"dynamic_contrast": 0.0,
			"spatial_clarity": 0.0,
			"loop_durability": 0.0,
			"implementation_ready": 0.0,
			"emotional_truth": 0.0  # This one requires context, default to mid
		},
		
		# Layer A: Composition
		"composition": {},
		
		# Layer B: Production
		"production": {},
		
		# Layer C: Game-readiness
		"game_ready": {},
		
		# Summary
		"overall_score": 0.0,
		"estimated_lambda": profile.lambda,
		"genre_fit": 0.0
	}
	
	# === LAYER A: COMPOSITION ===
	result["composition"] = analyze_composition(audio, bpm)
	
	# === LAYER B: PRODUCTION ===
	result["production"] = analyze_production(audio, profile)
	
	# === LAYER C: GAME-READINESS ===
	result["game_ready"] = analyze_game_readiness(audio, bpm)
	
	# === CALCULATE RUBRIC SCORES ===
	_calculate_rubric(result)
	
	# Overall score (average of rubric, excluding emotional_truth which needs context)
	var rubric_sum = 0.0
	var rubric_count = 0
	for key in result["rubric"].keys():
		if key != "emotional_truth":
			rubric_sum += result["rubric"][key]
			rubric_count += 1
	result["overall_score"] = rubric_sum / rubric_count if rubric_count > 0 else 2.5
	
	# Genre fit based on frequency alignment
	result["genre_fit"] = result["production"].get("genre_alignment", 0.5)
	
	# Refined λ estimate
	result["estimated_lambda"] = _estimate_lambda(result, profile)
	
	return result


## Layer A: Composition analysis
static func analyze_composition(audio: PackedFloat32Array, bpm: float) -> Dictionary:
	var comp = {}
	
	# 1. Signature/Identity analysis
	var signature = analyze_signature_consistency(audio)
	comp["signature_consistency"] = signature.consistency
	comp["signature_test_passed"] = signature.consistency > 0.7
	
	# 2. Arc legibility (energy shape)
	var arc = analyze_energy_arc(audio, 8192)
	comp["energy_curve"] = arc.curve
	comp["arc_shape"] = arc.shape  # "flat", "building", "peak_middle", "declining", "complex"
	comp["arc_legibility"] = arc.legibility
	
	# 3. Motif recurrence (via repetition detection)
	var motif = analyze_motif_recurrence(audio, bpm)
	comp["motif_recurrence_count"] = motif.count
	comp["motif_strength"] = motif.strength
	
	# 4. Tension channels
	var tension = analyze_tension_channels(audio)
	comp["tension_channels_active"] = tension.count
	comp["tension_risk"] = tension.count > 3  # "trailer cliché" warning
	
	return comp


## Layer B: Production analysis
static func analyze_production(audio: PackedFloat32Array, profile: Dictionary) -> Dictionary:
	var prod = {}
	
	# 4. Palette coherence
	var palette = analyze_palette_coherence(audio)
	prod["palette_family_count"] = palette.family_count
	prod["palette_coherence"] = palette.coherence
	
	# 5. Frequency allocation
	var freq = analyze_frequency_allocation(audio, profile)
	prod["band_energies"] = freq.bands
	prod["band_ownership_clear"] = freq.ownership_clear
	prod["genre_alignment"] = freq.genre_alignment
	prod["low_mid_warning"] = freq.bands.get("low_mid", 0.0) > 0.20  # Mud warning
	prod["presence_vo_conflict"] = freq.bands.get("presence", 0.0) > 0.20
	
	# 6. Dynamic contrast
	var dynamics = analyze_dynamic_contrast(audio)
	prod["micro_contrast"] = dynamics.micro
	prod["macro_contrast"] = dynamics.macro
	prod["crest_factor"] = dynamics.crest_factor
	prod["transient_clarity"] = dynamics.transient_clarity
	
	# 7. Space/Spatial
	var space = analyze_spatial_design(audio)
	prod["mono_collapse_score"] = space.mono_collapse
	prod["center_clarity"] = space.center_clarity
	prod["stereo_width"] = space.width
	
	return prod


## Layer C: Game-readiness analysis
static func analyze_game_readiness(audio: PackedFloat32Array, bpm: float) -> Dictionary:
	var game = {}
	
	# 8. Loop durability
	var loop = analyze_loop_durability(audio, bpm)
	game["loop_seam_score"] = loop.seam_score
	game["fatigue_risk"] = loop.fatigue_risk
	game["fatigue_culprits"] = loop.culprits  # Which elements cause fatigue
	
	# 9. VO safety
	var vo = analyze_vo_safety(audio)
	game["vo_safety_score"] = vo.safety_score
	game["presence_energy"] = vo.presence_energy
	game["vo_recommendation"] = vo.recommendation
	
	# 10. Implementation readiness (basic stem analysis would go here)
	game["loop_point_viable"] = loop.seam_score > 0.6
	game["stems_separable"] = true  # Would need multi-track for real analysis
	
	return game


## Calculate the 10-point rubric from detailed metrics
static func _calculate_rubric(result: Dictionary):
	var r = result["rubric"]
	var comp = result["composition"]
	var prod = result["production"]
	var game = result["game_ready"]
	
	# 1. Identity Token (signature consistency + motif strength)
	var identity = (comp.get("signature_consistency", 0.5) + comp.get("motif_strength", 0.5)) / 2.0
	r["identity_token"] = _to_rubric_scale(identity)
	
	# 2. Cohesion (palette coherence + spatial center)
	var cohesion = (prod.get("palette_coherence", 0.5) + prod.get("center_clarity", 0.5)) / 2.0
	r["cohesion"] = _to_rubric_scale(cohesion)
	
	# 3. Controlled Variation (not static, not chaotic)
	var variation = 0.5
	var tension_count = comp.get("tension_channels_active", 2)
	if tension_count >= 2 and tension_count <= 3:
		variation = 0.9
	elif tension_count == 1 or tension_count == 4:
		variation = 0.6
	else:
		variation = 0.3
	r["controlled_variation"] = _to_rubric_scale(variation)
	
	# 4. Energy Arc
	r["energy_arc"] = _to_rubric_scale(comp.get("arc_legibility", 0.5))
	
	# 5. Frequency Allocation
	var freq_score = prod.get("genre_alignment", 0.5)
	if prod.get("low_mid_warning", false):
		freq_score -= 0.15
	r["frequency_allocation"] = _to_rubric_scale(freq_score)
	
	# 6. Dynamic Contrast
	var dyn = (prod.get("micro_contrast", 0.5) + prod.get("macro_contrast", 0.5)) / 2.0
	r["dynamic_contrast"] = _to_rubric_scale(dyn)
	
	# 7. Spatial Clarity
	var spatial = (prod.get("mono_collapse_score", 0.5) + prod.get("center_clarity", 0.5)) / 2.0
	r["spatial_clarity"] = _to_rubric_scale(spatial)
	
	# 8. Loop Durability
	var loop_score = game.get("loop_seam_score", 0.5)
	if game.get("fatigue_risk", 0.0) > 0.5:
		loop_score -= 0.2
	r["loop_durability"] = _to_rubric_scale(loop_score)
	
	# 9. Implementation Ready
	var impl = 0.7 if game.get("loop_point_viable", false) else 0.4
	if game.get("vo_safety_score", 0.5) > 0.6:
		impl += 0.15
	r["implementation_ready"] = _to_rubric_scale(impl)
	
	# 10. Emotional Truth (context-dependent, default to mid-range)
	r["emotional_truth"] = 3.0  # Needs scene context to evaluate


## Convert 0-1 score to 1-5 rubric scale
static func _to_rubric_scale(score: float) -> float:
	return clampf(score * 4.0 + 1.0, 1.0, 5.0)


## Estimate λ from analysis results
static func _estimate_lambda(result: Dictionary, profile: Dictionary) -> float:
	var comp = result["composition"]
	var prod = result["production"]
	
	# λ influenced by:
	# - Low tension channels = more order (lower λ)
	# - High signature consistency = more order
	# - High variation = more chaos (higher λ)
	
	var order_score = comp.get("signature_consistency", 0.5) * 0.4
	order_score += (1.0 - prod.get("micro_contrast", 0.5)) * 0.3
	
	var chaos_score = comp.get("tension_channels_active", 2) / 5.0 * 0.3
	chaos_score += prod.get("micro_contrast", 0.5) * 0.2
	
	var estimated = profile.lambda * 0.5 + (chaos_score - order_score + 0.5) * 0.5
	return clampf(estimated, 0.1, 0.9)


# === COMPOSITION ANALYSIS FUNCTIONS ===

static func analyze_signature_consistency(audio: PackedFloat32Array) -> Dictionary:
	# Compare spectral fingerprints from random segments
	var segment_length = int(SAMPLE_RATE * 5.0)  # 5 second segments
	var segments = []
	
	if audio.size() < segment_length * 3:
		return {"consistency": 0.5}
	
	# Get 3 random segments
	for i in range(3):
		var start = randi() % (audio.size() - segment_length)
		var seg = audio.slice(start, start + segment_length)
		var fingerprint = _compute_spectral_fingerprint(seg)
		segments.append(fingerprint)
	
	# Compare fingerprints
	var total_similarity = 0.0
	var comparisons = 0
	for i in range(segments.size()):
		for j in range(i + 1, segments.size()):
			total_similarity += _compare_fingerprints(segments[i], segments[j])
			comparisons += 1
	
	var consistency = total_similarity / comparisons if comparisons > 0 else 0.5
	return {"consistency": consistency}


static func analyze_energy_arc(audio: PackedFloat32Array, window_size: int) -> Dictionary:
	var curve = []
	var num_windows = int(audio.size() / window_size)
	
	for w in range(num_windows):
		var offset = w * window_size
		var window = audio.slice(offset, offset + window_size)
		curve.append(calculate_rms(window))
	
	if curve.size() < 4:
		return {"curve": curve, "shape": "unknown", "legibility": 0.5}
	
	# Determine shape
	var first_quarter = _average_range(curve, 0, curve.size() / 4)
	var second_quarter = _average_range(curve, curve.size() / 4, curve.size() / 2)
	var third_quarter = _average_range(curve, curve.size() / 2, curve.size() * 3 / 4)
	var fourth_quarter = _average_range(curve, curve.size() * 3 / 4, curve.size())
	
	var shape = "complex"
	var legibility = 0.5
	
	# Detect common shapes
	if third_quarter > first_quarter * 1.3 and third_quarter > fourth_quarter * 1.1:
		shape = "peak_middle"
		legibility = 0.85
	elif fourth_quarter > first_quarter * 1.3:
		shape = "building"
		legibility = 0.75
	elif first_quarter > fourth_quarter * 1.3:
		shape = "declining"
		legibility = 0.65
	elif abs(first_quarter - fourth_quarter) < 0.1 * first_quarter:
		var variance = _calculate_variance(curve)
		if variance < 0.01:
			shape = "flat"
			legibility = 0.3  # Flat = low legibility
		else:
			shape = "oscillating"
			legibility = 0.6
	
	return {"curve": curve, "shape": shape, "legibility": legibility}


static func analyze_motif_recurrence(audio: PackedFloat32Array, bpm: float) -> Dictionary:
	# Detect recurring patterns via autocorrelation
	var bar_samples = int(SAMPLE_RATE * 240.0 / bpm)  # Samples per bar
	
	# Simplified: count energy peaks that recur at bar intervals
	var hop = int(bar_samples / 4)
	var energies = []
	
	for i in range(0, audio.size() - hop, hop):
		energies.append(calculate_rms(audio.slice(i, i + hop)))
	
	# Find peaks
	var peaks = []
	var threshold = _average_array(energies) * 1.3
	for i in range(1, energies.size() - 1):
		if energies[i] > threshold and energies[i] > energies[i-1] and energies[i] > energies[i+1]:
			peaks.append(i)
	
	# Count recurring intervals (motif returns)
	var interval_counts = {}
	for i in range(peaks.size()):
		for j in range(i + 1, peaks.size()):
			var interval = peaks[j] - peaks[i]
			var key = int(interval / 4) * 4  # Quantize to bar-ish units
			interval_counts[key] = interval_counts.get(key, 0) + 1
	
	var max_count = 0
	for count in interval_counts.values():
		max_count = max(max_count, count)
	
	var recurrence_count = max_count
	var strength = clampf(float(max_count) / 5.0, 0.0, 1.0)  # 5+ recurrences = full strength
	
	return {"count": recurrence_count, "strength": strength}


static func analyze_tension_channels(audio: PackedFloat32Array) -> Dictionary:
	# Count how many "tension channels" are active
	# Channels: harmonic density, rhythmic density, brightness, dynamics
	
	var channels_active = 0
	
	# 1. Harmonic density (via spectral complexity)
	var spectral_complexity = _analyze_spectral_complexity(audio)
	if spectral_complexity > 0.5:
		channels_active += 1
	
	# 2. Rhythmic density (via onset rate)
	var onset_rate = _analyze_onset_rate(audio)
	if onset_rate > 4.0:  # More than 4 onsets per second
		channels_active += 1
	
	# 3. Brightness (via spectral centroid)
	var brightness = _analyze_brightness(audio)
	if brightness > 3000:  # Centroid above 3kHz
		channels_active += 1
	
	# 4. Dynamic activity (via RMS variance)
	var dynamic_variance = _analyze_dynamic_activity(audio)
	if dynamic_variance > 0.05:
		channels_active += 1
	
	return {"count": channels_active}


# === PRODUCTION ANALYSIS FUNCTIONS ===

static func analyze_palette_coherence(audio: PackedFloat32Array) -> Dictionary:
	# Estimate number of distinct timbral families via spectral clustering
	var window_size = 8192
	var centroids = []
	
	for i in range(0, audio.size() - window_size, window_size):
		var window = audio.slice(i, i + window_size)
		var centroid = estimate_spectral_centroid(window)
		var spread = _estimate_spectral_spread(window, centroid)
		centroids.append({"centroid": centroid, "spread": spread})
	
	# Simple clustering: count distinct centroid ranges
	var families = {}
	for c in centroids:
		var bucket = int(c.centroid / 500) * 500  # 500Hz buckets
		families[bucket] = families.get(bucket, 0) + 1
	
	var significant_families = 0
	var total = centroids.size()
	for count in families.values():
		if count > total * 0.1:  # Family appears in >10% of windows
			significant_families += 1
	
	# Coherence: fewer families = more coherent
	var coherence = clampf(1.0 - (significant_families - 3) * 0.15, 0.3, 1.0)
	
	return {"family_count": significant_families, "coherence": coherence}


static func analyze_frequency_allocation(audio: PackedFloat32Array, profile: Dictionary) -> Dictionary:
	var band_energies = {}
	for band in BANDS.keys():
		band_energies[band] = 0.0
	
	# Analyze via windowed ZCR and energy
	var window_size = 2048
	var num_windows = int(audio.size() / window_size)
	
	for w in range(num_windows):
		var offset = w * window_size
		var window = audio.slice(offset, offset + window_size)
		var zcr = calculate_zero_crossing_rate(window)
		var rms = calculate_rms(window)
		var dominant_freq = zcr * SAMPLE_RATE / 2.0
		
		for band in BANDS.keys():
			var band_def = BANDS[band]
			if dominant_freq >= band_def.min and dominant_freq < band_def.max:
				band_energies[band] += rms
	
	# Normalize
	var total = 0.0
	for band in band_energies.keys():
		total += band_energies[band]
	if total > 0:
		for band in band_energies.keys():
			band_energies[band] /= total
	
	# Check ownership clarity (one band shouldn't dominate completely)
	var max_energy = 0.0
	var min_energy = 1.0
	for e in band_energies.values():
		max_energy = max(max_energy, e)
		min_energy = min(min_energy, e)
	var ownership_clear = max_energy < 0.5 and min_energy > 0.02
	
	# Genre alignment
	var alignment = 1.0
	for band in BANDS.keys():
		var ideal = profile.get(band, 0.15)
		var actual = band_energies.get(band, 0.0)
		alignment -= abs(ideal - actual) * 1.5
	alignment = clampf(alignment, 0.0, 1.0)
	
	return {"bands": band_energies, "ownership_clear": ownership_clear, "genre_alignment": alignment}


static func analyze_dynamic_contrast(audio: PackedFloat32Array) -> Dictionary:
	# Micro contrast: variation within short windows
	var micro_rms = []
	var micro_window = 4096
	for i in range(0, audio.size() - micro_window, micro_window):
		micro_rms.append(calculate_rms(audio.slice(i, i + micro_window)))
	var micro_variance = _calculate_variance(micro_rms)
	var micro_contrast = clampf(micro_variance * 20.0, 0.0, 1.0)
	
	# Macro contrast: variation across larger sections
	var section_count = 4
	var section_size = audio.size() / section_count
	var section_rms = []
	for i in range(section_count):
		var start = int(i * section_size)
		var end = int((i + 1) * section_size)
		section_rms.append(calculate_rms(audio.slice(start, end)))
	var macro_range = section_rms.max() - section_rms.min() if section_rms.size() > 0 else 0.0
	var macro_contrast = clampf(macro_range * 5.0, 0.0, 1.0)
	
	# Crest factor (peak to RMS)
	var peak = 0.0
	for s in audio:
		peak = max(peak, abs(s))
	var total_rms = calculate_rms(audio)
	var crest_factor = peak / total_rms if total_rms > 0 else 1.0
	
	# Transient clarity (high crest = clear transients)
	var transient_clarity = clampf((crest_factor - 1.0) / 5.0, 0.0, 1.0)
	
	return {
		"micro": micro_contrast,
		"macro": macro_contrast,
		"crest_factor": crest_factor,
		"transient_clarity": transient_clarity
	}


static func analyze_spatial_design(audio: PackedFloat32Array) -> Dictionary:
	# For mono input, we can only estimate what stereo *would* be
	# Real stereo analysis would need L/R channels
	
	# Simplified: estimate "center clarity" from spectral focus
	var centroid_variance = _analyze_spectral_consistency(audio)
	var center_clarity = 1.0 - clampf(centroid_variance / 1000.0, 0.0, 0.7)
	
	# Mono collapse (for mono input, this is always 1.0)
	var mono_collapse = 0.85  # Assume reasonable if we got this far
	
	# Width estimate (from transient diffusion)
	var width = 0.5  # Default mid-width for mono
	
	return {
		"mono_collapse": mono_collapse,
		"center_clarity": center_clarity,
		"width": width
	}


# === GAME-READINESS ANALYSIS FUNCTIONS ===

static func analyze_loop_durability(audio: PackedFloat32Array, bpm: float) -> Dictionary:
	# Loop seam: compare start and end
	var seam_length = int(SAMPLE_RATE * 0.5)  # 500ms comparison
	
	if audio.size() < seam_length * 2:
		return {"seam_score": 0.5, "fatigue_risk": 0.5, "culprits": []}
	
	var start_seg = audio.slice(0, seam_length)
	var end_seg = audio.slice(audio.size() - seam_length, audio.size())
	
	# Compare energy levels
	var start_rms = calculate_rms(start_seg)
	var end_rms = calculate_rms(end_seg)
	var energy_match = 1.0 - abs(start_rms - end_rms) / max(start_rms, end_rms, 0.001)
	
	# Compare spectral content
	var start_zcr = calculate_zero_crossing_rate(start_seg)
	var end_zcr = calculate_zero_crossing_rate(end_seg)
	var spectral_match = 1.0 - abs(start_zcr - end_zcr) / max(start_zcr, end_zcr, 0.001)
	
	var seam_score = (energy_match * 0.5 + spectral_match * 0.5)
	
	# Fatigue analysis: detect repetitive high-frequency transients
	var hf_onset_count = _count_hf_onsets(audio)
	var duration = audio.size() / SAMPLE_RATE
	var hf_rate = hf_onset_count / duration
	
	var fatigue_risk = clampf(hf_rate / 10.0, 0.0, 1.0)  # >10 HF transients/sec = fatigue
	
	var culprits = []
	if hf_rate > 8.0:
		culprits.append("hi-hats")
	if hf_rate > 12.0:
		culprits.append("arpeggios")
	
	return {"seam_score": seam_score, "fatigue_risk": fatigue_risk, "culprits": culprits}


static func analyze_vo_safety(audio: PackedFloat32Array) -> Dictionary:
	# Measure energy in presence band (2-5kHz) - VO conflict zone
	var presence_energy = 0.0
	var total_energy = 0.0
	
	var window_size = 2048
	for i in range(0, audio.size() - window_size, window_size):
		var window = audio.slice(i, i + window_size)
		var zcr = calculate_zero_crossing_rate(window)
		var rms = calculate_rms(window)
		var freq = zcr * SAMPLE_RATE / 2.0
		
		total_energy += rms
		if freq >= 2000 and freq <= 5000:
			presence_energy += rms
	
	var presence_ratio = presence_energy / total_energy if total_energy > 0 else 0.0
	
	# Safety score: lower presence = safer for VO
	var safety_score = 1.0 - clampf(presence_ratio * 2.0, 0.0, 0.7)
	
	var recommendation = "OK"
	if presence_ratio > 0.25:
		recommendation = "Consider ducking 2-5kHz during dialogue"
	elif presence_ratio > 0.35:
		recommendation = "High VO conflict - needs sidechain or separate mix"
	
	return {
		"safety_score": safety_score,
		"presence_energy": presence_ratio,
		"recommendation": recommendation
	}


# === UTILITY FUNCTIONS ===

static func calculate_rms(samples: PackedFloat32Array) -> float:
	var sum = 0.0
	for s in samples:
		sum += s * s
	return sqrt(sum / samples.size()) if samples.size() > 0 else 0.0


static func calculate_zero_crossing_rate(samples: PackedFloat32Array) -> float:
	var crossings = 0
	for i in range(1, samples.size()):
		if (samples[i] >= 0) != (samples[i-1] >= 0):
			crossings += 1
	return float(crossings) / samples.size() if samples.size() > 0 else 0.0


static func estimate_spectral_centroid(samples: PackedFloat32Array) -> float:
	var zcr = calculate_zero_crossing_rate(samples)
	return zcr * SAMPLE_RATE / 2.0


static func _estimate_spectral_spread(samples: PackedFloat32Array, centroid: float) -> float:
	# Simplified spread estimate
	var zcr_variance = 0.0
	var chunk_size = samples.size() / 8
	var zcrs = []
	for i in range(8):
		var chunk = samples.slice(i * chunk_size, (i + 1) * chunk_size)
		zcrs.append(calculate_zero_crossing_rate(chunk))
	return _calculate_variance(zcrs) * SAMPLE_RATE


static func _compute_spectral_fingerprint(samples: PackedFloat32Array) -> Array:
	# Create a simple spectral fingerprint using band energies
	var fingerprint = []
	var chunk_size = samples.size() / 6
	for i in range(6):
		var chunk = samples.slice(i * chunk_size, (i + 1) * chunk_size)
		fingerprint.append(calculate_rms(chunk))
		fingerprint.append(calculate_zero_crossing_rate(chunk))
	return fingerprint


static func _compare_fingerprints(fp1: Array, fp2: Array) -> float:
	if fp1.size() != fp2.size() or fp1.size() == 0:
		return 0.5
	var diff = 0.0
	for i in range(fp1.size()):
		diff += abs(fp1[i] - fp2[i])
	var avg_diff = diff / fp1.size()
	return clampf(1.0 - avg_diff * 5.0, 0.0, 1.0)


static func _average_range(arr: Array, start: int, end: int) -> float:
	var sum = 0.0
	var count = 0
	for i in range(start, min(end, arr.size())):
		sum += arr[i]
		count += 1
	return sum / count if count > 0 else 0.0


static func _average_array(arr: Array) -> float:
	var sum = 0.0
	for v in arr:
		sum += v
	return sum / arr.size() if arr.size() > 0 else 0.0


static func _calculate_variance(arr: Array) -> float:
	if arr.size() == 0:
		return 0.0
	var mean = _average_array(arr)
	var variance = 0.0
	for v in arr:
		variance += pow(v - mean, 2)
	return variance / arr.size()


static func _analyze_spectral_complexity(audio: PackedFloat32Array) -> float:
	# Higher ZCR variance = more spectral complexity
	var zcrs = []
	var window = 2048
	for i in range(0, audio.size() - window, window):
		zcrs.append(calculate_zero_crossing_rate(audio.slice(i, i + window)))
	return clampf(_calculate_variance(zcrs) * 100.0, 0.0, 1.0)


static func _analyze_onset_rate(audio: PackedFloat32Array) -> float:
	var hop = 512
	var energies = []
	for i in range(0, audio.size() - hop, hop):
		energies.append(calculate_rms(audio.slice(i, i + hop)))
	
	var onsets = 0
	var threshold = _average_array(energies) * 1.5
	for i in range(1, energies.size() - 1):
		if energies[i] > threshold and energies[i] > energies[i-1] * 1.3:
			onsets += 1
	
	var duration = audio.size() / SAMPLE_RATE
	return onsets / duration if duration > 0 else 0.0


static func _analyze_brightness(audio: PackedFloat32Array) -> float:
	return estimate_spectral_centroid(audio)


static func _analyze_dynamic_activity(audio: PackedFloat32Array) -> float:
	var rms_values = []
	var window = 4096
	for i in range(0, audio.size() - window, window):
		rms_values.append(calculate_rms(audio.slice(i, i + window)))
	return _calculate_variance(rms_values)


static func _analyze_spectral_consistency(audio: PackedFloat32Array) -> float:
	var centroids = []
	var window = 4096
	for i in range(0, audio.size() - window, window):
		centroids.append(estimate_spectral_centroid(audio.slice(i, i + window)))
	var mean = _average_array(centroids)
	var variance = _calculate_variance(centroids)
	return sqrt(variance)


static func _count_hf_onsets(audio: PackedFloat32Array) -> int:
	# Count high-frequency transients (potential fatigue sources)
	var hop = 256
	var hf_count = 0
	var prev_hf_energy = 0.0
	
	for i in range(0, audio.size() - hop, hop):
		var chunk = audio.slice(i, i + hop)
		var zcr = calculate_zero_crossing_rate(chunk)
		var rms = calculate_rms(chunk)
		
		# High frequency = high ZCR
		if zcr > 0.3:  # Threshold for "high frequency"
			var hf_energy = rms
			if hf_energy > prev_hf_energy * 2.0 and hf_energy > 0.02:
				hf_count += 1
			prev_hf_energy = hf_energy
	
	return hf_count
