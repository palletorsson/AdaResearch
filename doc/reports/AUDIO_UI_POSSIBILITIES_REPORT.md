# Audio UI and Control Possibilities Report

Date: 2026-02-05
Scope: AdaResearch audio system (SongDevTools + soundbanks + generators)

## Goal
Expose full sound parameters and patterns per layer/section, plus an easy way to say "more of X, less of Y" (wetness, attack, brightness, etc.), and preview layer sounds/patterns for the current section.

## Current State (Relevant Surfaces)
- SongDevTools UI: res://commons/audio/catalog/SongDevTools.gd
- Sound editor panel: res://commons/audio/catalog/ui/SoundDetailPanel.gd
- Parameter registry: res://commons/audio/catalog/SynthConfigRegistry.gd
- Word-to-parameter map: res://commons/audio/parameters/word_synthesis_map.json
- Soundbank patterns: res://commons/audio/generators/SoundbankGenerator.gd
- Melody patterns: res://commons/audio/generators/MelodyGenerator.gd

## Possibilities (Ordered by Simplicity and ROI)

### 1) Section Macro Panel (Fastest, No Schema Changes)
Add a small panel in SongDevTools that applies per-section macro sliders:
- Brightness (filter cutoff)
- Attack
- Release
- Reverb (wet)
- Delay (wet)
- Stereo width
- Bass level
- Drums level

Behavior:
- Stores values per section (in-memory or saved to a small local cache)
- No JSON schema changes required
- Immediate "more/less" control

Pros:
- Quick to implement
- Solves the "more wet/less attack" request directly
- Minimal risk

Cons:
- Not tied to per-layer parameter specifics
- Harder to share across songs without extra persistence

### 2) Section Word Chips (Simple, Expressive)
Add a word list per section, e.g. "more wet", "less bright", "slow attack":
- Map each word to param nudges via word_synthesis_map.json
- Treat "more/less" as +/- bias toward max/min

Pros:
- Human friendly
- Reusable vocabulary
- No complex NLP required

Cons:
- Requires a small translation layer
- Still coarse

### 3) Auto-Generated Parameter UI per Layer (Requested)
Use SynthConfigRegistry to auto-build sliders for each layer:
- ADSR where relevant
- Filter (cutoff, resonance)
- Mod (LFO rate/depth)
- FX (reverb mix, delay mix)
- Show non-numeric fields (type, style, pattern) as labels

Pros:
- Shows the real synth parameters
- Clear exposure of attack/sustain/decay/release
- Works for synth-based songs

Cons:
- Requires consistent param naming across generators
- Needs UI grouping (envelope, filter, fx)

### 4) Pattern Visualization Panel
Display current layer patterns:
- Soundbank drums: 16-step grid from SoundbankGenerator.PATTERNS
- Bass patterns: BASS_PATTERNS
- Melodic/seq patterns: MelodyGenerator patterns

Options:
- Read-only grid first
- Later upgrade to clickable step editor

Pros:
- Immediate visual insight into groove
- Supports previewing the current section

Cons:
- Some generators do not have exposed patterns

### 5) Section Preview (Layer-Level Audio Preview)
Add "Preview Layer" for the current section:
- Render 1-2 bars for only that layer
- Use generator functions already in SongDevTools

Pros:
- Directly answers "preview the sound and pattern"
- Easy to compare sections

Cons:
- Pre-rendered audio means changes require regeneration

### 6) Per-Section Automation + Per-Layer FX Sends (Most Important Addition)
Add a lightweight automation layer for section overrides:
- Per-section overrides (mix + per-layer params)
- Simple vocabulary to JSON mapping

Pros:
- Aligns with film/game/pop workflow
- Makes the system feel like a real instrument

Cons:
- Requires persistence format and merging with base params

## Recommended First Step (Straightforward)
Implement 1 + 3 + 4 in SongDevTools:
1. Section Macro Panel (fast control)
2. Auto-generated parameter UI per layer
3. Pattern visualization panel

This gives immediate results without a new schema.

## Optional Next Step
Add Section Word Chips for expressive control without complex NLP.

## Implementation Notes (Short)
- Reuse SynthConfigRegistry as the canonical parameter source for UI.
- Add UI grouping in SoundDetailPanel (Envelope, Filter, FX, Mod).
- Add a PatternPanel widget or simple grid in SongDevTools.

## Files to Modify (Likely)
- commons/audio/catalog/SongDevTools.gd
- commons/audio/catalog/ui/SoundDetailPanel.gd
- commons/audio/catalog/SynthConfigRegistry.gd
- commons/audio/parameters/word_synthesis_map.json
- commons/audio/generators/SoundbankGenerator.gd
- commons/audio/generators/MelodyGenerator.gd

## Open Questions
- Should section controls be persisted per song file or kept as dev-only state?
- Should patterns be editable or read-only in the first pass?
- Should word chips be in the main UI or the sound detail panel?

