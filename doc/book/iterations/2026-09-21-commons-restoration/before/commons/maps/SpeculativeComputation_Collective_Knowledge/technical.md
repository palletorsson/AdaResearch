# Contribute, preserve a source, revise a piece

This hall follows Situated Computation's four separate claims and leads to Rhizome Network's changing connections. Its primary is `peer_production_tool`; the [scene](../../../commons/artifacts/peer_production_tool/peer_production_tool.tscn) and [source](../../../commons/artifacts/peer_production_tool/peer_production_tool.gd) implement the encounter.

## First comparison

The hall uses twelve generated sources, sixty-piece capacity and a 0.7-second interval between packet launches. A packet advances with `delta * 4` and retains its sender index when it lands. The program chooses senders; they are not people choosing to participate. Piece positions follow an authored helix.

FLOW holds or resumes both packet motion and new launches. PIECE also holds flow and selects the next landed piece. A connecting line and P1–P12 identifiers let the visitor recover the selected source without relying on colour alone. COLOUR switches between the original purple-to-teal arrival-order gradient and source colours without changing geometry. Each landed record retains its source in either view.

## What the counts count

```gdscript
_placed += 1
_edits += 1
# count distinct contributors this version
if peer_idx >= 0 and peer_idx < _seen_peers.size() and not bool(_seen_peers[peer_idx]):
    _seen_peers[peer_idx] = true
    _contributors += 1
```

The historic `_contributors` counter remains cumulative source-version participation. It is labelled PARTICIPATIONS, correcting the earlier CONTRIBUTORS display without discarding its history. PIECES is the current form's occupancy; ADDITIONS is the lifetime arrival count. SOURCES counts distinct sources in this version; EVER counts distinct sources since this artifact's last rebuild. REVISIONS counts visitor revision operations separately. None counts unique humans.

VERSION retains one previous version in memory, clears the current records, pending packets and per-version flags, and waits for FLOW. Lifetime counts persist. At capacity, interactive placements hold the form; passive placements retain their automatic release behaviour. Configuration rebuild starts a fresh session, so these are not persistent saved totals.

## Dispute and revision

DISPUTE toggles a red outline on the selected existing record. REVISE rotates that piece another thirty degrees and alternates its height between original and 1.5 times original. Its source, location, addition count and current piece count do not change. Original and immediately previous transforms remain available in the record; `revised_by` records VISITOR and a revision number increments. Revision does not clear the dispute. This is a geometric editing demonstration, without semantic validation, agreement or a full history browser.

The central form uses a MultiMesh. Selection/dispute outlines share another MultiMesh so marking many pieces does not create twelve draw calls per outline. Source tracing is one cylinder. Dynamic counters use depth-tested Label3D text instead of caching an unbounded set of baked counter textures. Source records, packets, current geometry and retained previous version are bounded by the configured capacities. Rebuilding frees only owned children, preserving the museum's attached nodes.

## Placement and evidence

The full-size workbench remains at (6,5), now facing arrival. Two central pier cells become floor so that its front controls and central form can be reached and seen; four side piers remain. An explicit spawn at (6,1) and local dressing exclusions support approach. The other three authored tokens remain exactly placed.

The controlled museum probe tests actual button signals, repeated-source counting across versions, packet sender identity, held motion, colour-independent geometry, disputed revisions, capacity, safe empty operations, rebuild ownership, legacy behaviour and selected walks. Rendered desktop views are evidence of these selected states, not headset comfort, Quest performance or learning. See the [pass report](../../../doc/book/iterations/2026-09-20-collective-review/SUMMARY.md).

The existing wiki fragment and two other supporting tokens remain an ecology to develop. A single NORTH fragment still points to an absent EAST panel; this pass does not claim to complete that separate reading circuit. The earlier theoretical/design material remains in the [preserved proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/SpeculativeComputation_Collective_Knowledge/technical.md).
