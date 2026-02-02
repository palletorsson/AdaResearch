# Audio Catalog Architecture

## Overview

The Word Synth system provides **bidirectional translation** between:
- **Semantic words** (warm, bright, punchy) — human-understandable
- **Synth parameters** (filter.cutoff, env.attack) — machine-controllable

## User Flows

### Flow 1: Words → Sound (Forward)
```
User selects words in WordSynthDisplay
	↓
WordSynthBridge.words_to_live_params(layer, words)
	├─ Looks up each word in word_synthesis_map.json
	├─ Resolves conflicts (exclusive pairs, layer priorities)
	└─ Returns {bass_filter_cutoff: 400, reverb_mix: 0.5, ...}
	↓
SongDevTools.live_params updated
	↓
_apply_realtime_effects() → AudioServer bus effects
	↓
User hears the change
```

### Flow 2: Sound → Words (Reverse)
```
User clicks layer name in WordSynthDisplay
	↓
SongDevTools.show_sound_breakdown(layer)
	↓
SynthConfigRegistry.get_layer_config(song_id, layer)
	└─ Returns actual synth params for this layer
	↓
SoundIdentity.from_params(layer, config)
	├─ _build_recipe() → signal chain
	├─ _compute_features() → normalized 0-1 values
	├─ _derive_traits() → word tags
	└─ _build_explanations() → why each trait applies
	↓
SoundIdentityPanel displays:
	├─ Recipe: [osc:saw] → [filter:lowpass] → [fx:distortion]
	├─ Features: brightness=30%, warmth=70%, ...
	├─ Traits: warm, thick, analog (clickable)
	└─ Explanations: "warm because filter.cutoff=400"
```

### Flow 3: Song Playback
```
User clicks song button (e.g., "Kraftwerk")
	↓
SongDevTools._on_song_selected(song_id)
	↓
_generate_and_play(song_id)
	↓
AudioSynthesizer.generate_kraftwerk_song({})
	└─ Creates AudioStreamInteractive with sections
	↓
_load_song_words(song_id) → populates WordSynthDisplay
_load_timeline_for_song() → populates timeline
	↓
Audio plays, user can:
	├─ Adjust sliders → _apply_realtime_effects()
	├─ Click words → applies via WordSynthBridge
	└─ Click layers → shows SoundIdentity breakdown
```

## Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| `SongDevTools.gd` | Main UI, playback, slider controls |
| `WordSynthDisplay.gd` | Shows word tags per layer, "+"/click handlers |
| `WordSynthBridge.gd` | Words ↔ params translation, conflict resolution |
| `SoundIdentity.gd` | Analyzes params into traits/features/recipe |
| `SoundIdentityPanel.gd` | Visualizes SoundIdentity breakdown |
| `SynthConfigRegistry.gd` | Stores actual configs for iconic sounds |
| `AudioSynthesizer.gd` | Generates audio from params |
| `word_synthesis_map.json` | Word definitions, param specs, rules |

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        SongDevTools                             │
│  ┌──────────┐  ┌──────────────┐  ┌─────────────────────────┐   │
│  │ Sliders  │  │ WordSynth    │  │ SoundIdentityPanel      │   │
│  │          │  │ Display      │  │ (breakdown popup)       │   │
│  └────┬─────┘  └──────┬───────┘  └───────────┬─────────────┘   │
│       │               │                      │                  │
│       ▼               ▼                      ▼                  │
│  live_params    WordSynthBridge         SoundIdentity          │
│       │               │                      │                  │
└───────┼───────────────┼──────────────────────┼──────────────────┘
		│               │                      │
		▼               ▼                      ▼
┌───────────────┐ ┌─────────────────┐ ┌───────────────────┐
│ AudioServer   │ │ word_synthesis  │ │ SynthConfig       │
│ (bus effects) │ │ _map.json       │ │ Registry          │
└───────────────┘ └─────────────────┘ └───────────────────┘
```

## Configuration Sources

### word_synthesis_map.json (Source of Truth for Words)
- `param_spec`: Valid param names, units, ranges
- `timbral_words`, `envelope_words`, etc.: Word → param mappings
- `conflict_rules`: Exclusive pairs, priority groups
- `scene_presets`: Pre-defined word combinations
- `layer_templates`: Default words for bass/pad/lead/etc.

### SynthConfigRegistry.gd (Source of Truth for Iconic Sounds)
- Hardcoded configs for 16 song styles
- Each song has layers with actual param values
- Used for reverse analysis (what IS this sound?)

### WordSynthBridge.gd (Runtime Translation)
- `param_mapping`: Maps namespaced params to live_params names
- `layer_priority`: Layer-specific word weights
- Reads from JSON at runtime

## Trait Detection Rules

Traits are derived from features using threshold rules:

```gdscript
const TRAIT_RULES = {
	"bright": {"feature": "brightness", "min": 0.65},
	"warm": {"feature": "warmth", "min": 0.55},
	"plucky": {"feature": "attack_speed", "min": 0.8, 
			   "feature2": "decay_length", "max2": 0.4},
}
```

**Threshold rationale:**
- 0.65 for "bright" = top 35% of brightness range
- 0.55 for "warm" = above midpoint (warm is common)
- Compound rules (plucky) require multiple conditions

## Conflict Resolution

When words conflict (warm + cold both applied):

1. Check `exclusive_pairs` in conflict_rules
2. Later word in list wins (user intent)
3. Remaining words blended via weighted average
4. Layer priority adjusts weights (bass prefers warm)

## Adding New Words

1. Add to `word_synthesis_map.json` under appropriate category
2. Define `params` with ranges/tendencies
3. Add to `opposites` array of antonyms
4. Optionally add to `layer_templates` defaults

## Adding New Songs

1. Add generator in `AudioSynthesizer.gd`:
   - `generate_<name>_song()` returns AudioStreamInteractive
   - `_generate_<name>_section()` renders one section

2. Add config in `SynthConfigRegistry.gd`:
   - Layer names → param dictionaries
   - Use namespaced params (filter.cutoff, not cutoff)

3. Add to `SongDevTools.gd`:
   - Song list button
   - Match case in `_generate_and_play()`
   - Word definitions in `_load_song_words()`

4. Run `SynthConfigRegistry.print_validation_report()` to check typos
