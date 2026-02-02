class_name TrackImprover
extends RefCounted
## Analyzes track scores and provides actionable improvement suggestions
## Works with TrackAnalyzer results

# Genre target profiles (what each genre should aim for)
const GENRE_TARGETS = {
	"madonna_80s": {
		"bpm": 118,
		"lambda": 0.35,
		"frequency": {"sub": 0.12, "bass": 0.22, "low_mid": 0.12, "mid": 0.28, "presence": 0.16, "air": 0.10},
		"characteristics": ["gated_reverb_snare", "bright_synths", "4_on_floor", "hooky_melody", "octave_bass"],
		"rubric_targets": {
			"identity_token": 4.5,  # Madonna tracks are instantly recognizable
			"cohesion": 4.0,
			"energy_arc": 4.0,
			"frequency_allocation": 4.0,
			"dynamic_contrast": 3.5,
			"loop_durability": 4.0
		}
	},
	"modern_pop": {
		"bpm": 100,
		"lambda": 0.40,
		"frequency": {"sub": 0.15, "bass": 0.20, "low_mid": 0.12, "mid": 0.25, "presence": 0.15, "air": 0.13},
		"characteristics": ["sub_808", "sparse_arrangement", "vocal_chops", "sidechain_pump"],
		"rubric_targets": {
			"identity_token": 4.0,
			"cohesion": 4.5,
			"energy_arc": 3.5,
			"frequency_allocation": 4.5,
			"loop_durability": 4.0
		}
	},
	"kraftwerk": {
		"bpm": 110,
		"lambda": 0.25,
		"frequency": {"sub": 0.10, "bass": 0.20, "low_mid": 0.15, "mid": 0.28, "presence": 0.17, "air": 0.10},
		"characteristics": ["motorik_beat", "vocoder", "precise_sequence", "minimal_variation"],
		"rubric_targets": {
			"identity_token": 4.5,
			"cohesion": 5.0,
			"controlled_variation": 3.0,  # Intentionally repetitive
			"loop_durability": 5.0
		}
	}
}


