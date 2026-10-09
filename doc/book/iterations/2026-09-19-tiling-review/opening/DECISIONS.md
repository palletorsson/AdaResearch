# Tiling opening review — 19 September 2026

Scope: Pattern Disco and Pattern Foundry. The frozen 18 September review and current review principles were read together. This is a targeted encounter repair and a bounded runtime audit, not a uniform revision of the sequence. Originals of changed files and the two halls' manuscripts/configuration are under `before/`. `changes.diff` compares those exact originals with this pass; it does not compare against the already-dirty Git base.

## Pattern Disco — preserve the chapter, repair the surround and a held-floor flash

**Passage and purpose.** `commons/maps/Pattern_Disco/final.md`: “Changing the palette preserves the current phase”; “Holding the floor leaves the musical events active.” The return separates stored arrangement, colour assignment and clocks. Preserve the complete chapter and all three placed artifacts.

**Evidence.** SOURCE: `disco_controls.gd`, the standalone floor, sequencer and room-local bridge. CAPTURE: the assembled museum initially has saturated magenta lines surrounding the floor, as the review reported. RUNTIME: a deterministic event on a held floor visibly brightens its column, but the old controller never repaints that column; it disables the floor's own animation and only paints on a visual step or another control action. The failed `pulse-before` run records 21 passing assertions and this one failure. Matching musical/visual intervals did preserve independent phase; palette, pattern and speed also had the documented distinct effects.

**Missing layers and decision.** The surround is a map-local presentation issue. Add the same neutral comma-RGBA overrides used in the Arrays pass, with zero emission. The flash is a controller timing issue: record a 150 ms lifetime per musical column and restore the current pattern/palette when that lifetime ends, including during HOLD. Later events renew only their own column. Bind through this floor's existing sequencer bridge; leave the bridge and other floors' implementations unchanged. Do not change global shaders, global flags, geometry, musical clock or visual phase.

**Verification.** Current actual-hall probes pass 29 checks in Pattern Disco and 28 in Tutorial Disco. They cover palette/phase independence, speed, matching intervals without phase reset, visual time while sound is stopped, musical flashes while held, overlapping columns, repeated events on the same column, expiry after palette/pattern edits, own-hall sequencer binding, running-pattern advancement after a musical event and unchanged floor mesh. The original two-hall packed-scene bridge probe passes 17 checks, checking room-local pairing and no borrowing from a neighbouring hall without a sequencer. There is no listening, headset comfort or learner-comprehension claim.

## Pattern Foundry — preserve the system; make the first visit optional in length

**Passage and purpose.** `commons/maps/Pattern_Foundry/final.md`: “Copies share a source”; “Holding this sample means declining the next image”; “The room has separated into two different moments.” These are different state boundaries, not redundant descriptions. The asymmetric source, shared copies, different carriers, source recipe, held receiver, mapping, membership and ownership are all retained.

**Recovery evidence.** The implementations omitted from parts of the frozen source bundle are present. Inspecting `pattern_architecture.gd`, the loom recipe/study, `pattern_studio_plate.gd`, `pattern_studio_console.gd`, `studio_surface_controls.gd` and `curved_pattern_room.gd`, then running their actual-museum probes, confirms the relevant capability. The existing four machines remain useful sources; no secondary or decorative artifact was removed, promoted away, or hidden.

**Runtime results.** All four architecture SOURCE choices have live output; both architectural meshes accept the selected source; HOLD makes independent image copies; RESET restores the loom. Recipe checks cover a pointer edit propagating to both sheets, equal UV order/surface dimensions, independent material instances, hold/relink, source save/restore and validation, repeat spacing, offset and full-period equivalence, grouped wall membership, undo and unchanged support. Studio checks cover explicit source ownership, held image persistence, returning ownership to the loom, mixed group undo, ROOM WALL/FLOOR independence, arc-length mapping, existing collision and the annex approach route. This evidence rejects the implication that the omitted dependencies are absent work.

**Intervention.** Add only two paragraphs to `final.md`: an opening three-pass orientation, then a choice to relink the curve and continue to the annex on a first visit. The source-memory, spacing, offset and group experiments remain available on a return. Every original paragraph is preserved verbatim. The shorter route is optional; no control, capability, or claim has been removed. Its transitions follow tested boundaries: shared source → held receiver → changed owner/inhabitable room.

**Scope limit.** No Foundry artifact repair was warranted by these checks. Source and automated pointer/physics checks do not establish that a new visitor can find the route or distinguish every state label in a headset. That remains a learner/headset walkthrough. The longstanding historical source comment about the Jacquard loom was not promoted into the chapter or treated as a verified historical claim.

## Paired images and their limits

- Surround before: `baseline/Pattern_Disco-inside.png`. This is the original assembled hall, held checker at phase zero. Its log has no script/compile failure.
- Surround after, final chosen image: `pulse-visual-after/Pattern_Disco-held-pulse.png`. Same camera, field of view and held checker state, with map-local neutral surround and repaired expiry. The scripted pulse events have expired before capture. This clean final run replaces the initial `after/` image for delivery.
- Pulse before/after: `pulse-visual-before/Pattern_Disco-held-pulse.png` and `pulse-visual-after/Pattern_Disco-held-pulse.png`. Both use the current neutral hall. The before run re-instantiates the saved original controller script at the authored placement within the actual museum; it is a clearly identified source replay, not a claim to have captured the old live session. Both receive four events each on columns 3 and 7, wait 0.8 seconds and retain visual phase zero. The old controller retains two white bands; the repaired one restores the checker. No image pixels were edited. Each rendered run passes 11 state/placement checks.

The earlier `after/` surround and `runtime/` Foundry logs exposed the concurrently introduced shared `em_detail.gd` declaration error. Root repaired that dependency separately. They are retained as diagnostic evidence; the final `verified-runtime/`, `pulse-final/`, `mono-final/` and `pulse-visual-*` runs have no script or compile errors. Existing UID/certificate and rendered viewport warnings remain in full logs; passing assertions are not presented as an entirely clean project startup. A first draft independence runner selected its script name as the map; its failed one-check setup record remains under `runtime/` and is superseded by the explicitly named hall runs.

## Files changed by this pass

1. `commons/maps/Pattern_Disco/map_data.json` — neutral local grid surround.
2. `commons/artifacts/regularity/disco_controls.gd` — expire musical pulses independently of the held visual clock.
3. `commons/maps/Pattern_Foundry/final.md` — two optional-route signposts, with all original paragraphs retained.

All other additions are snapshots, focused probe copies/runners, logs, reports, source hashes and images in this iteration folder. No commits, reset, stash, global shader change, physics alteration, headset claim or production save-slot write was made.
