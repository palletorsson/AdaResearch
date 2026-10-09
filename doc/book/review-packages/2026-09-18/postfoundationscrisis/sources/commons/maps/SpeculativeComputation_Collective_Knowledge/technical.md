# Contribute — implementation and encounter

The primary artifact is `peer_production_tool`. Its [scene](../../../commons/artifacts/peer_production_tool/peer_production_tool.tscn) and [implementation](../../../commons/artifacts/peer_production_tool/peer_production_tool.gd) supply the behaviour described here.

Twelve generated peer positions send packets by default every 0.16 seconds. Each packet's life advances by delta*4; arrival calls _place_facet(). Sixty facets fill the display. Facet positions follow a prescribed helix, not negotiated knowledge. _reset_artifact() clears the form and _seen_peers but does not zero _edits or _contributors. The current contributor label counts source-version participation over time. This is recorded as a next improvement, not silently treated as a count of unique people.

## Operation to read after the encounter

```gdscript
_placed += 1
_edits += 1
# count distinct contributors this version
if peer_idx >= 0 and peer_idx < _seen_peers.size() and not bool(_seen_peers[peer_idx]):
    _seen_peers[peer_idx] = true
    _contributors += 1
```

Every accepted facet increments the edit count. The Boolean array _seen_peers lets the same source count only once within a version. On the next version those flags clear while the totals persist. A number labelled CONTRIBUTORS can therefore outgrow the twelve source positions. The code tells us what was counted more precisely than the label does.

## What to compare

Follow a packet from a rim node to the central form. Look for a second contribution from a source you have already seen. Watch a full version fill and restart; compare the new form with the counters that remain.

A returning source can add another facet without adding a new distinct source within that version. On reset the seen-peer flags clear, but the contributor counter persists. Across versions that number counts repeated participation, not unique people.

## Limits and next test

Separate lifetime edits, distinct sources in this version, and lifetime distinct sources in the readout. Check two complete cycles with a repeated source. Then add one disputed contribution whose revision changes an existing facet rather than increasing the pile.

This source audit does not establish headset readability, comfortable reach, collision clearance or frame rate. Those remain runtime observations. Existing supporting artifacts stay in the map; primary status identifies the book's encounter, not the only permitted content.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/SpeculativeComputation_Collective_Knowledge/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.