## Generate improvement suggestions from analysis results
static func get_suggestions(analysis: Dictionary, target_genre: String = "") -> Array:
	var suggestions = []
	
	var rubric = analysis.get("rubric", {})
	var comp = analysis.get("composition", {})
	var prod = analysis.get("production", {})
	var game = analysis.get("game_ready", {})
	
	# Get target profile if specified
	var target = GENRE_TARGETS.get(target_genre, {})
	var target_rubric = target.get("rubric_targets", {})
	var target_freq = target.get("frequency", {})
	
	# === IDENTITY SUGGESTIONS ===
	var identity_score = rubric.get("identity_token", 3.0)
	var identity_target = target_rubric.get("identity_token", 4.0)
	
	if identity_score < identity_target:
		var signature = comp.get("signature_consistency", 0.5)
		var motif = comp.get("motif_strength", 0.5)
		
		if signature < 0.6:
			suggestions.append({
				"category": "identity",
				"priority": "high",
				"issue": "Low signature consistency (%.0f%%)" % (signature * 100),
				"fix": "Add a recurring motif or signature sound that appears in every section",
				"param_hint": "motif_recurrence"
			})
		if motif < 0.5:
			suggestions.append({
				"category": "identity",
				"priority": "high",
				"issue": "Weak motif presence",
				"fix": "Create a memorable 2-4 note hook that returns every 8-16 bars",
				"param_hint": "motif_interval"
			})
	
	# === FREQUENCY SUGGESTIONS ===
	var freq_score = rubric.get("frequency_allocation", 3.0)
	var bands = prod.get("band_energies", {})
	
	if prod.get("low_mid_warning", false):
		suggestions.append({
			"category": "frequency",
			"priority": "high",
			"issue": "Low-mid buildup (mud)",
			"fix": "Cut 200-500Hz on pads/bass, or use high-pass on non-bass elements",
			"param_hint": "low_mid_cut"
		})
	
	if prod.get("presence_vo_conflict", false):
		suggestions.append({
			"category": "frequency",
			"priority": "medium",
			"issue": "High presence energy (VO conflict risk)",
			"fix": "Reduce 2-5kHz on synths, or make presence elements sparser",
			"param_hint": "presence_duck"
		})
	
	# Check against genre targets
	if not target_freq.is_empty():
		for band in bands.keys():
			var actual = bands.get(band, 0.0)
			var ideal = target_freq.get(band, 0.15)
			var diff = actual - ideal
			
			if abs(diff) > 0.08:  # >8% deviation
				var direction = "too much" if diff > 0 else "not enough"
				suggestions.append({
					"category": "frequency",
					"priority": "medium",
					"issue": "%s in %s band (%.0f%% vs target %.0f%%)" % [direction.capitalize(), band, actual * 100, ideal * 100],
					"fix": "Adjust %s elements %s" % [band, "down" if diff > 0 else "up"],
					"param_hint": band + "_level"
				})
	
	# === DYNAMICS SUGGESTIONS ===
	var dynamic_score = rubric.get("dynamic_contrast", 3.0)
	var micro = prod.get("micro_contrast", 0.5)
	var macro = prod.get("macro_contrast", 0.5)
	
	if micro < 0.4:
		suggestions.append({
			"category": "dynamics",
			"priority": "medium",
			"issue": "Low micro contrast (static within sections)",
			"fix": "Add velocity variation to drums, or filter movement on synths",
			"param_hint": "velocity_variation"
		})
	
	if macro < 0.4:
		suggestions.append({
			"category": "dynamics",
			"priority": "medium",
			"issue": "Low macro contrast (sections too similar)",
			"fix": "Make intro/outro quieter, or add more layers in chorus",
			"param_hint": "section_energy_range"
		})
	
	# === ARC SUGGESTIONS ===
	var arc_score = rubric.get("energy_arc", 3.0)
	var arc_shape = comp.get("arc_shape", "unknown")
	
	if arc_shape == "flat":
		suggestions.append({
			"category": "arc",
			"priority": "high",
			"issue": "Flat energy curve (no journey)",
			"fix": "Create build-up to a peak, then release. Vary layer count per section.",
			"param_hint": "energy_curve"
		})
	
	# === LOOP SUGGESTIONS ===
	var loop_score = rubric.get("loop_durability", 3.0)
	var seam = game.get("loop_seam_score", 0.5)
	var fatigue = game.get("fatigue_risk", 0.0)
	
	if seam < 0.6:
		suggestions.append({
			"category": "loop",
			"priority": "high",
			"issue": "Poor loop seam (%.0f%% match)" % (seam * 100),
			"fix": "Match intro and outro energy levels. End on same chord as start.",
			"param_hint": "loop_seam"
		})
	
	if fatigue > 0.5:
		var culprits = game.get("fatigue_culprits", [])
		suggestions.append({
			"category": "loop",
			"priority": "medium",
			"issue": "Loop fatigue risk from: " + ", ".join(culprits) if culprits.size() > 0 else "hi-freq repetition",
			"fix": "Reduce hi-hat density, add variation to arps, or lower brightness",
			"param_hint": "hat_density"
		})
	
	# === GENRE-SPECIFIC SUGGESTIONS ===
	if target_genre == "madonna_80s":
		suggestions.append_array(_get_madonna_suggestions(analysis))
	
	# Sort by priority
	suggestions.sort_custom(func(a, b): 
		var priority_order = {"high": 0, "medium": 1, "low": 2}
		return priority_order.get(a.priority, 2) < priority_order.get(b.priority, 2)
	)
	
	return suggestions


static func _get_madonna_suggestions(analysis: Dictionary) -> Array:
	var suggestions = []
	var prod = analysis.get("production", {})
	var bands = prod.get("band_energies", {})
	
	# Madonna-specific checks
	var mid = bands.get("mid", 0.0)
	var presence = bands.get("presence", 0.0)
	
	if mid < 0.25:
		suggestions.append({
			"category": "genre:madonna",
			"priority": "medium",
			"issue": "Mid-range too thin for 80s pop",
			"fix": "Add bright synth pads in 500-2kHz range (Juno-style)",
			"param_hint": "synth_brightness"
		})
	
	if presence < 0.14:
		suggestions.append({
			"category": "genre:madonna",
			"priority": "medium",
			"issue": "Needs more presence/attack for 80s sound",
			"fix": "Add gated reverb snare, brighter hi-hats",
			"param_hint": "gated_snare"
		})
	
	# Always suggest Madonna characteristics
	suggestions.append({
		"category": "genre:madonna",
		"priority": "low",
		"issue": "Madonna checklist",
		"fix": "Ensure: gated reverb snare, octave-jumping bass, bright synth stabs, 4-on-floor kick",
		"param_hint": "madonna_checklist"
	})
	
	return suggestions


## Format suggestions as readable text
static func format_suggestions(suggestions: Array) -> String:
	if suggestions.is_empty():
		return "✅ No major issues found!"
	
	var output = "## Improvement Suggestions\n\n"
	
	var current_priority = ""
	for s in suggestions:
		var priority = s.get("priority", "medium")
		if priority != current_priority:
			current_priority = priority
			var icon = "🔴" if priority == "high" else "🟡" if priority == "medium" else "🟢"
			output += "\n### %s %s Priority\n" % [icon, priority.capitalize()]
		
		output += "- **%s**: %s\n" % [s.get("issue", ""), s.get("fix", "")]
	
	return output


## Get a genre target profile
static func get_genre_profile(genre: String) -> Dictionary:
	return GENRE_TARGETS.get(genre, {})
