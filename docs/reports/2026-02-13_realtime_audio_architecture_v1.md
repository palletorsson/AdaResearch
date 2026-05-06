# Realtime Audio Architecture v1
**Date:** 2026-02-13  
**Owner:** Audio Systems  
**Scope:** Song editing/playback unification for `SongDevTools`, pattern editors, and track preview

## 1. Product Goal
Build one realtime audio path so these always match:
- Step preview in instrument editors
- Layer preview
- Full-track transport playback
- Offline export (WAV/stems)

If a user changes a step/note/chord/param, they hear the same result everywhere.

### 1.1 What We Actually Want
- Instrument-first workflow: design and hear one instrument clearly.
- Context workflow: hear that same instrument inside the full section/track.
- Determinism: same state produces same sound in preview, playback, and export.
- Editability: every UI control has an audible effect, with no silent timeline-only updates.

## 2. Core Principle
UI is not audio logic.  
UI emits edit commands into a shared song state.  
One runtime engine reads that state and renders sound.

## 3. Current Problems (Observed)
- Multiple preview/playback code paths produce different sound behavior.
- Routing by display labels (`"Pad"`, `"I"`, etc.) creates wrong sound fallback.
- Pattern editors can advance timeline without guaranteed musically-correct audio trigger context.
- Runtime and export are not guaranteed to use identical generation behavior.

## 4. v1 Target Architecture

### 4.1 Canonical Song State
Single state model in memory:
- `SongState`
  - `song_id: String`
  - `bpm: float`
  - `key: String`
  - `scale: String`
  - `transport: {playing, position_sec, loop_start, loop_end}`
  - `sections: Array[SectionState]`
  - `tracks: Dictionary[String, TrackState]` (keyed by stable `track_id`)

- `TrackState`
  - `track_id: String`
  - `instrument_id: String` (stable engine id, not UI text)
  - `role: String` (`drum|bass|lead|pad|arp|fx|vocal`)
  - `pattern: Array[float]`
  - `notes: Array[int]`
  - `chords: Array[String]`
  - `automation: Dictionary`
  - `mix: {mute, solo, gain_db, pan}`
  - `params: Dictionary`

### 4.2 Command Bus
All UI writes become typed commands:
- `SetStepVelocity(track_id, step, velocity)`
- `SetStepNote(track_id, step, midi_note)`
- `SetStepChord(track_id, step, degree)`
- `SetTrackParam(track_id, key, value)`
- `SetTrackMix(track_id, mute/solo/gain/pan)`
- `SetTransport(playing/seek/loop/bpm)`
- `ApplyPatternPreset(track_id, preset_id)`

Commands mutate `SongState` and emit a state-change event.

### 4.3 Unified Runtime Engine
Introduce one engine service (name suggestion: `SongRuntimeEngine`) that supports modes:
- `preview_step(track_id, step_context)`
- `preview_layer(track_id)`
- `render_realtime(song_state_snapshot)`
- `render_offline(song_state_snapshot, quality_mode)`

Same DSP/generator path for all modes.

### 4.4 Instrument Resolver
Explicit resolver maps `instrument_id -> generator/soundbank script`.
- Never resolve from UI labels.
- UI labels are metadata only.
- Roman chord degree (`I`, `V`, `vi`) is harmonic input, not sound id.

### 4.5 Track Structure (No Hard Rewrite Required)
To support current songs and future editing:
- Keep current track model, but formalize two layers:
  - `VoiceDefinition` (what sound engine to use and with what params)
  - `PatternDefinition` (what notes/chords/steps are played and when)
- A `TrackState` references one voice + one active pattern.
- This avoids a destructive track rewrite while still enabling robust per-role editors (`drum|bass|lead|pad|arp`).

## 5. UI Contract (Per Editor)
Each editor emits both:
- a **state command** (persistent change)
- optional **audition event** (transient trigger)

Examples:
- Drum editor click:
  - `SetStepVelocity(kick_track, step, 1.0)`
  - `preview_step(kick_track, {step})`
