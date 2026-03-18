# Audio Suite Discovery Pass — 2026-03-15

## Workspace Inventory

| Metric | Count |
|--------|-------|
| GDScript files | 361 |
| JSON configs | 346 |
| Godot scenes (.tscn) | 82 |
| Documentation (.md) | 51 |
| Soundbank folders | 25 |
| Song definitions | 44 |
| Rack controls | 15 |
| Generator engines | 63 |
| Parameter categories | 26 |
| Test files | ~10 |

Top-level subsystems: generators, catalog, soundbanks, sequencer, compositions, interfaces, rack_controls, runtime, systems, components, live, sync, presets, parameters.

## Runtime Health

### Bug: `is_ambient_playing()` inverted logic
**File:** `SoundBankSingleton.gd:146-152`
```gdscript
func is_ambient_playing(preset_name: String) -> bool:
    return current_ambient_preset == preset_name and _is_transitioning
```
Returns `true` ONLY during transitions. Should check `current_ambient_preset == preset_name` without requiring `_is_transitioning`. Same issue in `should_skip_generation()`.

### Thread callback safety
**File:** `generators/AudioSynthesizer.gd` — `_on_generation_complete()` checks `data.callback_obj` for truthiness but doesn't use `is_instance_valid()`. Object could be freed between thread completion and deferred callback.

### Thread reuse
**File:** `generators/AudioSynthesizer.gd` — Static `generation_thread` not properly recycled after first use. Second async generation call may fail.

### No broken path refs
All `res://commons/audio/` paths verified correct. No stale `res://audio/` references found.

## Blocked Task Analysis

### 1. SuperCollider Integration via OSC (`X0W81rBI6_7u3JNhqr9d0`)
**Status:** No SuperCollider or OSC protocol code exists. All "OSC" references are oscillator-related.
**Re-scope:** Create a concrete spike task — define OSC bridge protocol, test with `gdextension` or UDP, measure latency. Or mark as deferred/wishlist.

### 2. Build Wavetable and Granular Native Synths (`yax787NhhzPZlgqFjRl_v`)
**Status:** Memory claims these were built, but NO `WavetableSynth.gd` or `GranularSynth.gd` exists in commons/audio. Likely developed in standalone ntrack project, never ported back.
**Re-scope:** Port from ntrack or rebuild. Concrete first step: locate files in ntrack, copy to `generators/`, adapt resource paths.

### 3. Implement HITL Co-Creation Workflows (`xXxUKXvV02iJFl78vhxuM`)
**Status:** `catalog/ui/AIAssistantPanel.gd` EXISTS with file-based communication protocol (user://ai_state.json, ai_chat.json, ai_response.json). Phase 1 & 2 claimed complete.
**Re-scope:** Verify panel loads, test file protocol roundtrip, document what works. May be closeable after verification.

## Coverage Gaps

### Soundbank-to-Suite Parity (from QA matrix)
- **0 out of 13 genres pass full parity**
- detroit_techno: 4 sounds missing from soundbank (sequence, sweep_up, sweep_down, impact)
- synthwave: 3 sounds missing (lead, sweep_up, impact)
- 11 genres have NO soundbank folder at all

### Sequencer Registration
- SoundSuiteSequencer only registers 1 soundbank mapper at startup (detroit_techno)
- 24 other soundbanks exist but are NOT auto-registered
- Missing dynamic suite switching

### Song Catalog
- 44 song JSONs exist, only 21 listed in SongPreviewDesktop (48%)
- `dark_wave_cathedral` audio route EXISTS (verified 2026-03-18) — was incorrectly flagged as broken
- 3 hybrid songs in UI have no JSON (computer_love, i_feel_love, kpop_prog) — work via redirect

### Missing Systems
- `SongSpecValidator.gd` — referenced in memory but doesn't exist in commons/audio
- `FUTURE_ROADMAP.md` — referenced in memory but not found
- WavetableSynth / GranularSynth — not present

### Test Coverage
- ~10 test files exist but no test runner or CI integration
- QA matrix is static (Feb 11, 2026) and stale

## Runnable Follow-Up Tasks

### High Priority
1. **Fix `is_ambient_playing()` logic bug** — Remove `and _is_transitioning` from the check. Simple 2-line fix.
2. **Register all soundbanks in SoundSuiteSequencer** — Auto-scan `soundbanks/` on startup instead of hardcoding detroit_techno.
3. **Add missing detroit_techno soundbank scripts** — Create sequence.gd, sweep_up.gd, sweep_down.gd, impact.gd.

### Medium Priority
4. **Add missing synthwave soundbank scripts** — Create lead.gd, sweep_up.gd, impact.gd.
5. ~~**Fix dark_wave_cathedral audio route**~~ — ALREADY COMPLETE: Routed to `SoundbankGenerator.generate_song("dark_wave", params)` since commit 0cf771cb (2026-02-11).
6. **Port WavetableSynth/GranularSynth from ntrack** — Locate in /Documents/ntrack, copy, adapt paths.
7. **Create SongSpecValidator.gd** — Runtime validation of bank-to-song parity. Integrate into SongDevTools.

### Low Priority
8. **Expand SongPreviewDesktop listing** — Add remaining 23 songs or document curation intent.
9. **Regenerate QA matrix** — Update SUITE_QA_MATRIX with current state.
10. **SuperCollider OSC feasibility spike** — Research, define protocol, test basic UDP message.
