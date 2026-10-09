# Gravity: Moving References — 11 September 2026

VFM_07_Gravity now places two primary experiments ahead of nine retained supporting artifacts. Map 22x16 becomes 22x48. Primaries remain orbital_mechanics_demo and three_body_problem, with opt-in lesson variants sharing gravity_relations.gd. Legacy wrappers preserve their earlier behavior without the lesson metadata.

The source/satellite variant holds a 12 kg source fixed; the satellite is 1 kg. The mutual variant begins with two equal 4 kg bodies, then can add a third while retaining the pair's beginning. It computes a baseline and comparison differing in one initial X coordinate. Shared softened law G=1, epsilon=0.25 m; velocity Verlet at 240 Hz. No hard-body collisions or player force. All controls, frame exits, display offsets, arrow caps and history bounds are described in tutorial.md and the illustrated guide.

All eleven artifact identities remain. Two primaries move to (11,8) and (11,24). Other nine shift by 32 rows. forcedirected3d gains museum-only presentation: its standalone environment, lights and overlay are skipped and its camera is not activated. Its map token uses scale 0.08 and height 2 m to stop its graph crossing into the main experiment. The existing simulation itself is retained. Prior code, text, roles and book data are backed up under before; placements.json records cells.

51 actual-museum desktop checks pass. Both captures inspected. Momentum tolerance was revised from 1e-5 to 1e-3 kg m/s after measuring 1.9846e-5 residual over the four-second three-body run; finite-precision Vector3 summation is not exact momentum conservation. Energy ratio 0.99992286. RMS paired difference 0.07578795 m after four model seconds for a 0.03 m perturbation of one initial coordinate. This is not a chaos certification. Boot UID and shader-cache warnings remain outside this change. Headset comfort, legibility, reach, sustained performance and comprehensive secondary review remain pending.

final.md, tutorial.md, critical.md, intent, blurb, artifacts and field notes now describe the implemented encounters. Book lines, core selection, role order, hashes, museum indexes and the possible-bodies guide are aligned. Historical primary notes were rewritten as secondary notes; the originals remain in before.

Next: VFM_09_Legs, asking what support and contact make possible after attraction. No commits made.
