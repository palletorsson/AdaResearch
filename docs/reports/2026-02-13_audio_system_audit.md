# Audio System Upgrade Plan — Full Audit
**Date:** 2026-02-13  
**Auditor:** Ada  
**Scope:** Verify every claim in the proposed upgrade report against actual codebase

---

## Verdict: Report is ~80% accurate, with significant gaps

The report correctly identifies the core problems but underestimates some issues, mischaracterizes others, and misses a few critical blockers entirely.

---

## Claim-by-Claim Verification

### ✅ CONFIRMED: Solo/mute/volume handlers are placeholders

**Evidence:** `SongDevTools.gd` lines 2640-2651:
```gdscript
func _on_layer_solo(_pressed: bool, layer_name: String):
    # TODO: Implement actual solo via bus routing
    pass

func _on_layer_mute(_pressed: bool, layer_name: String):
    # TODO: Implement actual mute via bus routing
    pass

func _on_layer_volume(_value: float, layer_name: String):
    # TODO: Apply to layer-specific bus
    pass
```
These are literal `pass` stubs. The UI checkboxes and sliders exist and are wired (lines 1723-1760) but do nothing. **This is the single biggest gap** — the core interaction promise of the tool is broken.

### ✅ CONFIRMED: Layer preview uses simplified waveform, not real soundbank

**Evidence:** `_generate_layer_preview()` (line 2731) builds audio from scratch using basic sin/sawtooth oscillators with hardcoded frequency lookup by layer name. It does NOT use `SoundbankLoader`, `SoundbankGenerator`, or any real sound scripts.

Meanwhile, `StemEditor._generate_track_audio()` (line 657) DOES use the real path: `SoundbankLoader.load_genre()` → `bank.get_sound_script()` → `script.generate()`. The report correctly identifies this asymmetry.

### ✅ CONFIRMED: Two `SoundSuiteSequencer` with identical class_name

**Evidence:**
- `commons/audio/sequencer/SoundSuiteSequencer.gd` (19,915 bytes) — the full-featured one with voice management, soundbank mapping, suite definitions
- `commons/grid/SoundSuiteSequencer.gd` (11,279 bytes) — simpler version, references `SoundBank` singleton

Both declare `class_name SoundSuiteSequencer`. In Godot, this means **whichever one gets registered last wins**, and the behavior is undefined/load-order-dependent. This is a genuine runtime hazard.

**The grid version** is likely the older one (simpler, less code, no voice pooling). The sequencer version is the mature one.

### ⚠️ PARTIALLY CORRECT: "Realtime parameter application is split between lightweight and bus-effect code paths"

**Evidence:** `_apply_live_params()` (line 2583) only sets Master bus volume:
```gdscript
func _apply_live_params():
    var master_idx = AudioServer.get_bus_index("Master")
    AudioServer.set_bus_volume_db(master_idx, live_params["master_volume"])
    # TODO: Connect these to actual synth parameters when AudioSynthesizer supports it
```

The report says it's "split between lightweight and bus-effect code paths" — but **it's worse than that**. The live_params dictionary has ~20 entries (filter cutoff, resonance, reverb, chorus, etc.) but `_apply_live_params()` only routes ONE of them (master volume). The rest are display-only. The bus effects are set up at init (lines 182-248) but never updated from live_params in the process loop.

**Correction:** It's not "split between two paths" — it's one broken path that only connects at the volume level.

### ✅ CONFIRMED: Analysis samples only first clip

**Evidence:** `_analyze_current_track()` (line 2230):
```gdscript
var first_clip = _current_stream.get_clip_stream(0)
```
It explicitly grabs only clip index 0 (first section). A song might have 6-12 sections. The analysis scores the intro and ignores everything else.

### ⚠️ PARTIALLY CORRECT: "Multiple overlapping authoring surfaces create duplicated logic"

The three surfaces are:
1. **SongDevTools** (141KB) — deep editor, transport, timeline, word controls, parameter sliders, analysis, AI panel
2. **SongPreviewDesktop** (58KB) — lighter preview + export, also has timeline, opens StemEditor
3. **StemEditor** (25KB) — DAW-lane view with real per-track rendering

The report says they overlap. **More precisely:**
- SongDevTools and SongPreviewDesktop are parallel entry points that share some components but have divergent playback behavior (documented in ARCHITECTURE.md — bus effects differ, generator paths differ)
- StemEditor is launched FROM SongPreviewDesktop (line 604) and is the only one with real per-track render
- The actual duplication is: both SongDevTools and StemEditor need per-track render, but SongDevTools fakes it while StemEditor does it properly

---

## Issues the Report MISSES

### 🔴 CRITICAL: `_apply_live_params()` is almost entirely non-functional

The report mentions "split between lightweight and bus-effect code paths" but doesn't flag that 19 of 20 live parameters DO NOTHING. This is the #1 fix needed — not a service abstraction, but literally wiring the existing parameters to existing bus effects.

The bus effects (lowpass, highpass, distortion, chorus, delay, reverb, limiter) are already created at init. They just need `_apply_live_params()` to call `AudioServer.set_bus_effect_enabled/set_param()` for each.

### 🔴 CRITICAL: No per-layer AudioStreamPlayer / bus architecture exists

The report proposes "LayerRoutingManager" as if it's a matter of management. The actual problem is more fundamental: **all audio goes through a single `AudioStreamPlayer` playing a single `AudioStreamInteractive`**. The Interactive stream has all layers pre-mixed into each section clip.

