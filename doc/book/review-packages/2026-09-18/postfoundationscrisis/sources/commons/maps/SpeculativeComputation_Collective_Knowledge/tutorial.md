# Does more activity mean more voices?

The situated panels preserved separate views. This machine sends contributions from a rim into one shared form.

<!-- @peer_production_tool -->

Follow a packet from a rim node to the central form. Look for a second contribution from a source you have already seen. Watch a full version fill and restart; compare the new form with the counters that remain.

A returning source can add another facet without adding a new distinct source within that version. On reset the seen-peer flags clear, but the contributor counter persists. Across versions that number counts repeated participation, not unique people.

The source makes the operation inspectable:

```gdscript
_placed += 1
_edits += 1
# count distinct contributors this version
if peer_idx >= 0 and peer_idx < _seen_peers.size() and not bool(_seen_peers[peer_idx]):
    _seen_peers[peer_idx] = true
    _contributors += 1
```

Every accepted facet increments the edit count. The Boolean array _seen_peers lets the same source count only once within a version. On the next version those flags clear while the totals persist. A number labelled CONTRIBUTORS can therefore outgrow the twelve source positions. The code tells us what was counted more precisely than the label does.

[Implementation](../../../commons/artifacts/peer_production_tool/peer_production_tool.gd). This is an excerpt from the artifact, not a standalone program.

The shape accepts every arriving contribution. No peer can challenge another's content, and no correction replaces an earlier facet. A growing form is a useful image of collective activity, but its smoothness conceals the work of maintaining knowledge. The counter exposes another loss: attendance across versions is not the same as a growing community. A commons needs ways to preserve disagreement, trace a revision and distinguish repair from accumulation.

<!-- @ -->

Many sources can still feed a single centre. The next machine changes the rule of connection.

## Next experiment — not yet a visitor control

Separate lifetime edits, distinct sources in this version, and lifetime distinct sources in the readout. Check two complete cycles with a repeated source. Then add one disputed contribution whose revision changes an existing facet rather than increasing the pile.
