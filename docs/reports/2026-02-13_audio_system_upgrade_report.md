# Audio System Upgrade Report
**Date:** 2026-02-13
**Scope:** Proposed upgrade of AdaResearch audio authoring, realtime synthesis control, analysis, and export workflow.

## Executive Summary

The current audio stack has strong building blocks but is fragmented across multiple tools and partially wired control paths. The proposed upgrade unifies authoring around one primary workflow, enables true per-layer realtime synthesis audition (solo/mute/volume and preview), integrates synthesis analysis into edit loops, and standardizes waveform/stem export.

The recommendation is to make `SongDevTools` the canonical authoring surface and absorb proven stem functionality from `StemEditor` into that workflow.

## Goals

1. Realtime audition of each track element (pad, drums, bass, lead, arp, fx) with accurate synth behavior.
2. Element-specific editing interfaces wired to actual synthesis parameters.
3. In-tool synthesis review (analysis + actionable improvement suggestions).
4. Reliable waveform and stem creation/export from the same pipeline.
5. Safe migration with minimal regressions in current song generation.

## Current State Assessment

### What already works

- Strong UI foundation for per-layer editing:
  - `commons/audio/catalog/ui/SoundDetailPanel.gd`
  - `commons/audio/catalog/ui/WordSynthDisplay.gd`
- Existing semantic control bridge:
  - `commons/audio/catalog/WordSynthBridge.gd`
- Existing track analysis and scorecard:
  - `commons/audio/analysis/TrackAnalyzer.gd`
  - `commons/audio/analysis/TrackImprover.gd`
  - `commons/audio/analysis/TrackScorecard.gd`
- Existing WAV export:
  - `commons/audio/generators/SongExporter.gd`
- Existing stem UI and export:
  - `commons/audio/catalog/StemEditor.gd`

### Main gaps blocking target workflow

1. Layer controls are not fully implemented in `SongDevTools` (solo/mute/volume handlers are placeholders).
2. Layer preview in `SongDevTools` uses a simplified generated waveform path, not always the true soundbank/generator voice path.
3. Realtime parameter application is split between lightweight and bus-effect code paths, reducing consistency.
4. Analysis currently samples only part of interactive streams in some flows (not full-track aggregated review).
5. Two `SoundSuiteSequencer` implementations with identical class name increase maintenance risk:
   - `commons/audio/sequencer/SoundSuiteSequencer.gd`
   - `commons/grid/SoundSuiteSequencer.gd`
6. Multiple overlapping authoring surfaces (`SongDevTools`, `SongPreviewDesktop`, `StemEditor`) create duplicated logic.

## Target Architecture

### Canonical authoring path

`SongDevTools` -> `SoundDetailPanel` -> `LayerRenderEngine` -> per-layer buses -> analysis/export services

### Proposed core services

1. `LayerRenderEngine` (new):
   - Single source for rendering one layer or full mix.
   - Uses existing soundbank/generator scripts, not approximated fallback synthesis.
2. `LayerRoutingManager` (new):
   - Creates/manages per-layer buses/players for true solo/mute/volume.
3. `ParamSchemaAdapter` (new):
   - Connects UI controls to valid per-layer parameter contracts.
   - Bridges `SynthConfigRegistry` and word mapping into actual render params.
4. `TrackReviewService` (new):
   - Full-track and per-layer analysis orchestration.
   - Integrates `TrackAnalyzer` and `TrackImprover`.
5. `WaveformService` (new):
   - Generates visual waveform buffers and standardized WAV/stem export artifacts.

## Phased Implementation Plan

## Phase 0: Alignment and Safety

- Choose one authoritative `SoundSuiteSequencer` class path and rename/deprecate the other.
- Document canonical authoring path in `commons/audio/catalog/ARCHITECTURE.md`.
- Add regression checklist for existing songs and soundbank suites.

Deliverables:
- Sequencer naming conflict removed.
- Architecture doc updated.