- Chord editor click:
  - `SetStepChord(pad_track, step, "IV")`
  - `preview_step(pad_track, {degree:"IV", key:"C", scale:"major"})`
- Arp editor tweak:
  - `SetTrackParam(arp_track, "direction", "up_down")`
  - `preview_layer(arp_track)`

## 6. Data Flow
1. UI emits command  
2. `SongStateStore` applies command  
3. `SongRuntimeEngine` consumes latest state snapshot  
4. Audio output + waveform/timeline are derived from same snapshot  
5. Export uses same engine in offline mode

## 7. Migration Plan (Safe, Incremental)

### Phase 0: Stabilize IDs (1 sprint)
- Add stable `track_id` and `instrument_id` where missing.
- Keep legacy layer names for display only.
- Add adapter for old saves/configs.

**Acceptance**
- No audio path uses UI label for sound routing.

### Phase 1: State + Commands (1 sprint)
- Add `SongStateStore` + command handlers.
- Wire `SoundDetailPanel`/pattern editors to commands first, keep existing audio code as fallback.

**Acceptance**
- Edits persist in one shared state model.

### Phase 2: Runtime Engine Unification (1-2 sprints)
- Extract and centralize generation path used by preview/transport/export.
- Route step/layer/full playback through engine mode API.

**Acceptance**
- Same edit gives same audible result in preview and full playback.

### Phase 3: Mix + Performance (1 sprint)
- Implement proper per-track mute/solo/gain in runtime mix graph.
- Add fast audition lane (short-duration low-latency preview path).

**Acceptance**
- Mute/solo/gain behave consistently in editor and playback.

### Phase 4: Export Parity + QA (1 sprint)
- Export engine uses same render primitives as runtime.
- Golden tests for drum/bass/lead/pad/arp parity.

**Acceptance**
- Preview A/B and export A/B match within defined tolerance.

## 8. Performance Rules
- No full-song re-render on every step click.
- Use small block rendering for audition.
- Cache per-track buffers only when state hash unchanged.
- Param smoothing for continuous controls.

## 9. Compatibility Strategy
- Keep existing song JSON files; add migration adapter layer.
- Old layer names map to `track_id`/`instrument_id` on load.
- Save in new format once edited.

## 10. Testing Matrix (Must-Have)
- Step preview correctness:
  - Drum hit, bass note, chord degree, arp note.
- Parity:
  - Step preview vs layer preview vs transport vs export.
- Routing:
  - No fallback to unrelated sound (e.g., keys -> kick).
- Regression:
  - Existing `*_sb` songs load and play.

## 11. Suggested File Ownership (v1)
- `commons/audio/catalog/SongDevTools.gd`
  - Orchestration/UI only, no bespoke DSP decisions.
- `commons/audio/catalog/ui/SoundDetailPanel.gd`
  - Command/event emission only.
- `commons/audio/catalog/LayerRenderer.gd`
  - Transitional rendering utility; eventually absorbed by runtime engine.
- `commons/audio/sequencer/SoundSuiteSequencer.gd`
  - Candidate runtime core if extended to all preview modes.

## 12. Definition of Done (v1)
- One engine path for step/layer/song/export.
- Stable ids replace label-based routing.
- Pattern edits are immediately audible and consistent.
- Mute/solo/gain work per-track in realtime.
- No known "timeline moves but no sound" in drum/bass/lead/pad/arp editors.

## 13. Immediate Implementation Focus (Next Sprint)
- Extract `SongStateStore` with command handlers and migrate `SoundDetailPanel` editor actions first.
- Move preview routing fully to `track_id`/`instrument_id`, remove remaining label-based fallback paths.
- Build `SongRuntimeEngine.preview_step()` as the single entry for editor audition.
- Add per-role parity checks on `kraftwerk` intro:
  - Pad chord edit changes audible output.
  - Arp edit changes audible output.
  - Keys never route to drum/kick fallback.