This means solo/mute/volume CANNOT be implemented by bus routing alone — you'd need to either:
1. Re-render individual layer audio on the fly (using StemEditor's approach), or
2. Change the generation pipeline to output separate AudioStreamPlayers per layer, each on its own bus

Option 1 is the realistic path. Option 2 is a deep architecture change. The report doesn't acknowledge this constraint.

### 🟡 MISSED: `AudioSynthesizer.gd` is 394KB (!)

This is the largest file in the entire project. It likely contains embedded logic that duplicates what generators and soundbanks do. Any audit should map what AudioSynthesizer does vs. SoundbankGenerator (101KB) vs. CustomSoundGenerator (201KB). Three massive generators with overlapping scope is a maintainability risk the report doesn't address.

### 🟡 MISSED: `GenreSynthBrowser.gd` is 170KB

Another massive file. The report doesn't mention it, but any unified authoring path needs to reckon with this. What does it do that SongDevTools doesn't?

### 🟡 MISSED: SongPreviewDesktop → StemEditor handoff loses context

SongPreviewDesktop creates StemEditor on button press (line 604-605) but the StemEditor has to re-parse song patterns from `SoundbankGenerator.PATTERNS` and `SoundbankGenerator.BASS_PATTERNS` — it doesn't receive the already-generated audio or stream. This means every StemEditor launch is a cold start.

### 🟡 MISSED: No word_synthesis_map.json validation

WordSynthBridge.words_to_live_params() maps words → parameter names, but if the parameter names don't match live_params keys, the mapping silently fails. There's no validation or error logging for this.

---

## Assessment of Proposed Architecture

### "5 New Services" — Overengineered?

| Proposed Service | Actually Needed? |
|---|---|
| `LayerRenderEngine` | **Yes, but...** StemEditor already has this logic in `_generate_track_audio()`. Extract it, don't rewrite it. |
| `LayerRoutingManager` | **Premature.** Per-layer buses only matter if you have per-layer audio streams. Since the current architecture pre-mixes into AudioStreamInteractive, you'd need the render engine first. |
| `ParamSchemaAdapter` | **Over-abstracted.** The real fix is: make `_apply_live_params()` actually apply params to bus effects. That's ~30 lines of code, not a service. |
| `TrackReviewService` | **Reasonable** but could just be an extension to TrackScorecard. No need for a new class. |
| `WaveformService` | **Reasonable** if you want waveform display + export from the same buffer. But SongExporter already exists. |

**Recommendation:** 1 new utility class (extracted from StemEditor's render logic), plus fixes to existing code. Not 5 new services.

---

## Revised Priority Order

### Sprint 0 (Safety, 1 day)
1. **Kill the duplicate SoundSuiteSequencer** — rename `commons/grid/SoundSuiteSequencer.gd` to `GridSequencer.gd` or similar, update its class_name
2. **Wire `_apply_live_params()` to bus effects** — connect filter_cutoff, resonance, reverb_mix, delay_time, etc. to the effects already created at init. This is ~40 lines and instantly makes the parameter sliders audible.

### Sprint 1 (Core Value, 2-3 days)
3. **Extract `LayerRenderer` from StemEditor** — take `_generate_track_audio()` and `_generate_mix()` into a shared utility class that both StemEditor and SongDevTools can use
4. **Replace `_generate_layer_preview()` in SongDevTools** — use the extracted LayerRenderer instead of fake oscillators
5. **Implement solo/mute/volume** — use LayerRenderer to pre-render per-layer buffers, play them on separate AudioStreamPlayers with per-layer volume/mute control

### Sprint 2 (Analysis, 1-2 days)
6. **Fix analysis to scan all sections** — iterate all clips in AudioStreamInteractive, not just clip 0
7. **Add per-layer analysis** — render individual layers via LayerRenderer, analyze each

### Sprint 3 (Consolidation, 2-3 days)
8. **Merge SongPreviewDesktop into SongDevTools** — SongPreviewDesktop is a subset. Absorb its export features into SongDevTools and deprecate it
9. **Standardize export** — use LayerRenderer for both stem export and full-mix export

---

## File Size / Complexity Audit

| File | Size | Concern |
|---|---|---|
| `AudioSynthesizer.gd` | 394 KB | 🔴 Enormous. Needs decomposition audit. |
| `GenreSynthBrowser.gd` | 170 KB | 🔴 What does this do that others don't? |
| `SongDevTools.gd` | 141 KB | 🟡 Large but justified (it's the main tool) |
| `SoundbankGenerator.gd` | 101 KB | 🟡 Core generator, warranted size |
| `CustomSoundGenerator.gd` | 201 KB | 🔴 Another massive generator. Overlap with AudioSynthesizer? |
| `SongPreviewDesktop.gd` | 58 KB | 🟡 Candidate for absorption into SongDevTools |
| `SynthElementBrowser.gd` | 57 KB | 🟡 Unclear overlap with GenreSynthBrowser |
| `SoundDetailPanel.gd` | 49 KB | OK — type-specific editors, warranted |
| `AIAssistantPanel.gd` | 50 KB | 🟡 Large for a panel. What does it do? |
| `StemEditor.gd` | 25 KB | ✅ Clean, focused, has the real render logic |

The top 3 files alone are **767 KB of GDScript**. That's a maintenance hazard regardless of architecture.

---

## Bottom Line

The report's diagnosis is mostly right. Its treatment plan is too abstract — it proposes 5 new service classes when the real fixes are:
1. Wire the 20 existing bus effect parameters (40 lines)
2. Extract StemEditor's render logic into a shared class
3. Kill the class_name collision
4. Fix analysis to scan full tracks

Start there. The service abstraction layer can come later if the codebase actually needs it — right now it needs plumbing, not architecture.