## Phase 1: Realtime Layer Audition (MVP)

- Implement `SongDevTools` layer solo/mute/volume handlers with true routing.
- Route layer preview requests through real layer render path.
- Reuse `StemEditor` track render code patterns as source material for unified renderer.

Deliverables:
- Accurate per-layer preview.
- Solo/mute/volume fully functional in authoring UI.

## Phase 2: Interface-to-Synthesis Binding

- Bind type-specific editors (drum/bass/chord/arp/lead) to actual parameter contracts.
- Remove fallback-only behavior where possible.
- Ensure word-based edits modify render-relevant params, not only display state.

Deliverables:
- Each element editor drives audibly correct synthesis changes in realtime.

## Phase 3: Synthesis Review Loop

- Analyze full rendered track (all sections) rather than first-clip-only paths.
- Add per-layer analysis mode.
- Show prioritized `TrackImprover` suggestions directly in review UI.

Deliverables:
- In-tool mix score + problem list + suggested fixes.

## Phase 4: Waveform and Export Unification

- Use one pipeline for:
  - full mix WAV
  - per-layer WAV
  - stems
- Add waveform view for current mix and selected layer from same rendered buffers.

Deliverables:
- Consistent outputs across play, preview, waveform, and export.

## Phase 5: Performance and QA

- Add caching/debouncing for fast preview response under rapid UI edits.
- Validate on desktop and VR targets.
- Add automated/scene-level smoke tests for render and export integrity.

Deliverables:
- Stable low-latency authoring workflow.

## File Impact Map (Planned)

- `commons/audio/catalog/SongDevTools.gd`
  - Main integration point for layer routing, preview, and review loop.
- `commons/audio/catalog/ui/SoundDetailPanel.gd`
  - Type-specific control binding to real params.
- `commons/audio/catalog/StemEditor.gd`
  - Reuse render logic; reduce duplication by extracting shared services.
- `commons/audio/sequencer/SoundSuiteSequencer.gd`
  - Keep as suite playback engine; optionally expose render hooks.
- `commons/audio/generators/SongExporter.gd`
  - Keep as export backend; align with unified render pipeline.
- `commons/audio/analysis/TrackAnalyzer.gd`
- `commons/audio/analysis/TrackImprover.gd`
- `commons/audio/analysis/TrackScorecard.gd`
  - Maintain analyzer stack; extend orchestration and display.
- `commons/audio/catalog/SynthConfigRegistry.gd`
- `commons/audio/catalog/WordSynthBridge.gd`
  - Normalize param contracts used by UI and renderer.

## Risks and Mitigations

1. Risk: Regressions in existing songs after pipeline unification.
   - Mitigation: Snapshot baseline renders and compare stems/spectral envelopes before merge.
2. Risk: Latency spikes during rapid parameter edits.
   - Mitigation: cache short previews and debounce expensive regeneration.
3. Risk: Conflicting legacy systems remain active.
   - Mitigation: explicitly deprecate parallel paths and gate new path behind one entry point.
4. Risk: Parameter schema drift across UI, word mapping, and render scripts.
   - Mitigation: centralized validation pass at tool startup.

## Acceptance Criteria

1. Solo/mute/volume in `SongDevTools` audibly isolate layers correctly.
2. Layer preview matches actual synthesis engine output for the selected layer.
3. Full-track analysis processes all sections and returns consistent scorecard output.
4. Waveform display and WAV export use the same rendered audio source.
5. Stem export produces one valid file per audible layer with expected timing and level.

## Suggested First Sprint (Pragmatic Start)

1. Resolve sequencer class conflict and lock canonical path.
2. Implement `SongDevTools` true layer routing (solo/mute/volume).
3. Replace simplified layer preview with unified layer renderer.
4. Wire full-track analysis to aggregated interactive stream render.

This first sprint delivers immediate creative value: accurate per-element realtime listening and editing without waiting for full system refactor.

