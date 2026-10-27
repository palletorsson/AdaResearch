# Color Nails transfer — Codex

Six original placements, source scale, height, yaw and config retained.
A single translation of source cells (x - 7, z - 6) keeps the salon and two
controllers in their original relation. No artifacts were rebuilt. Shafts remain
outside the arrangement. Source 180-degree salon faces its two RGB controls.

The original controller uses GameManager nail/skin signals. Both display hands
subscribe independently; player hand meshes are found through the xr_origin
group. Test nail and skin changes separately, actual grab input, saved colour,
and retained values after floor residency changes. The science screen, colour
ball case and miniature brick wall remain separate editable placements.

The giant hand is 4.3 m tall on its original cuff. Its elevated title board may
slightly meet the standard six-metre storey ceiling; measure and record without
resizing the tower or editing the artifact. This is transfer, not curation.

Native findings: added two bounded Void adapters. The ball case now measures
its reset threshold and spawn position relative to its editable transform;
the source used world Y and teleported balls to world zero. The RGB controllers
resolve the current Void rig directly.
Original geometry, materials, colour signals and palette behavior remain.

The native probe exercises both RGB points with real mouse/right-grip input
and tracked XR grip input. It waits for idle-frame colour propagation rather
than assuming physics steps have already updated a material.

The source restores saved colours asynchronously. The probe observes channel
independence after approach/grab so startup loading is not mistaken for input
cross-talk. Cross-session colour persistence is outside this transfer's tests.
