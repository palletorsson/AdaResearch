# Transformation: the route between halls

The authored end of each hall now leads to its next hall. Seven native forward-and-return probes pass with a real XRTools player body and a simulated room-scale headset offset. Trans_Pre and Trans_Introduction also pass through the complete base scene's VR staging handoff. These are engine tests, not a physical headset or standalone Quest acceptance test.

## Repairs

- **Trans_Pre:** the old exit approached a descent ramp and was rejected. Its fallback appeared near the entrance. Added one flat row beyond the ramp, moved `t` from `(4,23)` to `(4,24)`, and placed the portal on the outward landing. All existing exhibits retain their cells.
- **Trans_Introduction:** aligned `sp` with a new three-cell central opening at `(5,0)` instead of the narrow side opening. The exit now stands beyond the pit bank on a supported approach.
- **Trans_Rotation:** the old accepted frame faced away from the visitor. Its authored portal now faces back into the hall.
- **Trans_Pit:** the legacy spawn near the left wall prevented a valid arrival from Trans_Body. Added museum `sp` at `(4,0)`, on the existing clear floor opening. Moved the exit frame outward beyond the airlock. The source `t` remains at `(7,31)`.
- **Simulation frames:** the four adjusted exit bridges allow 2.4 metres for the 2.1-metre portal frame. The opening remains within the authored floor gap; no original side walls are cut away by the stage builder.
- **Unloading:** the delayed grid-disarm fallback now holds a weak reference, so it cannot call the typed callback with an already-freed hall grid.

`map_info.museum.portal_exit` supports `{"approach":"from_hall","outset":2.3}`. Here `from_hall` fixes the approach to source −Z, and `outset` moves the frame toward +Z from its `t` cell. The offset is capped at the supported approach length. The frame and full approach still undergo collision checks; invalid candidates retain rejection reasons in diagnostics. Maps without this configuration keep their existing placement rules.

## Verification

The reports check authored exit selection, both transitions, floor support, capsule clearance, actual body settling, room-scale offset, no immediate bounce, and at most one resident hall. The four repaired exits additionally check orientation and support along the entire 2.3-metre approach at 0.1-metre intervals. Translation, Scale and Body required no authored layout changes.

The final hall currently leads to **Biome_Ladder_Transformation**, the existing spine interlude. This repair does not redirect it to Array.

An intermittent clearance failure in Introduction was traced to a chasing `Silhouette0`, not the floor. Its final structural test explicitly pauses and removes the roaming silhouettes' collisions inside the test instance. Other moving exhibits, the player body and architecture remain active. Combat behaviour is unchanged in the museum and is not certified by this test. Other final route reports passed with roaming enemies active.

No GDScript or freed-grid timer errors occur in the final seven runs. Pre-existing missing-UID and material warnings remain outside this repair.

## Reproduce

From the repository root, for each report/spec hall:

```powershell
python tools/run_encounter_probe.py Trans_Pre --sequence transformation --render --probe tools/probes/hall_portal_navigation.gd --spec doc/book/iterations/2026-09-29-transformation-passages/specs/Trans_Pre.json
```

Use the corresponding hall/spec for the other six. `--render` is needed for saved specs that request a screenshot. Specs were captured from the passing runs; the runner replaces their output-directory fields.

See `verification.json` for final source hashes, the seven individual reports, and `repair.diff` for this repair's changes relative to the pre-repair snapshot. Reopen the museum to load changed source. An already-exported standalone Quest application needs a fresh export; none was installed during this repair.
